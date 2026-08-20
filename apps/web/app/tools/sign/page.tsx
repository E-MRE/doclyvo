import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { SignWorkspace } from "@/features/sign/components/SignWorkspace";

export const metadata: Metadata = {
  title: "İmzala",
  description: "Çiz, yaz veya yükle — imzanı PDF'e yerleştir. Hesap gerekmez.",
};

export default function SignPage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">İmzala</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          İmzanı oluştur, belgeye yerleştir.
        </p>
        <SignWorkspace />
      </main>
    </div>
  );
}
