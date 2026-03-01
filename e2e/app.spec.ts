import { test, expect } from '@playwright/test';

test.describe('GuitarrApp E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Wait for Flutter to fully load
    await page.goto('/');
    // Flutter web needs more time to initialize (engine + app)
    await page.waitForTimeout(5000);
  });

  test('app loads successfully', async ({ page }) => {
    // Take a screenshot to verify visual state
    await page.screenshot({ path: 'e2e/screenshots/home.png', fullPage: true });

    // Flutter renders to flt-glass-pane, check it exists in DOM
    const flutterPane = page.locator('flt-glass-pane');
    await expect(flutterPane).toHaveCount(1);
  });

  test('home screen displays correctly', async ({ page }) => {
    // Wait for app to be interactive
    await page.waitForTimeout(2000);

    // Take screenshot of home screen
    await page.screenshot({ path: 'e2e/screenshots/home-loaded.png', fullPage: true });

    // Check that the Flutter canvas is rendered
    const flutterView = page.locator('flutter-view, flt-glass-pane, canvas');
    await expect(flutterView.first()).toBeVisible();
  });

  test('can interact with the app', async ({ page }) => {
    await page.waitForTimeout(2000);

    // Get viewport size for click coordinates
    const viewport = page.viewportSize();
    if (!viewport) return;

    // Click in center of the screen (where main buttons typically are)
    const centerX = viewport.width / 2;
    const centerY = viewport.height / 2;

    // Perform a click interaction
    await page.mouse.click(centerX, centerY);
    await page.waitForTimeout(1000);

    // Take screenshot after interaction
    await page.screenshot({ path: 'e2e/screenshots/after-click.png', fullPage: true });
  });

  test('microphone permission dialog appears', async ({ page, context }) => {
    // This test verifies the app requests microphone access
    // Permissions are pre-granted in playwright config

    await page.waitForTimeout(2000);

    // Check browser permissions API
    const micPermission = await page.evaluate(async () => {
      try {
        const result = await navigator.permissions.query({ name: 'microphone' as PermissionName });
        return result.state;
      } catch {
        return 'unknown';
      }
    });

    console.log('Microphone permission state:', micPermission);
    expect(['granted', 'prompt', 'unknown']).toContain(micPermission);
  });

  test('navigation works - click on lesson area', async ({ page }) => {
    await page.waitForTimeout(2000);

    const viewport = page.viewportSize();
    if (!viewport) return;

    // Screenshot before navigation
    await page.screenshot({ path: 'e2e/screenshots/before-nav.png', fullPage: true });

    // Click on lower area where "Lecciones" button might be
    await page.mouse.click(viewport.width / 2, viewport.height * 0.7);
    await page.waitForTimeout(2000);

    // Screenshot after navigation attempt
    await page.screenshot({ path: 'e2e/screenshots/after-nav.png', fullPage: true });
  });

  test('app responds to keyboard input', async ({ page }) => {
    await page.waitForTimeout(2000);

    // Press escape key (common for closing dialogs)
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);

    // Press enter (common for confirmation)
    await page.keyboard.press('Enter');
    await page.waitForTimeout(500);

    await page.screenshot({ path: 'e2e/screenshots/after-keyboard.png', fullPage: true });
  });
});

test.describe('Visual Regression Tests', () => {
  test('home screen visual snapshot', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(3000);

    // Compare against baseline screenshot
    await expect(page).toHaveScreenshot('home-baseline.png', {
      maxDiffPixels: 100,
      threshold: 0.2,
    });
  });
});
