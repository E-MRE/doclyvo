"""Real-tesseract integration tests. Excluded from the default run — see pyproject.toml."""

from __future__ import annotations

from pathlib import Path

import pikepdf
import pytest

from app.features.ocr.schemas import OcrLanguage, OcrOutputFormat
from app.features.ocr.service import OcrService

FIXTURES_DIR = Path(__file__).parent.parent.parent / "fixtures"

pytestmark = pytest.mark.integration


def test_ocr_recognizes_text_from_a_rendered_page(tmp_path: Path) -> None:
    output_path = tmp_path / "out.txt"

    OcrService().recognize(
        FIXTURES_DIR / "sample_simple.pdf", output_path, OcrLanguage.EN, OcrOutputFormat.TEXT
    )

    text = output_path.read_text(encoding="utf-8")
    assert "Doclyvo fixture" in text
    assert "page 1" in text


def test_ocr_produces_a_searchable_pdf(tmp_path: Path) -> None:
    output_path = tmp_path / "out.pdf"

    OcrService().recognize(
        FIXTURES_DIR / "sample_simple.pdf",
        output_path,
        OcrLanguage.EN,
        OcrOutputFormat.SEARCHABLE,
    )

    with pikepdf.open(output_path) as pdf:
        assert len(pdf.pages) == 3
