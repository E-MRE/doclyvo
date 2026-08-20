from __future__ import annotations

from pathlib import Path

import pymupdf
import pytest

from app.core.errors import InvalidRequestError, UnsupportedFormatError
from app.features.sign.schemas import SignatureMode
from app.features.sign.service import SignService

FIXTURES_DIR = Path(__file__).parent.parent.parent / "fixtures"
_PLACEMENT = (0.6, 0.78, 0.32, 0.1)


def test_sign_type_mode_renders_text_on_target_page_only(tmp_path: Path) -> None:
    output_path = tmp_path / "out.pdf"

    SignService().sign(
        FIXTURES_DIR / "sample_simple.pdf",
        output_path,
        SignatureMode.TYPE,
        2,
        *_PLACEMENT,
        signature_text="Emre Gültekir",
    )

    assert output_path.exists()
    document = pymupdf.open(output_path)
    try:
        assert len(document) == 3
        assert "Emre Gültekir" in document[1].get_text()
        assert "Emre Gültekir" not in document[0].get_text()
        assert "Emre Gültekir" not in document[2].get_text()
    finally:
        document.close()


def test_sign_upload_mode_renders_image_on_target_page_only(tmp_path: Path) -> None:
    output_path = tmp_path / "out.pdf"

    SignService().sign(
        FIXTURES_DIR / "sample_simple.pdf",
        output_path,
        SignatureMode.UPLOAD,
        1,
        *_PLACEMENT,
        signature_image_path=FIXTURES_DIR / "sample_signature.png",
    )

    document = pymupdf.open(output_path)
    try:
        assert len(document[0].get_images()) > 0
        assert len(document[1].get_images()) == 0
    finally:
        document.close()


def test_sign_raises_on_encrypted_pdf(tmp_path: Path) -> None:
    with pytest.raises(UnsupportedFormatError):
        SignService().sign(
            FIXTURES_DIR / "sample_encrypted.pdf",
            tmp_path / "out.pdf",
            SignatureMode.TYPE,
            1,
            *_PLACEMENT,
            signature_text="Emre",
        )


def test_sign_raises_on_invalid_signature_image(tmp_path: Path) -> None:
    bad_image = tmp_path / "not-an-image.png"
    bad_image.write_bytes(b"not a real png")

    with pytest.raises(UnsupportedFormatError):
        SignService().sign(
            FIXTURES_DIR / "sample_simple.pdf",
            tmp_path / "out.pdf",
            SignatureMode.UPLOAD,
            1,
            *_PLACEMENT,
            signature_image_path=bad_image,
        )


def test_sign_raises_on_page_number_beyond_page_count(tmp_path: Path) -> None:
    with pytest.raises(InvalidRequestError):
        SignService().sign(
            FIXTURES_DIR / "sample_simple.pdf",
            tmp_path / "out.pdf",
            SignatureMode.TYPE,
            99,
            *_PLACEMENT,
            signature_text="Emre",
        )
