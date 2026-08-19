from __future__ import annotations

import io

import pikepdf
from httpx import AsyncClient


async def test_rotate_all_pages(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    response = await client.post(
        "/tools/rotate",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"angle": "90"},
    )

    assert response.status_code == 200
    with pikepdf.open(io.BytesIO(response.content)) as pdf:
        assert all(int(page.get("/Rotate", 0)) == 90 for page in pdf.pages)


async def test_rotate_specific_pages(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    response = await client.post(
        "/tools/rotate",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"angle": "180", "pages": "1"},
    )

    assert response.status_code == 200
    with pikepdf.open(io.BytesIO(response.content)) as pdf:
        assert int(pdf.pages[0].get("/Rotate", 0)) == 180
        assert int(pdf.pages[1].get("/Rotate", 0)) == 0


async def test_rotate_rejects_out_of_range_page(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/rotate",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"angle": "90", "pages": "99"},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"
