from __future__ import annotations

import json

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import Settings, get_settings
from app.core.errors import InvalidRequestError
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.redact.schemas import RedactRegion
from app.features.redact.service import RedactService

router = APIRouter(prefix="/tools/redact", tags=["redact"])


@router.post("")
async def redact_pdf(
    file: UploadFile = File(...),
    regions: str = Form(...),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    parsed_regions = _parse_regions(regions)

    workspace = create_workspace(settings)
    try:
        input_path = await save_upload(file, workspace, settings)
        output_path = workspace / "redacted.pdf"
        RedactService().redact(input_path, output_path, parsed_regions)
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        output_path,
        media_type="application/pdf",
        filename="redacted.pdf",
        background=BackgroundTask(cleanup_workspace, workspace),
    )


def _parse_regions(regions: str) -> list[RedactRegion]:
    try:
        raw = json.loads(regions)
    except json.JSONDecodeError as exc:
        raise InvalidRequestError("regions must be a valid JSON array.") from exc
    if not isinstance(raw, list) or not raw:
        raise InvalidRequestError("regions must be a non-empty JSON array.")

    parsed = []
    for item in raw:
        try:
            page_number = int(item["page_number"])
            x, y, width, height = (float(item[key]) for key in ("x", "y", "width", "height"))
        except (KeyError, TypeError, ValueError) as exc:
            raise InvalidRequestError(
                "each region must have page_number, x, y, width, and height."
            ) from exc
        if page_number < 1:
            raise InvalidRequestError("page_number must be at least 1.")
        if not (0 <= x <= 1 and 0 <= y <= 1 and 0 < width <= 1 and 0 < height <= 1):
            raise InvalidRequestError("x, y, width, and height must be normalized between 0 and 1.")
        parsed.append(RedactRegion(page_number, x, y, width, height))
    return parsed
