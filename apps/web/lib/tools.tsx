import type { ReactNode } from "react";

export interface ToolDefinition {
  id: string;
  title: string;
  description: string;
  href: string;
  featured?: boolean;
  icon: ReactNode;
}

const iconProps = {
  width: 19,
  height: 19,
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 2,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
};

export const TOOLS: ToolDefinition[] = [
  {
    id: "compress",
    title: "Sıkıştır",
    description: "Kaliteyi koruyarak dosya boyutunu küçült.",
    href: "/tools/compress",
    featured: true,
    icon: (
      <svg {...iconProps}>
        <path d="M8 3v4a1 1 0 0 1-1 1H3M16 3v4a1 1 0 0 0 1 1h4M8 21v-4a1 1 0 0 0-1-1H3M16 21v-4a1 1 0 0 1 1-1h4" />
      </svg>
    ),
  },
  {
    id: "merge",
    title: "Birleştir",
    description: "PDF'leri tek dosyada topla.",
    href: "/tools/merge",
    icon: (
      <svg {...iconProps}>
        <path d="M17 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2Z" />
        <path d="M9 9h6M9 13h6M9 17h4" />
      </svg>
    ),
  },
  {
    id: "split",
    title: "Böl",
    description: "Sayfaları ayrı dosyalara ayır.",
    href: "/tools/split",
    icon: (
      <svg {...iconProps}>
        <path d="M8 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h3M16 3h3a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-3M12 3v18" />
      </svg>
    ),
  },
  {
    id: "rotate",
    title: "Döndür",
    description: "Sayfaları istediğin yöne çevir.",
    href: "/tools/rotate",
    icon: (
      <svg {...iconProps}>
        <path d="M21 12a9 9 0 1 1-3-6.7" />
        <path d="M21 3v6h-6" />
      </svg>
    ),
  },
  {
    id: "reorder",
    title: "Yeniden Sırala",
    description: "Sayfaları istediğin sıraya getir.",
    href: "/tools/reorder",
    icon: (
      <svg {...iconProps}>
        <rect x="4" y="4" width="7" height="7" rx="1.5" />
        <rect x="13" y="4" width="7" height="7" rx="1.5" />
        <rect x="4" y="13" width="7" height="7" rx="1.5" />
        <rect x="13" y="13" width="7" height="7" rx="1.5" />
      </svg>
    ),
  },
  {
    id: "convert",
    title: "PDF to Word",
    description: "Düzenlenebilir Word'e çevir.",
    href: "/tools/pdf-to-word",
    icon: (
      <svg {...iconProps}>
        <path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2M7 9l5-5 5 5M12 4v13" />
      </svg>
    ),
  },
  {
    id: "watermark",
    title: "Filigran Ekle",
    description: "Metin filigranı yerleştir.",
    href: "/tools/watermark",
    icon: (
      <svg {...iconProps}>
        <path d="M12 19v-7m0 0V5m0 7 5-3m-5 3-5-3" />
        <circle cx="12" cy="19" r="2.2" />
      </svg>
    ),
  },
  {
    id: "ocr",
    title: "OCR",
    description: "Taranmış metni tanı.",
    href: "/tools/ocr",
    icon: (
      <svg {...iconProps}>
        <path d="M4 7V5a1 1 0 0 1 1-1h2M4 17v2a1 1 0 0 0 1 1h2M20 7V5a1 1 0 0 0-1-1h-2M20 17v2a1 1 0 0 1-1 1h-2M8 12h8" />
      </svg>
    ),
  },
  {
    id: "protect",
    title: "Koru",
    description: "Şifre ile kilitle.",
    href: "/tools/protect",
    icon: (
      <svg {...iconProps}>
        <rect x="5" y="11" width="14" height="9" rx="2" />
        <path d="M8 11V7a4 4 0 0 1 8 0v4" />
      </svg>
    ),
  },
  {
    id: "sign",
    title: "İmzala",
    description: "Elektronik imza ekle.",
    href: "/tools/sign",
    icon: (
      <svg {...iconProps}>
        <path d="M3 17s2-1 4-1 3 1 5 1 3-1 5-1 4 1 4 1M4 14 14 4l3 3-10 10H4z" />
      </svg>
    ),
  },
  {
    id: "redact",
    title: "Redakte Et",
    description: "Hassas alanları kalıcı olarak karart.",
    href: "/tools/redact",
    icon: (
      <svg {...iconProps}>
        <rect x="3" y="8" width="7" height="4" rx="1" />
        <rect x="14" y="14" width="7" height="4" rx="1" />
        <path d="M3 4h18M3 20h18" />
      </svg>
    ),
  },
];
