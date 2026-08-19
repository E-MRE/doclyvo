"use server";

import { ApiError, mergePdfs } from "@/lib/api-client";
import type { MergeActionResult } from "@/features/merge/types";

export async function mergePdfsAction(files: File[]): Promise<MergeActionResult> {
  try {
    const result = await mergePdfs(files);
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: {
        base64: buffer.toString("base64"),
        filename: result.filename,
        pageCount: Number(result.headers["x-page-count"] ?? 0),
        fileCount: Number(result.headers["x-file-count"] ?? files.length),
      },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while merging PDFs", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
