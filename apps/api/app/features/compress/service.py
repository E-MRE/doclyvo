from __future__ import annotations

import io
from pathlib import Path

import pikepdf
from pikepdf import Name, PdfImage

from app.core.errors import ProcessingFailedError, UnsupportedFormatError
from app.features.compress.schemas import CompressQuality

JPEG_QUALITY_BY_LEVEL: dict[CompressQuality, int] = {
    CompressQuality.LOW: 85,
    CompressQuality.RECOMMENDED: 60,
    CompressQuality.HIGH: 30,
}


class CompressService:
    def compress(self, input_path: Path, output_path: Path, quality: CompressQuality) -> None:
        jpeg_quality = JPEG_QUALITY_BY_LEVEL[quality]
        try:
            with pikepdf.open(input_path) as pdf:
                for page in pdf.pages:
                    for image_object in list(page.get_images().values()):
                        self._recompress_image(image_object, jpeg_quality)
                pdf.save(
                    output_path,
                    compress_streams=True,
                    object_stream_mode=pikepdf.ObjectStreamMode.generate,
                )
        except pikepdf.PasswordError as exc:
            raise UnsupportedFormatError("The PDF is password-protected.") from exc
        except pikepdf.PdfError as exc:
            raise ProcessingFailedError() from exc

    def _recompress_image(self, image_object: pikepdf.Object, jpeg_quality: int) -> None:
        try:
            pil_image = PdfImage(image_object).as_pil_image()
        except Exception:
            return

        if pil_image.mode not in ("RGB", "L"):
            pil_image = pil_image.convert("RGB")

        buffer = io.BytesIO()
        pil_image.save(buffer, format="JPEG", quality=jpeg_quality, optimize=True)

        image_object.write(buffer.getvalue(), filter=Name("/DCTDecode"))
        colorspace = Name("/DeviceGray") if pil_image.mode == "L" else Name("/DeviceRGB")
        image_object.ColorSpace = colorspace
        image_object.BitsPerComponent = 8
        if "/SMask" in image_object:
            del image_object["/SMask"]
