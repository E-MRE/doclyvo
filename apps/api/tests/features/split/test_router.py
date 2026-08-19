from __future__ import annotations

import io
import zipfile

from httpx import AsyncClient


async def test_split_returns_one_pdf_per_page(client: AsyncClient, simple_pdf_bytes: bytes) -> None:
    response = await client.post(
        "/tools/split",
        files={"file": ("sample.pdf", simple_pdf_bytes, "application/pdf")},
    )

    assert response.status_code == 200
    assert response.headers["x-page-count"] == "3"
    with zipfile.ZipFile(io.BytesIO(response.content)) as archive:
        names = sorted(archive.namelist())
        assert names == ["page-1.pdf", "page-2.pdf", "page-3.pdf"]
        for name in names:
            assert archive.read(name).startswith(b"%PDF")
