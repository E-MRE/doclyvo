"use client";

import { useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { ProgressBar } from "@/components/ProgressBar";
import { ResultPanel } from "@/components/ResultPanel";
import { UploadDropzone } from "@/components/UploadDropzone";
import { mergePdfsAction } from "@/features/merge/actions";
import type { MergeFileItem, MergeResult } from "@/features/merge/types";
import { useFakeProgress } from "@/lib/hooks/use-fake-progress";
import { formatBytes } from "@/lib/utils";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

let nextId = 0;

function toItems(files: File[]): MergeFileItem[] {
  return files.map((file) => ({ id: `f${(nextId += 1)}`, file }));
}

export function MergeWorkspace() {
  const [items, setItems] = useState<MergeFileItem[]>([]);
  const [phase, setPhase] = useState<Phase>("empty");
  const [result, setResult] = useState<MergeResult | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [, startTransition] = useTransition();
  const progress = useFakeProgress(phase === "processing");

  function handleFilesSelected(files: File[]) {
    setItems((current) => [...current, ...toItems(files)]);
    setResult(null);
    setPhase("idle");
  }

  function moveItem(id: string, direction: -1 | 1) {
    setItems((current) => {
      const index = current.findIndex((item) => item.id === id);
      const targetIndex = index + direction;
      if (index === -1 || targetIndex < 0 || targetIndex >= current.length) return current;
      const next = [...current];
      [next[index], next[targetIndex]] = [next[targetIndex], next[index]];
      return next;
    });
  }

  function removeItem(id: string) {
    setItems((current) => current.filter((item) => item.id !== id));
  }

  function handleMerge() {
    if (items.length < 2) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await mergePdfsAction(items.map((item) => item.file));
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
    setItems([]);
    setResult(null);
    setPhase("empty");
  }

  return (
    <div className="grid gap-6 md:grid-cols-[1fr_380px]">
      <div className="rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {items.length === 0 ? (
          <UploadDropzone multiple onFilesSelected={handleFilesSelected} />
        ) : (
          <div>
            <div className="mb-3.5 flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
                Sıra · oklarla değiştir
              </p>
              <UploadDropzoneAddButton onFilesSelected={handleFilesSelected} />
            </div>
            <div className="flex flex-col gap-2.5">
              {items.map((item, index) => (
                <div
                  key={item.id}
                  className="flex items-center gap-3 rounded-panel border border-border bg-bg px-3.5 py-3 dark:border-border-dark dark:bg-black"
                >
                  <span className="w-5 text-center text-xs font-bold text-text-soft dark:text-text-soft-dark">
                    {index + 1}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-semibold">{item.file.name}</p>
                    <p className="text-xs text-text-soft dark:text-text-soft-dark">
                      {formatBytes(item.file.size)}
                    </p>
                  </div>
                  <button
                    type="button"
                    disabled={index === 0}
                    onClick={() => moveItem(item.id, -1)}
                    className="rounded-lg p-1.5 text-text-soft transition disabled:opacity-30 dark:text-text-soft-dark"
                    aria-label="Yukarı taşı"
                  >
                    ↑
                  </button>
                  <button
                    type="button"
                    disabled={index === items.length - 1}
                    onClick={() => moveItem(item.id, 1)}
                    className="rounded-lg p-1.5 text-text-soft transition disabled:opacity-30 dark:text-text-soft-dark"
                    aria-label="Aşağı taşı"
                  >
                    ↓
                  </button>
                  <button
                    type="button"
                    onClick={() => removeItem(item.id)}
                    className="rounded-lg p-1.5 text-text-soft transition dark:text-text-soft-dark"
                    aria-label="Kaldır"
                  >
                    ✕
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      <div className="flex flex-col gap-6 rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {phase === "empty" && (
          <p className="text-sm text-text-soft dark:text-text-soft-dark">
            Birleştirmek için en az iki PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <div>
            <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Özet
            </p>
            <div className="flex flex-col gap-2.5">
              <SummaryRow label="Dosya sayısı" value={String(items.length)} highlighted />
              <SummaryRow label="Çıkış dosyası" value="1 PDF" />
            </div>
          </div>
        )}

        {phase === "processing" && <ProgressBar label="Birleştiriliyor…" percent={progress} />}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleMerge} />}

        {phase === "done" && result && (
          <ResultPanel
            currentToolId="merge"
            title="Birleştirme tamamlandı"
            description={`${result.fileCount} dosya → 1 PDF · ${result.pageCount} sayfa`}
            onDownload={handleDownload}
            onReset={handleReset}
          />
        )}

        <div className="flex flex-col gap-3">
          {phase === "idle" && (
            <button
              type="button"
              disabled={items.length < 2}
              onClick={handleMerge}
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95 disabled:opacity-55"
            >
              Birleştir
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

function SummaryRow({
  label,
  value,
  highlighted = false,
}: {
  label: string;
  value: string;
  highlighted?: boolean;
}) {
  return (
    <div
      className={`flex items-center justify-between rounded-panel px-3.5 py-3 ${
        highlighted
          ? "bg-bg dark:bg-black"
          : "border border-border dark:border-border-dark"
      }`}
    >
      <span className="text-xs text-text-soft dark:text-text-soft-dark">{label}</span>
      <span className="text-sm font-bold">{value}</span>
    </div>
  );
}

function UploadDropzoneAddButton({
  onFilesSelected,
}: {
  onFilesSelected: (files: File[]) => void;
}) {
  return (
    <label className="cursor-pointer rounded-capsule border border-border px-3.5 py-2 text-xs font-semibold text-accent transition dark:border-border-dark">
      + Dosya Ekle
      <input
        type="file"
        accept="application/pdf"
        multiple
        className="hidden"
        onChange={(event) => {
          if (event.target.files) onFilesSelected(Array.from(event.target.files));
          event.target.value = "";
        }}
      />
    </label>
  );
}
