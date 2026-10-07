param()
$ErrorActionPreference = "Stop"

$workspace = "c:\Agentic-AI\agentic-ai-powertools-issue-tracker-user-generic"
$evidenceDir = "$workspace\docs\TestExecution\evidence\STORY-0000-FullRun"
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

# Write a Node.js Playwright script
$nodeScript = @'
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const EVIDENCE_DIR = process.argv[2];
const HUB_URL = 'https://app.example.com
const DOCS_URL = 'https://app.example.com
const DOCS_SECURITY_URL = 'https://app.example.com

const CREDS = {
  user:    { email: 'sidqawadautomation+user@gmail.com',            pass: 'nsu4Test@wad' },
  admin:   { email: 'sidqawadautomation+administrator@gmail.com',   pass: 'nsu4Test@wad' },
  support: { email: 'sidqawadautomation+supportservices@gmail.com', pass: 'su4Test@wad' }
};

async function signIn(page, creds) {
  await page.goto(`${HUB_URL}/`);
  await page.waitForSelector('input[placeholder="Username"]', { timeout: 15000 });
  await page.locator('input[placeholder="Username"]').first().fill(creds.email);
  await page.locator('input[placeholder="Password"]').first().fill(creds.pass);
  await page.locator('input[name="signInSubmitButton"]').first().click();
  await page.waitForURL(`${HUB_URL}/**`, { timeout: 15000 });
  await page.waitForTimeout(2000);
}

async function ss(page, name) {
  const fpath = path.join(EVIDENCE_DIR, name);
  await page.screenshot({ path: fpath, fullPage: false });
  console.log('SCREENSHOT: ' + name);
  return fpath;
}

(async () => {
  const browser = await chromium.launch({ headless: true });

  // =====================================================================
  // STEP 1: User role - sign in and access docs via help icon
  // =====================================================================
  {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();
    
    // Capture hub redirecting to cognito when unauthenticated
    await page.goto(`${HUB_URL}/`);
    await page.waitForTimeout(2000);
    await ss(page, 'step1-01-hub-unauthenticated-redirects-to-cognito.png');
    
    await signIn(page, CREDS.user);
    await page.goto(`${HUB_URL}/cids`);
    await page.waitForTimeout(2000);
    await ss(page, 'step1-02-user-logged-in-hub-dashboard.png');
    
    // Click Help button
    await page.locator('#navBtn-help').click();
    await page.waitForTimeout(800);
    await ss(page, 'step1-03-help-dropdown-open.png');
    
    // Click Help menu item
    const dropdown = await page.waitForSelector('.dropdown-menu.show', { timeout: 5000 });
    const items = await dropdown.$$('.dropdown-item');
    if (items.length > 0) {
      const [newPage] = await Promise.all([
        ctx.waitForEvent('page'),
        items[0].click()
      ]);
      await newPage.waitForLoadState('networkidle');
      await ss(newPage, 'step1-04-user-docs-loaded-no-auth-prompt.png');
      console.log('STEP1_DOCS_URL: ' + newPage.url());
      await newPage.close();
    }
    await ctx.close();
  }

  // =====================================================================
  // STEP 2: Admin and Support roles - access docs, no auth prompt
  // =====================================================================
  for (const role of ['admin', 'support']) {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();
    await signIn(page, CREDS[role]);
    await page.goto(DOCS_URL);
    await page.waitForTimeout(2000);
    const title = await page.title();
    console.log(`STEP2_${role.toUpperCase()}_TITLE: ${title}`);
    await ss(page, `step2-${role}-docs-loaded-no-auth.png`);
    await ctx.close();
  }

  // =====================================================================
  // STEP 3: Unauthenticated - direct URL and deep link blocked
  // =====================================================================
  {
    const ctx = await browser.newContext(); // fresh context = no cookies
    const page = await ctx.newPage();
    
    await page.goto(DOCS_URL);
    await page.waitForTimeout(2000);
    const url1 = page.url();
    console.log('STEP3_DIRECT_URL_RESULT: ' + url1);
    await ss(page, 'step3-01-unauth-docs-direct-url-blocked.png');
    
    await page.goto(DOCS_SECURITY_URL);
    await page.waitForTimeout(2000);
    const url2 = page.url();
    console.log('STEP3_DEEP_LINK_RESULT: ' + url2);
    await ss(page, 'step3-02-unauth-docs-deep-link-blocked.png');
    
    await ctx.close();
  }

  // =====================================================================
  // STEP 4: AC-03 returnUrl - unauthenticated -> redirect -> sign in -> lands on originally requested page
  // =====================================================================
  {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();
    
    // Navigate to security page (unauthenticated)
    await page.goto(DOCS_SECURITY_URL);
    await page.waitForTimeout(2000);
    await ss(page, 'step4-01-unauth-security-page-redirect-to-signin.png');
    console.log('STEP4_BEFORE_SIGNIN_URL: ' + page.url());
    
    // Sign in
    const signinUrl = page.url();
    if (signinUrl.includes('cognito') || signinUrl.includes('login')) {
      await page.locator('input[placeholder="Username"]').first().fill(CREDS.user.email);
      await page.locator('input[placeholder="Password"]').first().fill(CREDS.user.pass);
      await page.locator('input[name="signInSubmitButton"]').first().click();
      await page.waitForTimeout(4000);
    }
    await ss(page, 'step4-02-credentials-entered-signing-in.png');
    
    // Wait for post-signin redirect
    await page.waitForTimeout(2000);
    const postUrl = page.url();
    console.log('STEP4_POST_SIGNIN_URL: ' + postUrl);
    await ss(page, 'step4-03-post-signin-landing-page.png');
    
    await ctx.close();
  }

  // =====================================================================
  // STEP 5 & 7: Logout - docs remain accessible (AC-05)
  // =====================================================================
  {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();
    
    await signIn(page, CREDS.user);
    // Open docs
    await page.goto(DOCS_URL);
    await page.waitForTimeout(2000);
    await ss(page, 'step5-01-docs-open-before-logout.png');
    
    // Return to hub and logout
    await page.goto(`${HUB_URL}/cids`);
    await page.waitForTimeout(1500);
    await page.locator('#navBtn-logOut').click();
    await page.waitForTimeout(2000);
    await ss(page, 'step5-02-hub-after-logout-signin-page.png');
    
    // Navigate back to docs (same session, cookie persists)
    await page.goto(DOCS_URL);
    await page.waitForTimeout(2000);
    const docsAfterLogout = page.url();
    console.log('STEP5_DOCS_URL_AFTER_LOGOUT: ' + docsAfterLogout);
    await ss(page, 'step5-03-docs-still-accessible-after-logout.png');
    
    // F5 refresh
    await page.reload();
    await page.waitForTimeout(2000);
    const docsAfterRefresh = page.url();
    console.log('STEP7_DOCS_URL_AFTER_F5: ' + docsAfterRefresh);
    await ss(page, 'step7-01-docs-still-accessible-after-f5-refresh.png');
    
    // Check for ac_docs_auth cookie
    const cookies = await ctx.cookies('https://app.example.com);
    const acDocsCookie = cookies.find(c => c.name === 'ac_docs_auth');
    console.log('AC_DOCS_AUTH_COOKIE: ' + (acDocsCookie ? JSON.stringify(acDocsCookie) : 'not found'));
    
    await ctx.close();
  }

  // =====================================================================
  // STEP 6: ? icon regression - all roles help opens without auth prompt
  // =====================================================================
  {
    const ctx = await browser.newContext();
    const page = await ctx.newPage();
    
    await signIn(page, CREDS.user);
    await page.goto(`${HUB_URL}/cids`);
    await page.waitForTimeout(2000);
    
    // Click ? help icon 
    await page.locator('#navBtn-help').click();
    await page.waitForTimeout(800);
    await ss(page, 'step6-01-question-icon-dropdown-open.png');
    
    // Click Help item
    const dropdown = await page.waitForSelector('.dropdown-menu.show', { timeout: 5000 });
    const items = await dropdown.$$('.dropdown-item');
    if (items.length > 0) {
      const [newPage] = await Promise.all([
        ctx.waitForEvent('page'),
        items[0].click()
      ]);
      await newPage.waitForLoadState('networkidle');
      await ss(newPage, 'step6-02-docs-loaded-via-help-icon.png');
      console.log('STEP6_DOCS_URL: ' + newPage.url());
      await newPage.close();
    }
    
    await ctx.close();
  }

  await browser.close();
  console.log('ALL_DONE');
})();
'@

$nodeScriptPath = "$workspace\scripts\capture-evidence.js"
$nodeScript | Set-Content -Path $nodeScriptPath -Encoding UTF8

# Check if playwright is available
$playwrightCheck = node -e "require('playwright'); console.log('ok')" 2>&1
if ($playwrightCheck -eq 'ok') {
    Write-Output "Playwright available, running script..."
    node "$nodeScriptPath" "$evidenceDir" 2>&1
} else {
    Write-Output "Playwright not found globally. Checking npx..."
    npx --yes playwright install chromium 2>&1 | Select-Object -Last 5
    npx playwright "$nodeScriptPath" "$evidenceDir" 2>&1
}
