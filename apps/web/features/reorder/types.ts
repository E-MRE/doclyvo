export interface ReorderResult {
  base64: string;
  filename: string;
}

export interface ActionError {
  code: string;
  message: string;
}

export type ReorderActionResult =
  | { ok: true; data: ReorderResult }
  | { ok: false; error: ActionError };
