import Link from "next/link";
import { TOOLS } from "@/lib/tools";

interface ResultPanelProps {
  title: string;
  description: string;
  currentToolId: string;
  onDownload: () => void;
  onReset: () => void;
}

export function ResultPanel({ title, description, currentToolId, onDownload, onReset }: ResultPanelProps) {
  const otherTools = TOOLS.filter((tool) => tool.id !== currentToolId).slice(0, 3);

  return (
    <div>
      <div className="text-center">
        <div className="animate-pop mx-auto mb-3.5 flex h-14 w-14 items-center justify-center rounded-full bg-accent/10 text-accent">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
            <path d="M20 6 9 17l-5-5" />
          </svg>
        </div>
        <p className="mb-1 text-base font-bold">{title}</p>
        <p className="text-sm text-text-soft dark:text-text-soft-dark">{description}</p>
      </div>

      <div className="mt-6 flex flex-col gap-3">
        <button
          type="button"
          onClick={onDownload}
          className="w-full rounded-panel bg-accent px-4 py-3.5 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
        >
          İndir
        </button>
        <button
          type="button"
          onClick={onReset}
          className="w-full rounded-panel border border-border px-4 py-3 text-sm font-semibold transition dark:border-border-dark"
        >
          Yeni İşlem
        </button>
      </div>

      {otherTools.length > 0 && (
        <div className="mt-7">
          <p className="mb-3 text-center text-[11px] font-semibold uppercase tracking-wide text-text-soft dark:text-text-soft-dark">
            Başka bir işlem yap
          </p>
          <div className="grid grid-cols-3 gap-2">
            {otherTools.map((tool) => (
              <Link
                key={tool.id}
                href={tool.href}
                className="flex flex-col items-center gap-2 rounded-panel border border-border p-3 text-center transition hover:-translate-y-0.5 dark:border-border-dark"
              >
                <span className="flex h-8 w-8 items-center justify-center rounded-panel bg-accent/10 text-accent">
                  {tool.icon}
                </span>
                <span className="text-xs font-semibold">{tool.title}</span>
              </Link>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
