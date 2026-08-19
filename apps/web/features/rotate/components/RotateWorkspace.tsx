"use client";

import { useEffect, useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { UploadDropzone } from "@/components/UploadDropzone";
import { rotatePdfAction } from "@/features/rotate/actions";
import type { RotateResult, RotationAngle } from "@/features/rotate/types";
import { usePdfPageCount } from "@/lib/hooks/use-pdf-page-count";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

const ANGLE_OPTIONS: Array<{ id: RotationAngle; label: string; hint: string }> = [
  { id: 90, label: "90° sağa döndür", hint: "Saat yönünde" },
  { id: 180, label: "180° çevir", hint: "Ters çevir" },
  { id: 270, label: "90° sola döndür", hint: "Saat yönü tersi" },
];

export function RotateWorkspace() {
  const [file, setFile] = useState<File | null>(null);
  const [angle, setAngle] = useState<RotationAngle>(90);
  const [selected, setSelected] = useState<number[]>([]);
  const [phase, setPhase] = useState<Phase>("empty");
  const [result, setResult] = useState<RotateResult | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [, startTransition] = useTransition();
  const { pageCount } = usePdfPageCount(file);

  useEffect(() => {
    if (pageCount) {
      setSelected(Array.from({ length: pageCount }, (_, index) => index + 1));
    }
  }, [pageCount]);

  function handleFilesSelected(files: File[]) {
    const [chosen] = files;
    if (!chosen) return;
    setFile(chosen);
    setResult(null);
    setPhase("idle");
  }

  function togglePage(pageNumber: number) {
    setSelected((current) =>
      current.includes(pageNumber)
        ? current.filter((n) => n !== pageNumber)
        : [...current, pageNumber],
    );
  }

  function toggleAll() {
    if (!pageCount) return;
    setSelected((current) =>
      current.length === pageCount ? [] : Array.from({ length: pageCount }, (_, i) => i + 1),
    );
  }

  function handleRotate() {
    if (!file || selected.length === 0) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await rotatePdfAction(file, angle, selected);
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

  const rotationDeg = angle === 90 ? "90deg" : angle === 180 ? "180deg" : "-90deg";
  const angleLabel = angle === 90 ? "90° sağa" : angle === 180 ? "180°" : "90° sola";

  return (
    <div className="grid gap-6 md:grid-cols-[1fr_380px]">
      <div className="rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {file ? (
          <div>
            <div className="mb-4 flex items-center justify-between border-b border-border pb-4 dark:border-border-dark">
              <div>
                <p className="text-sm font-semibold">{file.name}</p>
                <p className="text-xs text-text-soft dark:text-text-soft-dark">
                  {pageCount ? `${pageCount} sayfa` : "…"}
                </p>
              </div>
              {pageCount ? (
                <button
                  type="button"
                  onClick={toggleAll}
                  className="text-xs font-semibold text-accent"
                >
                  {selected.length === pageCount ? "Tümünü Kaldır" : "Tümünü Seç"}
                </button>
              ) : null}
            </div>
            {pageCount ? (
              <div className="grid grid-cols-6 gap-2.5">
                {Array.from({ length: pageCount }, (_, index) => {
                  const pageNumber = index + 1;
                  const isSelected = selected.includes(pageNumber);
                  return (
                    <button
                      type="button"
                      key={pageNumber}
                      onClick={() => togglePage(pageNumber)}
                      className="relative text-left"
                    >
                      <div
                        className={`aspect-page rounded-md border-2 bg-bg transition dark:bg-black ${
                          isSelected ? "border-accent" : "border-border dark:border-border-dark"
                        }`}
                        style={{
                          transform: isSelected ? `rotate(${rotationDeg}) scale(0.75)` : undefined,
                        }}
                      />
                      <span className="absolute bottom-1 right-1 rounded-md bg-surface px-1.5 py-px text-[10px] font-bold text-text-soft dark:bg-surface-dark dark:text-text-soft-dark">
                        {pageNumber}
                      </span>
                    </button>
                  );
                })}
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
            Döndürme seçeneklerini görmek için önce bir PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <div>
            <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Döndürme yönü
            </p>
            <div className="flex flex-col gap-2.5">
              {ANGLE_OPTIONS.map((option) => (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => setAngle(option.id)}
                  className={`flex flex-col rounded-panel border-2 px-4 py-3.5 text-left transition ${
                    angle === option.id ? "border-accent" : "border-border dark:border-border-dark"
                  }`}
                >
                  <span className="text-sm font-semibold">{option.label}</span>
                  <span className="text-xs text-text-soft dark:text-text-soft-dark">
                    {option.hint}
                  </span>
                </button>
              ))}
            </div>
            <p className="mt-3.5 rounded-panel bg-bg px-3 py-2.5 text-xs text-text-soft dark:bg-black dark:text-text-soft-dark">
              {selected.length} sayfa seçili · {angleLabel} döndürülecek
            </p>
          </div>
        )}

        {phase === "processing" && (
          <div className="py-6 text-center">
            <p className="mb-1.5 text-sm font-semibold">Döndürülüyor…</p>
            <p className="mb-5 text-xs text-text-soft dark:text-text-soft-dark">
              Bu birkaç saniye sürebilir.
            </p>
            <div className="h-2 animate-pulse rounded-full bg-bg dark:bg-black" />
          </div>
        )}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleRotate} />}

        {phase === "done" && (
          <div className="text-center">
            <p className="mb-1 text-base font-bold">Döndürme tamamlandı</p>
            <p className="text-sm text-text-soft dark:text-text-soft-dark">
              {selected.length} sayfa · {angleLabel} döndürüldü
            </p>
          </div>
        )}

        <div className="flex flex-col gap-3">
          {phase === "idle" && (
            <button
              type="button"
              disabled={selected.length === 0}
              onClick={handleRotate}
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95 disabled:opacity-55"
            >
              Döndür
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
                İndir
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
