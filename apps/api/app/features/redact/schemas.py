from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class RedactRegion:
    """Normalized (0-1) coordinates, top-left origin — matches pymupdf's own page.rect
    convention, so the service applies them with no axis conversion."""

    page_number: int
    x: float
    y: float
    width: float
    height: float
