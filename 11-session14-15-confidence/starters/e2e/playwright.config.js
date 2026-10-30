// One browser, the deployed URL, a junit report. Few journeys, the ones the client would notice.
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  retries: process.env.CI ? 1 : 0, // one retry, and the report says which test needed it - a flaky test is a finding
  reporter: [['list'], ['junit', { outputFile: 'e2e.xml' }]],
  use: { baseURL: process.env.BASE_URL || 'http://localhost:8000', trace: 'retain-on-failure' },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
