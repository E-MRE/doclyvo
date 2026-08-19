import Link from "next/link";

interface ToolCard {
  id: string;
  title: string;
  description: string;
  href: string | null;
  featured?: boolean;
}

const TOOLS: ToolCard[] = [
  {
    id: "compress",
    title: "Sıkıştır",
    description: "Kaliteyi koruyarak dosya boyutunu küçült.",
    href: "/tools/compress",
    featured: true,
  },
  { id: "merge", title: "Birleştir", description: "PDF'leri tek dosyada topla.", href: "/tools/merge" },
  { id: "split", title: "Böl", description: "Sayfaları ayrı dosyalara ayır.", href: null },
  { id: "convert", title: "PDF to Word", description: "Düzenlenebilir Word'e çevir.", href: null },
  { id: "sign", title: "İmzala", description: "Elektronik imza ekle.", href: null },
  { id: "protect", title: "Koru", description: "Şifre ile kilitle.", href: null },
];

export function ToolGrid() {
  return (
    <section id="araclar" className="px-6 pb-18 sm:px-12">
      <h2 className="mb-1 text-2xl font-extrabold">En çok kullanılan araçlar</h2>
      <p className="mb-6 text-sm text-text-soft dark:text-text-soft-dark">
        Bir araç seç, dosyanı bırak, işini bitir.
      </p>
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
        {TOOLS.map((tool) => (
          <ToolTile key={tool.id} tool={tool} />
        ))}
      </div>
    </section>
  );
}

function ToolTile({ tool }: { tool: ToolCard }) {
  const content = (
    <div
      className={`flex h-full flex-col justify-between rounded-card border-2 p-5 transition ${
        tool.featured ? "sm:col-span-2 sm:row-span-2" : ""
      } ${
        tool.href
          ? "border-transparent bg-bg hover:-translate-y-0.5 dark:bg-black"
          : "cursor-default border-transparent bg-bg opacity-60 dark:bg-black"
      }`}
    >
      <div className="flex items-center justify-between">
        <div className="flex h-10 w-10 items-center justify-center rounded-panel bg-accent/10 text-accent">
          ●
        </div>
        {!tool.href && (
          <span className="rounded-full bg-surface px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide text-text-soft dark:bg-surface-dark dark:text-text-soft-dark">
            Yakında
          </span>
        )}
      </div>
      <div>
        <p className="mb-1 font-bold">{tool.title}</p>
        <p className="text-xs text-text-soft dark:text-text-soft-dark">{tool.description}</p>
      </div>
    </div>
  );

  if (!tool.href) return content;

  return (
    <Link href={tool.href} className="block h-full">
      {content}
    </Link>
  );
}
