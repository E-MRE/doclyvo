from __future__ import annotations

from enum import StrEnum


class WatermarkPosition(StrEnum):
    CENTER = "center"
    DIAGONAL = "diagonal"
    CORNER = "corner"


class WatermarkOpacity(StrEnum):
    LIGHT = "light"
    MEDIUM = "medium"
    STRONG = "strong"
