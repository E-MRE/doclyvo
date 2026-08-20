"use client";

import { useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { ProgressBar } from "@/components/ProgressBar";
import { ResultPanel } from "@/components/ResultPanel";
import { UploadDropzone } from "@/components/UploadDropzone";
import { redactPdfAction } from "@/features/redact/actions";
import { RegionMarker } from "@/features/redact/components/RegionMarker";
import type { RedactRegion, RedactResult } from "@/features/redact/types";
import { useFakeProgress } from "@/lib/hooks/use-fake-progress";
import { usePdfPageCount } from "@/lib/hooks/use-pdf-page-count";
import { usePendingFile } from "@/lib/hooks/use-pending-file";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

let regionIdCounter = 0;

export function RedactWorkspace() {
  const [file, setFile] = usePendingFile();
  const [phase, setPhase] = useState<Phase>(file ? "idle" : "empty");
  const [currentPage, setCurrentPage] = useState(1);
  const [regions, setRegions] = useState<RedactRegion[]>([]);
  const [result, setResult] = useState<RedactResult | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [, startTransition] = useTransition();
  const { pageCount } = usePdfPageCount(file);
  const progress = useFakeProgress(phase === "processing");

  function handleFilesSelected(files: File[]) {
    const [chosen] = files;
    if (!chosen) return;
    setFile(chosen);
    setResult(null);
    setRegions([]);
    setCurrentPage(1);
    setPhase("idle");
  }

  function handleAddRegion(region: Omit<RedactRegion, "id">) {
    regionIdCounter += 1;
    setRegions((current) => [...current, { ...region, id: `region-${regionIdCounter}` }]);
  }

  function handleRemoveRegion(id: string) {
    setRegions((current) => current.filter((region) => region.id !== id));
  }

  function handleClearPage(pageNumber: number) {
    setRegions((current) => current.filter((region) => region.pageNumber !== pageNumber));
  }

  function handleRedact() {
    if (!file || regions.length === 0) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await redactPdfAction(file, regions);
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
    setRegions([]);
    setCurrentPage(1);
    setPhase("empty");
  }

  const summary = Array.from(new Set(regions.map((region) => region.pageNumber)))
    .sort((a, b) => a - b)
    .map((pageNumber) => ({
      pageNumber,
      count: regions.filter((region) => region.pageNumber === pageNumber).length,
    }));

  return (
    <div className="grid gap-6 md:grid-cols-[1fr_380px]">
      <div className="flex flex-col items-center rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {file ? (
          <>
            <div className="mb-4 flex w-full items-center justify-between">
              <p className="truncate text-sm font-semibold">{file.name}</p>
              {pageCount ? (
                <div className="flex items-center gap-2 text-xs text-text-soft dark:text-text-soft-dark">
                  <button
                    type="button"
                    disabled={currentPage <= 1}
                    onClick={() => setCurrentPage((page) => Math.max(1, page - 1))}
                    className="disabled:opacity-30"
                  >
                    ‹
                  </button>
                  Sayfa {currentPage} / {pageCount}
                  <button
                    type="button"
                    disabled={currentPage >= pageCount}
                    onClick={() => setCurrentPage((page) => Math.min(pageCount, page + 1))}
                    className="disabled:opacity-30"
                  >
                    ›
                  </button>
                </div>
              ) : null}
            </div>
            <RegionMarker
              pageNumber={currentPage}
              regions={regions}
              onAdd={handleAddRegion}
              onRemove={handleRemoveRegion}
            />
            <p className="mt-3 text-xs text-text-soft dark:text-text-soft-dark">
              Karartmak istediğin alanı sürükleyerek işaretle.
            </p>
          </>
        ) : (
          <UploadDropzone onFilesSelected={handleFilesSelected} />
        )}
      </div>

      <div className="flex flex-col gap-4 rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {phase === "empty" && (
          <p className="text-sm text-text-soft dark:text-text-soft-dark">
            Redaksiyon seçeneklerini görmek için önce bir PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <div>
            <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Karartılacak alanlar
            </p>
            {summary.length > 0 ? (
              <div className="mb-4 flex flex-col gap-2">
                {summary.map((row) => (
                  <div
                    key={row.pageNumber}
                    className="flex items-center justify-between rounded-panel border border-border px-3 py-2.5 dark:border-border-dark"
                  >
                    <span className="text-sm font-semibold">
                      Sayfa {row.pageNumber} — {row.count} alan
                    </span>
                    <button
                      type="button"
                      onClick={() => handleClearPage(row.pageNumber)}
                      className="text-xs font-semibold text-accent"
                    >
                      Kaldır
                    </button>
                  </div>
                ))}
              </div>
            ) : (
              <div className="mb-4 rounded-panel border border-dashed border-border p-4 text-center text-xs text-text-soft dark:border-border-dark dark:text-text-soft-dark">
                Henüz işaretlenmiş alan yok
              </div>
            )}

            <div className="flex gap-2.5 rounded-panel bg-accent/10 p-3">
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                className="mt-0.5 shrink-0 text-accent"
              >
                <path d="M12 9v4M12 17h.01" />
                <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z" />
              </svg>
              <p className="text-xs leading-relaxed">
                Bu alanların altındaki metin kalıcı olarak silinir, geri alınamaz.
              </p>
            </div>
          </div>
        )}

        {phase === "processing" && <ProgressBar label="Redakte ediliyor…" percent={progress} />}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleRedact} />}

        {phase === "done" && (
          <ResultPanel
            currentToolId="redact"
            title="Redaksiyon tamamlandı"
            description={`${regions.length} alan kalıcı olarak silindi`}
            onDownload={handleDownload}
            onReset={handleReset}
          />
        )}

        <div className="flex flex-col gap-3">
          {phase === "idle" && (
            <button
              type="button"
              onClick={handleRedact}
              disabled={regions.length === 0}
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95 disabled:opacity-55"
            >
              Redakte Et
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
