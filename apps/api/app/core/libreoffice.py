from __future__ import annotations

import asyncio
import logging
from pathlib import Path

from app.core.errors import ProcessingFailedError

logger = logging.getLogger("doclyvo")

_PDF_IMPORT_FILTER = "writer_pdf_import"
_EXPORT_FILTER_BY_FORMAT = {"docx": "MS Word 2007 XML"}


async def convert_via_libreoffice(
    input_path: Path,
    output_format: str,
    output_dir: Path,
    libreoffice_binary: str,
    timeout_seconds: int,
) -> Path:
    export_filter = _EXPORT_FILTER_BY_FORMAT.get(output_format)
    if export_filter is None:
        raise ProcessingFailedError()

    try:
        process = await asyncio.create_subprocess_exec(
            libreoffice_binary,
            "--headless",
            "--convert-to",
            f"{output_format}:{export_filter}",
            f"--infilter={_PDF_IMPORT_FILTER}",
            "--outdir",
            str(output_dir),
            str(input_path),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        _, stderr = await asyncio.wait_for(process.communicate(), timeout=timeout_seconds)
    except (FileNotFoundError, TimeoutError) as exc:
        logger.exception("LibreOffice conversion failed to run")
        raise ProcessingFailedError() from exc

    output_path = output_dir / f"{input_path.stem}.{output_format}"
    if process.returncode != 0 or not output_path.exists():
        logger.error("LibreOffice conversion failed: %s", stderr.decode(errors="replace"))
        raise ProcessingFailedError()

    return output_path
