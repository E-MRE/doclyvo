export type WatermarkPosition = "center" | "diagonal" | "corner";
export type WatermarkOpacity = "light" | "medium" | "strong";

export interface WatermarkResult {
  base64: string;
  filename: string;
}

export interface ActionError {
  code: string;
  message: string;
}

export type WatermarkActionResult =
  | { ok: true; data: WatermarkResult }
  | { ok: false; error: ActionError };
