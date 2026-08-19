import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  retries: 0,
  use: {
    baseURL: "http://localhost:3100",
  },
  webServer: [
    {
      command: "uv run --directory ../api uvicorn app.main:app --port 8100",
      url: "http://localhost:8100/health",
      reuseExistingServer: !process.env.CI,
      timeout: 30_000,
    },
    {
      command: "npm run dev -- --port 3100",
      url: "http://localhost:3100",
      reuseExistingServer: !process.env.CI,
      timeout: 30_000,
      env: { API_BASE_URL: "http://localhost:8100" },
    },
  ],
});
