from __future__ import annotations

from pathlib import Path

import pytest
from httpx import AsyncClient

from app.features.pdf_to_word.service import PdfToWordService


@pytest.fixture(autouse=True)
def _mock_pdf_to_word_service(monkeypatch: pytest.MonkeyPatch) -> None:
    async def fake_convert(
        self: PdfToWordService,
        input_path: Path,
        output_dir: Path,
        libreoffice_binary: str,
        timeout_seconds: int,
    ) -> Path:
        output_path = output_dir / "converted.docx"
        output_path.write_bytes(b"PK\x03\x04fake docx contents")
        return output_path

    monkeypatch.setattr(PdfToWordService, "convert", fake_convert)


async def test_convert_router_happy_path(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    response = await client.post(
        "/tools/pdf-to-word",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
    )

    assert response.status_code == 200
    assert (
        response.headers["content-type"]
        == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    )
    assert response.content.startswith(b"PK")
