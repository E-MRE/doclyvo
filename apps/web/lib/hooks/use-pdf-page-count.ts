"use client";

import { useEffect, useState } from "react";
import { PDFDocument } from "pdf-lib";

interface PdfPageCountState {
  pageCount: number | null;
  isLoading: boolean;
  error: string | null;
}

export function usePdfPageCount(file: File | null): PdfPageCountState {
  const [state, setState] = useState<PdfPageCountState>({
    pageCount: null,
    isLoading: false,
    error: null,
  });

  useEffect(() => {
    if (!file) {
      setState({ pageCount: null, isLoading: false, error: null });
      return;
    }

    let cancelled = false;
    setState({ pageCount: null, isLoading: true, error: null });

    file
      .arrayBuffer()
      .then((buffer) => PDFDocument.load(buffer))
      .then((document) => {
        if (!cancelled) {
          setState({ pageCount: document.getPageCount(), isLoading: false, error: null });
        }
      })
      .catch(() => {
        if (!cancelled) {
          setState({ pageCount: null, isLoading: false, error: "PDF okunamadı." });
        }
      });

    return () => {
      cancelled = true;
    };
  }, [file]);

  return state;
}
