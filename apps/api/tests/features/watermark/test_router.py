from __future__ import annotations

from httpx import AsyncClient


async def test_watermark_router_happy_path(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    response = await client.post(
        "/tools/watermark",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"text": "TASLAK", "position": "diagonal", "opacity": "medium"},
    )

    assert response.status_code == 200
    assert response.content.startswith(b"%PDF")


async def test_watermark_rejects_empty_text(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/watermark",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"text": "   "},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


async def test_watermark_rejects_password_protected_file(
    client: AsyncClient, encrypted_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/watermark",
        files={"file": ("locked.pdf", encrypted_pdf_bytes, "application/pdf")},
        data={"text": "TASLAK"},
    )

    assert response.status_code == 415
    assert response.json()["error"]["code"] == "unsupported_format"
