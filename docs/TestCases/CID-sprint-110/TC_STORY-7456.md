# Test Cases

**Quality Assurance  -  Test Case Document**

## Test Cases for `STORY-7456`

## Document Information

| **Filename**      | TC_STORY-7456.md                                               |
|-------------------|---------------------------------------------------------------|
| **Story Key**     | `STORY-7456`                                                   |
| **Story Summary** | Restrict online help to authenticated CID Hub users           |
| **Sprint**        | CID sprint 109                                                |
| **Prepared By**   | TBD                                                           |
| **Date Prepared** | 2026-07-08                                                    |
| **Status**        | Updated — Review Findings Applied (2026-07-16)              |
| **Xray Test Key** | STORY-7496 |

---

> **[2026-07-21] AC updated**: AC-05 wording revised — "browser session ends" now explicitly includes clearing cookies and machine restart. New Q/N note added specifying `ac_docs_auth` cookie as the access control mechanism. TC-10, TC-11, TC-12 prerequisites and steps updated accordingly.
> **[2026-07-22] TC-11 & TC-12 updated**: TC-11 Step 5 added — F5 refresh in the same browser session after logout is expected to PASS (docs still accessible; cookie persists). TC-12 rewritten — the correct blocking trigger is "close all browser windows (end browser session) then retry in a new browser window", not F5 refresh. This aligns with confirmed execution behaviour from STORY-7530 Cycle 1 Step 7.

## Story Acceptance Criteria

- **AC-01**: A user can view the online help **only after** they have authenticated with CID Hub.
  - **AC-01a**: The help is reachable to every authenticated user regardless of role  -  Admin, User, or Support.
- **AC-02**: A user **cannot** view any online help content, including by navigating directly to a help URL or a deep link to a specific help page, without logging in.
  - **AC-02a**: Any previously shared public help links **no longer display content** without an authenticated session. This is the change from today's behaviour.
- **AC-03**: An unauthenticated user who attempts to reach any online help page directly is **redirected to the CID Hub sign-in page**. After signing in, the help page originally requested is displayed.
- **AC-04**: Authenticated users continue to reach the online help from the **hub's existing help entry point** without disruption.
- **AC-05**: Session timeouts and logouts from CID Hub **do not affect** documentation pages. Once they are shown they remain accessible till the browser session ends (e.g., by closing all browser windows, clearing cookies, restarting the machine, etc.).

---

## Test Cases

---

### TC-STORY-7456-01  -  Authenticated user accesses online help via in-app entry point

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-01               |
| **AC Reference**| AC-01, AC-04                  |
| **Title**       | Authenticated user opens help via in-app entry point |
| **Type**        | Happy Path                    |
| **Priority**    | High                          |
| **Automation**  | Yes                           |

**Prerequisites**

- Test environment has online help deployed with authentication gate enabled
- Active test account with **User** role available
- User is not currently signed in to CID Hub

**Test Data**

| Field         | Value                          |
|---------------|--------------------------------|
| Username      | Test User account (User role)  |
| Help Entry    | Existing in-app help button/link/menu item |

**Steps**

| Step | Action                                                                 | Expected Result                                                          |
|------|------------------------------------------------------------------------|--------------------------------------------------------------------------|
| 1    | Open CID Hub in a browser and sign in with a User-role account         | User is successfully authenticated and lands on the hub home page        |
| 2    | Locate and click the existing in-app help entry point (e.g., "?" icon, Help menu) | Help documentation page loads without any additional sign-in prompt |
| 3    | Navigate to at least two different help pages using internal help links | All pages load successfully; no authentication challenge appears          |
| 4    | Verify that the browser URL corresponds to an online help page path (not a hub application page) | URL in the address bar points to the help documentation domain or path; this confirms the user reached the actual help system |

---

### TC-STORY-7456-02  -  Admin role can access online help

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-02               |
| **AC Reference**| AC-01a                        |
| **Title**       | Admin role user can view online help |
| **Type**        | Happy Path                    |
| **Priority**    | High                          |
| **Automation**  | Yes                           |

**Prerequisites**

- Active test account with **Admin** role available
- User is not currently signed in to CID Hub

**Test Data**

| Field    | Value                         |
|----------|-------------------------------|
| Username | Test Admin account (Admin role) |

**Steps**

| Step | Action                                                      | Expected Result                                                    |
|------|-------------------------------------------------------------|--------------------------------------------------------------------|
| 1    | Sign in to CID Hub with an Admin-role account               | Admin is successfully authenticated                                |
| 2    | Navigate to the online help via the in-app entry point      | Help page loads without any additional sign-in prompt              |
| 3    | Navigate to a specific help topic within the documentation  | Help content is fully rendered and readable                        |

---

### TC-STORY-7456-03  -  Support role can access online help

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-03               |
| **AC Reference**| AC-01a                        |
| **Title**       | Support role user can view online help |
| **Type**        | Happy Path                    |
| **Priority**    | High                          |
| **Automation**  | Yes                           |

**Prerequisites**

- Active test account with **Support** role available
- User is not currently signed in to CID Hub (sign out or use a fresh browser profile between role tests)

**Test Data**

| Field    | Value                             |
|----------|-----------------------------------|
| Username | Test Support account (Support role) |

**Steps**

| Step | Action                                                      | Expected Result                                                    |
|------|-------------------------------------------------------------|--------------------------------------------------------------------|
| 1    | Sign in to CID Hub with a Support-role account              | Support user is successfully authenticated                         |
| 2    | Navigate to the online help via the in-app entry point      | Help page loads without any additional sign-in prompt              |
| 3    | Navigate to a specific help topic within the documentation  | Help content is fully rendered and readable                        |

---

### TC-STORY-7456-04  -  Unauthenticated user blocked on direct help URL access

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-04               |
| **AC Reference**| AC-02                         |
| **Title**       | Unauthenticated user cannot access help via direct URL |
| **Type**        | Negative                      |
| **Priority**    | High                          |
| **Automation**  | Yes                           |

**Prerequisites**

- Fresh browser session (no active CID Hub session  -  use incognito/private mode or clear cookies)
- At least one known online help page URL
- **Note**: This TC verifies only that content is blocked (AC-02). The redirect behaviour is verified separately in TC-07 (AC-03). Both must be executed.

**Test Data**

| Field        | Value                                         |
|--------------|-----------------------------------------------|
| Help URL     | Direct URL to a help page (e.g., `/help/overview`) |
| Auth State   | Unauthenticated (no active session)           |

**Steps**

| Step | Action                                                                | Expected Result                                                          |
|------|-----------------------------------------------------------------------|--------------------------------------------------------------------------|
| 1    | Open an incognito/private browser window (no active CID Hub session)  | Fresh unauthenticated browser session                                    |
| 2    | Paste the direct help page URL into the address bar and navigate      | Help content is **not** displayed; user is **redirected to the CID Hub sign-in page** (no partial documentation is rendered) |
| 3    | Verify no help content is partially loaded or cached                  | No help page content visible; page does not render documentation; sign-in page is shown |

---

### TC-STORY-7456-05  -  Unauthenticated user blocked on deep link to specific help page

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-05               |
| **AC Reference**| AC-02                         |
| **Title**       | Unauthenticated user cannot access deep link to specific help page |
| **Type**        | Negative                      |
| **Priority**    | High                          |
| **Automation**  | Yes                           |

**Prerequisites**

- Fresh browser session (no active CID Hub session)
- At least one known deep-link URL pointing to a specific help sub-page or section (e.g., `/help/security/user-management`)

**Test Data**

| Field      | Value                                                       |
|------------|-------------------------------------------------------------|
| Deep Link  | URL to a specific help sub-page (not the help root)         |
| Auth State | Unauthenticated                                             |

**Steps**

| Step | Action                                                               | Expected Result                                                  |
|------|----------------------------------------------------------------------|------------------------------------------------------------------|
| 1    | Open an incognito/private browser window                             | Fresh unauthenticated session                                    |
| 2    | Paste the deep link URL to a specific help page and navigate         | Help content is **not** displayed; user is **redirected to the CID Hub sign-in page** |
| 3    | Confirm no partial content is rendered                               | Page shows no help documentation; user is redirected to the CID Hub sign-in page  -  no content is partially rendered |

---

### TC-STORY-7456-06  -  Previously public help links blocked for unauthenticated users

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-06               |
| **AC Reference**| AC-02a                        |
| **Title**       | Previously public help links blocked without an authenticated session |
| **Type**        | Negative                      |
| **Priority**    | High                          |
| **Automation**  | Yes                           |

**Prerequisites**

- At least one help URL that was publicly accessible **before** this story was implemented (confirm with dev)
- Fresh browser session (no active CID Hub session)

**Test Data**

| Field            | Value                                                       |
|------------------|-------------------------------------------------------------|
| Legacy Public URL | Previously accessible help URL (from before auth gate)     |
| Auth State       | Unauthenticated                                             |

**Steps**

| Step | Action                                                               | Expected Result                                                                       |
|------|----------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| 1    | Open an incognito/private browser window                             | Fresh unauthenticated session                                                         |
| 2    | Navigate to a previously public help URL                             | Help content is **no longer** displayed  -  page blocks access or redirects to sign-in  |
| 3    | Confirm the response is a redirect or 401/403, not help content      | No documentation is rendered; the browser either shows the CID Hub sign-in page (redirect) or returns a 401/403 HTTP response  -  the help URL does not serve any content |

> [!] **Evidence requirement**: Screenshot of this blocked state is mandatory as proof of the breaking change from AC-02a.

---

### TC-STORY-7456-07  -  Unauthenticated user redirected to sign-in page

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-07               |
| **AC Reference**| AC-03                         |
| **Title**       | Unauthenticated user redirected to CID Hub sign-in when accessing help |
| **Type**        | Happy Path                    |
| **Priority**    | High                          |
| **Automation**  | Yes                           |

**Prerequisites**

- Fresh browser session (no active CID Hub session)
- Known direct help URL
- **Note**: This TC verifies the redirect mechanism (AC-03). Content blocking is verified in TC-04 (AC-02). Both must be executed.

**Test Data**

| Field      | Value                          |
|------------|--------------------------------|
| Help URL   | Any valid online help page URL |
| Auth State | Unauthenticated                |

**Steps**

| Step | Action                                                              | Expected Result                                                        |
|------|---------------------------------------------------------------------|------------------------------------------------------------------------|
| 1    | Open an incognito/private browser window                            | Fresh unauthenticated session                                          |
| 2    | Navigate to a direct help page URL                                  | User is **redirected** to the CID Hub sign-in page                    |
| 3    | Confirm the sign-in page is the standard CID Hub login form         | CID Hub sign-in page is shown  -  no other auth form or error page       |

---

### TC-STORY-7456-08  -  After sign-in from redirect, user lands on originally requested help page

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-08               |
| **AC Reference**| AC-03                         |
| **Title**       | User lands on originally requested help page after signing in from redirect |
| **Type**        | Happy Path                    |
| **Priority**    | High                          |
| **Automation**  | Yes                           |

**Prerequisites**

- Fresh browser session (no active CID Hub session)
- Known URL of a specific help page (to use as the redirect target)
- Valid CID Hub credentials

**Test Data**

| Field         | Value                                                      |
|---------------|------------------------------------------------------------|
| Target Help URL | URL of a specific help page (e.g., `/help/security/overview`) |
| Username      | Valid User-role account credentials                        |
| Auth State    | Unauthenticated at start                                   |

**Steps**

| Step | Action                                                                         | Expected Result                                                                   |
|------|--------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| 1    | Open an incognito/private browser window                                       | Fresh unauthenticated session                                                     |
| 2    | Navigate to a specific help page URL (note the URL)                            | User is redirected to CID Hub sign-in page                                        |
| 3    | Sign in with valid credentials on the sign-in page                             | Authentication succeeds                                                           |
| 4    | Observe the page the user lands on after successful sign-in                    | User is **automatically redirected** to the originally requested help page        |
| 5    | Confirm the URL in the browser matches the original help page URL from Step 2  | URL matches; correct help page content is displayed                               |

---

### TC-STORY-7456-09  -  Authenticated user accesses help deep link directly without redirect

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-09               |
| **AC Reference**| AC-01, AC-03                  |
| **Title**       | Authenticated user navigating to deep link goes directly to help page  -  no extra redirect |
| **Type**        | Happy Path                    |
| **Priority**    | Medium                        |
| **Automation**  | Yes                           |

**Prerequisites**

- Active authenticated CID Hub session (any role)
- Known deep-link URL to a specific help page

**Test Data**

| Field       | Value                                        |
|-------------|----------------------------------------------|
| Deep Link   | URL to a specific help sub-page or section   |
| Auth State  | Authenticated                                |

**Steps**

| Step | Action                                                                  | Expected Result                                                    |
|------|-------------------------------------------------------------------------|--------------------------------------------------------------------|
| 1    | Sign in to CID Hub with valid credentials                               | User is authenticated                                              |
| 2    | Paste a deep link URL to a specific help page into the address bar      | Help page loads **directly** without any intermediate redirect     |
| 3    | Confirm the correct help content is displayed                           | Target help page content is rendered; no sign-in page appeared     |

---

### TC-STORY-7456-10  -  Session timeout does not close already-open help page

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-10               |
| **AC Reference**| AC-05                         |
| **Title**       | Session timeout does not affect already-open help page |
| **Type**        | Boundary                      |
| **Priority**    | High                          |
| **Automation**  | Partial                       |

**Prerequisites**

- Active authenticated CID Hub session
- Help page already open in browser tab
- **[2026-07-21] Cookie note**: Documentation access is controlled by the `ac_docs_auth` browser cookie. Cookies can persist even after the machine is restarted or all browser windows are closed. Verify cookie state via Browser DevTools ? Application ? Cookies during execution.
- Ability to artificially trigger a session timeout (confirm mechanism with dev — e.g., expire token via admin panel, or shorten session TTL in test env)
- **Pre-condition**: Confirm with dev team that the help server does not re-validate CID Hub session on each internal link click (AC-05 scope).

**Test Data**

| Field         | Value                                                  |
|---------------|--------------------------------------------------------|
| Session State | Active session with help page already loaded           |
| Trigger       | Artificial session expiry (coordinate with dev team)   |

**Steps**

| Step | Action                                                                       | Expected Result                                                               |
|------|------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| 1    | Sign in to CID Hub and navigate to any online help page                      | Help page is visible and loaded in the browser                                |
| 2    | Note the current URL and content of the open help page                       | Help page URL and content recorded                                            |
| 3    | Trigger a session timeout (artificially expire the CID Hub session)          | Session expires in CID Hub; hub shows a timeout/re-login prompt if navigated  |
| 4    | **Without refreshing** the help page tab  -  observe the already-open help tab | Help page **remains visible** and readable; content is not removed or blocked |
| 5    | Scroll the help page and click at least one internal navigation link or section heading | Linked content loads without any authentication prompt appearing; no redirect occurs. Optional: open Browser DevTools ? Application ? Cookies and confirm the `ac_docs_auth` cookie is still present. |

---

### TC-STORY-7456-11  -  Logout does not affect already-open help page

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-11               |
| **AC Reference**| AC-05                         |
| **Title**       | Logging out of CID Hub does not close or block already-open help page |
| **Type**        | Boundary                      |
| **Priority**    | High                          |
| **Automation**  | Partial                       |

**Prerequisites**

- Active authenticated CID Hub session
- Help page already open in a browser tab (separate from main hub tab)
- **[2026-07-21] Cookie note**: Documentation access is controlled by the `ac_docs_auth` browser cookie. Cookies can persist even after the machine is restarted or all browser windows are closed. Verify cookie state via Browser DevTools ? Application ? Cookies during execution.
- **Pre-condition**: Confirm with dev team that the help server does not re-validate CID Hub session on each internal link click (AC-05 scope).

**Test Data**

| Field         | Value                                              |
|---------------|----------------------------------------------------|
| Session State | Active session; help page loaded in a browser tab  |

**Steps**

| Step | Action                                                                    | Expected Result                                                                |
|------|---------------------------------------------------------------------------|--------------------------------------------------------------------------------|
| 1    | Sign in to CID Hub and open a help page in a new browser tab             | Help page is visible and loaded                                                |
| 2    | Switch to the main hub tab and perform a **logout** from CID Hub          | User is successfully signed out of CID Hub                                     |
| 3    | Switch back to the help page tab  -  **do not refresh** it                  | Help page **remains visible** and readable; no redirect or auth prompt appears |
| 4    | Scroll the already-open help page and click at least one internal navigation link or section heading | Content remains fully accessible; no redirect or authentication prompt appears after logout. Open Browser DevTools -> Application -> Cookies and confirm the `ac_docs_auth` cookie is still present. |
| 5    | **Refresh** the help page tab (F5) -- still within the same browser session after logout | Help page **remains accessible** -- content is still rendered. The `ac_docs_auth` cookie persists through hub logout so the docs server still honours the session. Confirm cookie is still visible in DevTools. This is expected per AC-05: the docs session stays open until the browser session itself ends (closing all windows or machine restart). |

> **Scenario coverage note**: Steps 1-4 cover **Scenario A** (no refresh after logout -> accessible). Step 5 covers **Scenario B** (F5 refresh in same browser session after logout -> still accessible). **Scenario C** (browser session ends -> blocked) is covered by TC-12.

---

### TC-STORY-7456-12 -- Docs blocked when browser session ends after logout (close all windows / machine restart)

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-12               |
| **AC Reference**| AC-02, AC-05                  |
| **Title**       | Docs access blocked once browser session ends after logout -- close all windows or machine restart |
| **Type**        | Negative                      |
| **Priority**    | Medium                        |
| **Automation**  | Manual                        |

**Prerequisites**

- Active authenticated CID Hub session with a docs page open in a browser tab
- **Manual-only**: This TC requires a full machine reboot while the docs browser tab is still open. Browser automation cannot perform a machine restart mid-test -- this TC must always be executed manually.
- **Q/N -- Cookie persistence check (mandatory pre-condition)**: Before executing, open Browser DevTools -> Application -> Cookies -> locate `ac_docs_auth` -> check the **Expires / Max-Age** column and record the value. If it shows "Session" the cookie expires when the browser closes; if it shows a future date, it persists past machine restart. This determines the expected outcome of Steps 5 and 6.

**Test Data**

| Field            | Value                                                           |
|------------------|-----------------------------------------------------------------|
| Session State    | Authenticated; docs tab open in browser                         |
| Pre-test Q/N     | `ac_docs_auth` Expires value -- record from DevTools before Step 1 |

**Steps**

| Step | Action                                                                     | Expected Result                                                             |
|------|----------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| 1    | Sign in to CID Hub; open a docs/help page in a separate browser tab and confirm it loads | Docs page loaded and visible in its tab                          |
| 2    | Logout from CID Hub in the hub tab                                         | Logout confirmed; hub shows sign-in page                                    |
| 3    | Switch to the docs tab -- **do not refresh** -- and confirm it is still accessible | Docs page **still accessible**; this is expected AC-05 behaviour while the browser session is alive (same as TC-11 Scenario A) |
| 4    | Open Browser DevTools -> Application -> Cookies -> locate `ac_docs_auth` and record whether it is a **Session** cookie or has an **Expires** date | Cookie type and expiry value recorded. This is the mandatory Q/N verification step confirming the `ac_docs_auth` access-control mechanism. |
| 5    | **Close all browser windows completely** (end the browser session) -- then reopen the browser and navigate directly to the docs URL | If `ac_docs_auth` is a **Session** cookie: docs are **blocked** -- user is redirected to CID Hub sign-in page (PASS). If it is a **Persistent** cookie with a future expiry: docs may still be accessible -- record actual result and raise as a finding for PO review. |
| 6    | *(Machine-restart path -- primary scenario for this TC)* With the docs tab still open and visible, **restart the machine**. After reboot, open the browser and navigate to the docs URL. | If `ac_docs_auth` was a **Session** cookie: docs are **blocked** after restart -- sign-in page shown (PASS). If it was a **Persistent** cookie: docs may still be accessible after restart -- record actual result and raise as finding for PO to confirm intended cookie lifetime vs AC-05 design. |
| 7    | Open Browser DevTools -> Application -> Cookies after restart and check whether `ac_docs_auth` is present | Document: (a) whether sign-in page appeared, (b) whether `ac_docs_auth` cookie is present after restart. Both data points required as execution evidence. |

> **Q/N verification note**: Per story Q/N 2026-07-21, browser cookies can persist even after machine restart if they carry a future expiry date. This TC is designed to surface that behaviour rather than assume it. Steps 5-7 must be executed to verify which cookie type is in use. If `ac_docs_auth` survives a machine restart (persistent cookie), the team must confirm with the PO whether that aligns with AC-05's "browser session ends" intent -- AC-05 does not specify cookie lifetime. Record all actual results regardless of expectation. **Do not mark as Pass/Fail until cookie type is confirmed in Step 4.**
### TC-STORY-7456-13  -  Regression: In-app help entry point continues to work

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-13               |
| **AC Reference**| AC-04                         |
| **Title**       | In-app help entry point is not broken by the authentication gate |
| **Type**        | Regression                    |
| **Priority**    | High                          |
| **Automation**  | Yes                           |

**Prerequisites**

- Active authenticated CID Hub session (all three roles: Admin, User, Support — run once per role if possible)
- In-app help entry point accessible (help icon/button/menu item in CID Hub UI)
- **Parameterization**: This TC is run three times — once per role (Admin, User, Support). Run it separately for each role. Clear the session (sign out or use a fresh browser profile) between runs.

**Test Data**

| Field    | Value                                   |
|----------|-----------------------------------------|
| Role     | Admin, then User, then Support (3 runs) |

**Steps**

| Step | Action                                                               | Expected Result                                                       |
|------|----------------------------------------------------------------------|-----------------------------------------------------------------------|
| 1    | Sign in to CID Hub with each role account in turn                    | Authenticated successfully                                            |
| 2    | Click the in-app help entry point (e.g., Help menu / "?" button)     | Online help page opens  -  **no sign-in prompt appears**                |
| 3    | Verify the help page content is fully rendered                       | Documentation is readable and navigable                               |
| 4    | Navigate between multiple help pages using in-page links             | All linked help pages load without interruption or additional auth    |

---

### TC-STORY-7456-14  -  URL query string and fragment preserved after sign-in from redirect

| Field           | Value                         |
|-----------------|-------------------------------|
| **TC ID**       | TC-STORY-7456-14               |
| **AC Reference**| AC-03                         |
| **Title**       | URL query string and/or fragment preserved in help deep link after sign-in from redirect |
| **Type**        | Boundary                      |
| **Priority**    | Medium                        |
| **Automation**  | Yes                           |

**Prerequisites**

- Fresh browser session (no active CID Hub session)
- A help URL containing at least one query string parameter (e.g., `?q=security`) **and/or** a hash fragment (e.g., `#user-management`)
- Valid CID Hub credentials

**Test Data**

| Field           | Value                                                                    |
|-----------------|--------------------------------------------------------------------------|
| Target Help URL | URL to a specific help page with query/fragment (e.g., `/help/overview?q=security#user-roles`) |
| Username        | Valid User-role account credentials                                      |
| Auth State      | Unauthenticated at start                                                 |

**Steps**

| Step | Action                                                                          | Expected Result                                                                                             |
|------|---------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| 1    | Open an incognito/private browser window                                        | Fresh unauthenticated session                                                                               |
| 2    | Navigate to a help URL containing a query string parameter and/or hash fragment (note the full URL) | User is redirected to the CID Hub sign-in page; the target URL is retained internally for post-auth redirect |
| 3    | Sign in with valid credentials on the sign-in page                             | Authentication succeeds                                                                                     |
| 4    | Observe the page loaded after successful sign-in                               | User is redirected to the originally requested help page  -  including the full URL with query string and/or fragment |
| 5    | Verify the URL in the address bar matches the original URL from Step 2         | Full URL (including query parameters and/or hash fragment) is preserved; page scrolls to or renders the originally anchored section |

---

## AC Coverage Matrix

> **TC ID abbreviation key**: TC-XX = TC-STORY-7456-XX throughout this matrix.

| AC Item  | Description (brief)                                                   | TC IDs Covering It                                           | Coverage Status |
|----------|-----------------------------------------------------------------------|--------------------------------------------------------------|-----------------|
| AC-01    | Authenticated users can view online help                              | TC-STORY-7456-01, TC-STORY-7456-02, TC-STORY-7456-03, TC-STORY-7456-09, TC-STORY-7456-13 | [OK] Covered      |
| AC-01a   | All roles (Admin / User / Support) can access help                    | TC-STORY-7456-01, TC-STORY-7456-02, TC-STORY-7456-03, TC-STORY-7456-13 | [OK] Covered      |
| AC-02    | Unauthenticated users cannot view help (direct URL or deep link)      | TC-STORY-7456-04, TC-STORY-7456-05, TC-STORY-7456-12          | [OK] Covered      |
| AC-02a   | Previously public help links blocked without authenticated session    | TC-STORY-7456-06                                              | [OK] Covered      |
| AC-03    | Unauthenticated users redirected to sign-in; land on requested page   | TC-STORY-7456-07, TC-STORY-7456-08, TC-STORY-7456-14          | [OK] Covered      |
| AC-04    | In-app help entry point works without disruption (regression)         | TC-STORY-7456-01, TC-STORY-7456-13                            | [OK] Covered      |
| AC-05    | Session timeout / logout does not affect already-open help pages; browser session end (close all windows / machine restart) blocks new access | TC-STORY-7456-10, TC-STORY-7456-11 (Scenarios A + B), TC-STORY-7456-12 (Scenario C) | ? Covered      |

---

## Notes and Assumptions

- **AC-05 session timeout testing (TC-10)**: Requires coordination with dev to artificially expire a session in the test environment. If not achievable, this test case is marked as Manual-Only and excluded from automation until a mechanism is available.
- **AC-02a legacy URL (TC-06)**: The specific list of previously public URLs must be confirmed with the development team before execution. At least one URL must be identified that was publicly accessible before this story's implementation.
- **Role accounts**: Three separate test accounts  -  one per role (Admin, User, Support)  -  must be provisioned and available before Stage 3 (Execution) begins.
- **Incognito/private browsing** is required for all negative and redirect tests (TC-04 to TC-09, TC-12) to guarantee a clean unauthenticated state and eliminate cached session interference.
- - **TC-11 and TC-12 -- Three distinct AC-05 scenarios** (all must be tested):
  - **Scenario A** (TC-11 Steps 1-4): Logout -> docs tab still open, no refresh -> docs **still accessible** (AC-05 session live). PASS expected.
  - **Scenario B** (TC-11 Step 5): Logout -> F5 refresh on the **same open tab** -> docs **still accessible** (cookie persists within browser session). PASS expected. Confirmed in STORY-7530 Cycle 1 Step 7.
  - **Scenario C** (TC-12): Logout -> **close all browser windows OR restart machine** -> open new browser -> navigate to docs -> docs **blocked** (browser session ended, session cookie cleared). PASS expected IF ac_docs_auth is a session cookie; raise finding if persistent.
  These three scenarios together fully define the AC-05 boundary. Scenario C must be run manually due to the machine-restart requirement.
- **TC-12** updated 2026-07-22: original TC incorrectly tested F5 refresh as the blocking trigger. Execution evidence from STORY-7530 Cycle 1 Step 7 confirmed F5 in the same browser session does NOT block (cookie persists through hub logout). TC-12 now correctly tests the close-all-windows + machine-restart browser-session-end boundary. TC-12 is Manual-only.- **TC-14** (URL fragment/query preservation) was added following TCR review recommendation RTC-01 to cover edge cases in the AC-03 redirect flow involving query strings and hash fragments.
- **AC-05 PO clarification required** (TC-12, M-04): Before executing TC-12, confirm with PO whether AC-05's "already-open pages remain accessible" applies to browser-cached content only, or whether it also covers page refreshes. This interpretation affects pass/fail for TC-12.
- **Automation note**: TC-10 (session timeout) is marked Partial automation  -  the logout trigger may need a manual setup step. All other test cases are fully automatable via browser automation (Playwright recommended).
- **Review applied**: All 3 high-priority and 4 medium-priority findings from TCR_STORY-7456.md applied on 2026-07-08.
- **[2026-07-21] AC-05 cookie mechanism (TC-10, TC-11, TC-12)**: The `ac_docs_auth` cookie controls documentation page access. Browser cookies can persist even after the computer is restarted or all browser windows are closed. Test sequence: verify cookie existence in Browser DevTools ? Application ? Cookies ? `ac_docs_auth`; test docs access with cookie present (access expected) and after clearing cookie (access should be blocked on next HTTP request). Updated per story Q/N note added 2026-07-21.
- **[2026-07-21] AC-05 PO clarification RESOLVED**: PO confirmed Option B — session persistence applies to already-loaded browser content until the browser session ends (closing all windows, clearing cookies, or restarting). TC-12 expected result validated. See Jira STORY-7456 for full PO response.

---

*Generated by: `test_case_preparation` agent | Updated by: `test_case_preparation` agent (TCR findings applied, TC-14 added) | Story data: STORY-7456  -  2026-07-08*






