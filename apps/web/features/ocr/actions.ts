"use server";

import { ApiError, ocrPdf } from "@/lib/api-client";
import type { OcrActionResult, OcrLanguage, OcrOutputFormat } from "@/features/ocr/types";

export async function ocrPdfAction(
  file: File,
  language: OcrLanguage,
  outputFormat: OcrOutputFormat,
): Promise<OcrActionResult> {
  try {
    const result = await ocrPdf(file, language, outputFormat);
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: { base64: buffer.toString("base64"), filename: result.filename, outputFormat },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while running OCR on a PDF", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
