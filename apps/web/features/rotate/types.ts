export type RotationAngle = 90 | 180 | 270;

export interface RotateResult {
  base64: string;
  filename: string;
}

export interface ActionError {
  code: string;
  message: string;
}

export type RotateActionResult =
  | { ok: true; data: RotateResult }
  | { ok: false; error: ActionError };
