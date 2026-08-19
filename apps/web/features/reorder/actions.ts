"use server";

import { ApiError, reorderPdf } from "@/lib/api-client";
import type { ReorderActionResult } from "@/features/reorder/types";

export async function reorderPdfAction(file: File, order: number[]): Promise<ReorderActionResult> {
  try {
    const result = await reorderPdf(file, order);
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: { base64: buffer.toString("base64"), filename: result.filename },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while reordering a PDF", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
