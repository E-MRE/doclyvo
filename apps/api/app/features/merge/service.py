from __future__ import annotations

from pathlib import Path

import pikepdf

from app.core.errors import ProcessingFailedError, UnsupportedFormatError


class MergeService:
    def merge(self, input_paths: list[Path], output_path: Path) -> int:
        try:
            with pikepdf.Pdf.new() as merged:
                for path in input_paths:
                    with pikepdf.open(path) as source:
                        merged.pages.extend(source.pages)
                merged.save(output_path)
                return len(merged.pages)
        except pikepdf.PasswordError as exc:
            raise UnsupportedFormatError("One of the files is password-protected.") from exc
        except pikepdf.PdfError as exc:
            raise ProcessingFailedError() from exc
