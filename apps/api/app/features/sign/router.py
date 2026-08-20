from __future__ import annotations

import hashlib

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import Settings, get_settings
from app.core.audit import record_audit_log_entry
from app.core.auth import get_optional_user_id
from app.core.errors import InvalidRequestError
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.sign.schemas import SignatureMode
from app.features.sign.service import SignService

router = APIRouter(prefix="/tools/sign", tags=["sign"])


@router.post("")
async def sign_pdf(
    file: UploadFile = File(...),
    mode: SignatureMode = Form(...),
    page_number: int = Form(...),
    x: float = Form(...),
    y: float = Form(...),
    width: float = Form(...),
    height: float = Form(...),
    signature_text: str | None = Form(None),
    signature_image: UploadFile | None = File(None),
    user_id: str | None = Depends(get_optional_user_id),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    if page_number < 1:
        raise InvalidRequestError("page_number must be at least 1.")
    if not (0 <= x <= 1 and 0 <= y <= 1 and 0 < width <= 1 and 0 < height <= 1):
        raise InvalidRequestError("x, y, width, and height must be normalized between 0 and 1.")
    if mode == SignatureMode.TYPE:
        if not signature_text or not signature_text.strip():
            raise InvalidRequestError("signature_text must not be empty for the type mode.")
    elif signature_image is None:
        raise InvalidRequestError("signature_image is required for the draw and upload modes.")

    workspace = create_workspace(settings)
    try:
        input_path = await save_upload(file, workspace, settings)
        signature_image_path = None
        if signature_image is not None:
            signature_image_path = await save_upload(
                signature_image, workspace, settings, suffix=".png"
            )
        output_path = workspace / "signed.pdf"
        SignService().sign(
            input_path,
            output_path,
            mode,
            page_number,
            x,
            y,
            width,
            height,
            signature_image_path=signature_image_path,
            signature_text=signature_text,
        )
        if user_id is not None:
            # Deliberately not a `Depends()` — that would build a DB engine on every request,
            # including anonymous ones, even with no DATABASE_URL configured (today's default).
            pdf_sha256 = hashlib.sha256(output_path.read_bytes()).hexdigest()
            await record_audit_log_entry(
                settings,
                user_id=user_id,
                tool="sign",
                action="self_sign",
                pdf_sha256=pdf_sha256,
            )
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        output_path,
        media_type="application/pdf",
        filename="signed.pdf",
        background=BackgroundTask(cleanup_workspace, workspace),
    )
