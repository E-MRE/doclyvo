from __future__ import annotations

from pathlib import Path

import pymupdf
import pytest

from app.core.errors import InvalidRequestError, UnsupportedFormatError
from app.features.redact.schemas import RedactRegion
from app.features.redact.service import RedactService

FIXTURES_DIR = Path(__file__).parent.parent.parent / "fixtures"


def test_redact_removes_text_from_the_target_page_only(tmp_path: Path) -> None:
    output_path = tmp_path / "out.pdf"

    RedactService().redact(
        FIXTURES_DIR / "sample_simple.pdf",
        output_path,
        [RedactRegion(page_number=1, x=0.0, y=0.0, width=1.0, height=1.0)],
    )

    assert output_path.exists()
    document = pymupdf.open(output_path)
    try:
        assert len(document) == 3
        assert "Doclyvo fixture" not in document[0].get_text()
        assert "Doclyvo fixture" in document[1].get_text()
        assert "Doclyvo fixture" in document[2].get_text()
    finally:
        document.close()


def test_redact_leaves_untargeted_regions_of_the_page_intact(tmp_path: Path) -> None:
    output_path = tmp_path / "out.pdf"

    # Fixture text sits near the top of the page — a region confined to the bottom half
    # must not touch it.
    RedactService().redact(
        FIXTURES_DIR / "sample_simple.pdf",
        output_path,
        [RedactRegion(page_number=1, x=0.0, y=0.6, width=1.0, height=0.4)],
    )

    document = pymupdf.open(output_path)
    try:
        assert "Doclyvo fixture" in document[0].get_text()
    finally:
        document.close()


def test_redact_raises_on_encrypted_pdf(tmp_path: Path) -> None:
    with pytest.raises(UnsupportedFormatError):
        RedactService().redact(
            FIXTURES_DIR / "sample_encrypted.pdf",
            tmp_path / "out.pdf",
            [RedactRegion(page_number=1, x=0.0, y=0.0, width=1.0, height=1.0)],
        )


def test_redact_raises_on_page_number_beyond_page_count(tmp_path: Path) -> None:
    with pytest.raises(InvalidRequestError):
        RedactService().redact(
            FIXTURES_DIR / "sample_simple.pdf",
            tmp_path / "out.pdf",
            [RedactRegion(page_number=99, x=0.0, y=0.0, width=1.0, height=1.0)],
        )
