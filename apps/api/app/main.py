from __future__ import annotations

import logging

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.core.errors import DoclyvoError
from app.features.compress.router import router as compress_router
from app.features.merge.router import router as merge_router
from app.features.ocr.router import router as ocr_router
from app.features.pdf_to_word.router import router as pdf_to_word_router
from app.features.protect.router import router as protect_router
from app.features.reorder.router import router as reorder_router
from app.features.rotate.router import router as rotate_router
from app.features.sign.router import router as sign_router
from app.features.split.router import router as split_router
from app.features.watermark.router import router as watermark_router

logger = logging.getLogger("doclyvo")

settings = get_settings()

app = FastAPI(title="Doclyvo API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(merge_router)
app.include_router(split_router)
app.include_router(compress_router)
app.include_router(rotate_router)
app.include_router(reorder_router)
app.include_router(watermark_router)
app.include_router(protect_router)
app.include_router(ocr_router)
app.include_router(pdf_to_word_router)
app.include_router(sign_router)


@app.exception_handler(DoclyvoError)
async def doclyvo_error_handler(request: Request, exc: DoclyvoError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": exc.code, "message": exc.message}},
    )


@app.exception_handler(Exception)
async def unhandled_error_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Unhandled error while processing request")
    return JSONResponse(
        status_code=500,
        content={"error": {"code": "internal_error", "message": "Something went wrong."}},
    )


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
