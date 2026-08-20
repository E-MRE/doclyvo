"""Real-Postgres integration test. Excluded from the default run — see pyproject.toml.

Requires a local Postgres reachable at DATABASE_URL (see .env.example):

    docker compose up -d && uv run alembic upgrade head && uv run pytest -m integration
"""

from __future__ import annotations

import pytest
from sqlalchemy import select

from app.config import get_settings
from app.core.audit import record_audit_log_entry
from app.core.database import _sessionmaker_for
from app.shared.models import AuditLogEntry

pytestmark = pytest.mark.integration


async def test_record_audit_log_entry_persists_a_row() -> None:
    settings = get_settings()
    assert settings.database_url, "DATABASE_URL must be set to run this integration test"

    await record_audit_log_entry(
        settings,
        user_id="integration-test-user",
        tool="sign",
        action="self_sign",
        pdf_sha256="a" * 64,
    )

    sessionmaker = _sessionmaker_for(settings.database_url)
    async with sessionmaker() as session:
        result = await session.execute(
            select(AuditLogEntry).where(AuditLogEntry.user_id == "integration-test-user")
        )
        rows = result.scalars().all()

    assert any(row.tool == "sign" and row.pdf_sha256 == "a" * 64 for row in rows)
