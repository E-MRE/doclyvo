import path from "node:path";
import { expect, test } from "@playwright/test";

const SAMPLE_PDF = path.join(__dirname, "fixtures", "sample-multipage.pdf");

test("reorders pages of a PDF through the web UI", async ({ page }) => {
  await page.goto("/tools/reorder");

  await page.setInputFiles('input[type="file"]', SAMPLE_PDF);

  await expect(page.getByText("Yeni sıra", { exact: true })).toBeVisible();

  await page.getByLabel("Sağa taşı").first().click();
  await page.getByRole("button", { name: "Sırala", exact: true }).click();

  await expect(page.getByText("Sıralama tamamlandı")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("button", { name: "İndir", exact: true })).toBeVisible();
});
