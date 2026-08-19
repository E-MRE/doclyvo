import path from "node:path";
import { expect, test } from "@playwright/test";

const SAMPLE_PDF = path.join(__dirname, "fixtures", "sample.pdf");

test("compresses a PDF end to end through the web UI", async ({ page }) => {
  await page.goto("/tools/compress");

  await page.setInputFiles('input[type="file"]', SAMPLE_PDF);

  await expect(page.getByText("Önerilen", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Sıkıştır", exact: true }).click();

  await expect(page.getByText("Sıkıştırma tamamlandı")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("button", { name: "İndir" })).toBeVisible();
});
