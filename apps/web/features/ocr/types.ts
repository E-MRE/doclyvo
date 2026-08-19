export type OcrLanguage = "tr" | "en";
export type OcrOutputFormat = "searchable" | "text";

export interface OcrResult {
  base64: string;
  filename: string;
  outputFormat: OcrOutputFormat;
}

export interface ActionError {
  code: string;
  message: string;
}

export type OcrActionResult = { ok: true; data: OcrResult } | { ok: false; error: ActionError };
