from __future__ import annotations

from pathlib import Path

import pikepdf

from app.core.errors import InvalidRequestError, ProcessingFailedError, UnsupportedFormatError
from app.features.rotate.schemas import RotationAngle


class RotateService:
    def rotate(
        self,
        input_path: Path,
        output_path: Path,
        angle: RotationAngle,
        page_numbers: list[int] | None,
    ) -> None:
        try:
            with pikepdf.open(input_path) as pdf:
                targets = self._resolve_targets(pdf, page_numbers)
                for page_number in targets:
                    pdf.pages[page_number - 1].rotate(int(angle), relative=True)
                pdf.save(output_path)
        except pikepdf.PasswordError as exc:
            raise UnsupportedFormatError("The PDF is password-protected.") from exc
        except pikepdf.PdfError as exc:
            raise ProcessingFailedError() from exc

    def _resolve_targets(self, pdf: pikepdf.Pdf, page_numbers: list[int] | None) -> list[int]:
        page_count = len(pdf.pages)
        if page_numbers is None:
            return list(range(1, page_count + 1))
        if any(number < 1 or number > page_count for number in page_numbers):
            raise InvalidRequestError(f"Page numbers must be between 1 and {page_count}.")
        return page_numbers
