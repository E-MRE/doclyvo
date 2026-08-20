from __future__ import annotations

from pathlib import Path

import pymupdf

from app.core.errors import InvalidRequestError, ProcessingFailedError, UnsupportedFormatError
from app.features.redact.schemas import RedactRegion


class RedactService:
    def redact(self, input_path: Path, output_path: Path, regions: list[RedactRegion]) -> None:
        try:
            document = pymupdf.open(input_path)
        except pymupdf.FileDataError as exc:
            raise ProcessingFailedError() from exc

        try:
            if document.needs_pass:
                raise UnsupportedFormatError("The PDF is password-protected.")

            page_count = document.page_count
            for region in regions:
                if region.page_number > page_count:
                    raise InvalidRequestError(f"page_number must be between 1 and {page_count}.")
                page = document[region.page_number - 1]
                page.add_redact_annot(self._to_page_rect(page, region), fill=(0, 0, 0))

            for page in document:
                page.apply_redactions()

            document.save(output_path)
        finally:
            document.close()

    def _to_page_rect(self, page: pymupdf.Page, region: RedactRegion) -> pymupdf.Rect:
        page_width = page.rect.width
        page_height = page.rect.height
        x0 = region.x * page_width
        y0 = region.y * page_height
        x1 = x0 + region.width * page_width
        y1 = y0 + region.height * page_height
        return pymupdf.Rect(x0, y0, x1, y1)
