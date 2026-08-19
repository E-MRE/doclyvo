from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import Settings, get_settings
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.compress.schemas import CompressQuality
from app.features.compress.service import CompressService

router = APIRouter(prefix="/tools/compress", tags=["compress"])


@router.post("")
async def compress_pdf(
    file: UploadFile = File(...),
    quality: CompressQuality = Form(CompressQuality.RECOMMENDED),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    workspace = create_workspace(settings)
    try:
        input_path = await save_upload(file, workspace, settings)
        output_path = workspace / "compressed.pdf"
        CompressService().compress(input_path, output_path, quality)
        original_size = input_path.stat().st_size
        compressed_size = output_path.stat().st_size
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        output_path,
        media_type="application/pdf",
        filename="compressed.pdf",
        headers={
            "X-Original-Size": str(original_size),
            "X-Compressed-Size": str(compressed_size),
        },
        background=BackgroundTask(cleanup_workspace, workspace),
    )
