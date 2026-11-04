// FR-008, end to end: a payment arrives by UPI, and the treasurer's screen stops showing that flat.
import { test, expect } from '@playwright/test';

test('FR-008 a flat that pays in full disappears from the treasurer\'s reminder screen', async ({ page, request }) => {
  await page.goto('/ui/reminders');
  await expect(page.getByRole('heading', { name: 'Reminders this month' })).toBeVisible();
  await expect(page.locator('li[data-flat="A-101"]')).toBeVisible();

  const paid = await request.post('/payments/upi', {
    data: { bank_reference: `E2E-${Date.now()}`, remark: 'A-101', payer: 'Meera', amount: '2500' },
  });
  expect(paid.status()).toBe(201);

  await page.reload();
  await expect(page.locator('li[data-flat="A-101"]')).toHaveCount(0);
});
