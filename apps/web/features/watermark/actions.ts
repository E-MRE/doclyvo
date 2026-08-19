"use server";

import { ApiError, watermarkPdf } from "@/lib/api-client";
import type {
  WatermarkActionResult,
  WatermarkOpacity,
  WatermarkPosition,
} from "@/features/watermark/types";

export async function watermarkPdfAction(
  file: File,
  text: string,
  position: WatermarkPosition,
  opacity: WatermarkOpacity,
): Promise<WatermarkActionResult> {
  try {
    const result = await watermarkPdf(file, text, position, opacity);
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: { base64: buffer.toString("base64"), filename: result.filename },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while watermarking a PDF", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
