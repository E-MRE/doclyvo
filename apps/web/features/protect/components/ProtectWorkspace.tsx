"use client";

import { useState, useTransition } from "react";
import { ErrorState } from "@/components/ErrorState";
import { ProgressBar } from "@/components/ProgressBar";
import { ResultPanel } from "@/components/ResultPanel";
import { UploadDropzone } from "@/components/UploadDropzone";
import { protectPdfAction } from "@/features/protect/actions";
import type { ProtectResult } from "@/features/protect/types";
import { useFakeProgress } from "@/lib/hooks/use-fake-progress";
import { usePendingFile } from "@/lib/hooks/use-pending-file";

type Phase = "empty" | "idle" | "processing" | "done" | "error";

const PASSWORD_CHARS = "ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$";

function generatePassword(): string {
  let password = "";
  for (let i = 0; i < 9; i += 1) {
    password += PASSWORD_CHARS[Math.floor(Math.random() * PASSWORD_CHARS.length)];
  }
  return password;
}

export function ProtectWorkspace() {
  const [file, setFile] = usePendingFile();
  const [password, setPassword] = useState(generatePassword);
  const [isRevealed, setIsRevealed] = useState(false);
  const [noPrint, setNoPrint] = useState(true);
  const [noCopy, setNoCopy] = useState(false);
  const [noEdit, setNoEdit] = useState(false);
  const [phase, setPhase] = useState<Phase>(file ? "idle" : "empty");
  const [result, setResult] = useState<ProtectResult | null>(null);
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

  function handleProtect() {
    if (!file) return;
    setPhase("processing");
    startTransition(async () => {
      const response = await protectPdfAction(file, password, noPrint, noCopy, noEdit);
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
    setPassword(generatePassword());
    setIsRevealed(false);
    setPhase("empty");
  }

  const isProtected = phase === "done";

  return (
    <div className="grid gap-6 md:grid-cols-[1fr_380px]">
      <div className="flex flex-col items-center justify-center rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {file ? (
          <>
            <div className="mb-6 w-full">
              <p className="truncate text-sm font-semibold">{file.name}</p>
            </div>
            <div
              className={`flex h-24 w-24 items-center justify-center rounded-card transition ${
                isProtected ? "bg-accent/15 text-accent" : "bg-bg text-border dark:bg-black dark:text-border-dark"
              }`}
            >
              <svg
                width="42"
                height="42"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <rect x="5" y="11" width="14" height="9" rx="2" />
                <path d="M8 11V7a4 4 0 0 1 8 0v4" />
              </svg>
            </div>
            <p className="mt-4 text-xs text-text-soft dark:text-text-soft-dark">
              {isProtected ? "Belge şifreyle korunuyor" : "Henüz korunmadı"}
            </p>
          </>
        ) : (
          <UploadDropzone onFilesSelected={handleFilesSelected} />
        )}
      </div>

      <div className="flex flex-col gap-5 rounded-card border border-border bg-surface p-6 dark:border-border-dark dark:bg-surface-dark">
        {phase === "empty" && (
          <p className="text-sm text-text-soft dark:text-text-soft-dark">
            Şifre ve izin seçeneklerini görmek için önce bir PDF yükle.
          </p>
        )}

        {phase === "idle" && (
          <div>
            <p className="mb-2.5 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              Şifre
            </p>
            <div className="mb-4 flex items-center gap-2.5">
              <div className="flex-1 rounded-panel border border-border px-3.5 py-3 font-mono text-base tracking-widest dark:border-border-dark">
                {isRevealed ? password : "•".repeat(password.length)}
              </div>
              <button
                type="button"
                onClick={() => setIsRevealed((current) => !current)}
                className="flex h-10 w-10 items-center justify-center rounded-panel border border-border text-text-soft dark:border-border-dark dark:text-text-soft-dark"
                aria-label="Göster/Gizle"
              >
                <svg
                  width="18"
                  height="18"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7Z" />
                  <circle cx="12" cy="12" r="3" />
                </svg>
              </button>
            </div>
            <button
              type="button"
              onClick={() => {
                setPassword(generatePassword());
                setIsRevealed(true);
              }}
              className="mb-4 w-full rounded-panel border border-border py-2.5 text-xs font-semibold text-accent dark:border-border-dark"
            >
              Yeni Şifre Oluştur
            </button>

            <p className="mb-2.5 text-xs font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
              İzinler
            </p>
            <div className="flex flex-col gap-2.5">
              <PermissionRow
                label="Yazdırmayı engelle"
                checked={noPrint}
                onToggle={() => setNoPrint((current) => !current)}
              />
              <PermissionRow
                label="Kopyalamayı engelle"
                checked={noCopy}
                onToggle={() => setNoCopy((current) => !current)}
              />
              <PermissionRow
                label="Düzenlemeyi engelle"
                checked={noEdit}
                onToggle={() => setNoEdit((current) => !current)}
              />
            </div>
          </div>
        )}

        {phase === "processing" && <ProgressBar label="Korunuyor…" percent={progress} />}

        {phase === "error" && <ErrorState message={errorMessage} retry={handleProtect} />}

        {phase === "done" && (
          <ResultPanel
            currentToolId="protect"
            title="Belge korundu"
            description="Şifreyi güvenli bir yerde sakla, bu ekrandan sonra tekrar gösterilmez."
            onDownload={handleDownload}
            onReset={handleReset}
          />
        )}

        <div className="flex flex-col gap-3">
          {phase === "idle" && (
            <button
              type="button"
              onClick={handleProtect}
              className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
            >
              Koru
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

function PermissionRow({
  label,
  checked,
  onToggle,
}: {
  label: string;
  checked: boolean;
  onToggle: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onToggle}
      className={`flex items-center gap-2.5 rounded-panel border-2 px-3.5 py-3 text-left transition ${
        checked ? "border-accent" : "border-border dark:border-border-dark"
      }`}
    >
      <span
        className={`flex h-5 w-5 shrink-0 items-center justify-center rounded ${
          checked ? "bg-accent" : "bg-border dark:bg-border-dark"
        }`}
      >
        {checked && (
          <svg
            width="11"
            height="11"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#FFFFFF"
            strokeWidth="3"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M20 6 9 17l-5-5" />
          </svg>
        )}
      </span>
      <span className="text-sm font-semibold">{label}</span>
    </button>
  );
}
