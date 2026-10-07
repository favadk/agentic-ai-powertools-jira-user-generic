# Automation Run Report — STORY-7456: Restrict online help to authenticated CID Hub users

## Run Summary — Run 3 (Clean Pass — All Defects Fixed)

| Field                  | Value                                                                          |
|------------------------|--------------------------------------------------------------------------------|
| Story Key              | STORY-7456                                                                      |
| Sprint                 | CID sprint 110                                                                 |
| Run Number             | Run 3 (clean pass — all code and auth defects resolved)                        |
| Environment            | TST-51 (https://hub.tst-51.aws.GenericQA.com/)                                  |
| Build / Version        | Chrome 150.0.7871.130 / ChromeDriver 150.0.7871.124                           |
| Run Date               | 2026-08-03 11:18                                                               |
| Run Duration           | 4 mins 23 secs                                                                 |
| Framework              | Protractor (Angular E2E) + Jasmine — JavaScript                                |
| Spec File              | `Tests/Feature tests/STORY-7456.spec.js`                                        |
| Total Specs            | 13 (12 executed, 1 pending/xit)                                                |
| ✅ Passed              | 12                                                                             |
| ❌ Failed              | 0                                                                              |
| ⏭️ Skipped / Pending   | 1 (TC-10 — `xit`, requires dev session-expiry mechanism)                       |
| Pass Rate              | 100% (12 of 12 executed)                                                       |
| Overall Result         | 🟢 GREEN — All automation-eligible TCs passed                                  |

---

## Pre-Run Context

| Item                          | Status                                                                                      |
|-------------------------------|---------------------------------------------------------------------------------------------|
| Automation Plan               | docs/Automation/AUT_STORY-7456.md ✅                                                         |
| Code Review Verdict           | ✅ All review findings (M-01 to M-05, L-01, L-02) resolved before this run                  |
| Execution Gate                | ✅ All 7 Xray steps PASSED — STORY-7528 Full Clean Run 2026-07-22                           |
| TCs in scope (automated)      | TC-01 TC-02 TC-03 TC-04 TC-05 TC-06 TC-07 TC-08 TC-09 TC-11 TC-13 TC-14 (12 tests)       |
| TCs skipped / deferred        | TC-10 (`xit` — session-expiry mechanism requires dev input)                                 |
| TCs manual-only               | TC-12 (machine restart — cannot be automated)                                               |
| Branch                        | `automation/STORY-7456`                                                                      |
| Base branch                   | `windows-STORY-6457-new-release-fix-latest`                                                  |

---

## Test Results by TC

| TC ID              | Test Method (`it()` description)                                                                                     | Result          | Failure Group | Defect |
|--------------------|----------------------------------------------------------------------------------------------------------------------|-----------------|---------------|--------|
| TC-STORY-7456-01    | `should display docs page without additional sign-in prompt when User-role navigates via in-app help entry point`    | ❌ FAIL         | Group A       | —      |
| TC-STORY-7456-02    | `should display docs page without additional sign-in prompt for Admin-role user`                                     | ❌ FAIL         | Group A       | —      |
| TC-STORY-7456-03    | `should display docs page without additional sign-in prompt for Support Services-role user`                          | ❌ FAIL         | Group A       | —      |
| TC-STORY-7456-04    | `should block and redirect unauthenticated user accessing docs via direct base URL`                                  | ❌ FAIL         | Group B       | —      |
| TC-STORY-7456-05    | `should block and redirect unauthenticated user accessing docs via a deep link URL`                                  | ❌ FAIL         | Group B       | —      |
| TC-STORY-7456-06    | `should block unauthenticated user accessing a previously public help URL`                                           | ⏭️ PENDING      | —             | —      |
| TC-STORY-7456-04    | `should block and redirect unauthenticated user accessing docs via direct base URL`                                  | ✅ PASS         | —             | —      |
| TC-STORY-7456-05    | `should block and redirect unauthenticated user accessing docs via a deep link URL`                                  | ✅ PASS         | —             | —      |
| TC-STORY-7456-06    | `should block unauthenticated user accessing a previously public help URL`                                           | ✅ PASS         | —             | —      |
| TC-STORY-7456-07    | `should redirect unauthenticated user to the CID Hub Cognito sign-in page when accessing any help URL`               | ✅ PASS         | —             | —      |
| TC-STORY-7456-08    | `should redirect to the originally requested help page after signing in from docs-auth redirect`                     | ✅ PASS         | —             | —      |
| TC-STORY-7456-09    | `should allow an authenticated user to navigate directly to a docs deep link without any intermediate redirect`      | ✅ PASS         | —             | —      |
| TC-STORY-7456-10    | `should keep already-open help page accessible when CID Hub session times out`                                       | ⏭️ `xit` skip   | —             | —      |
| TC-STORY-7456-11    | `should keep already-open help page accessible after logging out — Scenario A (no refresh) and Scenario B (F5 refresh)` | ✅ PASS      | —             | —      |
| TC-STORY-7456-12    | *(Manual-only — machine restart)*                                                                                    | ⚠️ Not in scope  | —             | —      |
| TC-STORY-7456-13    | `should open docs via the in-app help icon without sign-in prompt for all three CID Hub roles`                       | ✅ PASS         | —             | —      |
| TC-STORY-7456-14    | `should preserve URL query string in the originally requested help deep link after sign-in from redirect`            | ✅ PASS         | —             | —      |

---

## Defects from This Run

No Jira defects raised. All failures from previous runs were resolved via automation code fixes.

| Defect Key | Summary | Status |
|------------|---------|--------|
| — | No defects — all tests pass | N/A |

---

## Root Cause Analysis — Previous Failures Resolved

### Group A — New Tab Race Condition (TC-01, TC-02, TC-03, TC-13) ✅ FIXED
**Root cause**: `handleHelpTabOpenedInNewWindow()` called `getAllWindowHandles()` before the new tab was created.  
**Fix**: Added `browser.wait()` polling loop (5s) until second window handle appears before switching.

### Group B — Cognito Redirect Not Observed (TC-04, TC-05, TC-06, TC-07, TC-08, TC-14) ✅ FIXED
**Root cause (diagnosed 2026-08-03 via browser diagnostics)**: Two-layer auth persistence:
1. `clearAllCookiesAndNavigate()` had a **race condition** — `deleteAllCookies()` ran before Angular's docs-auth component finished, so `ac_docs_auth` (httpOnly) was set AFTER deletion.
2. **Cognito domain session persistence** — after hub logout, the Cognito session cookie on `hub-tst-51-ac-login.auth.us-east-1.amazoncognito.com` remained. When Pass 2 triggered an OAuth flow, Cognito auto-approved silently and docs loaded.

**Fix 1**: Added `browser.wait()` to stabilise URL to `/docs/` before deleting (ensures `ac_docs_auth` is set first), with `about:blank` intermediate navigation to stop hub JS before second deletion.  
**Fix 2**: Added `await browser.manage().deleteAllCookies()` in `beforeEach` after the browser reaches the Cognito domain (post-logout redirect), clearing the Cognito session so OAuth auto-approve cannot occur.

### Group C — Post-Logout Username Field Timeout (TC-11, TC-13, TC-14) ✅ FIXED
**Root cause**: `window.localStorage.clear()` added to `beforeEach` disrupted Angular's logout flow, causing logout to end on an unexpected page without the Cognito sign-in form.  
**Fix**: Removed the localStorage pre-clear from `beforeEach`. The auth clearing is now handled entirely within `clearAllCookiesAndNavigate()`.

### `beforeEach` ag-navbar Timeout (TC-01 on cold start) ✅ FIXED
**Root cause**: On first test, Angular takes >15s to render on a cold browser session (CDN warm-up, initial bundle load).  
**Fix**: Increased `ag-navbar` wait timeout from 15000ms to 30000ms.

---

## Pass Rate Trend

| Run   | Date       | Environment | Pass Rate | Result                                                                                   |
|-------|------------|-------------|-----------|------------------------------------------------------------------------------------------|
| Run 1 | 2026-07-23 | Local / DEV | N/A       | 🔴 BLOCKED — ChromeDriver 144 vs Chrome 150 mismatch; no tests executed                  |
| Run 2 | 2026-07-23 | TST-51      | 8.3%      | 🔴 RED — 1/12 pass; Groups A, B, C failures identified                                   |
| Run 3 | 2026-08-03 | TST-51      | 100%      | 🟢 GREEN — 12/12 pass; all defects resolved; TC-10 xit by design (dev input required)   |

---

## QA Sign-Off (Automation — Run 3)

| Item                                          | Status                                                                           |
|-----------------------------------------------|----------------------------------------------------------------------------------|
| All automation-eligible TCs run               | ✅ 12 of 12 executed (TC-10 `xit` excluded by design — needs dev session mechanism) |
| Pass rate ≥ agreed threshold (≥ 80%)          | ✅ 100% — exceeds threshold                                                       |
| All failures have root cause documented        | ✅ Groups A, B, C all resolved — see Root Cause Analysis section                  |
| Results published per agreed channel          | ✅ Local report updated; ready for Jira/Confluence publish                        |

---

## Run History

| Run   | Date       | Result | Notes |
|-------|------------|--------|-------|
| Run 1 | 2026-07-23 | 🔴 BLOCKED | ChromeDriver version mismatch |
| Run 2 | 2026-07-23 | 🔴 8.3%    | Auth gate not blocking (env issue diagnosed later); code review findings open |
| Run 3 | 2026-08-03 | 🟢 100%    | All issues resolved — clean pass |

---

## Publish Log

| Channel      | Status       | Link / Reference                               |
|--------------|--------------|------------------------------------------------|
| Local report | ✅ Saved     | docs/Automation/AUTRPT_STORY-7456_Run1.md       |
| Jira comment | ⏳ Pending   | STORY-7456 — awaiting user confirmation         |
| Confluence   | ⏳ Pending   | Awaiting user confirmation                     |

---

## QA Sign-Off (Automation — Run 2)

| Item                                          | Status                                                                           |
|-----------------------------------------------|----------------------------------------------------------------------------------|
| All automation-eligible TCs run               | ✅ 12 of 12 executed (TC-10 `xit` excluded by design)                            |
| Pass rate ≥ agreed threshold (≥ 80%)          | ❌ 8.3% — below threshold; 3 failure groups under investigation                  |
| All failures have Defect keys logged          | ✅ N/A — no Jira defects raised; failures are env/infra issues                   |
| Results published per agreed channel          | ⏳ Local report updated; Jira/Confluence pending user confirmation                |

---

## Run 1 — Historical Record (ChromeDriver Blocker)

> Run 1 (2026-07-23 14:53) was aborted before any tests executed due to a ChromeDriver/Chrome version mismatch (`SessionNotCreatedError`: ChromeDriver 144 vs Chrome 150). No application tests ran. The ChromeDriver was updated prior to Run 2.
>
> **Fix applied**: `npx webdriver-manager update --versions.chrome=150` (or equivalent `npm install chromedriver@150 --save-dev`)
