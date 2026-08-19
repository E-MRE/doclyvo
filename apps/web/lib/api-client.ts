import "server-only";

const API_BASE_URL = process.env.API_BASE_URL ?? "http://localhost:8000";

interface ApiErrorBody {
  error?: { code?: string; message?: string };
}

export class ApiError extends Error {
  readonly code: string;
  readonly status: number;

  constructor(code: string, message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.code = code;
    this.status = status;
  }
}

export interface ApiFileResult {
  blob: Blob;
  filename: string;
  headers: Record<string, string>;
}

async function postForFile(
  path: string,
  formData: FormData,
  defaultFilename: string,
): Promise<ApiFileResult> {
  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${path}`, { method: "POST", body: formData });
  } catch {
    throw new ApiError("service_unavailable", "Doclyvo sunucusuna ulaşılamadı.", 503);
  }

  if (!response.ok) {
    const body = (await response.json().catch(() => null)) as ApiErrorBody | null;
    throw new ApiError(
      body?.error?.code ?? "internal_error",
      body?.error?.message ?? "Something went wrong.",
      response.status,
    );
  }

  const headers: Record<string, string> = {};
  response.headers.forEach((value, key) => {
    headers[key] = value;
  });

  return { blob: await response.blob(), filename: defaultFilename, headers };
}

export async function compressPdf(
  file: File,
  quality: "low" | "recommended" | "high",
): Promise<ApiFileResult> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("quality", quality);
  return postForFile("/tools/compress", formData, "compressed.pdf");
}

export async function mergePdfs(files: File[]): Promise<ApiFileResult> {
  const formData = new FormData();
  files.forEach((file) => formData.append("files", file));
  return postForFile("/tools/merge", formData, "merged.pdf");
}

export async function splitPdf(file: File): Promise<ApiFileResult> {
  const formData = new FormData();
  formData.append("file", file);
  return postForFile("/tools/split", formData, "pages.zip");
}

export async function rotatePdf(
  file: File,
  angle: 90 | 180 | 270,
  pages: number[],
): Promise<ApiFileResult> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("angle", String(angle));
  formData.append("pages", pages.join(","));
  return postForFile("/tools/rotate", formData, "rotated.pdf");
}

export async function reorderPdf(file: File, order: number[]): Promise<ApiFileResult> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("order", order.join(","));
  return postForFile("/tools/reorder", formData, "reordered.pdf");
}

export async function watermarkPdf(
  file: File,
  text: string,
  position: "center" | "diagonal" | "corner",
  opacity: "light" | "medium" | "strong",
): Promise<ApiFileResult> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("text", text);
  formData.append("position", position);
  formData.append("opacity", opacity);
  return postForFile("/tools/watermark", formData, "watermarked.pdf");
}

export async function protectPdf(
  file: File,
  password: string,
  noPrint: boolean,
  noCopy: boolean,
  noEdit: boolean,
): Promise<ApiFileResult> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("password", password);
  formData.append("no_print", String(noPrint));
  formData.append("no_copy", String(noCopy));
  formData.append("no_edit", String(noEdit));
  return postForFile("/tools/protect", formData, "protected.pdf");
}

export async function ocrPdf(
  file: File,
  language: "tr" | "en",
  outputFormat: "searchable" | "text",
): Promise<ApiFileResult> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("language", language);
  formData.append("output_format", outputFormat);
  const defaultFilename = outputFormat === "text" ? "recognized.txt" : "searchable.pdf";
  return postForFile("/tools/ocr", formData, defaultFilename);
}

export async function convertPdfToWord(file: File): Promise<ApiFileResult> {
  const formData = new FormData();
  formData.append("file", file);
  return postForFile("/tools/pdf-to-word", formData, "converted.docx");
}
