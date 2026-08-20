from __future__ import annotations

from enum import StrEnum


class SignatureMode(StrEnum):
    DRAW = "draw"
    TYPE = "type"
    UPLOAD = "upload"
