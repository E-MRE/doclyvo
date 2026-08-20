"use client";

import { useEffect, useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { UploadDropzone } from "@/components/UploadDropzone";
import { signPdfAction } from "@/features/sign/actions";
import { SignatureCanvas } from "@/features/sign/components/SignatureCanvas";
import type { SignMode, SignResult } from "@/features/sign/types";
import { usePdfPageCount } from "@/lib/hooks/use-pdf-page-count";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

type PlacedSignature =
  | { mode: "type"; text: string }
  | { mode: "draw" | "upload"; image: File };

const MODE_OPTIONS: Array<{ id: SignMode; label: string }> = [
  { id: "draw", label: "Çiz" },
  { id: "type", label: "Yaz" },
  { id: "upload", label: "Yükle" },
];

// Matches design/Sign.dc.html's fixed bottom-right stamp. The backend already accepts
// arbitrary normalized coordinates, so a drag-to-place UI can be added later without any
// API change — this just ships the placement the design actually specifies.
const PLACEMENT_BOX = { x: 0.6, y: 0.78, width: 0.32, height: 0.1 };

export function SignWorkspace() {
  const [file, setFile] = useState<File | null>(null);
  const [phase, setPhase] = useState<Phase>("empty");
  const [mode, setMode] = useState<SignMode>("draw");
  const [signatureText, setSignatureText] = useState("");
  const [signatureImageFile, setSignatureImageFile] = useState<File | null>(null);
  const [placedSignature, setPlacedSignature] = useState<PlacedSignature | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [result, setResult] = useState<SignResult | null>(null);
  const [errorMessage, setErrorMessage] = useState("");
  const [, startTransition] = useTransition();
  const { pageCount } = usePdfPageCount(file);

  useEffect(() => {
    if (pageCount && currentPage > pageCount) {
      setCurrentPage(1);
    }
  }, [pageCount, currentPage]);

  useEffect(() => {
    if (!placedSignature || placedSignature.mode === "type") {
      setPreviewUrl(null);
      return;
    }
    const url = URL.createObjectURL(placedSignature.image);
    setPreviewUrl(url);
    return () => URL.revokeObjectURL(url);
  }, [placedSignature]);

  function handleFilesSelected(files: File[]) {
    const [chosen] = files;
    if (!chosen) return;
    setFile(chosen);
    setResult(null);
    setCurrentPage(1);
    setPhase("idle");
  }

  function handleModeChange(nextMode: SignMode) {
    setMode(nextMode);
    setSignatureImageFile(null);
  }

  function handlePlaceSignature() {
    if (mode === "type") {
      const text = signatureText.trim();
      if (!text) return;
      setPlacedSignature({ mode: "type", text });
    } else {
      if (!signatureImageFile) return;
      setPlacedSignature({ mode, image: signatureImageFile });
    }
  }

  function handleSign() {
    if (!file || !placedSignature) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await signPdfAction(
        file,
        placedSignature.mode,
        { pageNumber: currentPage, ...PLACEMENT_BOX },
        placedSignature.mode === "type" ? placedSignature.text : undefined,
        placedSignature.mode !== "type" ? placedSignature.image : undefined,
      );
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
    setMode("draw");
    setSignatureText("");
    setSignatureImageFile(null);
    setPlacedSignature(null);
    setCurrentPage(1);
  }

  return (
    <div className="grid gap-6 md:grid-cols-[1fr_380px]">
      <div className="flex flex-col items-center rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {file ? (
          <>
            <div className="mb-4 flex w-full items-center justify-between">
              <p className="text-sm font-semibold">{file.name}</p>
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
            <div className="relative flex aspect-page w-full max-w-md items-end justify-end overflow-hidden rounded-capsule border border-border bg-bg p-8 dark:border-border-dark dark:bg-black">
              <div className="absolute inset-8 top-8 space-y-3.5">
                <div className="h-2 w-3/5 rounded-full bg-border dark:bg-border-dark" />
                <div className="h-2 w-5/6 rounded-full bg-border dark:bg-border-dark" />
                <div className="h-2 w-4/5 rounded-full bg-border dark:bg-border-dark" />
              </div>
              {placedSignature ? (
                <div className="rounded-panel border-2 border-accent bg-accent/10 px-4 py-2">
                  {placedSignature.mode === "type" ? (
                    <span className="font-signature text-2xl text-accent">
                      {placedSignature.text}
                    </span>
                  ) : previewUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={previewUrl} alt="İmza" className="h-10 object-contain" />
                  ) : null}
                </div>
              ) : (
                <div className="rounded-panel border-2 border-dashed border-border px-4 py-2.5 text-xs text-text-soft dark:border-border-dark dark:text-text-soft-dark">
                  İmza buraya yerleşecek
                </div>
              )}
            </div>
          </>
        ) : (
          <UploadDropzone onFilesSelected={handleFilesSelected} />
        )}
      </div>

      <div className="flex flex-col gap-4 rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {phase === "empty" && (
          <p className="text-sm text-text-soft dark:text-text-soft-dark">
            İmza seçeneklerini görmek için önce bir PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <>
            <div className="flex gap-1.5 rounded-panel bg-bg p-1 dark:bg-black">
              {MODE_OPTIONS.map((option) => (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => handleModeChange(option.id)}
                  className={`flex-1 rounded-capsule px-3 py-2 text-sm font-semibold transition ${
                    mode === option.id
                      ? "bg-accent text-white"
                      : "text-text-soft dark:text-text-soft-dark"
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>

            {mode === "draw" && <SignatureCanvas onChange={setSignatureImageFile} />}

            {mode === "type" && (
              <input
                type="text"
                value={signatureText}
                onChange={(event) => setSignatureText(event.target.value)}
                placeholder="Adını yaz"
                className="w-full rounded-panel border border-border bg-bg px-4 py-6 text-center font-signature text-3xl text-text dark:border-border-dark dark:bg-black dark:text-text-dark"
              />
            )}

            {mode === "upload" && (
              <UploadDropzone
                accept="image/png"
                label="İmza görselini yükle"
                hint="PNG · şeffaf arka plan önerilir"
                onFilesSelected={(files) => setSignatureImageFile(files[0] ?? null)}
              />
            )}

            <button
              type="button"
              onClick={handlePlaceSignature}
              disabled={mode === "type" ? !signatureText.trim() : !signatureImageFile}
              className="w-full rounded-panel border border-border px-4 py-2.5 text-sm font-semibold text-accent transition disabled:opacity-40 dark:border-border-dark"
            >
              Belgeye Yerleştir
            </button>
          </>
        )}

        {phase === "processing" && (
          <div className="py-6 text-center">
            <p className="mb-1.5 text-sm font-semibold">İmzalanıyor…</p>
            <p className="mb-5 text-xs text-text-soft dark:text-text-soft-dark">
              Bu birkaç saniye sürebilir.
            </p>
            <div className="h-2 animate-pulse rounded-full bg-bg dark:bg-black" />
          </div>
        )}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleSign} />}

        {phase === "done" && (
          <div className="text-center">
            <p className="mb-1 text-base font-bold">İmzalı PDF hazır</p>
            <p className="text-sm text-text-soft dark:text-text-soft-dark">
              Sayfa {currentPage} imzalandı
            </p>
          </div>
        )}

        <div className="flex flex-col gap-3">
          {phase === "idle" && (
            <button
              type="button"
              onClick={handleSign}
              disabled={!placedSignature}
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95 disabled:opacity-55"
            >
              İmzala
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
