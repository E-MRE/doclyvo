"use client";

import { useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { ProgressBar } from "@/components/ProgressBar";
import { ResultPanel } from "@/components/ResultPanel";
import { UploadDropzone } from "@/components/UploadDropzone";
import { convertPdfToWordAction } from "@/features/pdf-to-word/actions";
import type { ConvertResult } from "@/features/pdf-to-word/types";
import { useFakeProgress } from "@/lib/hooks/use-fake-progress";
import { usePendingFile } from "@/lib/hooks/use-pending-file";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

export function ConvertWorkspace() {
  const [file, setFile] = usePendingFile();
  const [phase, setPhase] = useState<Phase>(file ? "idle" : "empty");
  const [result, setResult] = useState<ConvertResult | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [, startTransition] = useTransition();
  const progress = useFakeProgress(phase === "processing");

  function handleFilesSelected(files: File[]) {
    const [chosen] = files;
    if (!chosen) return;
    setFile(chosen);
    setResult(null);
    setPhase("idle");
  }

  function handleConvert() {
    if (!file) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await convertPdfToWordAction(file);
      if (response.ok) {
        setResult(response.data);
        setPhase("done");
      } else {
        setErrorMessage(response.error.message);
        setPhase("error");
      }
    });
  }

  function handleDownload() {
    if (!result) return;
    const link = document.createElement("a");
    link.href = `data:application/vnd.openxmlformats-officedocument.wordprocessingml.document;base64,${result.base64}`;
    link.download = result.filename;
    link.click();
  }

  function handleReset() {
    setFile(null);
    setResult(null);
    setPhase("empty");
  }

  return (
    <div className="grid gap-6 md:grid-cols-[1fr_380px]">
      <div className="flex items-center justify-center gap-6 rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {file ? (
          <>
            <div className="text-center">
              <div className="mx-auto mb-2.5 flex h-20 w-16 items-center justify-center rounded-lg border border-border bg-accent/10 dark:border-border-dark">
                <svg
                  width="26"
                  height="26"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  className="text-accent"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                  <path d="M14 2v6h6" />
                </svg>
              </div>
              <p className="truncate text-sm font-semibold">{file.name}</p>
            </div>
            <svg
              width="28"
              height="28"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              className="text-text-soft dark:text-text-soft-dark"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M5 12h14M13 6l6 6-6 6" />
            </svg>
            <div className="text-center">
              <div className="mx-auto mb-2.5 flex h-20 w-16 items-center justify-center rounded-lg border border-border bg-word-brand/10 text-word-brand dark:border-border-dark">
                <svg
                  width="26"
                  height="26"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                  <path d="M14 2v6h6" />
                  <path d="M9 13h6M9 17h4" />
                </svg>
              </div>
              <p className="text-sm font-semibold">
                {file.name.replace(/\.pdf$/i, "")}.docx
              </p>
            </div>
          </>
        ) : (
          <UploadDropzone onFilesSelected={handleFilesSelected} />
        )}
      </div>

      <div className="flex flex-col gap-5 rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {phase === "empty" && (
          <p className="text-sm text-text-soft dark:text-text-soft-dark">
            Dönüştürmeye başlamak için önce bir PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <p className="rounded-panel bg-bg px-3.5 py-3 text-xs text-text-soft dark:bg-black dark:text-text-soft-dark">
            Çıktı formatı: <strong className="text-text dark:text-text-dark">.docx (Microsoft Word)</strong>
          </p>
        )}

        {phase === "processing" && <ProgressBar label="Dönüştürülüyor…" percent={progress} />}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleConvert} />}

        {phase === "done" && result && (
          <ResultPanel
            currentToolId="convert"
            title="Dönüştürme tamamlandı"
            description={`${result.filename} hazır`}
            onDownload={handleDownload}
            onReset={handleReset}
          />
        )}

        <div className="flex flex-col gap-3">
          {phase === "idle" && (
            <button
              type="button"
              onClick={handleConvert}
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
            >
              Word&apos;e Dönüştür
            </button>
          )}
          {phase === "processing" && (
            <button
              type="button"
              disabled
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white opacity-60"
            >
              İşleniyor…
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
