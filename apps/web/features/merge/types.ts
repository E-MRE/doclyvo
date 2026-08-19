export interface MergeFileItem {
  id: string;
  file: File;
}

export interface MergeResult {
  base64: string;
  filename: string;
  pageCount: number;
  fileCount: number;
}

export interface ActionError {
  code: string;
  message: string;
}

export type MergeActionResult = { ok: true; data: MergeResult } | { ok: false; error: ActionError };
