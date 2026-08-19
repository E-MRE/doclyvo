from __future__ import annotations

from fastapi import APIRouter, Depends, File, UploadFile
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

from app.config import Settings, get_settings
from app.core.files import cleanup_workspace, create_workspace, save_upload
from app.features.split.service import SplitService

router = APIRouter(prefix="/tools/split", tags=["split"])


@router.post("")
async def split_pdf(
    file: UploadFile = File(...),
    settings: Settings = Depends(get_settings),
) -> FileResponse:
    workspace = create_workspace(settings)
    try:
        input_path = await save_upload(file, workspace, settings)
        zip_path = workspace / "pages.zip"
        page_count = SplitService().split(input_path, workspace, zip_path)
    except Exception:
        cleanup_workspace(workspace)
        raise

    return FileResponse(
        zip_path,
        media_type="application/zip",
        filename="pages.zip",
        headers={"X-Page-Count": str(page_count)},
        background=BackgroundTask(cleanup_workspace, workspace),
    )
