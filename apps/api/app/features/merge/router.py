from __future__ import annotations

from fastapi import APIRouter, Depends, File, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import Settings, get_settings
from app.core.errors import InvalidRequestError
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.merge.service import MergeService

router = APIRouter(prefix="/tools/merge", tags=["merge"])


@router.post("")
async def merge_pdfs(
    files: list[UploadFile] = File(...),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    if len(files) < 2:
        raise InvalidRequestError("Merge requires at least two files.")

    workspace = create_workspace(settings)
    try:
        input_paths = [await save_upload(upload, workspace, settings) for upload in files]
        output_path = workspace / "merged.pdf"
        page_count = MergeService().merge(input_paths, output_path)
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        output_path,
        media_type="application/pdf",
        filename="merged.pdf",
        headers={"X-Page-Count": str(page_count), "X-File-Count": str(len(files))},
        background=BackgroundTask(cleanup_workspace, workspace),
    )
