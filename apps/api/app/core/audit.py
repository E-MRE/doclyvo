from __future__ import annotations

from sqlalchemy.exc import SQLAlchemyError

from app.config import Settings
from app.core.database import db_session
from app.core.errors import PersistenceError
from app.shared.models import AuditLogEntry


async def record_audit_log_entry(
    settings: Settings, *, user_id: str, tool: str, action: str, pdf_sha256: str
) -> None:
    try:
        async with db_session(settings) as session:
            session.add(
                AuditLogEntry(user_id=user_id, tool=tool, action=action, pdf_sha256=pdf_sha256)
            )
            await session.commit()
    except SQLAlchemyError as exc:
        raise PersistenceError() from exc
