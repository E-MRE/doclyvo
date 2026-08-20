from __future__ import annotations

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

_bearer_scheme = HTTPBearer(auto_error=False)


async def get_optional_user_id(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
) -> str | None:
    if credentials is None or not credentials.credentials.strip():
        return None
    # TODO(auth): once a real login system issues signed session tokens/JWTs, verify them
    # here (signature check / session-store lookup). This signature and its call sites
    # don't need to change when that happens.
    return credentials.credentials.strip()
