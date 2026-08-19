from __future__ import annotations

from httpx import AsyncClient


async def test_compress_returns_smaller_or_equal_pdf(
    client: AsyncClient, image_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/compress",
        files={"file": ("sample.pdf", image_pdf_bytes, "application/pdf")},
        data={"quality": "high"},
    )

    assert response.status_code == 200
    assert response.content.startswith(b"%PDF")
    compressed_size = int(response.headers["x-compressed-size"])
    original_size = int(response.headers["x-original-size"])
    assert compressed_size <= original_size


async def test_compress_defaults_to_recommended_quality(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/compress",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
    )

    assert response.status_code == 200


async def test_compress_rejects_password_protected_file(
    client: AsyncClient, encrypted_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/compress",
        files={"file": ("locked.pdf", encrypted_pdf_bytes, "application/pdf")},
    )

    assert response.status_code == 415
    assert response.json()["error"]["code"] == "unsupported_format"
