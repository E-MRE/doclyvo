from __future__ import annotations

from pathlib import Path

import pikepdf
import pymupdf
import pytest

from app.core.errors import UnsupportedFormatError
from app.features.watermark.schemas import WatermarkOpacity, WatermarkPosition
from app.features.watermark.service import WatermarkService

FIXTURES_DIR = Path(__file__).parent.parent.parent / "fixtures"


def test_watermark_applies_to_every_page(tmp_path: Path) -> None:
    output_path = tmp_path / "out.pdf"

    WatermarkService().add_watermark(
        FIXTURES_DIR / "sample_simple.pdf",
        output_path,
        "TASLAK",
        WatermarkPosition.DIAGONAL,
        WatermarkOpacity.MEDIUM,
    )

    assert output_path.exists()
    with pikepdf.open(output_path) as pdf:
        assert len(pdf.pages) == 3

    document = pymupdf.open(output_path)
    try:
        for page in document:
            assert "TASLAK" in page.get_text()
    finally:
        document.close()


def test_watermark_corner_position(tmp_path: Path) -> None:
    output_path = tmp_path / "out.pdf"

    WatermarkService().add_watermark(
        FIXTURES_DIR / "sample_simple.pdf",
        output_path,
        "GİZLİ",
        WatermarkPosition.CORNER,
        WatermarkOpacity.STRONG,
    )

    document = pymupdf.open(output_path)
    try:
        assert "GİZLİ" in document[0].get_text()
    finally:
        document.close()


def test_watermark_raises_on_encrypted_pdf(tmp_path: Path) -> None:
    with pytest.raises(UnsupportedFormatError):
        WatermarkService().add_watermark(
            FIXTURES_DIR / "sample_encrypted.pdf",
            tmp_path / "out.pdf",
            "TASLAK",
            WatermarkPosition.CENTER,
            WatermarkOpacity.LIGHT,
        )
