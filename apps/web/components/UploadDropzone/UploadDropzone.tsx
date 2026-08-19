"use client";

import { useRef, useState } from "react";

interface UploadDropzoneProps {
  multiple?: boolean;
  onFilesSelected: (files: File[]) => void;
}

export function UploadDropzone({ multiple = false, onFilesSelected }: UploadDropzoneProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);

  function handleFiles(fileList: FileList | null) {
    if (!fileList || fileList.length === 0) return;
    onFilesSelected(Array.from(fileList));
  }

  return (
    <div
      onDragOver={(event) => {
        event.preventDefault();
        setIsDragging(true);
      }}
      onDragLeave={() => setIsDragging(false)}
      onDrop={(event) => {
        event.preventDefault();
        setIsDragging(false);
        handleFiles(event.dataTransfer.files);
      }}
      className={`rounded-panel border-2 border-dashed p-11 text-center transition ${
        isDragging ? "border-accent" : "border-border dark:border-border-dark"
      }`}
    >
      <p className="mb-1 text-sm font-semibold">Dosyalarını buraya bırak</p>
      <p className="mb-5 text-xs text-text-soft dark:text-text-soft-dark">
        PDF · maksimum 100MB
      </p>
      <button
        type="button"
        onClick={() => inputRef.current?.click()}
        className="rounded-capsule bg-accent px-5 py-2.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
      >
        Dosya Seç
      </button>
      <input
        ref={inputRef}
        type="file"
        accept="application/pdf"
        multiple={multiple}
        className="hidden"
        onChange={(event) => handleFiles(event.target.files)}
      />
    </div>
  );
}
