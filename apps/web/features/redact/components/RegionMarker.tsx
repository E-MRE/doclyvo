"use client";

import { useState } from "react";
import type { RedactRegion } from "@/features/redact/types";

interface DraftRegion {
  startX: number;
  startY: number;
  x: number;
  y: number;
  width: number;
  height: number;
}

interface RegionMarkerProps {
  pageNumber: number;
  regions: RedactRegion[];
  onAdd: (region: Omit<RedactRegion, "id">) => void;
  onRemove: (id: string) => void;
}

const MIN_REGION_SIZE = 0.02;

function clampToUnit(value: number): number {
  return Math.min(Math.max(value, 0), 1);
}

export function RegionMarker({ pageNumber, regions, onAdd, onRemove }: RegionMarkerProps) {
  const [draft, setDraft] = useState<DraftRegion | null>(null);
  const regionsOnThisPage = regions.filter((region) => region.pageNumber === pageNumber);

  function positionFromEvent(event: React.PointerEvent<HTMLDivElement>) {
    const rect = event.currentTarget.getBoundingClientRect();
    return {
      x: clampToUnit((event.clientX - rect.left) / rect.width),
      y: clampToUnit((event.clientY - rect.top) / rect.height),
    };
  }

  function handlePointerDown(event: React.PointerEvent<HTMLDivElement>) {
    event.currentTarget.setPointerCapture(event.pointerId);
    const { x, y } = positionFromEvent(event);
    setDraft({ startX: x, startY: y, x, y, width: 0, height: 0 });
  }

  function handlePointerMove(event: React.PointerEvent<HTMLDivElement>) {
    if (!draft) return;
    const { x, y } = positionFromEvent(event);
    setDraft({
      startX: draft.startX,
      startY: draft.startY,
      x: Math.min(draft.startX, x),
      y: Math.min(draft.startY, y),
      width: Math.abs(x - draft.startX),
      height: Math.abs(y - draft.startY),
    });
  }

  function handlePointerUp() {
    if (draft && draft.width > MIN_REGION_SIZE && draft.height > MIN_REGION_SIZE) {
      onAdd({ pageNumber, x: draft.x, y: draft.y, width: draft.width, height: draft.height });
    }
    setDraft(null);
  }

  return (
    <div
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerLeave={handlePointerUp}
      className="relative aspect-page w-full max-w-md touch-none overflow-hidden rounded-capsule border border-border bg-bg p-8 dark:border-border-dark dark:bg-black"
    >
      <div className="w-full space-y-3.5">
        <div className="h-2 w-3/5 rounded-full bg-border dark:bg-border-dark" />
        <div className="h-2 w-5/6 rounded-full bg-border dark:bg-border-dark" />
        <div className="h-2 w-4/5 rounded-full bg-border dark:bg-border-dark" />
        <div className="h-2 w-2/3 rounded-full bg-border dark:bg-border-dark" />
      </div>

      {regionsOnThisPage.map((region) => (
        <div
          key={region.id}
          className="absolute rounded-sm border border-accent bg-redact-ink/95"
          style={{
            left: `${region.x * 100}%`,
            top: `${region.y * 100}%`,
            width: `${region.width * 100}%`,
            height: `${region.height * 100}%`,
          }}
        >
          <button
            type="button"
            onPointerDown={(event) => event.stopPropagation()}
            onClick={() => onRemove(region.id)}
            aria-label="Alanı kaldır"
            className="absolute -right-2 -top-2 flex h-[18px] w-[18px] items-center justify-center rounded-full border border-border bg-surface text-text-soft dark:border-border-dark dark:bg-surface-dark"
          >
            <svg
              width="10"
              height="10"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M18 6 6 18M6 6l12 12" />
            </svg>
          </button>
        </div>
      ))}

      {draft && (
        <div
          className="pointer-events-none absolute border border-dashed border-accent bg-accent/20"
          style={{
            left: `${draft.x * 100}%`,
            top: `${draft.y * 100}%`,
            width: `${draft.width * 100}%`,
            height: `${draft.height * 100}%`,
          }}
        />
      )}
    </div>
  );
}
