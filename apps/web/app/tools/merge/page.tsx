import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { MergeWorkspace } from "@/features/merge/components/MergeWorkspace";

export const metadata: Metadata = {
  title: "PDF Birleştir",
  description: "Birden çok PDF'i istediğin sırada tek dosyada birleştir — hesap gerekmez.",
};

export default function MergePage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">PDF Birleştir</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          Dosyaları istediğin sırada tek PDF&apos;te topla.
        </p>
        <MergeWorkspace />
      </main>
    </div>
  );
}
