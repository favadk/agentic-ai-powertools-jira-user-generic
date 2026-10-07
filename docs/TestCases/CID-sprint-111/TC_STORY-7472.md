# Test Cases

**Quality Assurance - Defect Regression Test Document**

## Test Cases for `STORY-7472`

## Document Information

| **Filename**      | TC_STORY-7472.md                                                                              |
|-------------------|----------------------------------------------------------------------------------------------|
| **Defect Key**    | `STORY-7472`                                                                                  |
| **Summary**       | 1439631 - Invalid CID FQDN incorrectly appends DNS search list when attempting to resolve   |
| **Sprint**        | CID sprint 111                                                                               |
| **Prepared By**   | test_case_preparation agent (Mode D - Defect Regression)                                     |
| **Date Prepared** | 2026-07-29                                                                                   |
| **Status**        | Draft                                                                                        |
| **Xray Test Key** | *(pending - create via `New-XrayTest` in xray-api.ps1)*                                     |

---

## Defect Summary

| Field | Value |
|---|---|
| **Defect Key** | `STORY-7472` |
| **Steps to Reproduce** | See TC-STORY-7472-01 |
| **Actual Result (bug)** | CID tries to resolve `sr-demo-cid.blahblah.com.openlabqa.org` â€” it incorrectly appends the DNS search list to a dotted FQDN. |
| **Expected Result (fix)** | CID should attempt to resolve `sr-demo-cid.blahblah.com` as-is and report failure â€” no DNS search list appended to a name that already contains dots. |
| **Root Cause** | CID resolution logic does not check whether the FQDN already contains a dot before appending the DNS search list. A dotted name is already fully qualified and must not receive search-list expansion. |
| **Environment** | Domain: openlabqa.org; Server: sr-ecmxt28.openl.org; CID FQDN: sr-demo-cid.blahblah.com |
| **Fix Version** | CID sprint 111 |

---

## Test Cases

---

### TC-STORY-7472-01  -  Bug Reproduction: Dotted FQDN incorrectly receives DNS search list (verbatim repro)

| Field           | Value                        |
|-----------------|------------------------------|
| **TC ID**       | TC-STORY-7472-01              |

| **Title**       | Dotted FQDN must not receive DNS search list append |
| **Type**        | Regression                   |
| **Priority**    | High                         |
| **Automation**  | Partial                      |

**Prerequisites**

- CID is provisioned and configured in a test environment.
- Domain: `openlabqa.org`
- Server: `http://sr-ecmxt28.openl.org` (configured as per defect repro â€” incorrectly set up server)
- CID hostname: `sr-demo-cid`
- CID FQDN set to: `sr-demo-cid.blahblah.com` (dotted â€” multi-label name)
- Access to the Recent Activities (RA) log in the CID management UI.

**Test Data**

| Field        | Value                          |
|--------------|--------------------------------|
| CID Hostname | `sr-demo-cid`                  |
| CID FQDN     | `sr-demo-cid.blahblah.com`     |
| Domain       | `openlabqa.org`                |
| Server URL   | `http://sr-ecmxt28.openl.org`  |

**Steps**

| Step | Action                                                                                          | Expected Result                                                                                                         |
|------|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| 1    | Log in to the CID management interface and navigate to the CID configuration for `sr-demo-cid`. | CID configuration page is displayed. FQDN field shows `sr-demo-cid.blahblah.com`.                                      |
| 2    | Confirm the CID FQDN is set to `sr-demo-cid.blahblah.com` and save/apply the configuration.    | Configuration is accepted without error.                                                                                |
| 3    | Activate the CID (trigger activation workflow).                                                 | CID activation process initiates.                                                                                       |
| 4    | Navigate to the Recent Activities (RA) log in the management interface.                         | RA log is displayed showing CID resolution attempt entries.                                                             |
| 5    | Inspect the DNS resolution attempt string logged for `sr-demo-cid.blahblah.com`.               | RA log shows the resolution string as exactly `sr-demo-cid.blahblah.com` â€” NO domain suffix (e.g. `.openlabqa.org`) appended. |
| 6    | Confirm the resolution attempt results in a failure/error (not a successful resolution).        | RA log shows a resolution failure for `sr-demo-cid.blahblah.com` â€” error is reported cleanly, no crash occurs.        |

---

### TC-STORY-7472-02 â€” Positive: Bare hostname (no dots) correctly receives DNS search list append

| Field           | Value                        |
|-----------------|------------------------------|
| **TC ID**       | TC-STORY-7472-02              |

| **Title**       | Bare hostname correctly receives DNS search list append |
| **Type**        | Happy Path                   |
| **Priority**    | High                         |
| **Automation**  | Partial                      |

**Prerequisites**

- CID is provisioned in a test environment with a valid server and domain configuration.
- Domain: `openlabqa.org`
- CID hostname configured as a bare name with no dots.
- Access to the Recent Activities (RA) log.

**Test Data**

| Field        | Value               |
|--------------|---------------------|
| CID Hostname | `sr-demo-cid`       |
| CID FQDN     | `sr-demo-cid` (no dots â€” bare hostname) |
| Domain       | `openlabqa.org`     |

**Steps**

| Step | Action                                                                                          | Expected Result                                                                                            |
|------|-------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| 1    | Log in to the CID management interface and navigate to the CID configuration.                   | CID configuration page is displayed.                                                                       |
| 2    | Set the CID FQDN/hostname to `sr-demo-cid` (bare name, no dots) and save the configuration.    | Configuration saved successfully.                                                                          |
| 3    | Activate the CID (trigger activation workflow).                                                 | CID activation process initiates.                                                                          |
| 4    | Navigate to the Recent Activities (RA) log.                                                     | RA log is displayed.                                                                                       |
| 5    | Inspect the DNS resolution attempt string logged for `sr-demo-cid`.                            | RA log shows the resolution string as `sr-demo-cid.openlabqa.org` â€” DNS search list domain IS appended to the bare hostname (correct behaviour). |
| 6    | Confirm whether resolution succeeds or fails gracefully.                                        | Resolution attempt is made against the appended FQDN; result (success or failure) is reported cleanly in RA log without crash. |

---

### TC-STORY-7472-03 â€” Boundary: Absolute FQDN ending with trailing dot must not receive DNS search list append

| Field           | Value                        |
|-----------------|------------------------------|
| **TC ID**       | TC-STORY-7472-03              |

| **Title**       | Absolute FQDN (trailing dot) must not receive DNS search list append |
| **Type**        | Boundary                     |
| **Priority**    | Medium                       |
| **Automation**  | No                           |

**Prerequisites**

- CID is provisioned in a test environment.
- Domain: `openlabqa.org`
- CID FQDN configured with a trailing dot to indicate an absolute/fully-qualified name.
- Access to the Recent Activities (RA) log.

**Test Data**

| Field        | Value                           |
|--------------|---------------------------------|
| CID FQDN     | `sr-demo-cid.blahblah.com.`    |
| Domain       | `openlabqa.org`                 |

**Steps**

| Step | Action                                                                                               | Expected Result                                                                                                                          |
|------|------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| 1    | Log in to the CID management interface and navigate to the CID configuration.                        | CID configuration page is displayed.                                                                                                     |
| 2    | Set the CID FQDN to `sr-demo-cid.blahblah.com.` (note the trailing dot) and save.                  | Configuration saved (or system strips trailing dot and preserves as FQDN â€” record observed behaviour).                                  |
| 3    | Activate the CID.                                                                                    | CID activation process initiates.                                                                                                        |
| 4    | Navigate to the Recent Activities (RA) log.                                                          | RA log is displayed.                                                                                                                     |
| 5    | Inspect the DNS resolution attempt string logged.                                                    | RA log shows the resolution string as `sr-demo-cid.blahblah.com` or `sr-demo-cid.blahblah.com.` â€” DNS search list domain is NOT appended. |
| 6    | Confirm the resolution attempt results in a clean failure or success without appended search suffix. | No `.openlabqa.org` suffix (or any other search-list domain) appears appended to the resolution string in the log.                      |

---

### TC-STORY-7472-04 â€” Boundary: Single-dot hostname edge case

| Field           | Value                        |
|-----------------|------------------------------|
| **TC ID**       | TC-STORY-7472-04              |

| **Title**       | Single-label name with exactly one dot â€” search list must not be appended |
| **Type**        | Boundary                     |
| **Priority**    | Medium                       |
| **Automation**  | No                           |

**Prerequisites**

- CID is provisioned in a test environment.
- Domain: `openlabqa.org`
- Access to the Recent Activities (RA) log.

**Test Data**

| Field        | Value                |
|--------------|----------------------|
| CID FQDN     | `sr-demo-cid.com`    |
| Domain       | `openlabqa.org`      |

**Steps**

| Step | Action                                                                                              | Expected Result                                                                                                  |
|------|-----------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| 1    | Log in to the CID management interface and navigate to the CID configuration.                       | CID configuration page is displayed.                                                                             |
| 2    | Set the CID FQDN to `sr-demo-cid.com` (contains exactly one dot) and save.                        | Configuration saved successfully.                                                                                |
| 3    | Activate the CID.                                                                                   | CID activation process initiates.                                                                                |
| 4    | Navigate to the Recent Activities (RA) log.                                                         | RA log is displayed.                                                                                             |
| 5    | Inspect the DNS resolution attempt string for `sr-demo-cid.com`.                                  | RA log shows the resolution attempted as exactly `sr-demo-cid.com` â€” no DNS search list domain appended.        |

---

### TC-STORY-7472-05 â€” Negative: Entirely invalid/unparseable FQDN results in graceful failure

| Field           | Value                        |
|-----------------|------------------------------|
| **TC ID**       | TC-STORY-7472-05              |

| **Title**       | Invalid unparseable FQDN results in graceful failure with no crash |
| **Type**        | Negative                     |
| **Priority**    | High                         |
| **Automation**  | No                           |

**Prerequisites**

- CID is provisioned in a test environment.
- Domain: `openlabqa.org`
- Access to the Recent Activities (RA) log and CID service logs.

**Test Data**

| Field        | Value                              |
|--------------|------------------------------------|
| CID FQDN     | `!!!invalid--fqdn##.blah..com`     |
| Domain       | `openlabqa.org`                    |

**Steps**

| Step | Action                                                                                             | Expected Result                                                                                                     |
|------|----------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| 1    | Log in to the CID management interface and navigate to the CID configuration.                      | CID configuration page is displayed.                                                                               |
| 2    | Set the CID FQDN to `!!!invalid--fqdn##.blah..com` (malformed, unparseable value) and attempt to save. | System either rejects the value at input with a validation error, OR saves it and handles it at activation time.   |
| 3    | If saved: activate the CID.                                                                        | CID activation proceeds without crashing the service.                                                              |
| 4    | Navigate to the Recent Activities (RA) log.                                                        | RA log is accessible and shows a resolution failure entry.                                                         |
| 5    | Inspect the RA log entry for the invalid FQDN.                                                     | RA log shows: resolution failed for the provided FQDN. No DNS search list domain is appended. No unhandled exception or crash is recorded in the service logs. |

---

### TC-STORY-7472-06 â€” Regression: Original bug scenario â€” full repro confirms fix

| Field           | Value                        |
|-----------------|------------------------------|
| **TC ID**       | TC-STORY-7472-06              |

| **Title**       | Full original bug repro confirms fix â€” no appended domain in RA log |
| **Type**        | Regression                   |
| **Priority**    | High                         |
| **Automation**  | Partial                      |

**Prerequisites**

- Fixed CID build deployed to test environment.
- Exact configuration from defect report:
  - Domain: `openlabqa.org`
  - Server: `http://sr-ecmxt28.openl.org` (incorrectly configured server â€” matches defect repro)
  - CID hostname: `sr-demo-cid`
  - CID FQDN: `sr-demo-cid.blahblah.com`
- Access to the Recent Activities (RA) log.

**Test Data**

| Field        | Value                          |
|--------------|--------------------------------|
| Domain       | `openlabqa.org`                |
| Server URL   | `http://sr-ecmxt28.openl.org`  |
| CID Hostname | `sr-demo-cid`                  |
| CID FQDN     | `sr-demo-cid.blahblah.com`     |

**Steps**

| Step | Action                                                                                                       | Expected Result                                                                                                                       |
|------|--------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| 1    | Deploy the fixed CID build to the test environment.                                                          | Deployment succeeds. CID service starts without error.                                                                                |
| 2    | Configure the CID with exactly the defect repro values: Domain `openlabqa.org`, Server `http://sr-ecmxt28.openl.org`, FQDN `sr-demo-cid.blahblah.com`. | Configuration saved successfully.                                                                               |
| 3    | Activate the CID.                                                                                            | CID activation process initiates.                                                                                                     |
| 4    | Navigate to the Recent Activities (RA) log.                                                                  | RA log is displayed with CID resolution attempt entries.                                                                              |
| 5    | Search the RA log for any entry containing `sr-demo-cid.blahblah.com.openlabqa.org`.                       | **No entry** exists containing `sr-demo-cid.blahblah.com.openlabqa.org`. The incorrectly appended form MUST NOT appear.              |
| 6    | Confirm the RA log entry for the resolution attempt shows only `sr-demo-cid.blahblah.com`.                 | RA log shows: resolution attempted for `sr-demo-cid.blahblah.com` â€” resolution fails cleanly (name not found / connection refused). No appended suffix present. |
| 7    | Check CID service logs for any crash, unhandled exception, or stack trace.                                  | No crash, no unhandled exception. Service remains running and stable after the failed resolution.                                     |

---

### TC-STORY-7472-07 â€” Regression: Adjacent DNS search list append behaviour unaffected by fix

| Field           | Value                        |
|-----------------|------------------------------|
| **TC ID**       | TC-STORY-7472-07              |

| **Title**       | DNS search list append for bare hostnames still works correctly after fix |
| **Type**        | Regression                   |
| **Priority**    | Medium                       |
| **Automation**  | Partial                      |

**Prerequisites**

- Fixed CID build deployed to test environment.
- CID configured with a known-good bare hostname (no dots).
- Domain: `openlabqa.org`
- Access to the Recent Activities (RA) log.

**Test Data**

| Field        | Value               |
|--------------|---------------------|
| CID Hostname | `sr-test-cid`       |
| CID FQDN     | `sr-test-cid` (bare hostname â€” no dots) |
| Domain       | `openlabqa.org`     |

**Steps**

| Step | Action                                                                                              | Expected Result                                                                                                            |
|------|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| 1    | On the fixed CID build, configure a CID with bare hostname `sr-test-cid` (no dots) and domain `openlabqa.org`. | Configuration saved successfully.                                                                                 |
| 2    | Activate the CID.                                                                                   | CID activation process initiates.                                                                                          |
| 3    | Navigate to the Recent Activities (RA) log.                                                         | RA log is displayed.                                                                                                       |
| 4    | Inspect the DNS resolution attempt string logged for `sr-test-cid`.                                | RA log shows the resolution attempted as `sr-test-cid.openlabqa.org` â€” DNS search list IS appended to the bare hostname. Fix has not broken the existing append behaviour. |

---
## Open Questions (Q&N Gate  -  Pending Responses)

> These questions were identified retroactively. TC authoring proceeded under accepted-risk. Post Q&N Jira comments on STORY-7472 before scheduling execution.

| Q/N # | Question | Ask | Blocks |
|---|---|---|---|
| Q/N-01 | The defect description says "See the MD file for regression and fix test scenarios"  -  this file was not attached or found. Where is it? It may contain an authoritative regression spec that conflicts with or supersedes these TCs. | Dev / PO | TC-01 through TC-07 may need revision |
| Q/N-02 | Does the fix use "any dot = fully qualified" (RFC 1535 standard), or a specific `ndots` threshold from `/etc/resolv.conf`? | Dev | TC-04 boundary condition  -  single-label name with one dot |
| Q/N-03 | Does the CID UI strip a trailing dot from the FQDN on save? If so, TC-03 (absolute FQDN with trailing dot) may not be testable via the UI and requires a direct config edit. | Dev | TC-03 testability |

**Status**: ⚠️ UNCONFIRMED  -  Jira Q&N comments not yet posted. Post manually on STORY-7472 @mentioning the Dev assignee for all three questions.

---

## Test Coverage

> Defect regression tests (Mode D)  -  coverage mapped to bug scenario, not ACs. See Defect Summary for traceability.


