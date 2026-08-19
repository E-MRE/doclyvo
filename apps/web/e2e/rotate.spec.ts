import path from "node:path";
import { expect, test } from "@playwright/test";

const SAMPLE_PDF = path.join(__dirname, "fixtures", "sample-multipage.pdf");

test("rotates all pages of a PDF through the web UI", async ({ page }) => {
  await page.goto("/tools/rotate");

  await page.setInputFiles('input[type="file"]', SAMPLE_PDF);

  await expect(page.getByText("Döndürme yönü", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Döndür", exact: true }).click();

  await expect(page.getByText("Döndürme tamamlandı")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("button", { name: "İndir", exact: true })).toBeVisible();
});
