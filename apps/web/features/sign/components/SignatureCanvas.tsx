"use client";

import { useRef, useState } from "react";
import { SIGNATURE_INK_COLOR } from "@/lib/design-tokens";

interface SignatureCanvasProps {
  onChange: (file: File | null) => void;
}

const CANVAS_WIDTH = 420;
const CANVAS_HEIGHT = 140;

export function SignatureCanvas({ onChange }: SignatureCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const isDrawingRef = useRef(false);
  const hasStrokesRef = useRef(false);
  const [hasStrokes, setHasStrokes] = useState(false);

  function pointerPosition(event: React.PointerEvent<HTMLCanvasElement>) {
    const rect = event.currentTarget.getBoundingClientRect();
    return {
      x: ((event.clientX - rect.left) / rect.width) * CANVAS_WIDTH,
      y: ((event.clientY - rect.top) / rect.height) * CANVAS_HEIGHT,
    };
  }

  function handlePointerDown(event: React.PointerEvent<HTMLCanvasElement>) {
    const ctx = canvasRef.current?.getContext("2d");
    if (!ctx) return;
    event.currentTarget.setPointerCapture(event.pointerId);
    const { x, y } = pointerPosition(event);
    ctx.beginPath();
    ctx.moveTo(x, y);
    isDrawingRef.current = true;
  }

  function handlePointerMove(event: React.PointerEvent<HTMLCanvasElement>) {
    if (!isDrawingRef.current) return;
    const ctx = canvasRef.current?.getContext("2d");
    if (!ctx) return;
    const { x, y } = pointerPosition(event);
    ctx.strokeStyle = SIGNATURE_INK_COLOR;
    ctx.lineWidth = 2.5;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.lineTo(x, y);
    ctx.stroke();
    hasStrokesRef.current = true;
    setHasStrokes(true);
  }

  function handlePointerUp() {
    if (!isDrawingRef.current) return;
    isDrawingRef.current = false;
    if (!hasStrokesRef.current) return;
    canvasRef.current?.toBlob((blob) => {
      if (blob) onChange(new File([blob], "signature.png", { type: "image/png" }));
    }, "image/png");
  }

  function handleClear() {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext("2d");
    if (!canvas || !ctx) return;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    hasStrokesRef.current = false;
    setHasStrokes(false);
    onChange(null);
  }

  return (
    <div>
      <canvas
        ref={canvasRef}
        width={CANVAS_WIDTH}
        height={CANVAS_HEIGHT}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        onPointerLeave={handlePointerUp}
        className="mb-3 h-36 w-full touch-none rounded-panel border border-border bg-bg dark:border-border-dark dark:bg-black"
      />
      <button
        type="button"
        onClick={handleClear}
        disabled={!hasStrokes}
        className="text-xs font-semibold text-accent disabled:opacity-40"
      >
        Temizle
      </button>
    </div>
  );
}
