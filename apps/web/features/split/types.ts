export interface SplitResult {
  base64: string;
  filename: string;
  pageCount: number;
}

export interface ActionError {
  code: string;
  message: string;
}

export type SplitActionResult = { ok: true; data: SplitResult } | { ok: false; error: ActionError };
