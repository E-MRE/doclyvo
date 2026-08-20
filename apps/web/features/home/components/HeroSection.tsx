"use client";

import { UploadDropzone } from "@/components/UploadDropzone";
import { formatBytes } from "@/lib/utils";

interface HeroSectionProps {
  file: File | null;
  onFileSelected: (file: File) => void;
  onClearFile: () => void;
}

export function HeroSection({ file, onFileSelected, onClearFile }: HeroSectionProps) {
  return (
    <section className="grid gap-10 px-6 py-16 sm:px-12 sm:py-20 md:grid-cols-2 md:items-center">
      <div>
        <span className="mb-5 inline-flex items-center rounded-full bg-accent/10 px-3 py-1.5 text-xs font-semibold text-accent">
          Hesap gerekmez, dosyaların cihazında kalır
        </span>
        <h1 className="mb-5 text-4xl font-extrabold leading-tight tracking-tight sm:text-5xl">
          PDF işleri iş gibi
          <br />
          hissettirmek zorunda değil.
        </h1>
        <p className="mb-8 max-w-md text-base leading-relaxed text-text-soft dark:text-text-soft-dark">
          Birleştir, böl, sıkıştır ve dönüştür — hepsi tek bir sade arayüzde. Doclyvo, PDF
          işlerini üç tıkla bitirmen için var.
        </p>
        <div className="flex items-center gap-3.5">
          <a
            href="#araclar"
            className="rounded-panel bg-accent px-6 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
          >
            Ücretsiz Başla
          </a>
          <a
            href="#araclar"
            className="rounded-panel border border-border px-5 py-3.5 text-sm font-semibold transition dark:border-border-dark"
          >
            Tüm araçları gör
          </a>
        </div>
      </div>
      <div className="animate-pop rounded-card border border-border bg-surface p-7 shadow-xl dark:border-border-dark dark:bg-surface-dark">
        {file ? (
          <div className="rounded-panel border border-border p-5 dark:border-border-dark">
            <div className="flex items-center gap-3 rounded-panel bg-accent/10 p-3.5">
              <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-panel bg-accent text-white">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                  <path d="M14 2v6h6" />
                </svg>
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold">{file.name}</p>
                <p className="text-xs text-text-soft dark:text-text-soft-dark">{formatBytes(file.size)}</p>
              </div>
              <button
                type="button"
                onClick={onClearFile}
                aria-label="Kaldır"
                className="text-text-soft transition hover:opacity-70 dark:text-text-soft-dark"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M18 6 6 18M6 6l12 12" />
                </svg>
              </button>
            </div>
            <p className="mt-4 text-center text-xs text-text-soft dark:text-text-soft-dark">
              Aşağıdan bir araç seç, dosyan orada seni bekliyor.
            </p>
          </div>
        ) : (
          <UploadDropzone
            onFilesSelected={([selected]) => selected && onFileSelected(selected)}
          />
        )}
      </div>
    </section>
  );
}
