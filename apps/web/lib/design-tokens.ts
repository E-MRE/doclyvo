export const ACCENT_COLOR = "#DC4731";

export const RADIUS = {
  card: 16,
  panel: 12,
  capsule: 10,
} as const;

export const LIGHT_COLORS = {
  bg: "#F5F5F7",
  surface: "#FFFFFF",
  border: "#D2D2D7",
  text: "#1D1D1F",
  textSoft: "#6E6E73",
} as const;

export const DARK_COLORS = {
  bg: "#000000",
  surface: "#1C1C1E",
  border: "#38383A",
  text: "#F5F5F7",
  textSoft: "#98989D",
} as const;

// The signature canvas draws onto a transparent PNG that gets composited onto a white PDF
// page — it must render as dark ink regardless of the app's light/dark theme, so it can't
// use the accent/theme tokens above.
export const SIGNATURE_INK_COLOR = "#1D1D1F";
