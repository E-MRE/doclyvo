import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { OcrWorkspace } from "@/features/ocr/components/OcrWorkspace";

export const metadata: Metadata = {
  title: "Metni Tanı (OCR)",
  description: "Taranmış PDF'leri aranabilir hale getir veya metnini çıkar — hesap gerekmez.",
};

export default function OcrPage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">Metni Tanı (OCR)</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          Taranmış belgeyi aranabilir hale getir.
        </p>
        <OcrWorkspace />
      </main>
    </div>
  );
}
