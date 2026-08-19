from __future__ import annotations

import io

import pikepdf
from httpx import AsyncClient


async def test_reorder_pages(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    with pikepdf.open(io.BytesIO(simple_pdf_bytes)) as original:
        original_first_page_text = original.pages[0].Contents.read_bytes()

    response = await client.post(
        "/tools/reorder",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"order": "3,1,2"},
    )

    assert response.status_code == 200
    with pikepdf.open(io.BytesIO(response.content)) as reordered:
        assert len(reordered.pages) == 3
        assert reordered.pages[1].Contents.read_bytes() == original_first_page_text


async def test_reorder_rejects_incomplete_order(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/reorder",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"order": "1,2"},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"
