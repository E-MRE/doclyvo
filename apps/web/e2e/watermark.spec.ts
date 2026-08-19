import path from "node:path";
import { expect, test } from "@playwright/test";

const SAMPLE_PDF = path.join(__dirname, "fixtures", "sample-multipage.pdf");

test("adds a watermark to a PDF through the web UI", async ({ page }) => {
  await page.goto("/tools/watermark");

  await page.setInputFiles('input[type="file"]', SAMPLE_PDF);

  await expect(page.getByText("Konum", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Filigran Ekle" }).click();

  await expect(page.getByText("Filigran eklendi")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("button", { name: "İndir", exact: true })).toBeVisible();
});
