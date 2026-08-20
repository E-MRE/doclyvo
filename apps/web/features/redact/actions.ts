"use server";

import { ApiError, redactPdf } from "@/lib/api-client";
import type { RedactActionResult, RedactRegion } from "@/features/redact/types";

export async function redactPdfAction(
  file: File,
  regions: RedactRegion[],
): Promise<RedactActionResult> {
  try {
    const result = await redactPdf(
      file,
      regions.map(({ pageNumber, x, y, width, height }) => ({ pageNumber, x, y, width, height })),
    );
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: { base64: buffer.toString("base64"), filename: result.filename },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while redacting a PDF", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
