from __future__ import annotations

import io

import pikepdf
from httpx import AsyncClient


async def test_protect_router_happy_path(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    response = await client.post(
        "/tools/protect",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"password": "correct-secret", "no_print": "true"},
    )

    assert response.status_code == 200
    with pikepdf.open(io.BytesIO(response.content), password="correct-secret") as pdf:
        assert pdf.allow.print_highres is False


async def test_protect_rejects_short_password(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/protect",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"password": "ab"},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"
