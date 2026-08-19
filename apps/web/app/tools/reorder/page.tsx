import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { ReorderWorkspace } from "@/features/reorder/components/ReorderWorkspace";

export const metadata: Metadata = {
  title: "Sayfaları Yeniden Sırala",
  description: "PDF sayfalarını istediğin sıraya getir — hesap gerekmez.",
};

export default function ReorderPage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">Sayfaları Yeniden Sırala</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          Sayfaları oklarla istediğin sıraya getir.
        </p>
        <ReorderWorkspace />
      </main>
    </div>
  );
}
