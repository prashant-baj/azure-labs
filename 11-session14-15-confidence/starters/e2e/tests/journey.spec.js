// One journey the client would notice - named after the requirement it proves. Keep these few:
// every end-to-end test is slow and the most likely to be flaky. Prefer roles and text over CSS selectors.
import { test, expect } from '@playwright/test';

test('FR-0nn <the journey, in the client\'s words>', async ({ page }) => {
  await page.goto('/');                                          // the page the journey starts on
  await expect(page.getByRole('heading').first()).toBeVisible();  // replace: what the user must see
  // await page.getByRole('button', { name: '<action>' }).click();
  // await expect(page.getByText('<outcome>')).toBeVisible();
});
