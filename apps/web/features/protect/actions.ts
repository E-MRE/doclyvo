"use server";

import { ApiError, protectPdf } from "@/lib/api-client";
import type { ProtectActionResult } from "@/features/protect/types";

export async function protectPdfAction(
  file: File,
  password: string,
  noPrint: boolean,
  noCopy: boolean,
  noEdit: boolean,
): Promise<ProtectActionResult> {
  try {
    const result = await protectPdf(file, password, noPrint, noCopy, noEdit);
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: { base64: buffer.toString("base64"), filename: result.filename },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while protecting a PDF", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
