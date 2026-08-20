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

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="tr" className={caveat.variable}>
      <body className="font-sans antialiased">{children}</body>
    </html>
  );
}
