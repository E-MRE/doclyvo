import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    serverActions: {
      // Every tool uploads its PDF through a Server Action (`features/*/actions.ts`),
      // and Next caps a Server Action request body at 1MB by default. Anything
      // larger never reaches the action — it fails inside Next's own body
      // parser, which surfaces to the user as the opaque
      // "Application error: a server-side exception has occurred" page with a
      // digest, not as one of our handled `ok: false` results. That is why
      // Sıkıştır (and every other tool) died on any real-world PDF.
      //
      // 100MB matches `apps/api`'s `max_upload_size_mb`, so the backend's 413
      // stays the single place a too-large file is rejected — and it is
      // rejected with a message we control.
      bodySizeLimit: "100mb",
    },
  },
};

export default nextConfig;
