import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { ProtectWorkspace } from "@/features/protect/components/ProtectWorkspace";

export const metadata: Metadata = {
  title: "PDF'i Koru",
  description: "Şifre ve izinlerle PDF belgeni koru — hesap gerekmez.",
};

export default function ProtectPage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">PDF&apos;i Koru</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          Şifre ve izinlerle belgeni koru.
        </p>
        <ProtectWorkspace />
      </main>
    </div>
  );
}
