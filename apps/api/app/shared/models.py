from __future__ import annotations

import uuid
from datetime import datetime
from enum import StrEnum

from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class AuditLogEntry(Base):
    """Append-only: the only write path (`app.core.audit.record_audit_log_entry`) ever
    does `add` + `commit` — no update/delete function exists for this model."""

    __tablename__ = "audit_log_entries"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    tool: Mapped[str] = mapped_column(String(50))
    action: Mapped[str] = mapped_column(String(50))
    pdf_sha256: Mapped[str] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class JobStatus(StrEnum):
    SUCCEEDED = "succeeded"
    FAILED = "failed"


class Job(Base):
    """Schema only — no router writes here yet. A per-user "history" view has no consumer
    until real accounts exist (nobody could view "their" history), so wiring a write into
    each tool's router is deferred to whenever login ships. See apps/api/README.md for the
    intended write pattern then. Distinct from AuditLogEntry above, which is `sign`'s
    hash-sealed compliance trail, not a general "what did I run" history."""

    __tablename__ = "jobs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    tool: Mapped[str] = mapped_column(String(50))
    original_filename: Mapped[str | None] = mapped_column(String(255), nullable=True)
    status: Mapped[str] = mapped_column(String(20))
    error_code: Mapped[str | None] = mapped_column(String(50), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
