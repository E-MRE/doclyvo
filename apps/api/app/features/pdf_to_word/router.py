from __future__ import annotations

from fastapi import APIRouter, Depends, File, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import Settings, get_settings
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.pdf_to_word.service import PdfToWordService

router = APIRouter(prefix="/tools/pdf-to-word", tags=["pdf-to-word"])

_DOCX_MEDIA_TYPE = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"


@router.post("")
async def convert_pdf_to_word(
    file: UploadFile = File(...),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    workspace = create_workspace(settings)
    try:
        input_path = await save_upload(file, workspace, settings)
        output_path = await PdfToWordService().convert(
            input_path,
            workspace,
            settings.libreoffice_binary,
            settings.libreoffice_timeout_seconds,
        )
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        output_path,
        media_type=_DOCX_MEDIA_TYPE,
        filename="converted.docx",
        background=BackgroundTask(cleanup_workspace, workspace),
    )
