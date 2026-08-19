"use client";

import { useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { UploadDropzone } from "@/components/UploadDropzone";
import { splitPdfAction } from "@/features/split/actions";
import type { SplitResult } from "@/features/split/types";
import { usePdfPageCount } from "@/lib/hooks/use-pdf-page-count";
import { formatBytes } from "@/lib/utils";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

export function SplitWorkspace() {
  const [file, setFile] = useState<File | null>(null);
  const [phase, setPhase] = useState<Phase>("empty");
  const [result, setResult] = useState<SplitResult | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [, startTransition] = useTransition();
  const { pageCount } = usePdfPageCount(file);

  function handleFilesSelected(files: File[]) {
    const [selected] = files;
    if (!selected) return;
    setFile(selected);
    setResult(null);
    setPhase("idle");
  }

  function handleSplit() {
    if (!file) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await splitPdfAction(file);
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
    link.href = `data:application/zip;base64,${result.base64}`;
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
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold">{file.name}</p>
                <p className="text-xs text-text-soft dark:text-text-soft-dark">
                  {pageCount ? `${pageCount} sayfa · ` : ""}
                  {formatBytes(file.size)}
                </p>
              </div>
              <button
                type="button"
                onClick={handleReset}
                className="text-xs font-semibold text-accent"
              >
                Değiştir
              </button>
            </div>
            {pageCount ? (
              <div className="grid grid-cols-4 gap-2.5 md:grid-cols-6">
                {Array.from({ length: pageCount }, (_, index) => (
                  <div key={index} className="relative">
                    <div className="aspect-page rounded-md border border-border bg-bg dark:border-border-dark dark:bg-black" />
                    <span className="absolute bottom-1 right-1 rounded-md bg-surface px-1.5 py-px text-[10px] font-bold text-text-soft dark:bg-surface-dark dark:text-text-soft-dark">
                      {index + 1}
                    </span>
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
            Ayırma sonucunu görmek için önce bir PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <div>
            <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Sonuç
            </p>
            <div className="flex flex-col gap-2.5">
              <div className="flex items-center justify-between rounded-panel bg-bg px-3.5 py-3 dark:bg-black">
                <span className="text-xs text-text-soft dark:text-text-soft-dark">
                  Sayfa sayısı
                </span>
                <span className="text-sm font-bold">{pageCount ?? "…"}</span>
              </div>
              <div className="flex items-center justify-between rounded-panel border border-border px-3.5 py-3 dark:border-border-dark">
                <span className="text-xs text-text-soft dark:text-text-soft-dark">Çıkış</span>
                <span className="text-sm font-bold">
                  {pageCount ? `${pageCount} ayrı PDF (.zip)` : "…"}
                </span>
              </div>
            </div>
          </div>
        )}

        {phase === "processing" && (
          <div className="py-6 text-center">
            <p className="mb-1.5 text-sm font-semibold">Ayrılıyor…</p>
            <p className="mb-5 text-xs text-text-soft dark:text-text-soft-dark">
              Bu birkaç saniye sürebilir.
            </p>
            <div className="h-2 animate-pulse rounded-full bg-bg dark:bg-black" />
          </div>
        )}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleSplit} />}

        {phase === "done" && result && (
          <div className="text-center">
            <p className="mb-1 text-base font-bold">Ayırma tamamlandı</p>
            <p className="text-sm text-text-soft dark:text-text-soft-dark">
              {result.pageCount} sayfa → {result.pageCount} ayrı PDF
            </p>
          </div>
        )}

        <div className="flex flex-col gap-3">
          {phase === "idle" && (
            <button
              type="button"
              onClick={handleSplit}
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
            >
              Sayfalara Ayır
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
          {phase === "done" && (
            <>
              <button
                type="button"
                onClick={handleDownload}
                className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
              >
                İndir (.zip)
              </button>
              <button
                type="button"
                onClick={handleReset}
                className="w-full rounded-panel border border-border px-4 py-3 text-sm font-semibold transition dark:border-border-dark"
              >
                Yeni İşlem
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
