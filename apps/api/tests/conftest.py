from __future__ import annotations

import shutil
from collections.abc import AsyncIterator, Iterator
from pathlib import Path

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from app.config import get_settings
from app.main import app

FIXTURES_DIR = Path(__file__).parent / "fixtures"


@pytest.fixture(autouse=True)
def _isolated_temp_dir(tmp_path: Path) -> Iterator[Path]:
    get_settings.cache_clear()
    settings = get_settings()
    settings.temp_dir = tmp_path
    yield tmp_path
    get_settings.cache_clear()
    shutil.rmtree(tmp_path, ignore_errors=True)


@pytest_asyncio.fixture
async def client() -> AsyncIterator[AsyncClient]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as async_client:
        yield async_client


@pytest.fixture
def simple_pdf_bytes() -> bytes:
    return (FIXTURES_DIR / "sample_simple.pdf").read_bytes()


@pytest.fixture
def image_pdf_bytes() -> bytes:
    return (FIXTURES_DIR / "sample_with_image.pdf").read_bytes()


@pytest.fixture
def encrypted_pdf_bytes() -> bytes:
    return (FIXTURES_DIR / "sample_encrypted.pdf").read_bytes()
