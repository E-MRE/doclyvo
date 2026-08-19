import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { WatermarkWorkspace } from "@/features/watermark/components/WatermarkWorkspace";

export const metadata: Metadata = {
  title: "Filigran Ekle",
  description: "PDF sayfalarına metin filigranı yerleştir — hesap gerekmez.",
};

export default function WatermarkPage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">Filigran Ekle</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          Metin filigranını sayfalara yerleştir.
        </p>
        <WatermarkWorkspace />
      </main>
    </div>
  );
}
