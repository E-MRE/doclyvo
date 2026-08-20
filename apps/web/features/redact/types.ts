export interface RedactRegion {
  id: string;
  pageNumber: number;
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface RedactResult {
  base64: string;
  filename: string;
}

export interface ActionError {
  code: string;
  message: string;
}

export type RedactActionResult =
  | { ok: true; data: RedactResult }
  | { ok: false; error: ActionError };
