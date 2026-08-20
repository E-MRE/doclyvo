from __future__ import annotations

import io
from pathlib import Path

import pikepdf
from PIL import Image, UnidentifiedImageError
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas as reportlab_canvas

from app.core.errors import InvalidRequestError, ProcessingFailedError, UnsupportedFormatError
from app.features.sign.schemas import SignatureMode

_FONT_NAME = "Caveat-SemiBold"
_FONT_PATH = Path(__file__).resolve().parents[3] / "assets" / "fonts" / "Caveat-SemiBold.ttf"
pdfmetrics.registerFont(TTFont(_FONT_NAME, str(_FONT_PATH)))


class SignService:
    def sign(
        self,
        input_path: Path,
        output_path: Path,
        mode: SignatureMode,
        page_number: int,
        x: float,
        y: float,
        width: float,
        height: float,
        signature_image_path: Path | None = None,
        signature_text: str | None = None,
    ) -> None:
        try:
            with pikepdf.open(input_path) as pdf:
                if page_number < 1 or page_number > len(pdf.pages):
                    raise InvalidRequestError(
                        f"page_number must be between 1 and {len(pdf.pages)}."
                    )
                page = pdf.pages[page_number - 1]
                mediabox = page.mediabox
                page_width = float(mediabox[2] - mediabox[0])
                page_height = float(mediabox[3] - mediabox[1])
                overlay_bytes = self._build_overlay(
                    page_width,
                    page_height,
                    mode,
                    x,
                    y,
                    width,
                    height,
                    signature_image_path,
                    signature_text,
                )
                with pikepdf.open(io.BytesIO(overlay_bytes)) as overlay_pdf:
                    page.add_overlay(overlay_pdf.pages[0])
                pdf.save(output_path)
        except pikepdf.PasswordError as exc:
            raise UnsupportedFormatError("The PDF is password-protected.") from exc
        except pikepdf.PdfError as exc:
            raise ProcessingFailedError() from exc

    def _build_overlay(
        self,
        page_width: float,
        page_height: float,
        mode: SignatureMode,
        x: float,
        y: float,
        width: float,
        height: float,
        signature_image_path: Path | None,
        signature_text: str | None,
    ) -> bytes:
        box_width = width * page_width
        box_height = height * page_height
        box_x = x * page_width
        box_y = page_height - y * page_height - box_height

        buffer = io.BytesIO()
        canvas = reportlab_canvas.Canvas(buffer, pagesize=(page_width, page_height))

        if mode == SignatureMode.TYPE:
            text = (signature_text or "").strip()
            canvas.setFont(_FONT_NAME, box_height * 0.6)
            canvas.drawCentredString(box_x + box_width / 2, box_y + box_height * 0.3, text)
        else:
            assert signature_image_path is not None
            try:
                with Image.open(signature_image_path) as image:
                    image.verify()
            except (OSError, UnidentifiedImageError) as exc:
                raise UnsupportedFormatError("The signature image could not be read.") from exc
            canvas.drawImage(
                ImageReader(str(signature_image_path)),
                box_x,
                box_y,
                box_width,
                box_height,
                mask="auto",
                preserveAspectRatio=True,
                anchor="c",
            )

        canvas.save()
        return buffer.getvalue()
