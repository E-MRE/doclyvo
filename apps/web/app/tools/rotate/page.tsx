import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { RotateWorkspace } from "@/features/rotate/components/RotateWorkspace";

export const metadata: Metadata = {
  title: "PDF Döndür",
  description: "PDF sayfalarını seç ve istediğin yöne döndür — hesap gerekmez.",
};

export default function RotatePage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">PDF Döndür</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          Sayfaları seç, yönünü seç, döndür.
        </p>
        <RotateWorkspace />
      </main>
    </div>
  );
}
