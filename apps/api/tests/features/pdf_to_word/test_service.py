"""Real-LibreOffice integration tests. Excluded from the default run — see pyproject.toml.

Requires `soffice` on PATH or `LIBREOFFICE_BINARY` pointed at it (see .env.example) —
on macOS that's typically /Applications/LibreOffice.app/Contents/MacOS/soffice, not on PATH
by default.
"""

from __future__ import annotations

import zipfile
from pathlib import Path

import pytest

from app.config import get_settings
from app.features.pdf_to_word.service import PdfToWordService

FIXTURES_DIR = Path(__file__).parent.parent.parent / "fixtures"

pytestmark = pytest.mark.integration


async def test_convert_produces_a_docx_with_the_original_text(tmp_path: Path) -> None:
    settings = get_settings()

    output_path = await PdfToWordService().convert(
        FIXTURES_DIR / "sample_simple.pdf",
        tmp_path,
        settings.libreoffice_binary,
        settings.libreoffice_timeout_seconds,
    )

    assert output_path.exists()
    with zipfile.ZipFile(output_path) as archive:
        document_xml = archive.read("word/document.xml").decode("utf-8")
        assert "Doclyvo fixture" in document_xml
