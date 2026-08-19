"use server";

import { ApiError, splitPdf } from "@/lib/api-client";
import type { SplitActionResult } from "@/features/split/types";

export async function splitPdfAction(file: File): Promise<SplitActionResult> {
  try {
    const result = await splitPdf(file);
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: {
        base64: buffer.toString("base64"),
        filename: result.filename,
        pageCount: Number(result.headers["x-page-count"] ?? 0),
      },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while splitting a PDF", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
