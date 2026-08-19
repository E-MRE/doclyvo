"use server";

import { ApiError, compressPdf } from "@/lib/api-client";
import type { CompressActionResult, CompressQuality } from "@/features/compress/types";

export async function compressPdfAction(
  file: File,
  quality: CompressQuality,
): Promise<CompressActionResult> {
  try {
    const result = await compressPdf(file, quality);
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: {
        base64: buffer.toString("base64"),
        filename: result.filename,
        originalSize: Number(result.headers["x-original-size"] ?? 0),
        compressedSize: Number(result.headers["x-compressed-size"] ?? 0),
      },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while compressing a PDF", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
