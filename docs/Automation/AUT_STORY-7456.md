# Automation Code Plan — STORY-7456: Restrict online help to authenticated CID Hub users

## Summary

| Field                    | Value                                                                              |
|--------------------------|------------------------------------------------------------------------------------|
| Story Key                | STORY-7456                                                                          |
| Story Summary            | Restrict online help to authenticated CID Hub users                                |
| Sprint                   | CID sprint 109 (execution: CID sprint 110)                                         |
| Automation Engineer      | automation_code_preparation agent                                                  |
| Framework                | Protractor (Angular E2E) + Jasmine — JavaScript                                    |
| Date Prepared            | 2026-07-23                                                                         |
| Execution Gate           | ✅ All 7 Xray steps PASSED — STORY-7528 Full Clean Run 2026-07-22                  |
| TCs Automated            | 11 of 14 (TC-06 pending dev input; TC-10 partial; TC-12 manual)                   |
| TC Document              | docs/TestCases/TC_STORY-7456.md                                                     |
| Execution Report         | docs/TestExecution/TE_STORY-7456_Cycle1.md                                          |
| Evidence Review          | docs/EvidenceReview/ER_STORY-7456_Cycle1.md — Verdict: ✅ APPROVED                 |

---

## Story Team

| Role              | Name                              | Email                                        |
|-------------------|-----------------------------------|----------------------------------------------|
| PO (Reporter)     | REHMAN,SUNIL (GenericQA USA)        | sunil_rehman@exampleqa.local                     |
| Dev               | NGUYEN,AARON (GenericQA USA)        | aaron.nguyen@exampleqa.local (STORY-7484)         |
| Tester            | KHAN,FAVAD (GenericQA USA)          | favad.khan@exampleqa.local (STORY-7487)           |

---

## Automation Coverage

| TC ID              | AC Ref        | Type          | Automated   | Script Method / `it()` description                                                                         | Notes                                          |
|--------------------|---------------|---------------|-------------|-------------------------------------------------------------------------------------------------------------|------------------------------------------------|
| TC-STORY-7456-01    | AC-01, AC-04  | Happy Path    | ✅ Yes      | `should display docs page without additional sign-in prompt when User-role navigates via in-app help entry point` | Covers multi-page navigation within docs      |
| TC-STORY-7456-02    | AC-01a        | Happy Path    | ✅ Yes      | `should display docs page without additional sign-in prompt for Admin-role user`                            |                                                |
| TC-STORY-7456-03    | AC-01a        | Happy Path    | ✅ Yes      | `should display docs page without additional sign-in prompt for Support Services-role user`                  | Uses `GenericQAUserIsLoggedIn` (not customerUser) |
| TC-STORY-7456-04    | AC-02         | Negative      | ✅ Yes      | `should block and redirect unauthenticated user accessing docs via direct base URL`                          | Clears all cookies before navigation           |
| TC-STORY-7456-05    | AC-02         | Negative      | ✅ Yes      | `should block and redirect unauthenticated user accessing docs via a deep link URL`                          |                                                |
| TC-STORY-7456-06    | AC-02a        | Negative      | ⚠️ Pending  | `should block unauthenticated user accessing a previously public help URL`                                   | **Dev input required**: `legacyPublicHelpUrl` must be set in `constantData.json`. Currently calls Jasmine `pending()` if unset. |
| TC-STORY-7456-07    | AC-03         | Happy Path    | ✅ Yes      | `should redirect unauthenticated user to the CID Hub Cognito sign-in page when accessing any help URL`       | Verifies sign-in form is present on redirect   |
| TC-STORY-7456-08    | AC-03         | Happy Path    | ✅ Yes      | `should redirect to the originally requested help page after signing in from docs-auth redirect`             | Uses `signInFromCognitoRedirectAndLandOnDocs()` — bypasses hub navbar wait |
| TC-STORY-7456-09    | AC-01, AC-03  | Happy Path    | ✅ Yes      | `should allow an authenticated user to navigate directly to a docs deep link without any intermediate redirect` |                                            |
| TC-STORY-7456-10    | AC-05         | Boundary      | ⚠️ Partial  | `xit` — `should keep already-open help page accessible when CID Hub session times out`                       | **Dev coordination required**: artificial session-expiry mechanism needed. See Known Limitations. |
| TC-STORY-7456-11    | AC-05         | Boundary      | ✅ Yes      | `should keep already-open help page accessible after logging out of CID Hub — Scenario A (no refresh) and Scenario B (F5 refresh)` | Scenarios A+B automated; Scenario C = TC-12 (Manual) |
| TC-STORY-7456-12    | AC-02, AC-05  | Negative      | ❌ Manual   | Not in spec file                                                                                             | Machine restart cannot be automated             |
| TC-STORY-7456-13    | AC-04         | Regression    | ✅ Yes      | `should open docs via the in-app help icon without sign-in prompt for all three CID Hub roles`               | Parameterised loop across User, Admin, Support roles |
| TC-STORY-7456-14    | AC-03         | Boundary      | ✅ Yes      | `should preserve URL query string in the originally requested help deep link after sign-in from redirect`     | Verifies `?q=access` preserved in returnUrl    |

---

## New Files Created / Modified

| File Path                                                     | Change Type  | Description                                                                              |
|---------------------------------------------------------------|--------------|------------------------------------------------------------------------------------------|
| `Pages/onlineHelpPage.js`                                     | **Created**  | New Page Object — docs-auth navigation, redirect detection, cookie inspection, multi-tab management, Cognito sign-in from docs redirect |
| `Tests/Feature tests/STORY-7456.spec.js`                       | **Created**  | Feature test spec — 11 Jasmine `it()` tests + 1 `xit()` (TC-10 pending)                |
| `TestData/constantData.json`                                  | **Modified** | Added `onlineHelp` section: `deepLinkPath`, `deepLinkWithQueryPath`, `legacyPublicHelpUrl` |

---

## Framework Alignment Notes

| Aspect               | Applied pattern                                                                           |
|----------------------|-------------------------------------------------------------------------------------------|
| Framework            | Protractor + Jasmine (JavaScript) — `test.conf.js`, `directConnect: true`, Chrome          |
| Spec file location   | `Tests/Feature tests/STORY-7456.spec.js` — consistent with all existing feature specs      |
| Page Object location | `Pages/onlineHelpPage.js` — consistent with existing page objects                         |
| Import pattern       | `require('../../Pages/...')`, `require('../../TestData/...')`, `require('../../commonUtils')` |
| Login helpers        | `login.customerUserIsLoggedIn(email, password)` / `login.GenericQAUserIsLoggedIn(email, password)` |
| Logout               | `navBar.clickOnLogoutButton()`                                                             |
| URL wait             | `CommonUtils.checkPageUrl(str)` → `browser.wait(EC.urlContains(str), timeout)`            |
| Tab management       | `CommonUtils.openUrlInNewTab(url)`, `browser.getAllWindowHandles()`, `browser.switchTo().window(handle)` |
| `beforeEach`         | Closes extra tabs + ensures logged-out state (logout if hub icon present; else `browser.get(baseUrl)`) |
| Angular sync         | `browser.waitForAngularEnabled(false)` before navigating to non-Angular docs/Cognito pages |
| Test data            | `testData.customerUser.user.email`, `testData.customerUser.administrator.email`, `testData.GenericQAUser.supportServices.email` |
| Assertions           | Jasmine `expect(value).toContain(str, message)` / `.toBe(bool, message)`                   |

---

## Known Limitations and Blockers

### TC-06 — Legacy public help URL (⚠️ Dev input required)

- **Issue**: AC-02a requires testing a URL that was publicly accessible before STORY-7456. No specific URL was available at automation time.
- **Action**: `testData.onlineHelp.legacyPublicHelpUrl` in `TestData/constantData.json` is currently empty (`""`). TC-06 calls Jasmine `pending()` when this value is unset.
- **Resolution**: Aaron Nguyen (aaron.nguyen@exampleqa.local) has been notified via STORY-7456 story comment to provide the URL. Once provided, set `legacyPublicHelpUrl` in `constantData.json` and TC-06 will execute automatically.

### TC-10 — Session timeout (⚠️ Partial, `xit`)

- **Issue**: Artificially expiring a CID Hub session mid-test requires either: (a) a shortened TTL in the test environment, or (b) an admin API endpoint to invalidate session tokens.
- **Action**: TC-10 is marked `xit` in the spec with full code skeleton in place. Aaron Nguyen notified via story comment.
- **Resolution**: Once the session-expiry mechanism is confirmed, replace `xit` with `it` and implement Step 3 (session expiry trigger) in the test body.

### TC-12 — Browser session end / machine restart (❌ Manual-only)

- **Issue**: The test requires closing all browser windows or restarting the machine mid-test. Browser automation frameworks (including Protractor/ChromeDriver) cannot perform a machine restart.
- **Resolution**: TC-12 remains permanently Manual-only. No automation is possible.

### `navigateToHelpPage()` tab behavior

- The in-app Help dropdown may open docs in the same tab or a new tab depending on the link's `target` attribute.
- `onlineHelpPage.handleHelpTabOpenedInNewWindow(originalHandle)` handles both cases: switches to the new tab if one is opened, stays on the current tab if not.
- Observed behavior during execution (Step 6 evidence): docs appeared to open in a new tab. The page object handles both outcomes.

---

## Run Command

```powershell
cd "C:\automation\06102026\UI_Protractor_Tests"
git checkout windows-STORY-6457-new-release-fix-latest
git pull origin windows-STORY-6457-new-release-fix-latest
git checkout -b automation/STORY-7456
npx protractor test.conf.js --specs "Tests/Feature tests/STORY-7456.spec.js"
```

---

## Next Step

Invoke `automation_code_review` agent to validate coverage against all automation-eligible TCs and check code quality before the local test run.

> **After review approval**: run the spec locally, verify all tests pass, commit with message `automation(STORY-7456): E2E tests for online help authentication gate`, push branch `automation/STORY-7456`, and raise PR to `release-fr1.4`.
