import type { Metadata } from "next";
import { Header } from "@/components/Header";
import { RedactWorkspace } from "@/features/redact/components/RedactWorkspace";

export const metadata: Metadata = {
  title: "Redakte Et",
  description: "Hassas alanları kalıcı olarak karart — hesap gerekmez.",
};

export default function RedactPage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main className="mx-auto max-w-5xl px-6 py-14 sm:px-8">
        <h1 className="mb-1 text-3xl font-extrabold">Redakte Et</h1>
        <p className="mb-9 text-base text-text-soft dark:text-text-soft-dark">
          Hassas alanları kalıcı olarak karart.
        </p>
        <RedactWorkspace />
      </main>
    </div>
  );
}
