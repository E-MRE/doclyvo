"use client";

interface ErrorStateProps {
  message: string;
  retry?: () => void;
}

export function ErrorState({ message, retry }: ErrorStateProps) {
  return (
    <div className="rounded-panel border border-border bg-bg p-6 text-center dark:border-border-dark dark:bg-black">
      <p className="text-sm text-text-soft dark:text-text-soft-dark">{message}</p>
      {retry ? (
        <button
          type="button"
          onClick={retry}
          className="mt-4 rounded-capsule bg-accent px-4 py-2 text-sm font-semibold text-white transition hover:opacity-90 active:scale-95"
        >
          Tekrar dene
        </button>
      ) : null}
    </div>
  );
}
