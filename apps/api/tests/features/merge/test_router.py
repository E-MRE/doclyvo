from __future__ import annotations

from httpx import AsyncClient


async def test_merge_combines_pages_in_order(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    files = [
        ("files", ("a.pdf", simple_pdf_bytes, "application/pdf")),
        ("files", ("b.pdf", simple_pdf_bytes, "application/pdf")),
    ]

    response = await client.post("/tools/merge", files=files)

    assert response.status_code == 200
    assert response.headers["x-page-count"] == "6"
    assert response.content.startswith(b"%PDF")


async def test_merge_requires_at_least_two_files(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    files = [("files", ("a.pdf", simple_pdf_bytes, "application/pdf"))]

    response = await client.post("/tools/merge", files=files)

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


async def test_merge_rejects_password_protected_file(
    client: AsyncClient, simple_pdf_bytes: bytes, encrypted_pdf_bytes: bytes
) -> None:
    files = [
        ("files", ("a.pdf", simple_pdf_bytes, "application/pdf")),
        ("files", ("locked.pdf", encrypted_pdf_bytes, "application/pdf")),
    ]

    response = await client.post("/tools/merge", files=files)

    assert response.status_code == 415
    assert response.json()["error"]["code"] == "unsupported_format"
