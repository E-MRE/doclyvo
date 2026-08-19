export interface ConvertResult {
  base64: string;
  filename: string;
}

export interface ActionError {
  code: string;
  message: string;
}

export type ConvertActionResult =
  | { ok: true; data: ConvertResult }
  | { ok: false; error: ActionError };
