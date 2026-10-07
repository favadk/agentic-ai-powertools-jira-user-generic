# Automation Code Review — OLAC-7456: Restrict online help to authenticated CID Hub users

## Review Summary

| Field                | Value                                                                              |
|----------------------|------------------------------------------------------------------------------------|
| Story Key            | OLAC-7456                                                                          |
| Story Summary        | Restrict online help to authenticated CID Hub users                                |
| Reviewed By          | automation_code_review agent                                                       |
| Review Date          | 2026-07-23                                                                         |
| Automation Plan      | docs/Automation/AUT_OLAC-7456.md                                                   |
| TC Document          | docs/TestCases/TC_OLAC-7456.md                                                     |
| Execution Gate       | ✅ All 7 Xray steps PASSED — OLAC-7528 Full Clean Run 2026-07-22                  |
| Scripts Reviewed     | `Pages/onlineHelpPage.js`, `Tests/Feature tests/OLAC-7456.spec.js`, `TestData/constantData.json` (read from `C:\automation\06102026\UI_Protractor_Tests\` — Bitbucket unreachable at review time) |
| High Priority Issues | 0                                                                                  |
| Medium Priority      | 5                                                                                  |
| Low Priority         | 2                                                                                  |
| **Verdict**          | **⚠️ Approved with comments**                                                      |
| Code Validated       | ✅ Yes — all findings confirmed against actual source files; no findings from previous draft reversed |

---

## Coverage Assessment

All 14 TCs assessed. 11 automation-eligible TCs are implemented or correctly deferred.

| TC ID              | Automation Target | Script Method / it() Description                                                                                          | Coverage Found | Status          |
|--------------------|-------------------|---------------------------------------------------------------------------------------------------------------------------|----------------|-----------------|
| TC-OLAC-7456-01    | Yes               | `should display docs page without additional sign-in prompt when User-role navigates via in-app help entry point`         | ✅ Yes         | Covered         |
| TC-OLAC-7456-02    | Yes               | `should display docs page without additional sign-in prompt for Admin-role user`                                          | ✅ Yes         | Covered         |
| TC-OLAC-7456-03    | Yes               | `should display docs page without additional sign-in prompt for Support Services-role user`                               | ✅ Yes         | Covered         |
| TC-OLAC-7456-04    | Yes               | `should block and redirect unauthenticated user accessing docs via direct base URL`                                       | ✅ Yes         | Covered         |
| TC-OLAC-7456-05    | Yes               | `should block and redirect unauthenticated user accessing docs via a deep link URL`                                       | ✅ Yes         | Covered         |
| TC-OLAC-7456-06    | Yes (pending)     | `should block unauthenticated user accessing a previously public help URL` — `pending()` guard when `legacyPublicHelpUrl` unset | ✅ Yes    | Correctly gated |
| TC-OLAC-7456-07    | Yes               | `should redirect unauthenticated user to the CID Hub Cognito sign-in page when accessing any help URL`                    | ✅ Yes         | Covered         |
| TC-OLAC-7456-08    | Yes               | `should redirect to the originally requested help page after signing in from docs-auth redirect`                          | ✅ Yes         | Covered         |
| TC-OLAC-7456-09    | Yes               | `should allow an authenticated user to navigate directly to a docs deep link without any intermediate redirect`            | ✅ Yes         | Covered         |
| TC-OLAC-7456-10    | Partial           | `xit` — `should keep already-open help page accessible when CID Hub session times out`                                    | ✅ Yes         | Correctly `xit` |
| TC-OLAC-7456-11    | Partial           | `should keep already-open help page accessible after logging out — Scenario A (no refresh) and Scenario B (F5 refresh)`   | ✅ Yes         | Covered (A+B)   |
| TC-OLAC-7456-12    | Manual only       | Machine restart — not in spec                                                                                             | ✅ N/A         | Correctly excluded |
| TC-OLAC-7456-13    | Yes               | `should open docs via the in-app help icon without sign-in prompt for all three CID Hub roles`                            | ✅ Yes         | Covered         |
| TC-OLAC-7456-14    | Yes               | `should preserve URL query string in the originally requested help deep link after sign-in from redirect`                 | ✅ Yes         | Covered         |

**Coverage result: 100% — all automation-eligible TCs have a corresponding `it()` or correctly deferred `xit()` / `pending()` block.**

---

## Findings

### Medium Priority — Should Fix Before Merge

#### Finding M-01 — Unused keys in `TestData/constantData.json`

- **File**: `TestData/constantData.json` — `onlineHelp` object
- **Issue**: Two keys added under `onlineHelp` — `deepLinkPath` (`"docs/security/"`) and `deepLinkWithQueryPath` (`"docs/security/?q=access"`) — are never read by `OLAC-7456.spec.js` or `onlineHelpPage.js`. The spec uses page object getters (`onlineHelp.docsSecurityUrl`, `onlineHelp.docsDeepLinkWithQuery`) that compute the same URLs at runtime from `browser.params.baseUrl`. The JSON entries therefore create false documentation: any reader of `constantData.json` would assume the spec drives navigation from these values, when in fact it does not.
- **TC Reference**: All TCs using the docs deep link (TC-01 through TC-09, TC-13, TC-14)
- **Suggestion**: Remove the two unused keys; retain only `legacyPublicHelpUrl` (which is actively guarded by the TC-06 `pending()` check).

  ```json
  // Before
  "onlineHelp": {
      "deepLinkPath": "docs/security/",
      "deepLinkWithQueryPath": "docs/security/?q=access",
      "legacyPublicHelpUrl": ""
  }

  // After
  "onlineHelp": {
      "legacyPublicHelpUrl": ""
  }
  ```

---

#### Finding M-02 — Cognito sign-in selectors duplicated between `onlineHelpPage.js` and `loginPage.js`

- **File**: `Pages/onlineHelpPage.js` — class field declarations, lines ~16–18
- **Issue**: `onlineHelpPage.js` declares three private instance fields that replicate the CSS selectors already present in `loginPage.js`:

  | `onlineHelpPage.js` | `loginPage.js` |
  |---------------------|----------------|
  | `element.all(by.css('input[name=username]')).last()` | `$$('input[name=username]').last()` |
  | `element.all(by.css('input[name=password]')).last()` | `$$('input[name=password').last()` *(note: `loginPage.js` has a missing `]` in this selector — typo)* |
  | `element.all(by.css('input[name=signInSubmitButton]')).last()` | `$$('input[name=signInSubmitButton]').last()` |

  `loginPage.js` has a pre-existing typo in the password selector (`input[name=password` — missing closing `]`). The new `onlineHelpPage.js` correctly uses `input[name=password]` (with the closing bracket). This divergence means a selector change on the Cognito login form must now be tracked and applied in two separate page objects independently, with a risk of one being missed.

  The functional separation *is* valid — `signInFromCognitoRedirectAndLandOnDocs()` must not call `navBar.waitForNavbar()` because the post-sign-in landing page is a docs page, not the Angular hub. A refactor to `loginPage.js`'s `userIsLoggedIn` to accept an optional landing-page waiter strategy would eliminate the duplication.

- **TC Reference**: TC-OLAC-7456-08, TC-OLAC-7456-14
- **Suggestion**: Add a `signInCognitoOnly(email, password)` method to the `Login` class that performs the credential entry and button click *without* waiting for the navbar, then call it from `signInFromCognitoRedirectAndLandOnDocs()` in `onlineHelpPage.js`:

  ```js
  // loginPage.js — new method (no navbar wait)
  async signInCognitoOnly(email, password) {
      await browser.wait(
          protractor.ExpectedConditions.presenceOf(element(by.css('input[name=username]'))),
          10000, 'Cognito username field not present'
      )
      await this.#username.sendKeys(email)
      await this.#password.sendKeys(password)
      await this.#signInBtn.click()
      await browser.waitForAngularEnabled(false)
  }

  // onlineHelpPage.js — simplified
  async signInFromCognitoRedirectAndLandOnDocs(email, password) {
      await this.waitForCognitoSignInToLoad()
      await login.signInCognitoOnly(email, password)
      await this.waitForDocsPageToLoad(60000)
  }
  ```

---

#### Finding M-03 — Duplicate `browser.waitForAngularEnabled(false)` in `beforeEach`

- **File**: `Tests/Feature tests/OLAC-7456.spec.js` — `beforeEach` block, lines ~67–82
- **Issue**: `browser.waitForAngularEnabled(false)` is called twice before the `if (await navBar.cidHubIconIsPresent())` check — once at the very top of the hook, and once again immediately before the `if` statement. The second call is entirely redundant; nothing between the two calls re-enables Angular sync.

  ```js
  beforeEach(async () => {
      await browser.waitForAngularEnabled(false)        // ← first call (correct)

      await closeExtraTabs()

      await browser.waitForAngularEnabled(false)        // ← second call (redundant)
      if (await navBar.cidHubIconIsPresent()) {
          ...
      }
  })
  ```

- **TC Reference**: All TCs (affects every test run)
- **Suggestion**: Remove the second `await browser.waitForAngularEnabled(false)` call immediately before the `if` statement.

---

#### Finding M-04 — `browser.sleep(3000)` in TC-11 Scenario B

- **File**: `Tests/Feature tests/OLAC-7456.spec.js` — TC-11 Scenario B, line after `await browser.refresh()`
- **Issue**: After calling `browser.refresh()`, the spec uses a hardcoded `await browser.sleep(3000)` before reading the URL. Hardcoded sleeps are an anti-pattern: they cause intermittent failures on slow CI environments (insufficient wait) and waste wall-clock time on fast machines. The `waitForDocsPageToLoad()` helper already provides a proper `browser.wait()` with a configurable timeout for exactly this scenario.

  ```js
  // Current (anti-pattern)
  await browser.refresh()
  await browser.waitForAngularEnabled(false)
  await browser.sleep(3000) // allow docs-auth redirect evaluation to settle

  const urlScenarioB = await browser.getCurrentUrl()
  ```

- **TC Reference**: TC-OLAC-7456-11
- **Suggestion**: Replace `browser.sleep(3000)` with `await onlineHelp.waitForDocsPageToLoad()`:

  ```js
  // Suggested
  await browser.refresh()
  await browser.waitForAngularEnabled(false)
  await onlineHelp.waitForDocsPageToLoad()   // proper wait — replaces sleep(3000)

  const urlScenarioB = await browser.getCurrentUrl()
  ```

---

#### Finding M-05 — Raw element locator inlined in TC-07 spec body

- **File**: `Tests/Feature tests/OLAC-7456.spec.js` — TC-07 `it()` body
- **Issue**: TC-07's Step 3 assertion uses `element(by.css('input[name=username]'))` directly in the test method body rather than through a page object method:

  ```js
  // Current — raw locator in spec body (violates 'Page Object or helper methods are used' rule)
  const usernameField = element(by.css('input[name=username]'))
  expect(await usernameField.isPresent()).toBe(true,
      'The Cognito sign-in form (username input) should be present...')
  ```

  Per `automation-code-standards.md`, raw locators must not be inlined in test method bodies — they belong in page object or helper methods. The `onlineHelpPage.js` page object already encapsulates Cognito redirect state (`isOnCognitoSignInPage()`, `waitForCognitoSignInToLoad()`), but lacks a method to assert sign-in form presence. No other feature spec in `Tests/Feature tests/` uses raw locators inline in `it()` bodies (confirmed by review of `OLAC-6518.spec.js`).

- **TC Reference**: TC-OLAC-7456-07
- **Suggestion**: Add `isSignInFormPresent()` to `onlineHelpPage.js` and use it in the spec:

  ```js
  // onlineHelpPage.js — add new method
  async isSignInFormPresent() {
      return element(by.css('input[name=username]')).isPresent()
  }

  // OLAC-7456.spec.js TC-07 — replace inline locator with page object call
  expect(await onlineHelp.isSignInFormPresent()).toBe(true,
      'The Cognito sign-in form (username input) should be present on the redirect destination page — AC-03')
  ```

---

### Low Priority — Recommended

#### Finding L-01 — `openHelpViaNavbarAndSwitchToDocsTab` inlines calls already wrapped by `navBar.navigateToHelpPage()`

- **File**: `Tests/Feature tests/OLAC-7456.spec.js` — module-level helper `openHelpViaNavbarAndSwitchToDocsTab`
- **Issue**: The helper calls `navBar.openHelpDropdown()` followed by `navBar.clickDropdownItem(navBar.helpDropdownItem)`. These two calls are exactly the body of `navBar.navigateToHelpPage()` (via `navigateToPageFromHelpDropdown`). Future changes to the help navigation flow (e.g., menu restructuring) would need to be applied to both `navBar.navigateToHelpPage()` and this helper independently.

  ```js
  // Current
  async function openHelpViaNavbarAndSwitchToDocsTab(mainHandle) {
      await navBar.openHelpDropdown()
      await navBar.clickDropdownItem(navBar.helpDropdownItem)
      await onlineHelp.handleHelpTabOpenedInNewWindow(mainHandle)
  }
  ```

- **Suggestion**: Delegate the navigation to the existing wrapper:

  ```js
  async function openHelpViaNavbarAndSwitchToDocsTab(mainHandle) {
      await navBar.navigateToHelpPage()
      await onlineHelp.handleHelpTabOpenedInNewWindow(mainHandle)
  }
  ```

---

#### Finding L-02 — TC-13 cleanup between role iterations duplicates `closeExtraTabs()`

- **File**: `Tests/Feature tests/OLAC-7456.spec.js` — TC-OLAC-7456-13 `it()` body, between-iteration cleanup block
- **Issue**: The for-loop cleanup inside TC-13 re-implements the same `getAllWindowHandles()` + reverse-close logic already in the module-level `closeExtraTabs()` helper. Any future fix to `closeExtraTabs()` (e.g., error handling for a closed tab) must be duplicated here.

  ```js
  // Inline in TC-13 (duplicates closeExtraTabs logic)
  const handles = await browser.getAllWindowHandles()
  for (let i = handles.length - 1; i > 0; i--) {
      await browser.switchTo().window(handles[i])
      await browser.close()
  }
  await browser.switchTo().window(handles[0])
  ```

- **Suggestion**: Replace the inline block with `await closeExtraTabs()`.

---

## Framework Alignment Assessment

| Check                                                    | Status     | Notes                                                                       |
|----------------------------------------------------------|------------|-----------------------------------------------------------------------------|
| Spec file location (`Tests/Feature tests/`)              | ✅ Pass    | Consistent with all existing feature specs                                  |
| Page object location (`Pages/`)                          | ✅ Pass    | Consistent with existing page objects                                       |
| Import paths (`../../Pages/`, `../../TestData/`, `../../commonUtils.js`) | ✅ Pass | Matches all existing feature specs |
| Jasmine lifecycle hooks (`describe` / `it` / `beforeEach`) | ✅ Pass  | Matches project convention; no base class used (Protractor/Jasmine standard) |
| Login helpers (`login.customerUserIsLoggedIn()` / `login.GenericQAUserIsLoggedIn()`) | ✅ Pass | Correct helpers, correct password fields from `testData` |
| Logout (`navBar.clickOnLogoutButton()`)                  | ✅ Pass    | Matches existing specs                                                      |
| Hub login-state detection (`navBar.cidHubIconIsPresent()`) | ✅ Pass  | Matches `OLAC-6518.spec.js` and others                                      |
| Angular sync management (`browser.waitForAngularEnabled(false)`) | ✅ Pass | Correctly applied before non-Angular (docs, Cognito) navigation           |
| Tab management (`getAllWindowHandles`, `switchTo().window()`) | ✅ Pass | Uses standard WebDriver/Protractor tab API                                |
| Assertions (`expect().toContain()` / `.toBe()` with messages) | ✅ Pass | Descriptive failure messages on every assertion                           |
| Test data (`testData.customerUser.*`, `testData.GenericQAUser.*`) | ✅ Pass | Consistent with `constantData.json` schema                              |
| Module-level page object instances (`const login = new Login()`) | ✅ Pass | Consistent with all existing feature specs                            |
| `EC` / `ExpectedConditions` alias convention             | ⚠️ Partial | `onlineHelpPage.js` uses `ExpectedConditions` directly; project convention (see `commonUtils.js`) is `const EC = ExpectedConditions` |
| `navBar.navigateToHelpPage()` leveraged                  | ⚠️ Partial | Exists in `navbarPage.js` but inlined in spec helper — see L-01            |
| Unused test data entries removed                         | ⚠️ Partial | Two unused keys remain in `constantData.json` — see M-01                   |
| `browser.sleep()` anti-pattern absent                    | ⚠️ Partial | One instance in TC-11 Scenario B — see M-04                                |
| Raw locators absent from spec bodies                     | ⚠️ Partial | One raw locator in TC-07 `it()` body — see M-05                            |

---

## Verdict and Required Actions

**Verdict: ⚠️ Approved with comments**

The code is functionally correct, well-structured, and achieves full automation coverage for all eligible TCs. All 11 `it()` tests and 1 `xit()` align exactly to their corresponding TC IDs and ACs. No blocking defects were found. All findings have been validated against the actual source files at `C:\automation\06102026\UI_Protractor_Tests\`. **None of the 6 findings from the initial review draft have been addressed in the current code** — all remain open and must be resolved before the PR is raised.

**Required before merge (Medium Priority):**

| # | Finding | File | Action | Status |
|---|---------|------|--------|--------|
| M-01 | Remove unused `deepLinkPath` and `deepLinkWithQueryPath` from `constantData.json` | `TestData/constantData.json` | Delete the two unused keys | 🔴 Open |
| M-02 | Resolve Cognito selector duplication between `onlineHelpPage.js` and `loginPage.js` | `Pages/onlineHelpPage.js`, `Pages/loginPage.js` | Extract `signInCognitoOnly()` to `Login` class or document the intentional duplication | 🔴 Open |
| M-03 | Remove redundant second `browser.waitForAngularEnabled(false)` in `beforeEach` | `Tests/Feature tests/OLAC-7456.spec.js` | Delete the duplicate call | 🔴 Open |
| M-04 | Replace `browser.sleep(3000)` with `await onlineHelp.waitForDocsPageToLoad()` | `Tests/Feature tests/OLAC-7456.spec.js` | Use proper wait condition | 🔴 Open |
| M-05 | Raw element locator `element(by.css('input[name=username]'))` inlined in TC-07 spec body | `Tests/Feature tests/OLAC-7456.spec.js`, `Pages/onlineHelpPage.js` | Add `isSignInFormPresent()` to `onlineHelpPage.js`; use it in the spec | 🔴 Open (new) |

**Suggested before merge (Low Priority):**

| # | Finding | File | Action | Status |
|---|---------|------|--------|--------|
| L-01 | Use `navBar.navigateToHelpPage()` in `openHelpViaNavbarAndSwitchToDocsTab` | `Tests/Feature tests/OLAC-7456.spec.js` | Delegate to existing navbar method | 🔴 Open |
| L-02 | Use `closeExtraTabs()` in TC-13 cleanup | `Tests/Feature tests/OLAC-7456.spec.js` | Replace inline for-loop with helper call | 🔴 Open |

**Next step:**

Address M-01 through M-04, then proceed to the local test run:

```powershell
cd "C:\automation\06102026\UI_Protractor_Tests"
git checkout windows-olac-6457-new-release-fix-latest
git pull origin windows-olac-6457-new-release-fix-latest
git checkout -b automation/OLAC-7456
npx protractor test.conf.js --specs "Tests/Feature tests/OLAC-7456.spec.js"
```

All tests must pass before the PR is raised to `release-fr1.4`.
