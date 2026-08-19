import path from "node:path";
import { expect, test } from "@playwright/test";

const SAMPLE_PDF = path.join(__dirname, "fixtures", "sample-multipage.pdf");

test("protects a PDF with a password through the web UI", async ({ page }) => {
  await page.goto("/tools/protect");

  await page.setInputFiles('input[type="file"]', SAMPLE_PDF);

  await expect(page.getByText("İzinler", { exact: true })).toBeVisible();

  await page.getByRole("button", { name: "Koru", exact: true }).click();

  await expect(page.getByText("Belge korundu")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("button", { name: "İndir", exact: true })).toBeVisible();
});
