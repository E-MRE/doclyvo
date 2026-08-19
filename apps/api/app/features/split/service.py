from __future__ import annotations

import zipfile
from pathlib import Path

import pikepdf

from app.core.errors import ProcessingFailedError, UnsupportedFormatError


class SplitService:
    def split(self, input_path: Path, output_dir: Path, zip_path: Path) -> int:
        try:
            with pikepdf.open(input_path) as pdf:
                page_count = len(pdf.pages)
                with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
                    for index in range(page_count):
                        page_path = output_dir / f"page-{index + 1}.pdf"
                        with pikepdf.Pdf.new() as single_page:
                            single_page.pages.append(pdf.pages[index])
                            single_page.save(page_path)
                        archive.write(page_path, arcname=page_path.name)
                return page_count
        except pikepdf.PasswordError as exc:
            raise UnsupportedFormatError("The PDF is password-protected.") from exc
        except pikepdf.PdfError as exc:
            raise ProcessingFailedError() from exc
