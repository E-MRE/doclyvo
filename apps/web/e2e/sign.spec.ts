import path from "node:path";
import { expect, test } from "@playwright/test";

const SAMPLE_PDF = path.join(__dirname, "fixtures", "sample-multipage.pdf");

test("signs a PDF through the web UI using the type mode", async ({ page }) => {
  await page.goto("/tools/sign");

  await page.setInputFiles('input[type="file"]', SAMPLE_PDF);

  await page.getByRole("button", { name: "Yaz" }).click();
  await page.getByPlaceholder("Adını yaz").fill("Emre Gültekir");
  await page.getByRole("button", { name: "Belgeye Yerleştir" }).click();

  await page.getByRole("button", { name: "İmzala" }).click();

  await expect(page.getByText("İmzalı PDF hazır")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("button", { name: "İndir", exact: true })).toBeVisible();
});
