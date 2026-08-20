from __future__ import annotations

import shutil
import uuid
from pathlib import Path

from fastapi import UploadFile

from app.config import Settings
from app.core.errors import FileTooLargeError

UPLOAD_CHUNK_SIZE = 1024 * 1024


def create_workspace(settings: Settings) -> Path:
    workspace = settings.temp_dir / uuid.uuid4().hex
    workspace.mkdir(parents=True, exist_ok=True)
    return workspace


def cleanup_workspace(workspace: Path) -> None:
    shutil.rmtree(workspace, ignore_errors=True)


async def save_upload(
    upload: UploadFile, destination_dir: Path, settings: Settings, suffix: str = ".pdf"
) -> Path:
    destination = destination_dir / f"{uuid.uuid4().hex}{suffix}"
    max_size = settings.max_upload_size_mb * 1024 * 1024
    size = 0
    with destination.open("wb") as buffer:
        while chunk := await upload.read(UPLOAD_CHUNK_SIZE):
            size += len(chunk)
            if size > max_size:
                buffer.close()
                destination.unlink(missing_ok=True)
                raise FileTooLargeError(settings.max_upload_size_mb)
            buffer.write(chunk)
    return destination
