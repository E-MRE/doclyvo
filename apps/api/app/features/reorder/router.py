from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import Settings, get_settings
from app.core.errors import InvalidRequestError
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.reorder.service import ReorderService

router = APIRouter(prefix="/tools/reorder", tags=["reorder"])


@router.post("")
async def reorder_pdf(
    file: UploadFile = File(...),
    order: str = Form(...),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    page_order = _parse_order(order)

    workspace = create_workspace(settings)
    try:
        input_path = await save_upload(file, workspace, settings)
        output_path = workspace / "reordered.pdf"
        ReorderService().reorder(input_path, output_path, page_order)
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        output_path,
        media_type="application/pdf",
        filename="reordered.pdf",
        background=BackgroundTask(cleanup_workspace, workspace),
    )


def _parse_order(order: str) -> list[int]:
    try:
        return [int(value.strip()) for value in order.split(",") if value.strip()]
    except ValueError as exc:
        raise InvalidRequestError("order must be a comma-separated list of integers.") from exc
