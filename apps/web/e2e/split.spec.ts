import path from "node:path";
import { expect, test } from "@playwright/test";

const SAMPLE_PDF = path.join(__dirname, "fixtures", "sample-multipage.pdf");

test("splits a PDF into one file per page through the web UI", async ({ page }) => {
  await page.goto("/tools/split");

  await page.setInputFiles('input[type="file"]', SAMPLE_PDF);

  await expect(page.getByText("Sonuç", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Sayfalara Ayır" }).click();

  await expect(page.getByText("Ayırma tamamlandı")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("button", { name: "İndir (.zip)" })).toBeVisible();
});
