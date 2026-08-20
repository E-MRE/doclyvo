FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# libreoffice-writer pulls in only the Writer + core deps needed for PDF-to-Word conversion
# (the full `libreoffice` metapackage installs every app and roughly doubles image size).
# tesseract-ocr-tur is the Turkish language pack the `ocr` endpoint offers alongside `eng`.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice-writer \
    tesseract-ocr \
    tesseract-ocr-tur \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev

COPY . .
RUN uv sync --frozen --no-dev

ENV PATH="/app/.venv/bin:$PATH"
ENV TEMP_DIR=/tmp/doclyvo

EXPOSE 8000

# Render (and most PaaS) inject $PORT at runtime; default to 8000 for local `docker run`.
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
