"use client";

import Link from "next/link";
import { setPendingFile } from "@/lib/pending-file";
import { TOOLS, type ToolDefinition } from "@/lib/tools";

interface ToolGridProps {
  file: File | null;
}

export function ToolGrid({ file }: ToolGridProps) {
  return (
    <section id="araclar" className="px-6 pb-18 sm:px-12">
      <h2 className="mb-1 text-2xl font-extrabold">En çok kullanılan araçlar</h2>
      <p className="mb-6 text-sm text-text-soft dark:text-text-soft-dark">
        Bir araç seç, dosyanı bırak, işini bitir.
      </p>
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {TOOLS.map((tool) => (
          <ToolTile key={tool.id} tool={tool} file={file} />
        ))}
      </div>
    </section>
  );
}

function ToolTile({ tool, file }: { tool: ToolDefinition; file: File | null }) {
  function handleClick() {
    if (file) {
      setPendingFile(file);
    }
  }

  return (
    <Link
      href={tool.href}
      onClick={handleClick}
      className={`toolcard group flex h-full flex-col justify-between rounded-card border-2 p-5 transition hover:-translate-y-0.5 hover:border-accent active:scale-[0.98] ${
        tool.featured
          ? "col-span-2 border-accent bg-accent/10 p-6 sm:row-span-2"
          : "border-border dark:border-border-dark"
      }`}
    >
      <div className="flex items-center justify-between">
        <span
          className={`flex items-center justify-center rounded-panel ${
            tool.featured ? "h-11 w-11 bg-accent text-white" : "h-10 w-10 bg-accent/10 text-accent"
          }`}
        >
          {tool.icon}
        </span>
        {tool.featured && (
          <span className="rounded-full bg-surface px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide text-accent dark:bg-surface-dark">
            Öne Çıkan
          </span>
        )}
      </div>
      <div className={tool.featured ? "mt-4" : "mt-3"}>
        <p className={`mb-1 font-bold ${tool.featured ? "text-lg" : ""}`}>{tool.title}</p>
        <p className="text-xs text-text-soft dark:text-text-soft-dark">{tool.description}</p>
      </div>
    </Link>
  );
}
