import path from "node:path";
import { expect, test } from "@playwright/test";

const SAMPLE_PDF = path.join(__dirname, "fixtures", "sample-multipage.pdf");

test("converts a PDF to Word through the web UI", async ({ page }) => {
  await page.goto("/tools/pdf-to-word");

  await page.setInputFiles('input[type="file"]', SAMPLE_PDF);

  await expect(page.getByText(".docx (Microsoft Word)")).toBeVisible();

  await page.getByRole("button", { name: "Word'e Dönüştür" }).click();

  await expect(page.getByText("Dönüştürme tamamlandı")).toBeVisible({ timeout: 20_000 });
  await expect(page.getByRole("button", { name: "İndir", exact: true })).toBeVisible();
});
