from __future__ import annotations

from pathlib import Path

from app.core.libreoffice import convert_via_libreoffice


class PdfToWordService:
    async def convert(
        self,
        input_path: Path,
        output_dir: Path,
        libreoffice_binary: str,
        timeout_seconds: int,
    ) -> Path:
        return await convert_via_libreoffice(
            input_path, "docx", output_dir, libreoffice_binary, timeout_seconds
        )
