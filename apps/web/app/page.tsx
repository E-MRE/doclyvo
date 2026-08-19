import { Header } from "@/components/Header";
import { HeroSection } from "@/features/home/components/HeroSection";
import { ToolGrid } from "@/features/home/components/ToolGrid";

export default function HomePage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main>
        <HeroSection />
        <ToolGrid />
      </main>
    </div>
  );
}
