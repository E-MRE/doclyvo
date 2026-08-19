from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import Settings, get_settings
from app.core.errors import InvalidRequestError
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.watermark.schemas import WatermarkOpacity, WatermarkPosition
from app.features.watermark.service import WatermarkService

router = APIRouter(prefix="/tools/watermark", tags=["watermark"])


@router.post("")
async def watermark_pdf(
    file: UploadFile = File(...),
    text: str = Form(...),
    position: WatermarkPosition = Form(WatermarkPosition.DIAGONAL),
    opacity: WatermarkOpacity = Form(WatermarkOpacity.MEDIUM),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    watermark_text = text.strip()
    if not watermark_text:
        raise InvalidRequestError("text must not be empty.")

    workspace = create_workspace(settings)
    try:
        input_path = await save_upload(file, workspace, settings)
        output_path = workspace / "watermarked.pdf"
        WatermarkService().add_watermark(input_path, output_path, watermark_text, position, opacity)
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        output_path,
        media_type="application/pdf",
        filename="watermarked.pdf",
        background=BackgroundTask(cleanup_workspace, workspace),
    )
