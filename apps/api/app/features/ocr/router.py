from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask
from starlette.concurrency import run_in_threadpool

from app.config import Settings, get_settings
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.ocr.schemas import OcrLanguage, OcrOutputFormat
from app.features.ocr.service import OcrService

router = APIRouter(prefix="/tools/ocr", tags=["ocr"])


@router.post("")
async def ocr_pdf(
    file: UploadFile = File(...),
    language: OcrLanguage = Form(OcrLanguage.TR),
    output_format: OcrOutputFormat = Form(OcrOutputFormat.SEARCHABLE),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    is_text_output = output_format == OcrOutputFormat.TEXT
    output_name = "recognized.txt" if is_text_output else "searchable.pdf"
    media_type = "text/plain" if is_text_output else "application/pdf"

    workspace = create_workspace(settings)
    try:
        input_path = await save_upload(file, workspace, settings)
        output_path = workspace / output_name
        await run_in_threadpool(
            OcrService().recognize, input_path, output_path, language, output_format
        )
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        output_path,
        media_type=media_type,
        filename=output_name,
        background=BackgroundTask(cleanup_workspace, workspace),
    )
