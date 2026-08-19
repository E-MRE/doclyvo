from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import Settings, get_settings
from app.core.errors import InvalidRequestError
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.rotate.schemas import RotationAngle
from app.features.rotate.service import RotateService

router = APIRouter(prefix="/tools/rotate", tags=["rotate"])


@router.post("")
async def rotate_pdf(
    file: UploadFile = File(...),
    angle: RotationAngle = Form(...),
    pages: str | None = Form(None),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    page_numbers = _parse_pages(pages)

    workspace = create_workspace(settings)
    try:
        input_path = await save_upload(file, workspace, settings)
        output_path = workspace / "rotated.pdf"
        RotateService().rotate(input_path, output_path, angle, page_numbers)
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        output_path,
        media_type="application/pdf",
        filename="rotated.pdf",
        background=BackgroundTask(cleanup_workspace, workspace),
    )


def _parse_pages(pages: str | None) -> list[int] | None:
    if pages is None or pages.strip() == "":
        return None
    try:
        return [int(value.strip()) for value in pages.split(",") if value.strip()]
    except ValueError as exc:
        raise InvalidRequestError("pages must be a comma-separated list of integers.") from exc
