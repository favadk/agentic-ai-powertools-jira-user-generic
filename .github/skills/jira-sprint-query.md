---
description: Standard workflow for discovering the active Jira sprint, board, and User Stories
---

# Jira Sprint & Story Discovery

## Steps to Find the Active Sprint and User Stories

1. **Identify the project key** (e.g., `STORY`, `CDS2REP`). Ask the user if not provided.
2. **List Agile boards** using `jira_get_agile_boards` — locate the team's primary board for the project.
3. **Get active sprints** using `jira_get_sprints_from_board` — find the sprint with `state = "active"`.
4. **Retrieve sprint issues** using `jira_get_sprint_issues` with the active sprint ID.
5. **Filter for User Stories only** — issue type = "Story". Exclude Defects, Tasks, Epics, Sub-tasks.
6. **Fetch full story details** using `jira_get_issue` for each story key to get: Summary, Description, Acceptance Criteria, Story Points, Assignee, Status, Fix Version.

## Alternative: JQL Search

```
project = {KEY} AND issuetype = Story AND sprint in openSprints()
```

Use `jira_search` with this JQL as an alternative when board discovery is slow or the board ID is not known.

## Story Assessment Checklist

For each User Story found, determine:

- [ ] Is the story new to this sprint? (Status = To Do or In Progress, not a carryover with existing TCs)
- [ ] Is AC present? If AC is missing, **stop and flag the story** — do not proceed with test case creation.
- [ ] Does it have linked test cases already? (Check linked issues for Xray Test type)
- [ ] Is it automation-eligible? (Has testable functional behaviour, not purely config/infra)

## Notes

- Never invent or assume AC, story details, or owner names — use only concrete information from Jira.
- If a board is not found, ask the user to provide the board ID or board name.
- If AC is missing from a story, mark Stage 1 (Test Case Preparation) as "Blocked — AC required".
