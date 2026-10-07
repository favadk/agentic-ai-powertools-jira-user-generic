# QA Sprint Plan

**Quality Assurance — Sprint User Story QA Plan**

## QA Plan for `#{STORY-KEY}`

## Header

| **Filename**       | QAP_{STORY-KEY}.md                           |
|--------------------|----------------------------------------------|
| **Story Key**      | `{STORY-KEY}`                                |
| **Story Summary**  | `{Story Summary from issue-tracker}`                  |
| **Sprint**         | `{Sprint Name}`                              |
| **QA Owner**       | `{Assigned tester or TBD}`                   |
| **Plan Created**   | `{Date}`                                     |
| **Automation Target** | Yes / No / Partial                        |

---

## Story Overview

**Description**

`{Concise summary of what the story delivers — in user-facing terms, no technical jargon}`

**Acceptance Criteria**

- **AC-01**: `{Acceptance criterion 1}`
- **AC-02**: `{Acceptance criterion 2}`
- **AC-03**: `{Acceptance criterion 3}`

> *If AC is missing from issue-tracker, this field will read: ⚠️ AC NOT AVAILABLE — plan is blocked until AC is provided by the Product Owner.*

---

## QA Lifecycle Checklist

| # | QA Stage                          | Agent to Use                          | Status       | Output Artifact                              |
|---|-----------------------------------|---------------------------------------|--------------|----------------------------------------------|
| 1 | Test Case Preparation             | `test_case_preparation` agent         | ☐ Pending    | `docs/TestCases/{sprint-slug}/TC_{STORY-KEY}.md`           |
| 2 | Test Case Review                  | `test_case_review` agent              | ☐ Pending    | `docs/TestCaseReview/TCR_{TC-KEY}.md`        |
| 3 | Test Case Execution               | `test_case_execution` agent           | ☐ Pending    | `docs/TestExecution/{sprint-slug}/TE_{STORY-KEY}_Cycle1.md`|
| 4 | Execution Evidence Review         | `test_case_evidence_review` agent     | ☐ Pending    | `docs/EvidenceReview/ER_{STORY-KEY}_Cycle1.md`|
| 5 | Automation Code Preparation       | `automation_code_preparation` agent   | ☐ Pending    | `docs/Automation/AUT_{STORY-KEY}.md`         |
| 6 | Automation Code Review            | `automation_code_review` agent        | ☐ Pending    | `docs/Automation/AUTR_{STORY-KEY}.md`        |
| 7 | Automation Run & Publish Results  | `automation_run_publish` agent        | ☐ Pending    | `docs/Automation/AUTRPT_{STORY-KEY}_Run1.md` |

> **Stages 5–7** are applicable only when **Automation Target = Yes or Partial**.

---

## Risk Assessment

| Risk                                         | Likelihood | Impact | Mitigation Strategy                                      |
|----------------------------------------------|------------|--------|----------------------------------------------------------|
| AC is ambiguous or incomplete                | Medium     | High   | Clarify with PO before test case preparation begins      |
| Story has no automation hook                 | Low        | Medium | Flag as Manual-Only; skip stages 5–7                    |
| Story is blocked by a dependency             | Low        | High   | Defer QA stages; re-plan at sprint review                |
| Regression impact outside story scope       | Medium     | High   | Identify affected areas; add regression test cases       |
| Test environment not available              | Low        | High   | Align with DevOps; schedule execution in next window     |

---

## Dependencies and Notes

**Dependent Stories / Issues**

| Issue Key | Summary                       | Dependency Type               |
|-----------|-------------------------------|-------------------------------|
| `{KEY}`   | `{Summary}`                   | Must complete before testing  |

**Environment and Data Prerequisites**

- `{List any environment access, test accounts, or data setup required}`
- `{Any service mocks, feature flags, or configuration needed}`

**Notes**

- `{Any other relevant context for the QA engineer}`

---

## Definition of Done — QA Perspective

The story is considered **QA-complete** when all applicable items below are checked:

- [ ] All test cases prepared and cover every AC item
- [ ] Test cases reviewed and approved
- [ ] All test cases executed; pass/fail recorded in execution report
- [ ] Execution evidence reviewed and signed off
- [ ] All defects raised in issue-tracker as type "Defect" with correct severity and story link
- [ ] Automation code written *(if Automation Target = Yes/Partial)*
- [ ] Automation code reviewed and merged *(if Automation Target = Yes/Partial)*
- [ ] Automation suite run; results published to agreed channel *(if Automation Target = Yes/Partial)*
- [ ] No open High or Critical defects linked to this story
- [ ] QA sign-off recorded in this document

---

## QA Sign-Off

| Field                      | Value            |
|----------------------------|------------------|
| **QA Owner**               | `{Name}`         |
| **QA Lead**                | `{Name / TBD}`   |
| **Sign-Off Date**          | `{Date}`         |
| **QA Status**              | ✅ Complete / ❌ Not Complete / ⚠️ Conditional |

---

*Generated by: `sprint_story_qa_plan` agent | Template: `docs/_TEMPLATES/QASPrintPlanTemplate.md`*
