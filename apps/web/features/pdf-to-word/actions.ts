"use server";

import { ApiError, convertPdfToWord } from "@/lib/api-client";
import type { ConvertActionResult } from "@/features/pdf-to-word/types";

export async function convertPdfToWordAction(file: File): Promise<ConvertActionResult> {
  try {
    const result = await convertPdfToWord(file);
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: { base64: buffer.toString("base64"), filename: result.filename },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while converting a PDF to Word", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
