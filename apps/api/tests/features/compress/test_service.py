from __future__ import annotations

from pathlib import Path

import pikepdf
import pytest

from app.core.errors import UnsupportedFormatError
from app.features.compress.schemas import CompressQuality
from app.features.compress.service import CompressService

FIXTURES_DIR = Path(__file__).parent.parent.parent / "fixtures"


def test_compress_recompresses_embedded_images(tmp_path: Path) -> None:
    output_path = tmp_path / "out.pdf"

    CompressService().compress(
        FIXTURES_DIR / "sample_with_image.pdf", output_path, CompressQuality.HIGH
    )

    assert output_path.exists()
    with pikepdf.open(output_path) as pdf:
        assert len(pdf.pages) == 1


def test_compress_raises_on_encrypted_pdf(tmp_path: Path) -> None:
    with pytest.raises(UnsupportedFormatError):
        CompressService().compress(
            FIXTURES_DIR / "sample_encrypted.pdf", tmp_path / "out.pdf", CompressQuality.LOW
        )
