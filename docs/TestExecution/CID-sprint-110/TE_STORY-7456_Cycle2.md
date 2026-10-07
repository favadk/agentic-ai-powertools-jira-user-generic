# Test Execution Report -- STORY-7456 Cycle 2 (Fix Verification)

## Summary

| Field               | Value                                                        |
|---------------------|--------------------------------------------------------------|
| **Story**           | STORY-7456 -- Restrict online help to authenticated CID Hub users |
| **Xray Test**       | STORY-7496                                                    |
| **Xray Test Execution** | STORY-7534                                               |
| **Xray Test Run ID**| `6a6134f372d5b592fbf526e9`                                  |
| **Sprint**          | CID sprint 110                                               |
| **Cycle**           | 2 (Build Retest / Fix Verification)                          |
| **Environment**     | SIT / TEST                                                   |
| **Base URL**        | https://hub.tst-51.aws.GenericQA.com/                          |
| **Docs URL**        | https://hub.tst-51.aws.GenericQA.com/docs/                     |
| **Application Version** | CID Hub 1.4.0 (post-STORY-7531 fix build)                |
| **Executed by**     | sidqawadautomation+user@gmail.com                            |
| **Execution Date**  | 2026-07-22                                                   |
| **Cycle 1 Reference** | STORY-7528 (FAILED -- AC-03 defect)                       |
| **Overall Result**  | **PASS**                                                     |

---

## Purpose

This cycle was triggered after a new build was deployed that included the fix for **STORY-7531** (AC-03: `returnUrl` parameter not honoured after Cognito sign-in). All 7 steps from Cycle 1 were re-executed against the new build to confirm the fix and verify no regressions.

---

## Step Results

| Step | Xray Step ID                             | Status   | Summary                                                                                                         |
|------|------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| 1    | `1d664a4c-f24b-41fd-9b21-7afadb81787b`  | PASSED   | Pre-requisites verified: CID Hub post-STORY-7531 fix build; logged in as User role (`sidqawadautomation+user@gmail.com`). |
| 2    | `9aac8aa4-0f12-433d-b131-1f44efbffeaa`  | PASSED   | All three roles (User, Admin, Support) successfully accessed help/docs. No regressions on authenticated docs access. |
| 3    | `d6e35aa0-1a0f-4cec-8034-5ae689379c95`  | PASSED   | Unauthenticated direct URL access to `/docs/` was redirected to sign-in page; no docs content shown.           |
| 4    | `2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78`  | **PASSED** | **AC-03 FIX VERIFIED**: After navigating to `/docs/security/` unauthenticated and completing sign-in via Cognito, the docs-auth flow correctly redirected to `/docs/security/` (the originally requested page). `returnUrl` is now honoured. STORY-7531 resolved. |
| 5    | `87b04cd4-995a-4d74-b116-7cc45c4393f9`  | PASSED   | Docs remained accessible after logout. Regression check passed.                                                 |
| 6    | `bd67bfa7-0f5e-4f57-b817-e464659ace4c`  | PASSED   | `?` help icon opens docs tab correctly; no regression.                                                          |
| 7    | `0238d135-84fe-4ea0-850f-1ddd35640e10`  | PASSED   | F5 refresh on docs tab after logout -- docs at `/docs/` still accessible. AC-05 Scenario B behaviour unchanged. |

---

## AC-03 Fix Verification Detail (Step 4)

**Cycle 1 behaviour (FAILED):**
- Navigate to `/docs/security/` while unauthenticated
- Redirected to Cognito sign-in
- After sign-in, `CognitoAuthService.originalUrl` in localStorage stored `/` (hub root)
- Docs-auth redirected to `/` (hub root) -- incorrect

**Cycle 2 behaviour (PASSED):**
- Navigate to `/docs/security/` while unauthenticated
- Redirected to Cognito sign-in
- After sign-in, `CognitoAuthService.originalUrl` in localStorage stores `/docs-auth?returnUrl=%2Fdocs%2Fsecurity%2F`
- Docs-auth correctly serves `/docs/security/` and sets `ac_docs_auth` cookie
- Browser lands on `/docs/security/` -- Security page fully rendered
- `returnUrl` parameter is now honoured

---

## Findings

| # | Finding  | Status      | Resolution         |
|---|----------|-------------|---------------------|
| 1 | STORY-7531: AC-03 `returnUrl` not honoured | **Resolved** | Fix confirmed in Cycle 2. STORY-7531 transitioned to Done. |

No new findings in Cycle 2.

---

## Evidence Files

Screenshots saved to `docs/TestExecution/evidence/STORY-7456-Cycle2/` and uploaded to Xray step 4 of run `6a6134f372d5b592fbf526e9`:

| File                                                    | Step | Notes                                                        |
|---------------------------------------------------------|------|--------------------------------------------------------------|
| `step4-01-unauthenticated-cognito-redirect.png`         | 4    | Cognito sign-in page shown after navigating to `/docs/security/` unauthenticated |
| `step4-02-credentials-entered.png`                      | 4    | Test user credentials entered on Cognito sign-in page        |
| `step4-03-post-signin-correct-redirect-PASS.png`        | 4    | Security docs page at `/docs/security/` correctly loaded post sign-in -- PASS |

---

## Test Accounts Used

| Role                    | Username                                           |
|-------------------------|----------------------------------------------------|
| Customer User           | sidqawadautomation+user@gmail.com                  |
| Customer Administrator  | sidqawadautomation+administrator@gmail.com         |
| GenericQA Support Services| sidqawadautomation+supportservices@gmail.com       |

---

## AC-05 Scenario Coverage Notes

| Scenario | Coverage in this cycle | Result   |
|----------|------------------------|----------|
| A -- Logout, no refresh, tab stays open | Step 5 | PASSED |
| B -- Logout, F5 refresh in same browser session | Step 7 | PASSED -- cookie persists; docs still accessible |
| C -- Close all windows / machine restart | Not executed (Manual only) | Deferred (unchanged from Cycle 1) |

---

## Cycle Comparison

| Step | Cycle 1 | Cycle 2 | Change                     |
|------|---------|---------|----------------------------|
| 1    | PASSED  | PASSED  | No change                  |
| 2    | PASSED  | PASSED  | No change                  |
| 3    | PASSED  | PASSED  | No change                  |
| 4    | FAILED  | PASSED  | AC-03 fix confirmed         |
| 5    | PASSED  | PASSED  | No change                  |
| 6    | PASSED  | PASSED  | No change                  |
| 7    | PASSED  | PASSED  | No change                  |
| **Overall** | **FAIL** | **PASS** | **Ready for Test Results Review** |
