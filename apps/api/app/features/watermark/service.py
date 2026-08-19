from __future__ import annotations

import io
from pathlib import Path

import pikepdf
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas as reportlab_canvas

from app.core.errors import ProcessingFailedError, UnsupportedFormatError
from app.features.watermark.schemas import WatermarkOpacity, WatermarkPosition

_FONT_NAME = "DejaVuSans-Bold"
_FONT_PATH = Path(__file__).resolve().parents[3] / "assets" / "fonts" / "DejaVuSans-Bold.ttf"
pdfmetrics.registerFont(TTFont(_FONT_NAME, str(_FONT_PATH)))

_ACCENT_RGB = (0.86, 0.28, 0.19)
_OPACITY_BY_LEVEL: dict[WatermarkOpacity, float] = {
    WatermarkOpacity.LIGHT: 0.18,
    WatermarkOpacity.MEDIUM: 0.35,
    WatermarkOpacity.STRONG: 0.55,
}
_ROTATION_DEGREES_BY_POSITION: dict[WatermarkPosition, int] = {
    WatermarkPosition.CENTER: 0,
    WatermarkPosition.DIAGONAL: -30,
    WatermarkPosition.CORNER: 0,
}


class WatermarkService:
    def add_watermark(
        self,
        input_path: Path,
        output_path: Path,
        text: str,
        position: WatermarkPosition,
        opacity: WatermarkOpacity,
    ) -> None:
        try:
            with pikepdf.open(input_path) as pdf:
                for page in pdf.pages:
                    mediabox = page.mediabox
                    width = float(mediabox[2] - mediabox[0])
                    height = float(mediabox[3] - mediabox[1])
                    overlay_bytes = self._build_overlay(width, height, text, position, opacity)
                    with pikepdf.open(io.BytesIO(overlay_bytes)) as overlay_pdf:
                        page.add_overlay(overlay_pdf.pages[0])
                pdf.save(output_path)
        except pikepdf.PasswordError as exc:
            raise UnsupportedFormatError("The PDF is password-protected.") from exc
        except pikepdf.PdfError as exc:
            raise ProcessingFailedError() from exc

    def _build_overlay(
        self,
        width: float,
        height: float,
        text: str,
        position: WatermarkPosition,
        opacity: WatermarkOpacity,
    ) -> bytes:
        buffer = io.BytesIO()
        canvas = reportlab_canvas.Canvas(buffer, pagesize=(width, height))
        canvas.setFillColorRGB(*_ACCENT_RGB)
        canvas.setFillAlpha(_OPACITY_BY_LEVEL[opacity])
        canvas.setFont(_FONT_NAME, 40)

        canvas.saveState()
        if position == WatermarkPosition.CORNER:
            canvas.translate(width - 40, 40)
            canvas.drawRightString(0, 0, text)
        else:
            canvas.translate(width / 2, height / 2)
            canvas.rotate(_ROTATION_DEGREES_BY_POSITION[position])
            canvas.drawCentredString(0, 0, text)
        canvas.restoreState()

        canvas.save()
        return buffer.getvalue()
