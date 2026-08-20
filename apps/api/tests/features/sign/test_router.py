from __future__ import annotations

from pathlib import Path

import pytest
from httpx import AsyncClient

import app.features.sign.router as sign_router
from app.config import get_settings

_PLACEMENT = {"page_number": "1", "x": "0.6", "y": "0.78", "width": "0.32", "height": "0.1"}


@pytest.fixture(autouse=True)
def _no_database(_isolated_temp_dir: Path) -> None:
    get_settings().database_url = None


async def test_sign_anonymous_request_never_touches_audit_log(
    client: AsyncClient, simple_pdf_bytes: bytes, monkeypatch: pytest.MonkeyPatch
) -> None:
    async def _fail_if_called(*args: object, **kwargs: object) -> None:
        raise AssertionError("record_audit_log_entry must not be called for anonymous requests")

    monkeypatch.setattr(sign_router, "record_audit_log_entry", _fail_if_called)

    response = await client.post(
        "/tools/sign",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"mode": "type", "signature_text": "Emre Gültekir", **_PLACEMENT},
    )

    assert response.status_code == 200
    assert response.content.startswith(b"%PDF")


async def test_sign_authenticated_request_records_audit_log(
    client: AsyncClient, simple_pdf_bytes: bytes, monkeypatch: pytest.MonkeyPatch
) -> None:
    calls: list[dict[str, object]] = []

    async def _fake_record(settings: object, **kwargs: object) -> None:
        calls.append(kwargs)

    monkeypatch.setattr(sign_router, "record_audit_log_entry", _fake_record)

    response = await client.post(
        "/tools/sign",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"mode": "type", "signature_text": "Emre Gültekir", **_PLACEMENT},
        headers={"Authorization": "Bearer test-user-123"},
    )

    assert response.status_code == 200
    assert len(calls) == 1
    assert calls[0]["user_id"] == "test-user-123"
    assert calls[0]["tool"] == "sign"
    assert len(calls[0]["pdf_sha256"]) == 64


async def test_sign_authenticated_request_without_database_fails(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/sign",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"mode": "type", "signature_text": "Emre Gültekir", **_PLACEMENT},
        headers={"Authorization": "Bearer test-user-123"},
    )

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "persistence_failed"


async def test_sign_upload_mode_happy_path(
    client: AsyncClient, simple_pdf_bytes: bytes, signature_png_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/sign",
        files={
            "file": ("sample.pdf", simple_pdf_bytes, "application/pdf"),
            "signature_image": ("signature.png", signature_png_bytes, "image/png"),
        },
        data={"mode": "upload", **_PLACEMENT},
    )

    assert response.status_code == 200
    assert response.content.startswith(b"%PDF")


async def test_sign_rejects_empty_signature_text_in_type_mode(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/sign",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"mode": "type", "signature_text": "   ", **_PLACEMENT},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


async def test_sign_rejects_missing_signature_image_for_upload_mode(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    response = await client.post(
        "/tools/sign",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"mode": "upload", **_PLACEMENT},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


async def test_sign_rejects_out_of_range_coordinates(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    placement = {**_PLACEMENT, "x": "1.5"}
    response = await client.post(
        "/tools/sign",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"mode": "type", "signature_text": "Emre", **placement},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"


async def test_sign_rejects_page_number_beyond_page_count(
    client: AsyncClient, simple_pdf_bytes: bytes
) -> None:
    placement = {**_PLACEMENT, "page_number": "99"}
    response = await client.post(
        "/tools/sign",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
        data={"mode": "type", "signature_text": "Emre", **placement},
    )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "invalid_request"
