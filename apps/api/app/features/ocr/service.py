from __future__ import annotations

import io
from pathlib import Path

import pikepdf
import pymupdf
import pytesseract
from PIL import Image

from app.core.errors import ProcessingFailedError, UnsupportedFormatError
from app.features.ocr.schemas import OcrLanguage, OcrOutputFormat

_RENDER_DPI = 200
_TESSERACT_LANGUAGE_BY_CODE: dict[OcrLanguage, str] = {
    OcrLanguage.TR: "tur",
    OcrLanguage.EN: "eng",
}


class OcrService:
    def recognize(
        self,
        input_path: Path,
        output_path: Path,
        language: OcrLanguage,
        output_format: OcrOutputFormat,
    ) -> None:
        tesseract_language = _TESSERACT_LANGUAGE_BY_CODE[language]

        try:
            document = pymupdf.open(input_path)
        except pymupdf.FileDataError as exc:
            raise ProcessingFailedError() from exc

        try:
            if document.needs_pass:
                raise UnsupportedFormatError("The PDF is password-protected.")

            if output_format == OcrOutputFormat.TEXT:
                self._write_text(document, output_path, tesseract_language)
            else:
                self._write_searchable_pdf(document, output_path, tesseract_language)
        finally:
            document.close()

    def _write_text(self, document: pymupdf.Document, output_path: Path, language: str) -> None:
        chunks = [
            pytesseract.image_to_string(self._render(page), lang=language) for page in document
        ]
        output_path.write_text("\n\n".join(chunks), encoding="utf-8")

    def _write_searchable_pdf(
        self, document: pymupdf.Document, output_path: Path, language: str
    ) -> None:
        with pikepdf.Pdf.new() as merged:
            for page in document:
                page_pdf_bytes = pytesseract.image_to_pdf_or_hocr(
                    self._render(page), lang=language, extension="pdf"
                )
                with pikepdf.open(io.BytesIO(page_pdf_bytes)) as page_pdf:
                    merged.pages.extend(page_pdf.pages)
            merged.save(output_path)

    def _render(self, page: pymupdf.Page) -> Image.Image:
        pixmap = page.get_pixmap(dpi=_RENDER_DPI)
        return Image.frombytes("RGB", (pixmap.width, pixmap.height), pixmap.samples)
