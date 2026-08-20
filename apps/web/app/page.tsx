import { Header } from "@/components/Header";
import { HomeExperience } from "@/features/home/components/HomeExperience";

export default function HomePage() {
  return (
    <div className="min-h-screen bg-bg dark:bg-black">
      <Header />
      <main>
        <HomeExperience />
      </main>
    </div>
  );
}
