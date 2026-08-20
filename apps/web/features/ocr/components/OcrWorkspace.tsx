"use client";

import { useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { ProgressBar } from "@/components/ProgressBar";
import { ResultPanel } from "@/components/ResultPanel";
import { UploadDropzone } from "@/components/UploadDropzone";
import { ocrPdfAction } from "@/features/ocr/actions";
import type { OcrLanguage, OcrOutputFormat, OcrResult } from "@/features/ocr/types";
import { useFakeProgress } from "@/lib/hooks/use-fake-progress";
import { usePendingFile } from "@/lib/hooks/use-pending-file";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

const LANGUAGE_OPTIONS: Array<{ id: OcrLanguage; label: string }> = [
  { id: "tr", label: "Türkçe" },
  { id: "en", label: "English" },
];

const FORMAT_OPTIONS: Array<{ id: OcrOutputFormat; label: string; hint: string }> = [
  { id: "searchable", label: "Aranabilir PDF", hint: "Görüntü + görünmez metin katmanı" },
  { id: "text", label: "Düz Metin (.txt)", hint: "Sadece tanınan metin" },
];

function decodeBase64Text(base64: string): string {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return new TextDecoder("utf-8").decode(bytes);
}

export function OcrWorkspace() {
  const [file, setFile] = usePendingFile();
  const [language, setLanguage] = useState<OcrLanguage>("tr");
  const [outputFormat, setOutputFormat] = useState<OcrOutputFormat>("searchable");
  const [phase, setPhase] = useState<Phase>(file ? "idle" : "empty");
  const [result, setResult] = useState<OcrResult | null>(null);
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

  function handleOcr() {
    if (!file) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await ocrPdfAction(file, language, outputFormat);
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
    const mediaType = result.outputFormat === "text" ? "text/plain" : "application/pdf";
    const link = document.createElement("a");
    link.href = `data:${mediaType};base64,${result.base64}`;
    link.download = result.filename;
    link.click();
  }

  function handleReset() {
    setFile(null);
    setResult(null);
    setPhase("empty");
  }

  const recognizedText =
    result?.outputFormat === "text" ? decodeBase64Text(result.base64) : null;

  return (
    <div className="grid gap-6 md:grid-cols-[1fr_380px]">
      <div className="rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {file ? (
          <>
            <p className="mb-4 truncate text-sm font-semibold">{file.name}</p>
            {recognizedText ? (
              <div className="rounded-panel border border-border bg-bg p-5 dark:border-border-dark dark:bg-black">
                <p className="mb-2.5 text-[11px] font-bold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
                  Tanınan metin
                </p>
                <p className="whitespace-pre-wrap text-sm leading-relaxed">{recognizedText}</p>
              </div>
            ) : (
              <div className="rounded-panel border border-dashed border-border p-8 text-center dark:border-border-dark">
                <p className="text-sm text-text-soft dark:text-text-soft-dark">
                  {phase === "done"
                    ? "Aranabilir PDF hazır — metin önizlemesi için “Düz Metin” çıktısını seç."
                    : "Tanınan metin burada görünecek."}
                </p>
              </div>
            )}
          </>
        ) : (
          <UploadDropzone onFilesSelected={handleFilesSelected} />
        )}
      </div>

      <div className="flex flex-col gap-5 rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {phase === "empty" && (
          <p className="text-sm text-text-soft dark:text-text-soft-dark">
            Dil ve çıktı formatını seçmek için önce bir PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <div>
            <p className="mb-2.5 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Dil
            </p>
            <div className="mb-4 flex gap-2">
              {LANGUAGE_OPTIONS.map((option) => (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => setLanguage(option.id)}
                  className={`flex-1 rounded-panel border-2 py-3 text-center text-sm font-semibold transition ${
                    language === option.id
                      ? "border-accent"
                      : "border-border dark:border-border-dark"
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>

            <p className="mb-2.5 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Çıktı formatı
            </p>
            <div className="flex flex-col gap-2.5">
              {FORMAT_OPTIONS.map((option) => (
                <button
                  key={option.id}
                  type="button"
                  onClick={() => setOutputFormat(option.id)}
                  className={`rounded-panel border-2 px-4 py-3.5 text-left transition ${
                    outputFormat === option.id
                      ? "border-accent"
                      : "border-border dark:border-border-dark"
                  }`}
                >
                  <span className="block text-sm font-semibold">{option.label}</span>
                  <span className="block text-xs text-text-soft dark:text-text-soft-dark">
                    {option.hint}
                  </span>
                </button>
              ))}
            </div>
          </div>
        )}

        {phase === "processing" && <ProgressBar label="Metin taranıyor…" percent={progress} />}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleOcr} />}

        {phase === "done" && (
          <ResultPanel
            currentToolId="ocr"
            title="Tanıma tamamlandı"
            description={
              result?.outputFormat === "text" ? "recognized.txt hazır" : "searchable.pdf hazır"
            }
            onDownload={handleDownload}
            onReset={handleReset}
          />
        )}

        <div className="flex flex-col gap-3">
          {phase === "idle" && (
            <button
              type="button"
              onClick={handleOcr}
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
            >
              Metni Tanı
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
