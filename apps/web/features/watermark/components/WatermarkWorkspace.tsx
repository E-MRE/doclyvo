"use client";

import { useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { ProgressBar } from "@/components/ProgressBar";
import { ResultPanel } from "@/components/ResultPanel";
import { UploadDropzone } from "@/components/UploadDropzone";
import { watermarkPdfAction } from "@/features/watermark/actions";
import type {
  WatermarkOpacity,
  WatermarkPosition,
  WatermarkResult,
} from "@/features/watermark/types";
import { useFakeProgress } from "@/lib/hooks/use-fake-progress";
import { usePendingFile } from "@/lib/hooks/use-pending-file";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

const PRESET_TEXTS = ["TASLAK", "GİZLİ", "ÖRNEK"];

const POSITION_OPTIONS: Array<{ id: WatermarkPosition; label: string }> = [
  { id: "center", label: "Ortala" },
  { id: "diagonal", label: "Çapraz" },
  { id: "corner", label: "Alt Köşe" },
];

const OPACITY_OPTIONS: Array<{ id: WatermarkOpacity; label: string }> = [
  { id: "light", label: "Hafif" },
  { id: "medium", label: "Orta" },
  { id: "strong", label: "Koyu" },
];

export function WatermarkWorkspace() {
  const [file, setFile] = usePendingFile();
  const [textIndex, setTextIndex] = useState(0);
  const [position, setPosition] = useState<WatermarkPosition>("diagonal");
  const [opacity, setOpacity] = useState<WatermarkOpacity>("medium");
  const [phase, setPhase] = useState<Phase>(file ? "idle" : "empty");
  const [result, setResult] = useState<WatermarkResult | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [, startTransition] = useTransition();
  const progress = useFakeProgress(phase === "processing");

  const text = PRESET_TEXTS[textIndex];

  function handleFilesSelected(files: File[]) {
    const [chosen] = files;
    if (!chosen) return;
    setFile(chosen);
    setResult(null);
    setPhase("idle");
  }

  function handleWatermark() {
    if (!file) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await watermarkPdfAction(file, text, position, opacity);
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
      <div className="flex flex-col items-center rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {file ? (
          <>
            <div className="mb-4 flex w-full items-center justify-between">
              <p className="truncate text-sm font-semibold">{file.name}</p>
              <button
                type="button"
                onClick={handleReset}
                className="text-xs font-semibold text-accent"
              >
                Değiştir
              </button>
            </div>
            <div className="relative flex aspect-page w-full max-w-md items-center justify-center overflow-hidden rounded-capsule border border-border bg-bg p-8 dark:border-border-dark dark:bg-black">
              <div className="w-full space-y-3.5">
                <div className="h-2 w-3/5 rounded-full bg-border dark:bg-border-dark" />
                <div className="h-2 w-5/6 rounded-full bg-border dark:bg-border-dark" />
                <div className="h-2 w-4/5 rounded-full bg-border dark:bg-border-dark" />
              </div>
              <div
                className="pointer-events-none absolute inset-0 flex items-center justify-center"
                style={{
                  transform:
                    position === "diagonal"
                      ? "rotate(-30deg)"
                      : position === "corner"
                        ? "translate(28%, 35%)"
                        : undefined,
                }}
              >
                <span
                  className="whitespace-nowrap text-3xl font-extrabold tracking-wide text-accent"
                  style={{
                    opacity: opacity === "light" ? 0.18 : opacity === "medium" ? 0.35 : 0.55,
                  }}
                >
                  {text}
                </span>
              </div>
            </div>
          </>
        ) : (
          <UploadDropzone onFilesSelected={handleFilesSelected} />
        )}
      </div>

      <div className="flex flex-col gap-5 rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {phase === "empty" && (
          <p className="text-sm text-text-soft dark:text-text-soft-dark">
            Filigran seçeneklerini görmek için önce bir PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <div>
            <div className="mb-3 flex items-center justify-between">
              <span className="text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
                Metin
              </span>
              <button
                type="button"
                onClick={() => setTextIndex((current) => (current + 1) % PRESET_TEXTS.length)}
                className="text-xs font-semibold text-accent"
              >
                Değiştir
              </button>
            </div>
            <div className="mb-4 rounded-panel bg-bg py-3.5 text-center text-base font-bold dark:bg-black">
              {text}
            </div>

            <p className="mb-2.5 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Konum
            </p>
            <div className="mb-4 flex flex-col gap-2.5">
              {POSITION_OPTIONS.map((option) => (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => setPosition(option.id)}
                  className={`rounded-panel border-2 px-4 py-3 text-left text-sm font-semibold transition ${
                    position === option.id
                      ? "border-accent"
                      : "border-border dark:border-border-dark"
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>

            <p className="mb-2.5 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Şeffaflık
            </p>
            <div className="flex gap-2">
              {OPACITY_OPTIONS.map((option) => (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => setOpacity(option.id)}
                  className={`flex-1 rounded-panel border-2 py-2.5 text-center text-xs font-semibold transition ${
                    opacity === option.id
                      ? "border-accent"
                      : "border-border dark:border-border-dark"
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>
        )}

        {phase === "processing" && (
          <ProgressBar label="Filigran ekleniyor…" percent={progress} />
        )}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleWatermark} />}

        {phase === "done" && (
          <ResultPanel
            currentToolId="watermark"
            title="Filigran eklendi"
            description="Tüm sayfalara uygulandı"
            onDownload={handleDownload}
            onReset={handleReset}
          />
        )}

        <div className="flex flex-col gap-3">
          {phase === "idle" && (
            <button
              type="button"
              onClick={handleWatermark}
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
            >
              Filigran Ekle
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
