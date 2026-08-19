import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { SplitWorkspace } from "@/features/split/components/SplitWorkspace";

export const metadata: Metadata = {
  title: "PDF Sayfalara Ayır",
  description: "Bir PDF'in her sayfasını ayrı bir dosya olarak indir — hesap gerekmez.",
};

export default function SplitPage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">PDF&apos;i Sayfalara Ayır</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          Her sayfayı ayrı bir PDF olarak indir.
        </p>
        <SplitWorkspace />
      </main>
    </div>
  );
}
