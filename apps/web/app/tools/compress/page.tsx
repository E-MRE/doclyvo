import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { CompressWorkspace } from "@/features/compress/components/CompressWorkspace";

export const metadata: Metadata = {
  title: "PDF Sıkıştır",
  description: "PDF dosyalarının boyutunu kaliteyi koruyarak küçült — hesap gerekmez.",
};

export default function CompressPage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">PDF Sıkıştır</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          Dosya boyutunu kaliteyi koruyarak küçült.
        </p>
        <CompressWorkspace />
      </main>
    </div>
  );
}
