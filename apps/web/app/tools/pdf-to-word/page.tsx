import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { ConvertWorkspace } from "@/features/pdf-to-word/components/ConvertWorkspace";

export const metadata: Metadata = {
  title: "PDF'i Word'e Çevir",
  description: "PDF'ini düzenlenebilir bir .docx dosyasına dönüştür — hesap gerekmez.",
};

export default function PdfToWordPage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">PDF&apos;i Word&apos;e Çevir</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          Düzenlenebilir bir .docx dosyasına dönüştür.
        </p>
        <ConvertWorkspace />
      </main>
    </div>
  );
}
