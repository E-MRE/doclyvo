import path from "node:path";
import { expect, test } from "@playwright/test";

const SAMPLE_PDF = path.join(__dirname, "fixtures", "sample-multipage.pdf");

test("recognizes text from a PDF through the web UI", async ({ page }) => {
  await page.goto("/tools/ocr");

  await page.setInputFiles('input[type="file"]', SAMPLE_PDF);

  await page.getByText("Düz Metin (.txt)").click();
  await page.getByRole("button", { name: "Metni Tanı" }).click();

  await expect(page.getByText("Tanıma tamamlandı")).toBeVisible({ timeout: 20_000 });
  await expect(page.getByText("Doclyvo fixture")).toBeVisible();
  await expect(page.getByRole("button", { name: "İndir", exact: true })).toBeVisible();
});
