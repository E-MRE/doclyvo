"use server";

import { ApiError, signPdf } from "@/lib/api-client";
import type { SignActionResult, SignMode, SignPlacement } from "@/features/sign/types";

export async function signPdfAction(
  file: File,
  mode: SignMode,
  placement: SignPlacement,
  signatureText?: string,
  signatureImage?: File,
  // once login ships, read the session token here (e.g. cookies()) and pass it through
  authToken?: string,
): Promise<SignActionResult> {
  try {
    const result = await signPdf(file, mode, placement, signatureText, signatureImage, authToken);
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: { base64: buffer.toString("base64"), filename: result.filename },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while signing a PDF", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
