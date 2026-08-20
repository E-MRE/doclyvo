import path from "node:path";
import { expect, test } from "@playwright/test";

const SAMPLE_PDF = path.join(__dirname, "fixtures", "sample-multipage.pdf");

test("redacts a marked region of a PDF through the web UI", async ({ page }) => {
  await page.goto("/tools/redact");

  await page.setInputFiles('input[type="file"]', SAMPLE_PDF);

  const preview = page.locator("div.aspect-page");
  const box = await preview.boundingBox();
  if (!box) throw new Error("page preview not found");

  await page.mouse.move(box.x + box.width * 0.2, box.y + box.height * 0.2);
  await page.mouse.down();
  await page.mouse.move(box.x + box.width * 0.7, box.y + box.height * 0.35);
  await page.mouse.up();

  await expect(page.getByText("Sayfa 1 — 1 alan")).toBeVisible();

  await page.getByRole("button", { name: "Redakte Et" }).click();

  await expect(page.getByText("Redaksiyon tamamlandı")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("button", { name: "İndir", exact: true })).toBeVisible();
});
