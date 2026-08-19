export type CompressQuality = "low" | "recommended" | "high";

export interface CompressResult {
  base64: string;
  filename: string;
  originalSize: number;
  compressedSize: number;
}

export interface ActionError {
  code: string;
  message: string;
}

export type CompressActionResult =
  | { ok: true; data: CompressResult }
  | { ok: false; error: ActionError };
