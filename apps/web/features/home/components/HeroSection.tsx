import Link from "next/link";

export function HeroSection() {
  return (
    <section className="grid gap-10 px-6 py-16 sm:px-12 sm:py-20 md:grid-cols-2 md:items-center">
      <div>
        <span className="mb-5 inline-flex items-center rounded-full bg-accent/10 px-3 py-1.5 text-xs font-semibold text-accent">
          Hesap gerekmez, dosyaların cihazında kalır
        </span>
        <h1 className="mb-5 text-4xl font-extrabold leading-tight tracking-tight sm:text-5xl">
          PDF işleri iş gibi
          <br />
          hissettirmek zorunda değil.
        </h1>
        <p className="mb-8 max-w-md text-base leading-relaxed text-text-soft dark:text-text-soft-dark">
          Birleştir, böl, sıkıştır ve dönüştür — hepsi tek bir sade arayüzde. Doclyvo, PDF
          işlerini üç tıkla bitirmen için var.
        </p>
        <div className="flex items-center gap-3.5">
          <Link
            href="/tools/compress"
            className="rounded-panel bg-accent px-6 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
          >
            Ücretsiz Başla
          </Link>
          <a
            href="#araclar"
            className="rounded-panel border border-border px-5 py-3.5 text-sm font-semibold transition dark:border-border-dark"
          >
            Tüm araçları gör
          </a>
        </div>
      </div>
      <div className="rounded-card border border-border bg-surface p-7 shadow-xl dark:border-border-dark dark:bg-surface-dark">
        <div className="rounded-panel border-2 border-dashed border-border p-11 text-center dark:border-border-dark">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-panel bg-accent/10 text-accent">
            ↑
          </div>
          <p className="mb-1.5 text-sm font-semibold">Dosyalarını buraya bırak</p>
          <p className="mb-5 text-xs text-text-soft dark:text-text-soft-dark">
            PDF, PNG veya JPEG · maksimum 100MB
          </p>
          <Link
            href="/tools/compress"
            className="inline-block rounded-capsule bg-accent px-5 py-2.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
          >
            Dosya Seç
          </Link>
        </div>
      </div>
    </section>
  );
}
