"use client";

import { useState } from "react";
import { takePendingFile } from "@/lib/pending-file";

export function usePendingFile() {
  return useState<File | null>(() => takePendingFile());
}
