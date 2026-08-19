import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "Doclyvo — PDF araçları",
    template: "%s · Doclyvo",
  },
  description: "Birleştir, böl, sıkıştır ve dönüştür — hesap gerekmeden, dosyaların cihazında.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="tr">
      <body className="font-sans antialiased">{children}</body>
    </html>
  );
}
