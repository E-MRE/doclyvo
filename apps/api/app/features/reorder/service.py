from __future__ import annotations

from pathlib import Path

import pikepdf

from app.core.errors import InvalidRequestError, ProcessingFailedError, UnsupportedFormatError


class ReorderService:
    def reorder(self, input_path: Path, output_path: Path, page_order: list[int]) -> None:
        try:
            with pikepdf.open(input_path) as pdf:
                page_count = len(pdf.pages)
                self._validate_order(page_order, page_count)
                reordered = pikepdf.Pdf.new()
                for page_number in page_order:
                    reordered.pages.append(pdf.pages[page_number - 1])
                reordered.save(output_path)
                reordered.close()
        except pikepdf.PasswordError as exc:
            raise UnsupportedFormatError("The PDF is password-protected.") from exc
        except pikepdf.PdfError as exc:
            raise ProcessingFailedError() from exc

    def _validate_order(self, page_order: list[int], page_count: int) -> None:
        if sorted(page_order) != list(range(1, page_count + 1)):
            raise InvalidRequestError(
                f"order must contain each page from 1 to {page_count} exactly once."
            )
