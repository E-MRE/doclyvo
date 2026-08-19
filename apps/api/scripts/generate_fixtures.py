"""Regenerate tests/fixtures/*.pdf. Run with `uv run python scripts/generate_fixtures.py`."""

from __future__ import annotations

import io
from pathlib import Path

import pikepdf
from PIL import Image
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

FIXTURES_DIR = Path(__file__).resolve().parent.parent / "tests" / "fixtures"


def _write_text_pdf(path: Path, page_count: int) -> None:
    buffer = io.BytesIO()
    pdf_canvas = canvas.Canvas(buffer, pagesize=letter)
    for page_number in range(1, page_count + 1):
        pdf_canvas.drawString(72, 700, f"Doclyvo fixture — page {page_number}")
        pdf_canvas.showPage()
    pdf_canvas.save()
    path.write_bytes(buffer.getvalue())


def _write_image_pdf(path: Path) -> None:
    buffer = io.BytesIO()
    pdf_canvas = canvas.Canvas(buffer, pagesize=letter)
    image = Image.effect_noise((800, 600), 60).convert("RGB")
    image_buffer = io.BytesIO()
    image.save(image_buffer, format="PNG")
    image_buffer.seek(0)
    from reportlab.lib.utils import ImageReader

    pdf_canvas.drawImage(ImageReader(image_buffer), 72, 72, width=400, height=300)
    pdf_canvas.showPage()
    pdf_canvas.save()
    path.write_bytes(buffer.getvalue())


def _write_encrypted_pdf(source: Path, destination: Path) -> None:
    encryption = pikepdf.Encryption(owner="owner-secret", user="user-secret")
    with pikepdf.open(source) as pdf:
        pdf.save(destination, encryption=encryption)


def main() -> None:
    FIXTURES_DIR.mkdir(parents=True, exist_ok=True)
    simple_path = FIXTURES_DIR / "sample_simple.pdf"
    _write_text_pdf(simple_path, page_count=3)
    _write_image_pdf(FIXTURES_DIR / "sample_with_image.pdf")
    _write_encrypted_pdf(simple_path, FIXTURES_DIR / "sample_encrypted.pdf")


if __name__ == "__main__":
    main()
