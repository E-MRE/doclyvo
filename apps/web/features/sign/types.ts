export type SignMode = "draw" | "type" | "upload";

export interface SignPlacement {
  pageNumber: number;
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface SignResult {
  base64: string;
  filename: string;
}

export interface ActionError {
  code: string;
  message: string;
}

export type SignActionResult = { ok: true; data: SignResult } | { ok: false; error: ActionError };
