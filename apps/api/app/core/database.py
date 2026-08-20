from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from functools import lru_cache

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import Settings
from app.core.errors import PersistenceError


class Base(DeclarativeBase):
    pass


@lru_cache
def _sessionmaker_for(database_url: str) -> async_sessionmaker[AsyncSession]:
    engine = create_async_engine(database_url, pool_pre_ping=True)
    return async_sessionmaker(engine, expire_on_commit=False)


@asynccontextmanager
async def db_session(settings: Settings) -> AsyncIterator[AsyncSession]:
    if not settings.database_url:
        raise PersistenceError()
    async with _sessionmaker_for(settings.database_url)() as session:
        yield session
