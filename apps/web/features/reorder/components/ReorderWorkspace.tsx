"use client";

import { useEffect, useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { ProgressBar } from "@/components/ProgressBar";
import { ResultPanel } from "@/components/ResultPanel";
import { UploadDropzone } from "@/components/UploadDropzone";
import { reorderPdfAction } from "@/features/reorder/actions";
import type { ReorderResult } from "@/features/reorder/types";
import { useFakeProgress } from "@/lib/hooks/use-fake-progress";
import { usePdfPageCount } from "@/lib/hooks/use-pdf-page-count";
import { usePendingFile } from "@/lib/hooks/use-pending-file";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

export function ReorderWorkspace() {
  const [file, setFile] = usePendingFile();
  const [order, setOrder] = useState<number[]>([]);
  const [phase, setPhase] = useState<Phase>(file ? "idle" : "empty");
  const [result, setResult] = useState<ReorderResult | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [, startTransition] = useTransition();
  const { pageCount } = usePdfPageCount(file);
  const progress = useFakeProgress(phase === "processing");

  useEffect(() => {
    if (pageCount) {
      setOrder(Array.from({ length: pageCount }, (_, index) => index + 1));
    }
  }, [pageCount]);

  function handleFilesSelected(files: File[]) {
    const [chosen] = files;
    if (!chosen) return;
    setFile(chosen);
    setResult(null);
    setPhase("idle");
  }

  function move(originalNumber: number, direction: -1 | 1) {
    setOrder((current) => {
      const index = current.indexOf(originalNumber);
      const targetIndex = index + direction;
      if (index === -1 || targetIndex < 0 || targetIndex >= current.length) return current;
      const next = [...current];
      [next[index], next[targetIndex]] = [next[targetIndex], next[index]];
      return next;
    });
  }

  function handleReorder() {
    if (!file) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await reorderPdfAction(file, order);
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
          <div>
            <div className="mb-4 flex items-center gap-3 border-b border-border pb-4 dark:border-border-dark">
              <p className="truncate text-sm font-semibold">{file.name}</p>
              <p className="text-xs text-text-soft dark:text-text-soft-dark">
                {pageCount ? `${pageCount} sayfa` : "…"}
              </p>
            </div>
            {pageCount ? (
              <div className="grid grid-cols-3 gap-3 md:grid-cols-6">
                {order.map((originalNumber, index) => (
                  <div key={originalNumber} className="flex flex-col items-center gap-1.5">
                    <div className="relative w-full">
                      <div className="aspect-page rounded-md border border-border bg-bg dark:border-border-dark dark:bg-black" />
                      <span className="absolute bottom-1 right-1 rounded-md bg-surface px-1.5 py-px text-[10px] font-bold text-text-soft dark:bg-surface-dark dark:text-text-soft-dark">
                        {originalNumber}
                      </span>
                    </div>
                    <div className="flex items-center gap-0.5">
                      <button
                        type="button"
                        disabled={index === 0}
                        onClick={() => move(originalNumber, -1)}
                        className="rounded-lg p-1.5 text-text-soft transition disabled:opacity-30 dark:text-text-soft-dark"
                        aria-label="Sola taşı"
                      >
                        ←
                      </button>
                      <span className="w-3.5 text-center text-[11px] font-bold text-text-soft dark:text-text-soft-dark">
                        {index + 1}
                      </span>
                      <button
                        type="button"
                        disabled={index === order.length - 1}
                        onClick={() => move(originalNumber, 1)}
                        className="rounded-lg p-1.5 text-text-soft transition disabled:opacity-30 dark:text-text-soft-dark"
                        aria-label="Sağa taşı"
                      >
                        →
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : null}
          </div>
        ) : (
          <UploadDropzone onFilesSelected={handleFilesSelected} />
        )}
      </div>

      <div className="flex flex-col gap-6 rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {phase === "empty" && (
          <p className="text-sm text-text-soft dark:text-text-soft-dark">
            Sıralamayı görmek için önce bir PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <div>
            <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Yeni sıra
            </p>
            <p className="rounded-panel bg-bg px-3.5 py-3 text-xs leading-relaxed text-text-soft dark:bg-black dark:text-text-soft-dark">
              Sayfa sırası: {order.join(" → ")}
            </p>
          </div>
        )}

        {phase === "processing" && <ProgressBar label="Yeniden sıralanıyor…" percent={progress} />}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleReorder} />}

        {phase === "done" && (
          <ResultPanel
            currentToolId="reorder"
            title="Sıralama tamamlandı"
            description="Yeni sıra kaydedildi"
            onDownload={handleDownload}
            onReset={handleReset}
          />
        )}

        <div className="flex flex-col gap-3">
          {phase === "idle" && (
            <button
              type="button"
              onClick={handleReorder}
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
            >
              Sırala
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
