export interface ProtectResult {
  base64: string;
  filename: string;
}

export interface ActionError {
  code: string;
  message: string;
}

export type ProtectActionResult =
  | { ok: true; data: ProtectResult }
  | { ok: false; error: ActionError };
