---
description: Standard file naming conventions and folder structure for all QA lifecycle artifacts
---

# QA Artifact Naming Conventions

## Folder Structure

All QA artifacts are stored under `docs/` in the workspace root.

| Folder                                          | Contents                                |
|-------------------------------------------------|-----------------------------------------|
| `docs/QAPlan/`                                  | Sprint QA plans per story               |
| `docs/TestCases/`                               | Prepared test cases                     |
| `docs/TestCaseReview/`                          | Test case review findings               |
| `docs/TestExecution/{sprint-slug}/`                         | Execution reports for that sprint       |
| `docs/TestExecution/{sprint-slug}/evidence/{STORY-KEY}/`    | Screenshot evidence per story           |
| `docs/EvidenceReview/`                          | Evidence review sign-offs               |
| `docs/Automation/`                              | Automation plans, reviews, and reports  |
| `docs/ImpactAnalysis/`                          | Impact analysis documents               |
| `docs/RootCauseAnalysis/`                       | Root cause analysis documents           |
| `docs/_TEMPLATES/`                              | Source templates for all QA documents   |

## File Naming

| Document            | Path Pattern                                                               |
|---------------------|----------------------------------------------------------------------------|
| QA Plan             | `docs/QAPlan/QAP_{STORY-KEY}.md`                                           |
| Test Cases          | `docs/TestCases/TC_{STORY-KEY}.md`                                         |
| Test Case Review    | `docs/TestCaseReview/TCR_{TC-KEY}.md`                                      |
| Test Execution      | `docs/TestExecution/{sprint-slug}/TE_{STORY-KEY}_Cycle{N}.md`                            |
| Evidence Review     | `docs/EvidenceReview/ER_{STORY-KEY}_Cycle{N}.md`                           |
| Automation Plan     | `docs/Automation/AUT_{STORY-KEY}.md`                                       |
| Automation Review   | `docs/Automation/AUTR_{STORY-KEY}.md`                                      |
| Automation Report   | `docs/Automation/AUTRPT_{STORY-KEY}_Run{N}.md`                             |
| Impact Analysis     | `docs/ImpactAnalysis/IA_{ISSUE-KEY}.md`                                    |
| Root Cause Analysis | `docs/RootCauseAnalysis/RCA_{ISSUE-KEY}.md`                                |
| Screenshot Evidence | `docs/TestExecution/{sprint-slug}/evidence/{STORY-KEY}/TC{nn}_Step{i}_{status}.png`      |

## Rules

- Create the target directory if it does not already exist.
- Do **NOT** publish documents to Jira or Confluence automatically. All outputs are local unless the user explicitly requests publishing.
- Replace `{STORY-KEY}` with the Jira issue key (e.g., `STORY-0000`).
- Replace `{N}` with the cycle or run number, starting at 1.
- Replace `{TC-KEY}` with the Xray Test issue key (e.g., `STORY-0000`).
