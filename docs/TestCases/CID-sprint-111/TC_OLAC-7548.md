# Test Cases

**Quality Assurance — Test Case Document**

## Test Cases for `OLAC-7548`

---

## Document Information

| **Filename**      | TC_OLAC-7548.md                                        |
|-------------------|--------------------------------------------------------|
| **Story Key**     | `OLAC-7548`                                            |
| **Story Summary** | [CPE] Release Aug'26 Windows Update                    |
| **Sprint**        | CID sprint 111                                         |
| **Prepared By**   | automation_code_preparation agent                      |
| **Date Prepared** | 2026-08-11                                             |
| **Status**        | Ready to Run                                           |
| **Xray Test Key** | `OLAC-6457`                                            |
| **Spec File**     | `Tests/Story tests/OLAC-6457.spec.js`                  |

---

## Story Acceptance Criteria

- **AC-01**: User can **select** and **apply** the current month's (August 2026) Windows security update on their CIDs.
- **AC-02**: User **cannot** select any previous month's Windows update.

---

## ⚠️ Test Execution — Required Data

> **Tester action required**: Fill in all fields in the table below.
> Once complete, the automation agent will detect this update and run the tests automatically.

| # | Parameter | Required | Value (fill in) | Notes |
|---|-----------|----------|-----------------|-------|
| 1 | `IP_ADDRESS` | ✅ Yes | `130.27.137.48;130.27.139.78` | Two CID VM IPs (semicolon-separated) |
| 2 | `OLS_NAME` | ✅ Yes | `scs-perfPhy-SRV.scs.GenericQA.com` | OLS registered under SID-QA-WAD-Automation |
| 3 | `BASE_URL` | ✅ Yes | `https://hub.tst-51.aws.GenericQA.com` | Windows update tests run on tst-51 |
| 4 | `JENKINS_USER` | ⚠️ If no IP_ADDRESS | _(Jenkins NT username)_ | Required only when IP_ADDRESS is not provided |
| 5 | `JENKINS_TOKEN` | ⚠️ If no IP_ADDRESS | _(Jenkins API token)_ | Required only when IP_ADDRESS is not provided |
| 6 | `KB_WIN10` | ✅ Yes | `KB5120249` | Windows 10 21H2 — Aug'26 Patch Tuesday KB |
| 7 | `KB_WIN11` | ✅ Yes | `KB5121003` | Windows 11 24H2 — Aug'26 Patch Tuesday KB |

> **How to trigger the automated run**: Update `softwareManager.js` `kbArticles` with the real KB IDs from rows 6 and 7, then add a comment to this document in the format:
>
> ```
> READY_TO_RUN
> IP_ADDRESS=<value>
> OLS_NAME=<value>
> BASE_URL=<value>
> KB_WIN10=<value>
> KB_WIN11=<value>
> ```
>
> The automation agent monitors this document and will pick up the `READY_TO_RUN` marker and execute the test immediately.

---

## Test Implementation

**Test file:** `Tests/Story tests/OLAC-6457.spec.js`
**Branch:** `windows-olac-6457-new-release-fix-latest` (or `release-FR1.3.2`)
**Runner:** Jenkins job `ac_portal_e2e` on `scs-jenkins-5.scs.GenericQA.com`
**Suite param:** `CONF=storyTests` + `SPEC=./Tests/Story tests/OLAC-5808.spec.js`

### What the test verifies

| TC | Description | Automation |
|----|-------------|-----------|
| TC-01 | Aug'26 Windows update (`2026.08.1021H2.1` / `2026.08.1124H2.1`) appears in Software Library | ✅ Automated |
| TC-02 | Software Library shows only the **latest** update (no previous months available) | ✅ Automated |
| TC-03 | OLS Change modal — for a fresh OLS, only Aug'26 is selectable | ✅ Automated |
| TC-04 | OLS Change modal — for pre-existing OLS, shows [pre-installed + Aug'26] | ✅ Automated |
| TC-05 | CID1 installed **before** update → does **not** have Aug'26 KB installed on Windows VM | ✅ Automated |
| TC-06 | CID2 installed **after** update → **does** have Aug'26 KB installed on Windows VM | ✅ Automated |
| TC-07 | Downgrade scenario — Aug'26 update can be rolled back | ✅ Automated |

### SoftwareManager changes already applied

The following changes have been committed to `release-FR1.3.2` and `windows-olac-6457-new-release-fix-latest`:

- `softwareVersions[windows]`: added `23: '2026.08.1021H2.1'`, `24: '2026.08.1124H2.1'`
- `softwareDependencies[windows]`: updated CDS 1–11 to `[pre-installed, Aug'26]`
- `softwareVersionsReleaseDates`: added `2026-08-11 07:00:00+00:00` for both variants
- `kbArticles`: placeholders `KB_TBD_AUG26_WIN10` / `KB_TBD_AUG26_WIN11` — **replace with real KB IDs** (row 6/7 above)
- `releaseNotesLinkOnS3Bucket`: added win10 and win11 Aug'26 PDF paths

### Run command (local)

```powershell
cd C:\automation\06102026\UI_Protractor_Tests

$env:BASE_URL    = "https://hub.tst-51.aws.GenericQA.com"
$env:IP_ADDRESS  = "130.27.137.48;130.27.139.78"
$env:OLS_NAME    = "scs-perfPhy-SRV.scs.GenericQA.com"

npx protractor test.conf.js --specs "Tests/Story tests/OLAC-6457.spec.js"
```

### Run command (Jenkins)

Trigger job `ac_portal_e2e` on `scs-jenkins-5.scs.GenericQA.com` with:

| Jenkins Param | Value |
|---------------|-------|
| `BRANCH` | `release-FR1.3.2` |
| `CONF` | `storyTests` |
| `SPEC` | `./Tests/Story tests/OLAC-6457.spec.js` |
| `BASE_URL` | `https://hub.tst-51.aws.GenericQA.com` |
| `IP_ADDRESS` | _two CID VM IPs_ |
| `OLS_NAME` | _OLS FQDN_ |

---

## Test Execution Results

> _To be filled after test run._

| Run | Date | Result | Notes |
|-----|------|--------|-------|
| Cycle 1 | — | ⏳ Pending | Waiting for test data (see Required Data section above) |
