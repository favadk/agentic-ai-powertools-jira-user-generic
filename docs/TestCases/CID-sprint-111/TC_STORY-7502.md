# Test Cases -- STORY-7502: Consolidate the Registration/Management API to GenericQA domain, end-to-end

> Archived for historical trace only. Current-sprint authoritative document is docs/TestCases/CID-sprint-112/TC_STORY-7502.md.

## Document Information

| Field             | Value                                                                 |
|-------------------|-----------------------------------------------------------------------|
| **Story Key**     | `STORY-7502`                                                           |
| **Story Summary** | Consolidate the Registration/Management API to GenericQA domain, end-to-end |
| **Sprint**        | CID sprint 111                                                        |
| **Prepared By**   | test_case_preparation agent (via create-tc-STORY-7502.ps1)             |
| **Date Prepared** | 2026-08-17                                                                |
| **Status**        | Archived / Superseded by CID-sprint-112 TC document |
| **Xray Test Key** | STORY-7566                    |

---

## Story Acceptance Criteria

> *Verbatim from STORY-7502 Jira story (fetched by create-tc-STORY-7502.ps1).*

- **AC-01**: [Q/N PENDING] A new CID activates and registers using only the new GenericQA-domain registration hostname. No connection to the legacy hostname is required.
- **AC-02**: [Q/N PENDING] An in-field CID (FR1.0 or later) reaches the registration/management API on the new hostname after installing the Linux Update. No manual reconfiguration or re-registration is needed.
- **AC-03**: [Q/N PENDING] The TLS certificate presented on the new hostname is issued under an GenericQA-controlled chain or a public CA bound to the GenericQA domain. It is not a default AWS-managed certificate.
- **AC-04**: The Health Page and the CID Connectivity Tester tests for registration are consolidated to tests to GenericQA.
- **AC-05**: [Q/N PENDING] The online help entry for this endpoint lists the new hostname and the Linux Update version it requires.
- **AC-06**: [Q/N PENDING] The legacy hostname continues to work for CIDs that have not yet installed the Linux Update.
- **AC-07**: Design Notes
- **AC-08**: [Q/N PENDING] Terraform for the custom domain and certificate.
- **AC-09**: [Q/N PENDING] Config update, ac_install.sh, and Linux Update deliver the new hostname to devices.
- **AC-10**: [Q/N PENDING] Do not remove or redirect the legacy endpoint in this story. Retirement is out of scope until fleet adoption is confirmed.
- **AC-11**: [Q/N PENDING] The install-script download URL served to new customers must also move to the new hostname.
- **AC-12**: QA Notes
- **AC-13**: [Q/N PENDING] Activate a factory-fresh CID behind a firewall that allows only the new GenericQA hostname, with the legacy hostname blocked. Registration and activation complete.
- **AC-14**: [Q/N PENDING] Upgrade an FR1.0-era CID via Linux Update. Verify with DNS, packet capture, or CID logs that registration traffic now targets the new hostname, and confirm no fallback connections to the legacy hostname occur.
- **AC-15**: [Q/N PENDING] Regression: a not-yet-updated CID still registers via the legacy hostname.
- **AC-16**: Confirm the Health Page and Connectivity Tester rows are consolidated into GenericQA domain.

---

## Q&N Open Questions

### Q/N-01

> **PENDING**: Hostname matrix required for AC-01, AC-02, AC-05, AC-06, AC-09, AC-10, AC-11, AC-13, AC-14, AC-15. Please confirm exact Registration/Management hostnames by environment (SIT, UAT, PROD) and compatibility expectation (which CID versions should use GenericQA vs legacy hostnames). (Ask: Dev)

### Q/N-02

> **PENDING**: Firmware/version matrix required for AC-02, AC-05, AC-14. Please confirm in-scope CID firmware ranges, Linux Update minimum version, and any version-gated behaviors needed for test data setup. (Ask: Dev)

### Q/N-03

> **PENDING**: TLS/certificate evidence required for AC-03 and AC-08. Please confirm issuing CA chain, expected subject/SAN values for the GenericQA-domain certificate, and whether CID trust-store support is native or Linux Update-dependent. (Ask: Dev)

### Q/N-04

> **PENDING**: Code implementation trace required for AC-08, AC-09, AC-11 and traffic verification ACs. Please share merged PR links or commit SHAs with changed file paths for custom domain/certificate provisioning, config propagation, and install-script URL migration. (Ask: Dev)

> **Action**: Questions posted on Xray Test issue @Tester after Xray issue is created.
> Monitor replies via `scripts/monitor-po-responses.ps1`.

---

## Test Cases

---

### TC-STORY-7502-01

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-01`                                |
| **AC Reference**| AC-01                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-01 [AC-01] [BLOCKED -- Q/N PENDING]: A new CID activates and registers using only the new GenericQA-domain registration hostname. No connection to the legacy hostname is required.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-02

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-02`                                |
| **AC Reference**| AC-02                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-02 [AC-02] [BLOCKED -- Q/N PENDING]: An in-field CID (FR1.0 or later) reaches the registration/management API on the new hostname after installing the Linux Update. No manual reconfiguration or re-registration is needed.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-03

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-03`                                |
| **AC Reference**| AC-03                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-03 [AC-03] [BLOCKED -- Q/N PENDING]: The TLS certificate presented on the new hostname is issued under an GenericQA-controlled chain or a public CA bound to the GenericQA domain. It is not a default AWS-managed certificate.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-04

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-04`                                |
| **AC Reference**| AC-04                                 |
| **Title**       | Happy Path: Verify that the Health Page and the CID Connectivity Tester tests for registration are consolidated to tests to GenericQA. |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | Yes                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | Use SIT/non-prod environment; ensure Registration/Management API new GenericQA hostname is configured                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-04 [AC-04] Happy Path: Verify that the Health Page and the CID Connectivity Tester tests for registration are consolidated to tests to GenericQA.        | The Health Page and the CID Connectivity Tester tests for registration are consolidated to tests to GenericQA.      |

---

### TC-STORY-7502-05

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-05`                                |
| **AC Reference**| AC-05                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-05 [AC-05] [BLOCKED -- Q/N PENDING]: The online help entry for this endpoint lists the new hostname and the Linux Update version it requires.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-06

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-06`                                |
| **AC Reference**| AC-06                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-06 [AC-06] [BLOCKED -- Q/N PENDING]: The legacy hostname continues to work for CIDs that have not yet installed the Linux Update.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-07

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-07`                                |
| **AC Reference**| AC-07                                 |
| **Title**       | Happy Path: Verify that Design Notes |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | Yes                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | Use SIT/non-prod environment; ensure Registration/Management API new GenericQA hostname is configured                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-07 [AC-07] Happy Path: Verify that Design Notes        | Design Notes      |

---

### TC-STORY-7502-08

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-08`                                |
| **AC Reference**| AC-08                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-08 [AC-08] [BLOCKED -- Q/N PENDING]: Terraform for the custom domain and certificate.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-09

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-09`                                |
| **AC Reference**| AC-09                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-09 [AC-09] [BLOCKED -- Q/N PENDING]: Config update, ac_install.sh, and Linux Update deliver the new hostname to devices.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-10

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-10`                                |
| **AC Reference**| AC-10                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-10 [AC-10] [BLOCKED -- Q/N PENDING]: Do not remove or redirect the legacy endpoint in this story. Retirement is out of scope until fleet adoption is confirmed.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-11

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-11`                                |
| **AC Reference**| AC-11                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-11 [AC-11] [BLOCKED -- Q/N PENDING]: The install-script download URL served to new customers must also move to the new hostname.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-12

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-12`                                |
| **AC Reference**| AC-12                                 |
| **Title**       | Happy Path: Verify that QA Notes |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | Yes                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | Use SIT/non-prod environment; ensure Registration/Management API new GenericQA hostname is configured                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-12 [AC-12] Happy Path: Verify that QA Notes        | QA Notes      |

---

### TC-STORY-7502-13

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-13`                                |
| **AC Reference**| AC-13                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-13 [AC-13] [BLOCKED -- Q/N PENDING]: Activate a factory-fresh CID behind a firewall that allows only the new GenericQA hostname, with the legacy hostname blocked. Registration and activation complete.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-14

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-14`                                |
| **AC Reference**| AC-14                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-14 [AC-14] [BLOCKED -- Q/N PENDING]: Upgrade an FR1.0-era CID via Linux Update. Verify with DNS, packet capture, or CID logs that registration traffic now targets the new hostname, and confirm no fallback connections to the legacy hostname occur.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-15

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-15`                                |
| **AC Reference**| AC-15                                 |
| **Title**       | (BLOCKED -- Q/N pending) |
| **Type**        | Regression                                  |
| **Priority**    | High                                   |
| **Automation**  | No (blocked)                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | BLOCKED -- see Q/N list; test data to be confirmed                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-15 [AC-15] [BLOCKED -- Q/N PENDING]: Regression: a not-yet-updated CID still registers via the legacy hostname.        | BLOCKED -- expected result depends on Q/N resolution      |

> **BLOCKED**: This test step cannot be finalised until Q/N above is resolved.
> Expected result depends on pending Q/N response. Mark as `UNCONFIRMED` in Xray until resolved.

---

### TC-STORY-7502-16

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-16`                                |
| **AC Reference**| AC-16                                 |
| **Title**       | Happy Path: Verify that Confirm the Health Page and Connectivity Tester rows are consolidated into GenericQA domain. |
| **Type**        | Happy Path                                  |
| **Priority**    | High                                   |
| **Automation**  | Yes                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | Use SIT/non-prod environment; ensure Registration/Management API new GenericQA hostname is configured                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-16 [AC-16] Happy Path: Verify that Confirm the Health Page and Connectivity Tester rows are consolidated into GenericQA domain.        | Confirm the Health Page and Connectivity Tester rows are consolidated into GenericQA domain.      |

---

### TC-STORY-7502-17

| Field           | Value                                  |
|-----------------|----------------------------------------|
| **TC ID**       | `TC-STORY-7502-17`                                |
| **AC Reference**| N/A                                 |
| **Title**       | TC-STORY-7502-E2E [All ACs]: End-to-end smoke -- CID registers and connects via new GenericQA domain hostname |
| **Type**        | Happy Path -- End-to-End                                  |
| **Priority**    | High                                   |
| **Automation**  | Partial                            |

**Prerequisites**

- Admin or SRE user account with access to the test environment
- Registration/Management API new GenericQA hostname configured in SIT/non-prod
- CID device (FR1.0+) available for connectivity testing

**Test Data**

| Field              | Value                                                                      |
|--------------------|----------------------------------------------------------------------------|
| Story              | STORY-7502                                                                  |
| Environment        | SIT / non-prod                                                             |
| Test input         | CID device (FR1.0+ firmware); new GenericQA FQDN for Registration/Management API (see Q/N if unconfirmed)                                                              |

**Steps**

| Step | Action                                   | Expected Result                          |
|------|------------------------------------------|------------------------------------------|
| 1    | TC-STORY-7502-E2E [All ACs]: End-to-end smoke -- CID registers and connects via new GenericQA domain hostname        | CID device registers successfully via the new GenericQA-domain hostname. No TLS errors. Activity log records the connection. Existing CIDs not yet updated continue to work via legacy hostname.      |

---

## AC Coverage Matrix

| AC Item | Description (brief)                                          | TC IDs Covering It       | Coverage Status |
|---------|--------------------------------------------------------------|--------------------------|-----------------|
| AC-01   | A new CID activates and registers using only the new GenericQA-domain registrat... | TC-STORY-7502-01 | Covered (Q/N pending) |
| AC-02   | An in-field CID (FR1.0 or later) reaches the registration/management API on t... | TC-STORY-7502-02 | Covered (Q/N pending) |
| AC-03   | The TLS certificate presented on the new hostname is issued under an GenericQA-... | TC-STORY-7502-03 | Covered (Q/N pending) |
| AC-04   | The Health Page and the CID Connectivity Tester tests for registration are co... | TC-STORY-7502-04 | Covered |
| AC-05   | The online help entry for this endpoint lists the new hostname and the Linux ... | TC-STORY-7502-05 | Covered (Q/N pending) |
| AC-06   | The legacy hostname continues to work for CIDs that have not yet installed th... | TC-STORY-7502-06 | Covered (Q/N pending) |
| AC-07   | Design Notes | TC-STORY-7502-07 | Covered |
| AC-08   | Terraform for the custom domain and certificate. | TC-STORY-7502-08 | Covered (Q/N pending) |
| AC-09   | Config update, ac_install.sh, and Linux Update deliver the new hostname to de... | TC-STORY-7502-09 | Covered (Q/N pending) |
| AC-10   | Do not remove or redirect the legacy endpoint in this story. Retirement is ou... | TC-STORY-7502-10 | Covered (Q/N pending) |
| AC-11   | The install-script download URL served to new customers must also move to the... | TC-STORY-7502-11 | Covered (Q/N pending) |
| AC-12   | QA Notes | TC-STORY-7502-12 | Covered |
| AC-13   | Activate a factory-fresh CID behind a firewall that allows only the new Agile... | TC-STORY-7502-13 | Covered (Q/N pending) |
| AC-14   | Upgrade an FR1.0-era CID via Linux Update. Verify with DNS, packet capture, o... | TC-STORY-7502-14 | Covered (Q/N pending) |
| AC-15   | Regression: a not-yet-updated CID still registers via the legacy hostname. | TC-STORY-7502-15 | Covered (Q/N pending) |
| AC-16   | Confirm the Health Page and Connectivity Tester rows are consolidated into Ag... | TC-STORY-7502-16 | Covered |

---

## Notes and Assumptions

- This TC was auto-generated by `create-tc-STORY-7502.ps1` from the story's AC text.
- All test steps require human QA review before execution -- the automation script generates the structure; a QA engineer should verify expected results align with the implemented behaviour.
- "New GenericQA hostname" refers to the FQDN selected during the STORY-7501 spike (expected: `*.cid.GenericQA.com` or similar). Confirm exact FQDN with the Dev team (Q/N above).
- Backward-compatibility steps assume FR1.0+ CID firmware. Confirm trust-store impact with Dev (STORY-7501 spike findings).
- Sprint TE: to be populated by sprint TE linking step in this script.




