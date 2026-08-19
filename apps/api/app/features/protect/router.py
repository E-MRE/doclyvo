from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import Settings, get_settings
from app.core.errors import InvalidRequestError
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.protect.service import ProtectService

router = APIRouter(prefix="/tools/protect", tags=["protect"])

_MIN_PASSWORD_LENGTH = 4


@router.post("")
async def protect_pdf(
    file: UploadFile = File(...),
    password: str = Form(...),
    no_print: bool = Form(False),
    no_copy: bool = Form(False),
    no_edit: bool = Form(False),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    if len(password) < _MIN_PASSWORD_LENGTH:
        raise InvalidRequestError(f"password must be at least {_MIN_PASSWORD_LENGTH} characters.")

    workspace = create_workspace(settings)
    try:
        input_path = await save_upload(file, workspace, settings)
        output_path = workspace / "protected.pdf"
        ProtectService().protect(input_path, output_path, password, no_print, no_copy, no_edit)
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        output_path,
        media_type="application/pdf",
        filename="protected.pdf",
        background=BackgroundTask(cleanup_workspace, workspace),
    )
