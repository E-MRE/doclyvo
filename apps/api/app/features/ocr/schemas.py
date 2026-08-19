from __future__ import annotations

from enum import StrEnum


class OcrLanguage(StrEnum):
    TR = "tr"
    EN = "en"


class OcrOutputFormat(StrEnum):
    SEARCHABLE = "searchable"
    TEXT = "text"
