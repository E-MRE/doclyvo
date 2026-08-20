import type { Metadata } from "next";
import { Caveat } from "next/font/google";
import "./globals.css";

const caveat = Caveat({ subsets: ["latin"], weight: "600", variable: "--font-caveat" });

export const metadata: Metadata = {
  title: {
    default: "Doclyvo — PDF araçları",
    template: "%s · Doclyvo",
  },
  description: "Birleştir, böl, sıkıştır ve dönüştür — hesap gerekmeden, dosyaların cihazında.",
};

const THEME_INIT_SCRIPT = `
(function () {
  try {
    var stored = localStorage.getItem("theme");
    var dark = stored === "dark" || (stored !== "light" && window.matchMedia("(prefers-color-scheme: dark)").matches);
    document.documentElement.classList.toggle("dark", dark);
  } catch (e) {}
})();
`;

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="tr" className={caveat.variable}>
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_INIT_SCRIPT }} />
      </head>
      <body className="bg-bg font-sans text-text antialiased dark:bg-black dark:text-text-dark">
        {children}
      </body>
    </html>
  );
}
