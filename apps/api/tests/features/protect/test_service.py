from __future__ import annotations

from pathlib import Path

import pikepdf
import pytest

from app.features.protect.service import ProtectService

FIXTURES_DIR = Path(__file__).parent.parent.parent / "fixtures"


def test_protect_encrypts_with_the_given_password(tmp_path: Path) -> None:
    output_path = tmp_path / "out.pdf"

    ProtectService().protect(
        FIXTURES_DIR / "sample_simple.pdf",
        output_path,
        "correct-secret",
        no_print=True,
        no_copy=False,
        no_edit=False,
    )

    with pytest.raises(pikepdf.PasswordError):
        pikepdf.open(output_path)

    with pikepdf.open(output_path, password="correct-secret") as pdf:
        assert len(pdf.pages) == 3
        assert pdf.allow.print_highres is False
        assert pdf.allow.print_lowres is False
        assert pdf.allow.extract is True


def test_protect_no_copy_restricts_extraction(tmp_path: Path) -> None:
    output_path = tmp_path / "out.pdf"

    ProtectService().protect(
        FIXTURES_DIR / "sample_simple.pdf",
        output_path,
        "correct-secret",
        no_print=False,
        no_copy=True,
        no_edit=True,
    )

    with pikepdf.open(output_path, password="correct-secret") as pdf:
        assert pdf.allow.extract is False
        assert pdf.allow.modify_other is False
        assert pdf.allow.print_highres is True
