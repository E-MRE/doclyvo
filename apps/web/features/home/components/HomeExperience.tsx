"use client";

import { useState } from "react";
import { HeroSection } from "@/features/home/components/HeroSection";
import { ToolGrid } from "@/features/home/components/ToolGrid";

export function HomeExperience() {
  const [file, setFile] = useState<File | null>(null);

  function handleFileSelected(selected: File) {
    setFile(selected);
    setTimeout(() => {
      document.getElementById("araclar")?.scrollIntoView({ behavior: "smooth", block: "start" });
    }, 350);
  }

  return (
    <>
      <HeroSection file={file} onFileSelected={handleFileSelected} onClearFile={() => setFile(null)} />
      <ToolGrid file={file} />
    </>
  );
}
