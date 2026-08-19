"use server";

import { ApiError, rotatePdf } from "@/lib/api-client";
import type { RotateActionResult, RotationAngle } from "@/features/rotate/types";

export async function rotatePdfAction(
  file: File,
  angle: RotationAngle,
  pages: number[],
): Promise<RotateActionResult> {
  try {
    const result = await rotatePdf(file, angle, pages);
    const buffer = Buffer.from(await result.blob.arrayBuffer());

    return {
      ok: true,
      data: { base64: buffer.toString("base64"), filename: result.filename },
    };
  } catch (error) {
    if (error instanceof ApiError) {
      return { ok: false, error: { code: error.code, message: error.message } };
    }
    console.error("Unexpected error while rotating a PDF", error);
    return {
      ok: false,
      error: { code: "internal_error", message: "Bir şeyler ters gitti. Tekrar dene." },
    };
  }
}
