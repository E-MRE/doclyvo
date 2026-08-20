"use client";

import { useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { ProgressBar } from "@/components/ProgressBar";
import { ResultPanel } from "@/components/ResultPanel";
import { UploadDropzone } from "@/components/UploadDropzone";
import { compressPdfAction } from "@/features/compress/actions";
import type { CompressQuality, CompressResult } from "@/features/compress/types";
import { useFakeProgress } from "@/lib/hooks/use-fake-progress";
import { usePendingFile } from "@/lib/hooks/use-pending-file";
import { formatBytes, formatPercentChange } from "@/lib/utils";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

const QUALITY_OPTIONS: Array<{ id: CompressQuality; label: string; hint: string }> = [
  { id: "low", label: "Düşük Sıkıştırma", hint: "En yüksek kalite" },
  { id: "recommended", label: "Önerilen", hint: "Kalite ve boyut dengesi" },
  { id: "high", label: "Yüksek Sıkıştırma", hint: "En küçük boyut" },
];

export function CompressWorkspace() {
  const [file, setFile] = usePendingFile();
  const [quality, setQuality] = useState<CompressQuality>("recommended");
  const [phase, setPhase] = useState<Phase>(file ? "idle" : "empty");
  const [result, setResult] = useState<CompressResult | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [, startTransition] = useTransition();
  const progress = useFakeProgress(phase === "processing");

  function handleFilesSelected(files: File[]) {
    const [selected] = files;
    if (!selected) return;
    setFile(selected);
    setResult(null);
    setPhase("idle");
  }

  function handleCompress() {
    if (!file) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await compressPdfAction(file, quality);
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
    link.href = `data:application/pdf;base64,${result.base64}`;
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
      <div className="rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {file ? (
          <div className="flex items-center gap-3">
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-semibold">{file.name}</p>
              <p className="text-xs text-text-soft dark:text-text-soft-dark">
                {formatBytes(file.size)}
              </p>
            </div>
            <button type="button" onClick={handleReset} className="text-xs font-semibold text-accent">
              Değiştir
            </button>
          </div>
        ) : (
          <UploadDropzone onFilesSelected={handleFilesSelected} />
        )}
      </div>

      <div className="flex flex-col gap-6 rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {phase === "empty" && (
          <p className="text-sm text-text-soft dark:text-text-soft-dark">
            Sıkıştırma seçeneklerini görmek için önce bir PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <div>
            <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Sıkıştırma seviyesi
            </p>
            <div className="flex flex-col gap-2.5">
              {QUALITY_OPTIONS.map((option) => (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => setQuality(option.id)}
                  className={`flex flex-col rounded-panel border-2 px-4 py-3.5 text-left transition ${
                    quality === option.id
                      ? "border-accent"
                      : "border-border dark:border-border-dark"
                  }`}
                >
                  <span className="text-sm font-semibold">{option.label}</span>
                  <span className="text-xs text-text-soft dark:text-text-soft-dark">
                    {option.hint}
                  </span>
                </button>
              ))}
            </div>
          </div>
        )}

        {phase === "processing" && <ProgressBar label="Sıkıştırılıyor…" percent={progress} />}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleCompress} />}

        {phase === "done" && result && (
          <ResultPanel
            currentToolId="compress"
            title="Sıkıştırma tamamlandı"
            description={`${formatBytes(result.originalSize)} → ${formatBytes(result.compressedSize)} (-${formatPercentChange(result.originalSize, result.compressedSize)}%)`}
            onDownload={handleDownload}
            onReset={handleReset}
          />
        )}

        {phase === "idle" && (
          <button
            type="button"
            onClick={handleCompress}
            className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
          >
            Sıkıştır
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
  );
}
