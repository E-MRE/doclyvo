"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ThemeToggle } from "@/components/ThemeToggle";

export function Header() {
  const pathname = usePathname();
  const isHome = pathname === "/";

  return (
    <header className="sticky top-0 z-10 flex items-center justify-between border-b border-border bg-surface/70 px-6 py-4 backdrop-blur-xl dark:border-border-dark dark:bg-surface-dark/70 sm:px-12">
      <div className="flex items-center gap-3">
        {!isHome && (
          <Link
            href="/"
            aria-label="Ana sayfaya dön"
            className="flex h-9 w-9 items-center justify-center rounded-panel text-text-soft transition hover:opacity-75 active:scale-95 dark:text-text-soft-dark"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="m15 18-6-6 6-6" />
            </svg>
          </Link>
        )}
        <Link href="/" className="flex items-center gap-2.5">
          <span className="flex h-9 w-9 items-center justify-center rounded-capsule bg-accent text-white">
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
              <path d="M14 2v6h6" />
              <path d="M9 15l2 2 4-4" />
            </svg>
          </span>
          <span className="text-xl font-extrabold tracking-tight">doclyvo</span>
        </Link>
      </div>
      <div className="flex items-center gap-2">
        {isHome && (
          <Link
            href="/#araclar"
            className="hidden text-sm text-text-soft transition hover:opacity-70 dark:text-text-soft-dark sm:block"
          >
            Tüm Araçlar
          </Link>
        )}
        <ThemeToggle />
      </div>
    </header>
  );
}
