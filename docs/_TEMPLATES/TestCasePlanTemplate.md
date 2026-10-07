# Test Case Plan Template

## Quality Assurance Test Case Document

## Test Cases for `#{STORY-KEY}`

## Document Information

| **Filename**      | TC_{STORY-KEY}.md                           |
|-------------------|---------------------------------------------|
| **Story Key**     | `{STORY-KEY}`                               |
| **Story Summary** | `{Story Summary from Jira}`                 |
| **Sprint**        | `{Sprint Name}`                             |
| **Prepared By**   | `{QA Owner}`                                |
| **Date Prepared** | `{Date}`                                    |
| **Status**        | Draft / Under Review / Approved             |

---

## Story Reference Gate

> Complete this gate before authoring or updating test steps.

### Loaded References

| Source Type | Reference | Access Status | Relevant Sections Extracted | Used In |
| --- | --- | --- | --- | --- |
| Story | `{Jira Story Key + URL}` | Accessible / Restricted | `{AC, DN, QA Notes sections}` | AC list, expected results |
| Product Help | `{Help URL from project-reference-sources.md}` | Accessible / Restricted | `{Endpoint names, behavior notes}` | Expected results, step boundaries |
| API Spec | `{Swagger/OpenAPI URL}` | Accessible / Restricted | `{Methods, paths, schema constraints}` | API checks, negative cases |
| Additional Reference | `{Confluence/SharePoint/Design Doc}` | Accessible / Restricted | `{Rules, screenshots, decision notes}` | Preconditions, test data |

### Gate Checklist

- [ ] All configured references from .github/skills/project-reference-sources.md were attempted.
- [ ] Each inaccessible or login-restricted reference is explicitly marked as Restricted.
- [ ] Test scope is bounded to Story AC, Design Notes, QA Notes, and extracted reference evidence.
- [ ] Any missing evidence is captured as Q/N items before test execution.

---

## Story Acceptance Criteria

> *Verbatim from Jira. Assign sequential IDs AC-01, AC-02 …*

- **AC-01**: `{Acceptance criterion 1}`
- **AC-02**: `{Acceptance criterion 2}`
- **AC-03**: `{Acceptance criterion 3}`

---

## Test Case Details

---

### TC-{STORY-KEY}-01 — `{Test Case Title}`

| Field            | Value                                                    |
|------------------|----------------------------------------------------------|
| **TC ID**        | TC-{STORY-KEY}-01                                        |
| **AC Reference** | AC-01                                                    |
| **Title**        | `{Short, descriptive test objective}`                    |
| **Type**         | Happy Path / Negative / Boundary / Regression / UI       |
| **Priority**     | High / Medium / Low                                      |
| **Automation**   | Yes / No / Partial                                       |

#### Prerequisites

- `{What must be set up before this test runs}`
- `{Test data, user roles, environment state}`

#### Test Data

| Field       | Value         |
|-------------|---------------|
| `{Field 1}` | `{Value 1}`   |
| `{Field 2}` | `{Value 2}`   |

#### Steps

| Step | Action                                    | Expected Result                              |
|------|-------------------------------------------|----------------------------------------------|
| 1    | `{Specific navigation or user action}`    | `{Exact expected outcome — what user sees}`  |
| 2    | `{Next action}`                           | `{Expected result}`                          |
| 3    | `{Submit / confirm / validate action}`    | `{Final expected state or output}`           |

---

### TC-{STORY-KEY}-02 — `{Test Case Title}`

| Field            | Value                                                    |
|------------------|----------------------------------------------------------|
| **TC ID**        | TC-{STORY-KEY}-02                                        |
| **AC Reference** | AC-01                                                    |
| **Title**        | `{Short, descriptive test objective}`                    |
| **Type**         | Negative                                                 |
| **Priority**     | Medium                                                   |
| **Automation**   | Yes / No / Partial                                       |

#### Prerequisites (TC-02)

- `{Prerequisites}`

#### Test Data (TC-02)

| Field       | Value                |
|-------------|----------------------|
| `{Field 1}` | `{Invalid value}`    |

#### Steps (TC-02)

| Step | Action                          | Expected Result                                        |
|------|---------------------------------|--------------------------------------------------------|
| 1    | `{Action with invalid input}`   | `{Error message shown: "exact expected error text"}`   |
| 2    | `{Attempt to submit}`           | `{System rejects input; no data saved}`                |

---

Add more test cases following the same structure above.

---

## AC Coverage Matrix

| AC Item | Description (brief, max 80 chars)  | TC IDs Covering It          | Coverage Status |
|---------|------------------------------------|-----------------------------|-----------------|
| AC-01   | `{AC-01 text}`                     | TC-{STORY-KEY}-01, -02      | ✅ Covered      |
| AC-02   | `{AC-02 text}`                     | TC-{STORY-KEY}-03           | ✅ Covered      |
| AC-03   | `{AC-03 text}`                     | —                           | ❌ Not Covered  |

---

## Notes and Assumptions

- `{List any assumptions made due to ambiguous or missing AC}`
- `{List any test data prerequisites or environment dependencies}`
- `{Flag any items that require developer input before testing can proceed}`

---

*Generated by: `test_case_preparation` agent | Template: `docs/_TEMPLATES/TestCasePlanTemplate.md`*
