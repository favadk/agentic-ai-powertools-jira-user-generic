# QA Plan — OLAC-7502

**User Story:** OLAC-7502
**Sprint:** CID sprint 112
**Created:** 2026-08-14
**Status:** In Preparation

---

## Summary

QA Plan for story OLAC-7502: Consolidate the Registration/Management API to GenericQA domain, end-to-end.

This story implements end-to-end consolidation of the CID Registration/Management API endpoint under an GenericQA-owned hostname (*.cid.GenericQA.com), as defined by the OLAC-7501 spike. The story covers DNS, TLS, backward-compatibility, and CID agent connectivity.

---

## Automation Target

| Key | Value |
|-----|-------|
| **Automation Target** | TBD — to be confirmed after TC Review |
| **Automation Type** | API / Integration |
| **Priority** | High |

---

## Triage Result

| Field | Value |
|-------|-------|
| **Triage Mode** | Mode 0 → Mode A |
| **Test Case Action** | New TC (no existing Xray Test found for OLAC-7502) |
| **Existing Test Key** | None |
| **Execution Script** | `scripts/create-tc-olac-7502.ps1` |

---

## QA Lifecycle Checklist

| # | Stage | Status | Owner | Artifact |
|---|-------|--------|-------|----------|
| 1 | Test Case Preparation | ✅ COMPLETED | QA Agent | [TC_OLAC-7502.md](../TestCases/CID-sprint-112/TC_OLAC-7502.md) |
| 2 | Test Case Review | ⏳ PENDING | Lead QA | TCR_OLAC-7502.md |
| 3 | Test Case Execution | ⏳ PENDING | Tester | TE_OLAC-7502_Cycle1.md |
| 4 | Execution Evidence Review | ⏳ PENDING | Lead QA | ER_OLAC-7502_Cycle1.md |
| 5 | Automation Code Preparation | ⏳ PENDING | Automation | AUT_OLAC-7502.md |
| 6 | Automation Code Review | ⏳ PENDING | Lead QA | AUTR_OLAC-7502.md |
| 7 | Automation Run & Publish | ⏳ PENDING | Automation | AUTRPT_OLAC-7502_Run1.md |

> Stages 5–7 apply only when Automation Target is confirmed as Yes or Partial.

---

## Environment

| Component | Version / Value | Status |
|-----------|-----------------|--------|
| Test Environment | SIT / non-prod | ⏳ Pending confirmation |
| CID Firmware | FR1.0+ (exact versions per Q&N) | ⏳ Q/N pending |
| New GenericQA FQDN | *.cid.GenericQA.com (confirm with Dev) | ⏳ Q/N pending |
| Legacy AWS Hostname | *.amazonaws.com (backward-compat) | ⏳ To be confirmed |

---

## Sub-task Tracking

| Sub-task | Summary | Status |
|----------|---------|--------|
| OLAC-7557 | Create Test Case | In Dev (transitioned by create-tc-olac-7502.ps1) |

---

## Notes

- Story is part of the GenericQA domain consolidation initiative for CID AWS endpoints (see OLAC-7501 spike).
- TC preparation requires fetching ACs from Jira. Run `scripts/create-tc-olac-7502.ps1` to complete the full workflow.
- Active test references for this story are docs/TestCases/CID-sprint-112/TC_OLAC-7502.md and Xray test OLAC-7566.
- The Jira MCP server was unavailable at agent trigger time (2026-08-14); all Jira actions are delegated to the execution script.
- Q&N questions may be raised for: exact FQDN, cert chain details, CID firmware compatibility, backward-compat confirmation. See TC doc for details once script runs.
