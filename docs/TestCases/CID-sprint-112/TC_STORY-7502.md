# Test Cases -- STORY-7502: Consolidate the Registration/Management API to GenericQA domain (Sprint 112)

## Document Information

| Field | Value |
| --- | --- |
| Story Key | STORY-7502 |
| Story Summary | Consolidate the Registration/Management API to GenericQA domain, end-to-end |
| Sprint | CID Sprint 112 |
| Prepared By | test_case_preparation agent |
| Date Updated | 2026-08-31 |
| Status | Updated - portal hostname verification and FR1.4+ agent baseline synchronized to Xray |
| Xray Test Key | STORY-7566 |

---

## Sprint 112 Reference Baseline

This document is the authoritative STORY-7502 test reference for Sprint 112.

Reference points used in this document:

1. Story source: Jira issue STORY-7502 Acceptance Criteria and Q/N only
2. QA plan: docs/QAPlan/QAP_STORY-7502.md
3. Xray test: STORY-7566
4. CID Hub Home (stg-51): [https://hub.stg-51.aws.GenericQA.com/home](https://hub.stg-51.aws.GenericQA.com/home)
5. CID Help Documentation (stg-51): [https://hub.stg-51.aws.GenericQA.com/docs/](https://hub.stg-51.aws.GenericQA.com/docs/)
6. Jira Development evidence: `SID/ac_aws` commits `5d4e9253fe691c516d742f66aa9f8ee43a615277` and `8a13396e8874dec9da1f098b0001bf9527519600`
7. QA portal evidence: authenticated CID Management Portal screenshot, 2026-08-19

Only current-sprint artifacts are used for Sprint 112 tracking in this file.

Scope boundaries for test preparation:

- Cover only story Acceptance Criteria and Q/N items; exclude Design Note-only coverage.
- Cite the CID docs URL and section for each registration-link or expected-behavior assertion.
- Do not derive behavior from Design Notes or QA Notes.
- Use the Portal page API URL fields to verify the configured `hub` environment hostnames.
- CID Hub Home redirects to Cognito login in this environment. The CID Help Documentation introduction page was reviewed previously but does not establish registration, management API, Linux Update, TLS, Health Page, or Connectivity Tester behavior. No section-level product-behavior evidence is currently available.

## 0) CID Help Documentation Evidence

| URL | Access / section evidence | Result | Test impact |
| --- | --- | --- | --- |
| [CID Help Documentation](https://hub.stg-51.aws.GenericQA.com/docs/) | Introduction page only; no section covering Registration/Management API hostname migration, Linux Update, TLS, Health Page, or CID Connectivity Tester was available in the recorded review | Insufficient authority for product-behavior assertions | TC-01 through TC-06 remain evidence-blocked except for verbatim AC checks |
| [CID Hub Home](https://hub.stg-51.aws.GenericQA.com/home) | Redirects to Cognito login | Restricted | Cannot support home-page-specific assertions |

The authenticated portal screenshot shows the current legacy `hub` values as `https://hub-ac-management-api.stg-51.aws.GenericQA.com` and `https://hub-ac-registration-api.stg-51.aws.GenericQA.com`. The revised portal verification expects the corresponding `stg-51.cid.GenericQA.com` hostnames.

Required accessible Help evidence: direct URL and section heading for the endpoint hostname, required Linux Update version, and Health Page/Connectivity Tester registration behavior.

---

## 0.1) Verified Development Evidence

The Jira Development section links six `SID/ac_aws` commits. The following source evidence is directly applicable to staging:

| Commit / Source | Verified fact | AC impact |
| --- | --- | --- |
| `8a13396e887` - `ac_ops/terraform/environments/hub-stg-51/hub-stg-51.tf` | Staging uses `stg.cid.GenericQA.com` as the delegated public Route 53 subzone and wires registration and management URL prefixes from `cid_api_domains`. | AC-01, AC-02, AC-03, AC-06 |
| `8a13396e887` - `ac_ops/terraform/modules/cid_api_domains/cid_api_domains.tf` | New staging API hosts are `stg-registration-api.stg.cid.GenericQA.com` and `stg-management-api.stg.cid.GenericQA.com`. | AC-01, AC-02, AC-06 |
| `8a13396e887` - `cid_api_domains.tf` | Both custom domains map to the same existing Zappa REST API and environment stage; legacy Zappa domains are explicitly untouched and remain backward compatible. | AC-01, AC-02, AC-06 |
| `8a13396e887` - `cid_api_domains.tf` | A DNS-validated wildcard ACM certificate for `*.stg.cid.GenericQA.com` is created in `us-east-1` and assigned to EDGE API Gateway custom domains. The code does not identify the public issuer or CID trust-store behavior. | AC-03 |
| `5d4e9253fe6` / `8a13396e887` | Custom-domain rollout is implemented in Terraform for staging and other environments. No linked source establishes Linux Update behavior, Health Page/Connectivity Tester behavior, or Help content. | Q/N-03; AC-04; AC-05 |
| QA portal screenshot, 2026-08-19 | CID Management Portal displays Management API URL and Registration API URL fields for environment `hub`. | AC-01, AC-02, AC-04 |

---

## 1) Acceptance Criteria Coverage

| AC ID | Acceptance Criteria Summary | Covered By Xray Step | Coverage Status |
| --- | --- | --- | --- |
| AC-01 | New CID activates/registers using only new GenericQA hostname | TC-STORY-7502-01 | Portal verification ready: registration hostname specified |
| AC-02 | In-field FR1.0+ CID reaches new hostname after Linux Update with no manual re-registration | TC-STORY-7502-02 | Portal verification ready for FR1.4 released agents and above |
| AC-03 | TLS cert on new hostname is GenericQA-controlled/public CA for GenericQA domain, not default AWS cert | TC-STORY-7502-03 | Partially evidenced: DNS-validated ACM wildcard and EDGE domain verified; issuer/trust-store evidence missing |
| AC-04 | Health Page and CID Connectivity Tester registration checks consolidated to GenericQA domain | TC-STORY-7502-04 | Blocked: Help section and exact UI behavior missing |
| AC-05 | Online help lists new hostname and required Linux Update version | TC-STORY-7502-05 | Blocked: target help section and values missing |
| AC-06 | Legacy hostname continues for CIDs not yet Linux-updated | TC-STORY-7502-06 | Partially evidenced: legacy Zappa domains are retained; device/version evidence missing |

No E2E smoke case is included: it would require unverified endpoint, certificate, version, and traffic behavior.

---

## 2) Q/N Coverage And Status

Open questions are limited to missing implementation evidence and environment-specific validation inputs.

| Q/N ID | Question | Target Owner | Status |
| --- | --- | --- | --- |
| Q/N-01 | Provide API inventory with method/path and old to new hostname mapping for registration/management and install-script URL | Dev | Partially answered: staging registration and management hosts plus same-API mapping verified; request paths and install-script URL remain open |
| Q/N-02 | Provide TLS chain details for new hostname (issuer, SAN, trust-store expectations) | Dev | Partially answered: DNS-validated wildcard ACM certificate covers `*.stg.cid.GenericQA.com`; issuer and CID trust-store expectations remain open |
| Q/N-03 | Provide Linux Update/version matrix by environment (SIT/UAT/PROD) for hostname rollout | Dev | Partially answered: PO confirmed FR1.4 deployed to `CID-HUB-TST-51` with commit `6d6bfcc8`; cross-environment matrix details remain open |
| Q/N-04 | Provide merged PR links/commit SHAs with changed files mapped to AC coverage | Dev | Partially answered: commits `5d4e9253fe6`, `14e6e3041fd`, and `8a13396e887` map Terraform custom-domain changes to AC-01, AC-02, AC-03, and AC-06; no linked source maps AC-04 or AC-05 |

---

## 3) Reworked Test Cases (AC/Q/N Only)

Each expected result below is limited to the corresponding Jira acceptance criterion. The action is blocked wherever product Help section evidence or a Q/N response is needed to make it executable.

### TC-STORY-7502-01 - New CID registration uses the new GenericQA hostname

| Field | Value |
| --- | --- |
| AC / QN | AC-01; Q/N-01; Q/N-04 |
| Status | READY FOR PORTAL VERIFICATION |
| Action | Sign in to CID Management Portal and open the Portal page for environment `hub`. Read the Registration API URL field. |
| Test Data | Portal page > Registration API > Environment Name: `hub`. Example legacy value shown in the QA screenshot: `https://hub-ac-registration-api.stg-51.aws.GenericQA.com`. Expected replacement: `https://hub-ac-registration-api.stg-51.cid.GenericQA.com`. |
| Expected Result | Registration API URL is `https://hub-ac-registration-api.stg-51.cid.GenericQA.com`; it no longer uses the `stg-51.aws.GenericQA.com` hostname. |
| Evidence required | Screenshot of the Portal page showing the Registration API URL. |

### TC-STORY-7502-02 - Updated in-field CID uses the new hostname without manual re-registration

| Field | Value |
| --- | --- |
| AC / QN | AC-02; Q/N-01; Q/N-03; Q/N-04 |
| Status | READY FOR PORTAL AND AGENT VERIFICATION |
| Action | Confirm the CID is an FR1.4 released agent or above. Sign in to CID Management Portal, open the Portal page for environment `hub`, and read the Management API URL field; then exercise the CID registration/management flow using the approved evidence method. |
| Test Data | Portal page > Management API > Environment Name: `hub`; CID agent: FR1.4 released or above. Example legacy value shown in the QA screenshot: `https://hub-ac-management-api.stg-51.aws.GenericQA.com`. Expected replacement: `https://hub-ac-management-api.stg-51.cid.GenericQA.com`. |
| Expected Result | Management API URL is `https://hub-ac-management-api.stg-51.cid.GenericQA.com`. An FR1.4+ agent uses the new hostname without manual reconfiguration or re-registration. |
| Evidence required | Portal screenshot and approved CID traffic/log evidence. |

### TC-STORY-7502-03 - New hostname certificate meets the AC constraint

| Field | Value |
| --- | --- |
| AC / QN | AC-03; Q/N-02 |
| Status | READY FOR CERTIFICATE INSPECTION |
| Action | Inspect the TLS certificate presented by `hub-ac-registration-api.stg-51.cid.GenericQA.com` and `hub-ac-management-api.stg-51.cid.GenericQA.com`. |
| Test Data | Hosts from the Portal page for environment `hub`: `hub-ac-registration-api.stg-51.cid.GenericQA.com` and `hub-ac-management-api.stg-51.cid.GenericQA.com`. |
| Expected Result | Each host presents a certificate valid for the `stg-51.cid.GenericQA.com` domain, not the legacy AWS hostname. Capture the actual issuer, subject/SAN, and chain. |
| Evidence required | Actual issuer, certificate chain, and CID trust-store expectation. |

### TC-STORY-7502-04 - Registration checks are consolidated to the GenericQA domain

| Field | Value |
| --- | --- |
| AC / QN | AC-04; Q/N-01 |
| Status | READY FOR UI VERIFICATION |
| Action | Open the Health Page and CID Connectivity Tester, run their registration checks, and capture the displayed registration target. |
| Test Data | Portal page baseline for environment `hub`: Registration API expected as `hub-ac-registration-api.stg-51.cid.GenericQA.com`; Management API expected as `hub-ac-management-api.stg-51.cid.GenericQA.com`. |
| Expected Result | Both registration checks use the `stg-51.cid.GenericQA.com` domain and do not display the legacy `stg-51.aws.GenericQA.com` target. |
| Evidence required | Screenshot or approved log evidence from both surfaces. |

### TC-STORY-7502-05 - Online help documents hostname and Linux Update version

| Field | Value |
| --- | --- |
| AC / QN | AC-05; Q/N-01; Q/N-03 |
| Status | BLOCKED - HELP CONTENT PENDING |
| Action | Open the direct CID Help page and section supplied for the registration/management endpoint. |
| Test Data | Portal example for environment `hub`: document `hub-ac-registration-api.stg-51.cid.GenericQA.com` and/or `hub-ac-management-api.stg-51.cid.GenericQA.com`; agent baseline: FR1.4 released or above. |
| Expected Result | The entry lists the `stg-51.cid.GenericQA.com` registration or management hostname and states that FR1.4 released agents and above use the new endpoint. |
| Evidence required | Direct CID Help URL and section heading. |

### TC-STORY-7502-06 - Legacy registration remains available before update

| Field | Value |
| --- | --- |
| AC / QN | AC-06; Q/N-01; Q/N-03 |
| Status | READY FOR BACKWARD-COMPATIBILITY VERIFICATION |
| Action | Use a CID below the FR1.4 released-agent baseline and execute its registration flow using the approved evidence method. |
| Test Data | Portal screenshot legacy examples for environment `hub`: `hub-ac-registration-api.stg-51.aws.GenericQA.com` and `hub-ac-management-api.stg-51.aws.GenericQA.com`; CID agent: below FR1.4 released baseline. |
| Expected Result | The CID can continue to use the legacy `stg-51.aws.GenericQA.com` endpoint until it is updated to the FR1.4+ baseline. |
| Evidence required | Approved CID traffic/log evidence. |

## 4) Xray Synchronization

On 2026-08-19, the nine live Xray steps were replaced after a pre-replacement snapshot was saved to `docs/TestCaseReview/TCR_STORY-7566_PreReplacementSnapshot.md`.

- Removed DN-only steps `TC-STORY-7502-07` and `TC-STORY-7502-08`.
- Removed the DN-inclusive `TC-STORY-7502-E2E` step.
- Added the six AC/QN-only steps shown below.
- Posted the synchronization summary and remaining blockers on STORY-7566.
- On 2026-08-19, the six steps were corrected from authenticated Portal-page evidence for the `hub` environment: Registration API `hub-ac-registration-api.stg-51.cid.GenericQA.com`, Management API `hub-ac-management-api.stg-51.cid.GenericQA.com`, and the FR1.4+ agent baseline.
- The six live Xray data fields now include the Portal page, `hub` environment, field labels, screenshot-derived legacy values, and expected CID-domain replacements.

## 5) Synced Xray Step Inventory (Target State)

The following steps are synchronized with the current Xray Test `STORY-7566`.

| Step ID | Tag Scope | Action Summary |
| --- | --- | --- |
| TC-STORY-7502-01 | AC-01, Q/N-01, Q/N-04 | Portal Registration API URL verification |
| TC-STORY-7502-02 | AC-02, Q/N-01, Q/N-03, Q/N-04 | Portal Management API URL and FR1.4+ agent verification |
| TC-STORY-7502-03 | AC-03, Q/N-02 | CID-domain API certificate inspection |
| TC-STORY-7502-04 | AC-04, Q/N-01 | Health Page and Connectivity Tester target verification |
| TC-STORY-7502-05 | AC-05, Q/N-01, Q/N-03 | CID hostname and FR1.4+ Help-content verification |
| TC-STORY-7502-06 | AC-06, Q/N-01, Q/N-03 | Pre-FR1.4 legacy compatibility verification |

No live step is sourced only from Design Notes. The six steps above were read back from STORY-7566 after synchronization.

---

## 6) Current Sprint Artifacts

| Artifact Type | Sprint 112 Location |
| --- | --- |
| QA Plan | docs/QAPlan/QAP_STORY-7502.md |
| Test Case | docs/TestCases/CID-sprint-112/TC_STORY-7502.md |
| Xray Test | STORY-7566 |
| Test Execution (planned) | docs/TestExecution/CID-sprint-112/TE_STORY-7502_Cycle1.md |
| Evidence Review (planned) | docs/EvidenceReview/ER_STORY-7502_Cycle1.md |

---

## Remaining Evidence Gaps

- CID Help Documentation direct page URLs and section headings for all six ACs.
- Registration/management and install-script API inventory with old-to-new hostname mapping.
- New-host TLS issuer, chain, subject/SAN, and CID trust-store expectation.
- Linux Update and CID version matrix by environment.
- Merged PR/commit and changed-file evidence mapped to the ACs.
- Current STORY-7566 Xray step contract, including the live details of steps 07 and 08.

## Notes

- Sprint 112 execution should use this document and Xray STORY-7566 as the single source of truth.
- If Jira story text changes, rerun coverage alignment before execution.
- 2026-08-31 PO response recorded from story comment `2674824`: "We have deployed release FR1.4 to CID-HUB-TST-51 with commit hash 6d6bfcc8".
- 2026-08-19 QA feedback: the existing steps are not aligned with product behavior. This revision retains AC/QN coverage only, excludes Design Note-only coverage, and does not authorize execution until Help evidence, Q/N responses, Xray synchronization, and test-case review are complete.

## Comment Review Sync

- Reviewed At: 2026-08-31 14:35:46 -07:00
- Source Issue: STORY-7566 (XRAY_TEST)
- Comment ID 2679485: Please investigate and merge into the current test steps for end-to-end registration and management API migration.
- Review Summary: Evidence required before changing Xray steps.
- Verdict Counts: EVIDENCE_REQUIRED=1, CHANGE_REVIEW_REQUIRED=0

- Reviewed At: 2026-08-31 14:37:27 -07:00
- Source Issue: STORY-7566 (XRAY_TEST)
- Comment ID 2669164: Test covers ACs, but Q/N-01 to Q/N-03 and AC-05 evidence must be confirmed before execution.
- Review Summary: Evidence required before execution readiness.
- Verdict Counts: EVIDENCE_REQUIRED=1, CHANGE_REVIEW_REQUIRED=0

- Reviewed At: 2026-08-31 22:10:00Z
- Source Issue: STORY-7502 (STORY)
- Comment ID 2674824: FR1.4 deployed to CID-HUB-TST-51 with commit 6d6bfcc8.
- Review Summary: Q/N-03 partially answered; matrix details remain open.
- Verdict Counts: EVIDENCE_REQUIRED=0, CHANGE_REVIEW_REQUIRED=0

## Comment Review Sync

- Reviewed At: 2026-09-01 11:48:49 -07:00
- Source Issue: STORY-7566 (XRAY_TEST)
- Comment ID 2683416: Hi    , Thank you for merging the tst-51 coverage. The test steps for AC-01 through AC-06 look good. Please proceed with execution.
- Review Summary: Automated review completed with fallback classification due to incomplete model schema.
- Verdict Counts: EVIDENCE_REQUIRED=1, CHANGE_REVIEW_REQUIRED=0
