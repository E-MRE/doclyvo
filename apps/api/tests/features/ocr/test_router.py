from __future__ import annotations

from pathlib import Path

import pytest
from httpx import AsyncClient

from app.features.ocr.schemas import OcrLanguage, OcrOutputFormat
from app.features.ocr.service import OcrService


@pytest.fixture(autouse=True)
def _mock_ocr_service(monkeypatch: pytest.MonkeyPatch) -> None:
    def fake_recognize(
        self: OcrService,
        input_path: Path,
        output_path: Path,
        language: OcrLanguage,
        output_format: OcrOutputFormat,
    ) -> None:
        if output_format == OcrOutputFormat.TEXT:
            output_path.write_text("recognized text", encoding="utf-8")
        else:
            output_path.write_bytes(b"%PDF-1.4 fake searchable pdf")

    monkeypatch.setattr(OcrService, "recognize", fake_recognize)


async def test_ocr_router_returns_text_file(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    response = await client.post(
        "/tools/ocr",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"language": "en", "output_format": "text"},
    )

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/plain")
    assert response.text == "recognized text"


async def test_ocr_router_returns_searchable_pdf(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/ocr",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"language": "tr", "output_format": "searchable"},
    )

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"


async def test_ocr_router_defaults_to_turkish_searchable(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/ocr",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
    )

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
