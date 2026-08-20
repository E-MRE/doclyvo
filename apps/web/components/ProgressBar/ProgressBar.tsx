interface ProgressBarProps {
  label: string;
  percent: number;
}

export function ProgressBar({ label, percent }: ProgressBarProps) {
  const rounded = Math.round(percent);

  return (
    <div className="py-6 text-center">
      <p className="mb-1.5 text-sm font-semibold">
        {label} {rounded}%
      </p>
      <p className="mb-5 text-xs text-text-soft dark:text-text-soft-dark">
        Bu birkaç saniye sürebilir.
      </p>
      <div className="h-2 overflow-hidden rounded-full bg-bg dark:bg-black">
        <div
          className="h-full rounded-full bg-accent transition-[width] duration-200 ease-out"
          style={{ width: `${rounded}%` }}
        />
      </div>
    </div>
  );
}
