---
description: Standard pattern for raising Jira Defects and Sub-tasks with full TC and AC traceability — includes structured description with steps to reproduce, expected/actual results, screenshots, and logs
---

# Defect Creation Pattern

## Rules

- **For any story in the current active sprint: always raise findings as a Sub-task under the parent story. Never raise a standalone Defect for in-sprint stories.**
- Standalone Defect issue type is reserved for findings against stories that are NOT in the current sprint (e.g. regression findings against released versions).
- Only create after **explicit user confirmation**.
- **Description is mandatory** — it must be populated at creation time (not added later as a comment).
- Always reference the TC ID, step number, and AC item in the description.
- **Do NOT add findings to comments** — the description field is the authoritative record.

## Required Fields

| Field         | Value                                                              |
|---------------|--------------------------------------------------------------------|
| Issue Type    | **Defect**                                                         |
| Summary       | `[{STORY-KEY}] {Brief description of failure}`                     |
| Priority      | Critical / High / Medium / Low — confirm with user                |
| Environment   | DEV / SIT / UAT / STAGING                                          |
| Build/Version | The build under test at time of failure                           |

## Description Template

The description field **must** include all of the following sections. Do not skip any section — use "N/A" if genuinely not applicable.

```
**Summary of Issue**
{One to two sentences clearly explaining what went wrong and which AC is violated.}

---

**Failed Test Case**: TC-{STORY-KEY}-{nn} — {TC Title}
**Step**: Step {i} — "{Step action text}"
**AC Reference**: AC-{nn} — {AC text summary}
**Environment**: {Environment e.g. SIT/TEST https://app.example.com
**Build / Version**: {e.g. CID Hub 1.4.0 2a250245}
**Test Execution**: {XRAY-EXEC-KEY} Step {i}

---

**Steps to Reproduce**
1. {Step 1 — starting state, e.g. "Sign out of CID Hub or use incognito"}
2. {Step 2}
3. {Step 3 — the action that triggers the bug}
4. {Step 4 — observe the result}

---

**Expected Result**
{Exact expected result from the TC document or AC — what SHOULD happen.}

---

**Actual Result**
{Verbatim description of what actually happened — error message, wrong URL, missing element, etc.}

---

**Screenshots / Evidence**
- {Filename or path of screenshot 1, e.g. docs/TestExecution/{sprint-slug}/evidence/{STORY-KEY}/step4-evidence.png — describe what it shows}
- {Filename or path of screenshot 2}
- N/A if no screenshots captured

---

**Logs**
- {Paste relevant console errors, network response, or log snippet — first 20 lines only}
- N/A if no logs available
```

## Creation Method — Use batch_create_issues (REQUIRED)

`jira_create_issue` does not reliably accept a description field. Always use `jira_batch_create_issues` so the description can be embedded in the JSON payload at creation time.

### Sub-task under a story (preferred for in-sprint findings)

```json
[
  {
    "fields": {
      "project": { "key": "{PROJECT-KEY}" },
      "summary": "{Brief description — AC-nn defect found in Cycle N Step i}",
      "issuetype": { "name": "Sub-task" },
      "parent": { "key": "{STORY-KEY}" },
      "priority": { "name": "High" },
      "description": {
        "type": "doc",
        "version": 1,
        "content": [
          {
            "type": "paragraph",
            "content": [{ "type": "text", "text": "Summary of Issue: {one sentence description}" }]
          },
          {
            "type": "paragraph",
            "content": [{ "type": "text", "text": "Failed TC: TC-{STORY-KEY}-{nn} Step {i} | AC: AC-{nn} | Env: {env} | Build: {version} | TE: {exec-key}" }]
          },
          {
            "type": "paragraph",
            "content": [{ "type": "text", "text": "Steps to Reproduce: 1. {step1} 2. {step2} 3. {step3}" }]
          },
          {
            "type": "paragraph",
            "content": [{ "type": "text", "text": "Expected Result: {expected}" }]
          },
          {
            "type": "paragraph",
            "content": [{ "type": "text", "text": "Actual Result: {actual}" }]
          },
          {
            "type": "paragraph",
            "content": [{ "type": "text", "text": "Screenshots: {file paths}" }]
          },
          {
            "type": "paragraph",
            "content": [{ "type": "text", "text": "Logs: {log snippet or N/A}" }]
          }
        ]
      }
    }
  }
]
```

### Standalone Defect (regression / out-of-sprint findings ONLY)

Only use this when the failing story is **not** in the current active sprint. Use the same JSON structure but replace `"issuetype": { "name": "Sub-task" }` with `"issuetype": { "name": "Defect" }` and remove the `"parent"` field. Then add a `jira_create_issue_link` to link the Defect → "relates to" → `{STORY-KEY}`.

## Issue Linking (Defect only — out-of-sprint)

After creating a standalone Defect, create an issue link:
- Use `jira_get_link_types` to confirm available link types.
- **Link type**: `relates to` or `is tested by` (whichever is available).
- **Direction**: Defect → relates to → `{STORY-KEY}`.

Sub-tasks are automatically linked to their parent — no separate link step needed.

## Automation Defect Summary Pattern

When raising from an automation failure:

```
[Automation] [{STORY-KEY}] {Failed test description}
```

Include the stack trace (first 10 lines) in the "Logs" section of the description body.
