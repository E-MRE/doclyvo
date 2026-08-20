from __future__ import annotations

import json

from httpx import AsyncClient


def _regions(**overrides: object) -> str:
    region = {"page_number": 1, "x": 0.0, "y": 0.0, "width": 1.0, "height": 1.0}
    region.update(overrides)
    return json.dumps([region])


async def test_redact_router_happy_path(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    response = await client.post(
        "/tools/redact",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"regions": _regions()},
    )

    assert response.status_code == 200
    assert response.content.startswith(b"%PDF")


async def test_redact_rejects_malformed_json(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    response = await client.post(
        "/tools/redact",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"regions": "not json"},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


async def test_redact_rejects_empty_regions(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    response = await client.post(
        "/tools/redact",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"regions": "[]"},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


async def test_redact_rejects_missing_region_field(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/redact",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"regions": json.dumps([{"page_number": 1, "x": 0.0, "y": 0.0, "width": 1.0}])},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


async def test_redact_rejects_out_of_range_coordinates(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/redact",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"regions": _regions(x=1.5)},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


async def test_redact_rejects_page_number_beyond_page_count(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/redact",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"regions": _regions(page_number=99)},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


async def test_redact_rejects_password_protected_file(
    client: AsyncClient, encrypted_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/redact",
        files={"file": ("locked.pdf", encrypted_pdf_bytes, "application/pdf")},
        data={"regions": _regions()},
    )

    assert response.status_code == 415
    assert response.json()["error"]["code"] == "unsupported_format"
