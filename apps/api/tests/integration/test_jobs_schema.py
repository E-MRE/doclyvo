"""Real-Postgres integration test. Excluded from the default run — see pyproject.toml.

`Job` is schema-only (see app/shared/models.py) — nothing in the app writes to it yet, so
this only proves the migration produces a usable table, not any application behavior.

    docker compose up -d && uv run alembic upgrade head && uv run pytest -m integration
"""

from __future__ import annotations

import pytest
from sqlalchemy import select

from app.config import get_settings
from app.core.database import _sessionmaker_for
from app.shared.models import Job, JobStatus

# session-scoped loop: see test_audit_log.py — _sessionmaker_for's cached engine needs one
# event loop shared across the integration test session, not a fresh one per test function.
pytestmark = [pytest.mark.integration, pytest.mark.asyncio(loop_scope="session")]


async def test_job_table_accepts_a_row() -> None:
    settings = get_settings()
    assert settings.database_url, "DATABASE_URL must be set to run this integration test"

    sessionmaker = _sessionmaker_for(settings.database_url)
    async with sessionmaker() as session:
        session.add(
            Job(
                user_id=None,
                tool="compress",
                original_filename="invoice.pdf",
                status=JobStatus.SUCCEEDED,
                error_code=None,
            )
        )
        await session.commit()

        result = await session.execute(select(Job).where(Job.tool == "compress"))
        rows = result.scalars().all()

    assert any(row.original_filename == "invoice.pdf" for row in rows)
