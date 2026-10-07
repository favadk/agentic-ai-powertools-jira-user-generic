# Test Execution Report -- Sprint TE: CID sprint 110 (STORY-7456 / STORY-7496)

## Summary

| Field               | Value                                                        |
|---------------------|--------------------------------------------------------------|
| **Story**           | STORY-7456 -- Restrict online help to authenticated CID Hub users |
| **Xray Test**       | STORY-7496                                                    |
| **Xray Test Execution** | STORY-7528                                               |
| **Xray Test Run ID**| `6a5ff87b72d5b592fbee751e`                                  |
| **Sprint**          | CID sprint 110                                               |
| **Xray TE Summary** | Sprint TE: CID sprint 110                                    |
| **Environment**     | SIT / TEST                                                   |
| **Base URL**        | https://hub.tst-51.aws.GenericQA.com/                          |
| **Docs URL**        | https://hub.tst-51.aws.GenericQA.com/docs/                     |
| **Application Version** | CID Hub 1.4.0 8e67828d (Released 2026-07-22 13:15:26-07:00) |
| **Executed by**     | sidqawadautomation+user@gmail.com                            |
| **Initial Execution Date** | 2026-07-22                                            |
| **Full Clean Run Date**    | 2026-07-22                                            |
| **Overall Result**         | **PASS** (Full clean run — all 7 steps PASSED)        |

---

## Step Results

| Step | Xray Step ID                             | Status   | Summary                                                                                                         |
|------|------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| 1    | `1d664a4c-f24b-41fd-9b21-7afadb81787b`  | PASSED   | Hub redirects unauthenticated users to Cognito sign-in (AC-02). User role signed in and accessed docs via Help icon — no additional auth prompt (AC-01, AC-04). |
| 2    | `9aac8aa4-0f12-433d-b131-1f44efbffeaa`  | PASSED   | Admin and Support roles both authenticated and accessed docs without additional auth prompt (AC-01a verified across all three roles). |
| 3    | `d6e35aa0-1a0f-4cec-8034-5ae689379c95`  | PASSED   | Hub blocks unauthenticated access and redirects to Cognito (AC-02). Note: ac_docs_auth cookie persists after hub logout — this is expected per AC-05. |
| 4    | `2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78`  | PASSED   | STORY-7531 fix verified: Cognito sign-in page shown when hub session expired. After sign-in, docs/security page loads successfully. AC-03 returnUrl behaviour confirmed working. |
| 5    | `87b04cd4-995a-4d74-b116-7cc45c4393f9`  | PASSED   | Docs remained accessible after hub logout (no refresh, then internal nav link). ac_docs_auth cookie persists independently of hub Cognito session. AC-05 confirmed (Scenario A). |
| 6    | `bd67bfa7-0f5e-4f57-b817-e464659ace4c`  | PASSED   | Help (?) icon opens docs in new tab with no additional auth prompt for User role. TC-13 regression verified PASS. |
| 7    | `0238d135-84fe-4ea0-850f-1ddd35640e10`  | PASSED   | F5 refresh of docs/security page after hub logout — page remained accessible. ac_docs_auth cookie still valid. AC-05 Scenario B confirmed. |

---

## Findings

| # | Finding                          | AC  | Severity | Jira Ref    | Status      |
|---|----------------------------------|-----|----------|-------------|-------------|
| 1 | docs-auth ignores `returnUrl` after Cognito sign-in -- redirects to hub root instead of originally requested docs page | AC-03 | High | STORY-7531 (Sub-task) | **Resolved** (fix verified 2026-07-22) |

---

## Evidence Files

All screenshots saved to `docs/TestExecution/evidence/STORY-7456-FullRun/`:

| File                                                          | Step | Notes                                                        |
|---------------------------------------------------------------|------|--------------------------------------------------------------|
| `step1-01-hub-redirects-to-cognito-unauth.png`                | 1    | Hub → Cognito redirect when unauthenticated (AC-02)          |
| `step1-02-user-logged-in-hub-dashboard.png`                   | 1    | User role signed in, hub CIDs page visible                   |
| `step1-03-user-docs-loaded-via-help.png`                      | 1    | Docs Introduction page via Help icon, no auth prompt (AC-01, AC-04) |
| `step2-01-admin-docs-loaded-no-auth.png`                      | 2    | Admin role docs access, no auth prompt (AC-01a)              |
| `step2-02-support-docs-loaded-no-auth.png`                    | 2    | Support role docs access, no auth prompt (AC-01a)            |
| `step3-01-unauth-hub-redirects-to-signin.png`                 | 3    | Hub unauthenticated → Cognito sign-in (AC-02)                |
| `step3-02-docs-accessible-ac_docs_auth-cookie-persists-ac05.png` | 3 | ac_docs_auth cookie persists after hub logout (AC-05 behavior noted) |
| `step4-02-cognito-signin-page-hub-unauthenticated.png`        | 4    | Cognito sign-in page shown when hub session expired (AC-03)  |
| `step4-04-post-signin-docs-security-accessible-PASS.png`      | 4    | docs/security loaded after sign-in — AC-03 returnUrl PASS (STORY-7531 fix verified) |
| `step5-01-docs-open-before-logout.png`                        | 5    | Docs accessible before logout                                |
| `step5-02-hub-logged-out-cognito-signin-shown.png`            | 5    | Hub logged out — Cognito signin shown                        |
| `step5-03-docs-still-accessible-after-hub-logout-PASS.png`   | 5    | Docs still accessible after hub logout — AC-05 Scenario A PASS |
| `step5-04-internal-nav-link-accessible-after-logout-PASS.png` | 5    | Internal docs nav link accessible after logout               |
| `step6-01-user-signed-in-hub-dashboard.png`                   | 6    | User signed in, hub dashboard                                |
| `step6-02-help-dropdown-visible.png`                          | 6    | Help (?) dropdown visible                                    |
| `step6-03-docs-opened-via-help-icon-no-auth-prompt-PASS.png`  | 6    | Docs opened via help icon, no auth prompt — TC-13 regression PASS |
| `step7-01-f5-refresh-docs-still-accessible-post-logout-PASS.png` | 7 | F5 refresh after logout — docs still accessible — AC-05 Scenario B PASS |

---

## Test Accounts Used

| Role                    | Username                                           |
|-------------------------|----------------------------------------------------|
| Customer User           | sidqawadautomation+user@gmail.com                  |
| Customer Administrator  | sidqawadautomation+administrator@gmail.com         |
| GenericQA Support Services| sidqawadautomation+supportservices@gmail.com       |

---

## AC-05 Scenario Coverage Notes

Three distinct AC-05 scenarios were identified during this cycle. Step 7 confirmed Scenario B behaviour (F5 refresh in same browser session after logout -- docs still accessible), which required an update to TC-11 and TC-12. See [docs/TestCases/TC_STORY-7456.md](../TestCases/TC_STORY-7456.md) for details.

| Scenario | Coverage in this cycle | Result   |
|----------|------------------------|----------|
| A -- Logout, no refresh, tab stays open | Step 5 | PASSED |
| B -- Logout, F5 refresh in same browser session | Step 7 | PASSED -- cookie persists; docs still accessible |
| C -- Close all windows / machine restart | Not executed (TC-12 -- Manual only) | Deferred |

TC-12 (Scenario C) is Manual-only due to the machine-restart requirement and must be scheduled for a dedicated manual run.
