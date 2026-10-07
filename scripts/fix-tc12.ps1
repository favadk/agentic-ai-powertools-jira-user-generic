# Fix TC-11 (add Step 5) and rewrite TC-12 in TC_STORY-7456.md
$file = 'c:\Agentic-AI\agentic-ai-powertools-jira-user-new\docs\TestCases\TC_STORY-7456.md'
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

# Find boundaries
$s1 = $content.IndexOf('| 4    | Scroll the already-open help page')
$s2 = $content.IndexOf('### TC-STORY-7456-13')

if ($s1 -lt 0) { Write-Error "TC-11 step 4 not found"; exit 1 }
if ($s2 -lt 0) { Write-Error "TC-13 marker not found"; exit 1 }

Write-Output "s1=$s1  s2=$s2  block_length=$($s2 - $s1)"

$newBlock = @'
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

'@

$newContent = $content.Substring(0, $s1) + $newBlock + $content.Substring($s2)
[System.IO.File]::WriteAllText($file, $newContent, [System.Text.Encoding]::UTF8)
Write-Output "File updated successfully."
Write-Output "New file size: $((Get-Item $file).Length) bytes"
