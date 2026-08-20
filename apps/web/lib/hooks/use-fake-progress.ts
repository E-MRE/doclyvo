"use client";

import { useEffect, useState } from "react";

const MAX_ACTIVE_PROGRESS = 92;

export function useFakeProgress(active: boolean): number {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    if (!active) {
      return;
    }
    setProgress(0);
    const interval = setInterval(() => {
      setProgress((current) => Math.min(MAX_ACTIVE_PROGRESS, current + 6 + Math.random() * 8));
    }, 220);
    return () => clearInterval(interval);
  }, [active]);

  return active ? progress : 100;
}
