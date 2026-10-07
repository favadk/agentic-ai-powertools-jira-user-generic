---
description: Auto-discover the PO, Dev, and Tester assigned to a story from issue-tracker — used by all QA agents to direct comments and queries to the right person without user input
---

# Story Team Discovery

This skill defines **how every QA agent discovers the right person** to contact for a given type of communication. Load this skill early in any workflow that needs to post issue-tracker comments or direct queries to PO, Dev, or Tester.

> **All agents must run Team Discovery before posting any issue-tracker comment.** Never hard-code accountIds or ask the user for team member details — derive them from issue-tracker.

---

## Roles and Their Sources

| Role | Who they are | Where to find them |
|------|--------------|-----------------------|
| **PO** | Product Owner — owns acceptance criteria | `fields.reporter` on the User Story |
| **Dev** | Developer — responsible for implementation | `fields.assignee` on Implementation sub-task |
| **Tester** | Test Engineer — writes and executes tests | `fields.assignee` on Test case creation / Test case Execution sub-task |
| **TC Reviewer** | Test case peer reviewer — reviews TC quality | `fields.assignee` on Test case Review sub-task |
| **Evidence Reviewer** | Execution approver — reviews execution evidence | `fields.assignee` on Test case execution review sub-task |

---

## Discovery Steps

### TD-Step 1 — Fetch the Story and Its Sub-tasks

```powershell
# Step A: get the story with subtasks field included
# issue-tracker_get_issue with fields: "reporter,assignee,subtasks"
```

Extract the PO from `fields.reporter`:
```powershell
$po = @{
    accountId   = $story.fields.reporter.accountId
    displayName = $story.fields.reporter.displayName
    email       = $story.fields.reporter.emailAddress
}
```

Extract the sub-task list from `fields.subtasks[]` — this is returned directly in the story response (no separate JQL search needed):

```powershell
# Each entry in fields.subtasks[] has: key, fields.summary, fields.status, fields.issuetype
# BUT does NOT have fields.assignee — you must fetch each sub-task individually.
# Iterate ALL sub-tasks — do not stop at the first match.
# Each sub-task may map to a different role: Evidence Reviewer, TC Reviewer, Dev, or Tester.
foreach ($subtask in $story.fields.subtasks) {
    $detail = issue-tracker_get_issue($subtask.key, fields: "summary,issuetype,assignee,status")
    # Apply priority keyword table (TD-Step 2) to classify this sub-task
    # and assign its $detail.fields.assignee to the correct role variable:
    # $evidenceReviewer, $tcReviewer, $dev, or $tester
}
```

> **Important**: `issue-tracker_search` with `parent = "{STORY-KEY}"` is NOT reliable across all issue-tracker configurations. Always use `fields.subtasks` from the story's own response and then fetch each sub-task individually.

---

### TD-Step 2 — Classify Sub-tasks by Role

Apply keyword matching in **priority order** — most specific first. For each sub-task, check `fields.summary` (lowercased):

| Priority | Role | Match if summary contains... | Does NOT contain |
|----------|------|------------------------------|------------------|
| 1st | **Evidence Reviewer** | `execution review`, `test case execution review`, `evidence review` | — |
| 2nd | **TC Reviewer** | `test case review`, `tc review`, `test review`, `case review` | `execution` |
| 3rd | **Dev** | `implementation`, `development`, `dev task`, `design`, `architecture`, `backend`, `frontend`, `coding`, `engineering`, `technical`, `build`, `develop` | — |
| 4th | **Tester** | `test case creation`, `test creation`, `test case execution`, `test execution`, `testing`, `qa`, `quality assurance`, `verification`, `automated test`, `test automation`, `acceptance test`, `uat` | — |

> A sub-task that already matched a higher-priority role must not be reclassified. Process the priority list top-to-bottom and stop at first match per sub-task.

Store discovered roles:

```powershell
$dev             = @{ accountId = ...; displayName = ...; email = ... }  # from Implementation sub-task
$tester          = @{ accountId = ...; displayName = ...; email = ... }  # from Test case creation/Execution sub-task
$tcReviewer      = @{ accountId = ...; displayName = ...; email = ... }  # from Test case Review sub-task
$evidenceReviewer = @{ accountId = ...; displayName = ...; email = ... } # from Test case execution review sub-task
```

---

### TD-Step 3 — Fallback Rules

If a role cannot be discovered from sub-tasks, apply these fallbacks **in order**:

| Role | Fallback 1 | Fallback 2 |
|------|-----------|-----------|
| **PO** | `fields.reporter` of the story | `fields.creator` of the story |
| **Dev** | `fields.assignee` of the story (if story is still `In Dev`) | Ask user: "Who is the developer for {STORY-KEY}?" |
| **Tester** | Assignee of the linked test-management Test issue | Ask user: "Who is the tester for {STORY-KEY}?" || **TC Reviewer** | Same as Tester (if no dedicated reviewer sub-task exists) | Log: "No TC Reviewer sub-task found — using Tester as fallback" |
| **Evidence Reviewer** | Same as TC Reviewer | Log: "No Evidence Reviewer sub-task found — using TC Reviewer as fallback" |
> Only ask the user if both the primary source and all fallbacks fail.

---

### TD-Step 3a — Conflict Check: PO and Dev Must Not Be the Same Person

After assigning all three roles, **always check** whether `$dev.accountId == $po.accountId`.

**If they match:**

1. Log a warning:
   > "⚠️ Dev and PO resolved to the same person ({displayName}). The Implementation sub-task may not have been properly assigned. Applying fallback."

2. Apply Dev fallback in this order:
   - **First**: use `fields.assignee` of the User Story itself — this is typically the developer responsible for delivery
   - **Second**: if `fields.assignee` is also the same as PO (or is null) → ask the user once: `"The dev sub-task owner was not set separately from the PO. Who is the developer for {STORY-KEY}? (or type SKIP to use the PO for all queries)"`

3. After resolving, log the corrected team:
   > "Team corrected for {STORY-KEY}: PO={PO}, Dev={Dev} (fallback: story assignee), Tester={Tester}"

**Agents must never silently use the same person for both PO and Dev** — it leads to misdirected comments and missed notifications.

---

### TD-Step 4 — Record Team in Working Context

After discovery, hold these values in memory for use throughout the current agent session:

```
STORY_TEAM:
  PO:
    accountId:   {value}
    displayName: {value}
    email:       {value}
  Dev:
    accountId:   {value}
    displayName: {value}
    email:       {value}
  Tester:
    accountId:   {value}
    displayName: {value}
    email:       {value}
  TC Reviewer:
    accountId:   {value}
    displayName: {value}
    email:       {value}
  Evidence Reviewer:
    accountId:   {value}
    displayName: {value}
    email:       {value}
```

Log to the user (one line each):
```
Team discovered for {STORY-KEY}:
  PO               → {PO displayName} ({PO email})
  Dev              → {Dev displayName} ({Dev email})   [from sub-task: {sub-task summary}]
  Tester           → {Tester displayName} ({Tester email})   [from sub-task: {sub-task summary}]
  TC Reviewer      → {TC Reviewer displayName} ({TC Reviewer email})   [from sub-task: {sub-task summary}]
  Evidence Reviewer→ {Evidence Reviewer displayName} ({Evidence Reviewer email})   [from sub-task: {sub-task summary}]
```

---

## Directing Comments to the Right Person

### When to mention each role

| Situation | Who to mention | Why |
|-----------|---------------|-----|
| AC is ambiguous or missing | **PO** | PO owns the acceptance criteria |
| Expected result unclear for a business rule | **PO** | Business interpretation belongs to PO |
| A test step depends on an API endpoint / data structure | **Dev** | Technical implementation details |
| A prerequisite cannot be met due to a missing feature or config | **Dev** | Dev needs to confirm readiness |
| Test step FAIL due to a known bug | **Dev** | Dev needs to investigate the defect |
| TC document ready for peer review | **TC Reviewer** | TC Reviewer owns test case review sign-off |
| TC review findings need clarification | **TC Reviewer** | TC Reviewer must respond to review queries |
| Execution evidence ready for approval | **Evidence Reviewer** | Evidence Reviewer owns evidence sign-off |
| Evidence review deficiency found | **Evidence Reviewer** | Evidence Reviewer must confirm remediation |
| PR review comments on automation code | **Tester** | Tester owns test execution quality |
| Automation coverage approval needed | **Tester** | Tester signs off on automation scope |

---

## ADF Comment Template (issue-tracker mentions)

Use this pattern in PowerShell to build a issue-tracker comment that `@mentions` the right person. The `@mention` ensures issue-tracker sends them a notification.

```powershell
function New-issue-trackerCommentADF {
    param(
        [hashtable]$Mentionee,   # @{ accountId="..."; displayName="..." }
        [string]$MessageText
    )

    return @{
        body = @{
            type    = "doc"
            version = 1
            content = @(
                @{
                    type    = "paragraph"
                    content = @(
                        @{
                            type  = "mention"
                            attrs = @{
                                id   = $Mentionee.accountId
                                text = "@$($Mentionee.displayName)"
                            }
                        },
                        @{
                            type = "text"
                            text = " $MessageText"
                        }
                    )
                }
            )
        }
    } | ConvertTo-Json -Depth 10
}
```

### Usage examples

**AC clarification to PO:**
```powershell
$commentBody = New-issue-trackerCommentADF -Mentionee $po -MessageText @"
 — AC-05 clarification needed: The acceptance criterion states '...' but the test
case interpretation is unclear. Should unauthenticated users who bookmark a direct
help URL be redirected to login, or shown a 403 error page? Please confirm the
expected behaviour so we can finalise TC-12.

This comment was raised automatically by the QA agent during test case preparation.
"@
```

**Dev query for architecture/implementation detail:**
```powershell
$commentBody = New-issue-trackerCommentADF -Mentionee $dev -MessageText @"
 — Implementation query for {STORY-KEY}: The automation script needs to call
the help-access API endpoint to verify authentication state. Could you confirm
the endpoint path and whether it requires a bearer token or session cookie?
"@
```

**Tester notification for PR review:**
```powershell
$commentBody = New-issue-trackerCommentADF -Mentionee $tester -MessageText @"
 — Automation PR raised for {STORY-KEY}: The E2E automation scripts have passed
local test run and code review. PR: {PR_URL}. Please review and approve when ready.
"@
```

---

## Multi-Person Comments

When a comment is relevant to more than one role, include multiple mentions:

```powershell
# Mention both PO and Dev
$content = @(
    @{ type = "mention"; attrs = @{ id = $po.accountId;  text = "@$($po.displayName)"  } },
    @{ type = "text";    text = " and " },
    @{ type = "mention"; attrs = @{ id = $dev.accountId; text = "@$($dev.displayName)" } },
    @{ type = "text";    text = " — this test step touches both the AC definition and the implementation. See details below..." }
)
```

---

## When Multiple Sub-tasks Match the Same Role

If more than one sub-task matches the Dev or Tester keywords:

1. **Prefer the sub-task whose status is `In Progress`** — that person is actively working on it.
2. If still tied: prefer the sub-task with the most specific keyword match (e.g., `implementation` over `dev task`).
3. If still tied: use the first one returned by issue-tracker and log a warning:
   > "Multiple {role} sub-tasks found for {STORY-KEY}. Using {chosen sub-task key} ({assignee}). If this is wrong, specify the correct person."

---

## Auto-Discover source-control Branch from issue-tracker Dev Info

To find the feature branch a developer used (for context or comparison):

Use `issue-tracker_get_development_information` with the story key. This returns:
- `branches[]` — list of branches linked to this story
- `pullRequests[]` — list of PRs, their source/target branches, and merge status

Extract the **merged PR's source branch** as the developer's feature branch. This is useful when:
- You need to compare automation code against the feature implementation
- You need to confirm the code is already merged before starting test execution

```powershell
# The development info endpoint returns branch names
# Use the branch that has a MERGED pull request as the confirmed implementation branch
$mergedBranch = ($devInfo.pullRequests | Where-Object { $_.status -eq "MERGED" } | Select-Object -First 1).source.branch
```

> **Automation branch naming is always**: `automation/{STORY-KEY}` — this is fixed by convention. No user input required.
> **PR target branch is always**: `release-fr1.4` — this is fixed for this project. No user input required.
