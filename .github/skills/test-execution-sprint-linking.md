---
description: Test Execution Sprint Linking — ensures every test-management Test is linked to a Test Execution (TE) in the current active sprint before any execution begins. Governs the TE presence check, auto-TE creation, PO/PM notification via issue-tracker comment and Teams webhook, bulk-addition of all active sprint tests to the TE, and the hard blocking rule that prevents test_case_execution from starting without a confirmed sprint TE. Load in test_case_execution (blocking gate) and test_case_preparation (post-creation linkage).
---

# Test Execution Sprint Linking

> CRITICAL HARD STOP — CURRENT SPRINT ONLY
> Before reading or using any TC or execution artifact, verify the story is on the active sprint board. If the story is not in the current sprint, stop immediately and do not evaluate stale, legacy, or out-of-sprint test artifacts.

Load this skill in:
- **`test_case_execution`** — as Step 0B (mandatory blocking gate before any execution step)
- **`test_case_preparation`** — as a final step after the test-management Test is created (auto-link to sprint TE)

---

## 1. When This Skill Activates

| Agent | Trigger | Outcome |
|-------|---------|---------|
| `test_case_execution` | ALWAYS — Step 0B before execution starts | Block or proceed based on TE presence |
| `test_case_preparation` | After test-management Test is created | Link new test to sprint TE, create TE if missing |

---

## 2. TE Presence Check — Does a Sprint TE Exist?

### Sprint carry-over rule

If the story was carried from `previousSprintSlug` into the active sprint, this is a new execution cycle. Do not reuse the previous sprint's TE. Move/verify the story and its linked test-management Test in the active sprint, create a new TE for the active sprint, add the test-management Test to it, and link the new TE back to the story before execution.

Before execution begins, query the selected TE and verify that the story's test-management Test is attached and has an test-management test run. The execution agent must use that run for every step result and evidence update; if no run exists, it must stop and repair the TE linkage first.

### Pre-flight guardrail — current sprint only

Before reading any TC document or execution artifact, verify that `{STORY-KEY}` is present in the active sprint issue list for the configured project board. If the story is not on the current sprint board:

- stop immediately
- do not evaluate any legacy or out-of-sprint TC artifact
- do not proceed with execution
- report: `"Story {STORY-KEY} is not in the current sprint board; stale or out-of-sprint test artifacts are excluded."`

### Step 2.1 — Identify the active sprint

```powershell
# 1. Get the agile board for the project
$boards  = issue-tracker_get_agile_boards(projectKeyOrId: "{PROJECT-KEY}")
$boardId = $boards | Where-Object { $_.type -eq "scrum" } | Select-Object -First 1 -ExpandProperty id

# 2. Get the active sprint on that board
$sprints      = issue-tracker_get_sprints_from_board(boardId: $boardId, state: "active")
$activeSprint = $sprints | Select-Object -First 1
$sprintId     = $activeSprint.id
$sprintName   = $activeSprint.name
Write-Host "Active sprint: $sprintName (ID: $sprintId)"

# 3. Get ALL sprint issues now — reused in Step 2.2 (TE search) and Section 4.1 (bulk-add)
$sprintIssues = issue-tracker_get_sprint_issues(sprintId: $sprintId)
Write-Host "Sprint issues loaded: $($sprintIssues.Count)"
```

### Step 2.2 — Search for an existing sprint TE

> **Important**: Do NOT use `issue-tracker_search` with a `sprint = {ID}` JQL filter — this fails for some issue-tracker/test-management configurations. Instead, use the results from `issue-tracker_get_sprint_issues` (already called in Step 2.1) and filter locally:

```powershell
# Filter the sprint issues list for Test Execution issue type
$sprintTeList = $sprintIssues `
    | Where-Object { $_.fields.issuetype.name -eq "Test Execution" } `
    | Where-Object { $_.fields.status.statusCategory.key -ne "done" }

$sprintTe     = $sprintTeList | Select-Object -First 1
$teKey        = $sprintTe?.key
Write-Host "Sprint TE search result: $(if($teKey){ $teKey } else { 'NONE FOUND' })"
```

### Step 2.3 — Evaluate the search result

| Result | Action |
|--------|--------|
| One or more TE found | Use the first result. Log `"Sprint TE found: {TE-KEY} — {TE Summary}"`. Proceed to Section 4 to ensure the test is added. |
| No TE found | Proceed to Section 3 to auto-create, then Section 4. |

---

## 3. Auto-Create Sprint TE and Notify PO/PM

When no TE exists in the active sprint, run the following sequence fully before continuing.

### Step 3.1 — Create the Test Execution

```powershell
cd "C:\Agentic-AI\agentic-ai-powertools-issue-tracker-user-generic"
. .\scripts\test-management-api.ps1

# Create TE with no tests initially — tests are bulk-added in Section 4
$teKey = New-test-managementTestExecution `
    -ProjectKey  "{PROJECT-KEY}" `
    -StoryKey    "{STORY-KEY}" `
    -TestKeys    @() `
    -Summary     "Sprint TE: {SPRINT-NAME} — {PROJECT-KEY}" `
    -Environment "SIT"

Write-Host "Sprint TE auto-created: $teKey"
```

### Step 3.2 — Move the TE into the active sprint

```powershell
issue-tracker_move_issues_to_sprint(sprintId: $sprintId, issueKeys: @($teKey))
Write-Host "TE $teKey moved to sprint: $sprintName"
```

### Step 3.2a — Verify TE is now visible in the sprint board

After calling `issue-tracker_move_issues_to_sprint`, re-fetch the sprint issues to confirm the TE actually landed in the sprint. Do not assume the API call succeeded silently — always verify.

```powershell
# Re-fetch sprint issues to verify TE presence
$sprintIssuesRefresh = issue-tracker_get_sprint_issues(sprintId: $sprintId)
$teInSprint = $sprintIssuesRefresh | Where-Object { $_.key -eq $teKey }

if ($teInSprint) {
    Write-Host "✅ TE $teKey confirmed in sprint $sprintName — continuing."
} else {
    # TE is NOT in the sprint — permission failure or propagation delay
    Write-Warning "⚠️ TE $teKey was created but could not be confirmed in sprint $sprintName."
    Write-Warning "This is usually caused by missing 'Schedule Issues' permission on the QA service account."
    # Notification already sent in Step 3.3 — enter wait gate below
}
```

**If the TE is NOT confirmed in the sprint** — enter the Sprint Presence Wait Gate:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WAITING — Sprint TE not yet visible in sprint board
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Story:      {STORY-KEY}
TE Created: {TE-KEY}  →  {issue-tracker-BASE-URL}/browse/{TE-KEY}
Sprint:     {SPRINT-NAME}

The Test Execution was created but the QA service account
does not have 'Schedule Issues' permission to move it into
the sprint. PO and Manager have been notified via issue-tracker comment.

Required action (PO / Scrum Master):
  1. Open {issue-tracker-BASE-URL}/browse/{TE-KEY}
  2. Use the sprint field to assign it to sprint "{SPRINT-NAME}"
  3. Notify the QA tester once done

Once confirmed, re-run @test_case_execution for {STORY-KEY}.
The agent will detect the TE in the sprint and continue
automatically (transition to In Progress → add tests → execute).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**STOP here.** Do not proceed with test execution until the TE is confirmed in the sprint. When the tester re-runs `@test_case_execution`, Step 0B will re-run the presence check — the TE will now be found in the sprint and the workflow will continue from Step 4.3 (transition TE → In Progress → add tests → execute).

> **story_monitor integration**: The `story_monitor` agent's `STATUS_CHANGE` handler will also detect when the TE transitions to `In Progress` (once a human moves it to the sprint and starts it) and can re-trigger `test_case_execution` automatically if configured.

### Step 3.3 — Notify via test-management Test comment only

> **Rule**: All Q&A, status updates, and notifications about TE creation go on the **test-management Test** (`$test-managementTestKey`), NOT on the user story. The story remains clean — only the test-management Test and its TE carry workflow comments.

Post a comment on the **test-management Test** (`$test-managementTestKey`) using `issue-tracker_add_comment`, mentioning the tester:

**Resolve contacts** — read from `mcp.local.json` only. Never hardcode accountIds in skill files or comment templates:

```powershell
# Load project contacts from .vscode/mcp.local.json (accountIds are stored there, not here)
$mcpLocal       = Get-Content ".vscode/mcp.local.json" -Raw | ConvertFrom-Json
$contacts       = $mcpLocal.projectContacts.STORY   # adjust project key as needed

$ManagerName      = $contacts.manager.name
$ManagerAccountId = $contacts.manager.accountId     # read at runtime — never hardcoded

# PO: resolve from story fields.reporter first; fall back to mcp.local.json productOwner
$PoAccountId = if ($storyDetails.fields.reporter.accountId) { $storyDetails.fields.reporter.accountId } `
               elseif ($contacts.productOwner.accountId)    { $contacts.productOwner.accountId } `
               else { $null }
$PoName      = if ($storyDetails.fields.reporter.displayName) { $storyDetails.fields.reporter.displayName } `
               else { $contacts.productOwner.name }

# Build @mention strings — only include if accountId was found
$PoMention      = if ($PoAccountId)      { "[~accountid:$PoAccountId]" }      else { $PoName }
$ManagerMention = if ($ManagerAccountId) { "[~accountid:$ManagerAccountId]" } else { $ManagerName }
```

**issue-tracker comment template** (use `$PoMention` / `$ManagerMention` variables, never raw IDs):

```
{$PoMention}  {$ManagerMention}

*Sprint TE — Action Required*

A Sprint Test Execution has been automatically created for the active sprint:

  *{TE-KEY}* — {issue-tracker-BASE-URL}/browse/{TE-KEY}
  Summary: "Sprint TE: {SPRINT-NAME} — {PROJECT-KEY}"

*Action required*: [Open {TE-KEY}]({issue-tracker-BASE-URL}/browse/{TE-KEY}) and move it into sprint *{SPRINT-NAME}*.
The automated QA account does not have *Schedule Issues* permission — please action manually.

Please notify:
- Manager / PM: {manager.name} ( @{manager.email} )
- Product Owner: {po.name} ( @{po.email} )

— Automated QA Framework
```

> **Formatting rules**:
> - STORY/issue-tracker issue keys must always include an explicit browse URL: `{KEY} ( {issue-tracker-BASE-URL}/browse/{KEY} )` — issue-tracker auto-links the key AND the raw URL is clickable for reviewers.
> - Email addresses must be prefixed with `@`: `@name@domain.com`
> - No accountIds in comment body. Names and emails only.

### Step 3.4 — Notify via Microsoft Teams (if webhook URLs are configured)

Read `$TeamsWebhookUrls` from the project config (Section 7). If the list is non-empty, post to **each** webhook:

```powershell
$payload = @{
    "@type"    = "MessageCard"
    "@context" = "https://schema.org/extensions"
    summary    = "New Sprint TE created"
    themeColor = "0070C0"
    title      = "QA Framework: Sprint Test Execution Created"
    text       = "**Sprint TE auto-created:** [{TE-KEY}] Sprint TE: {SPRINT-NAME}`n`n" +
                 "**Action required:** Please verify [{TE-KEY}] is visible in sprint [{SPRINT-NAME}] and assign it as needed.`n`n" +
                 "/cc $PoMention $ManagerMention"
} | ConvertTo-Json -Depth 5

foreach ($webhookUrl in $TeamsWebhookUrls) {
    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType "application/json" -Body $payload
        Write-Host "Teams notification sent to: $webhookUrl"
    } catch {
        Write-Warning "Teams notification failed for webhook — falling back to issue-tracker comment only: $_"
    }
}
```

> **Fallback rule**: If `$TeamsWebhookUrls` is empty or all webhooks fail, the issue-tracker comment (Step 3.3) is sufficient. Log the fallback. Never block the workflow on a notification failure.

---

## 4. Bulk-Add All Active Sprint Tests to the TE

Once the sprint TE key is confirmed (found or just created), add ALL test-management Tests for stories in the active sprint.

### Step 4.1 — Get all story keys in the active sprint

```powershell
# $sprintIssues is already loaded from Step 2.1 — no second API call needed
$storyKeys = $sprintIssues `
    | Where-Object { $_.fields.issuetype.name -in @("Story","User Story","Task","Bug","Defect") } `
    | Select-Object -ExpandProperty key
```

### Step 4.2 — Collect test-management Test keys for each story

For each `$storyKey`:
1. **Primary source**: Read `docs/TestCases/TC_{storyKey}.md` — extract the `test-management Test Key` header field value
2. **Fallback**: `issue-tracker_search` with JQL: `issueType = Test AND issue in linkedIssues("{storyKey}", "tests")` — extract `key` fields

Collect all resolved test keys into `$allTestKeys`. Skip stories where no TC doc and no issue-tracker Test link exists — log them as `"No test-management Test found for {storyKey} — skipped"`.

### Step 4.3 — Add all collected tests to the sprint TE

```powershell
. .\scripts\test-management-api.ps1
mcp_test-management_add_tests_to_execution -TestExecKey $teKey -TestKeys $allTestKeys
Write-Host "Added $($allTestKeys.Count) tests to sprint TE $teKey"
```

> **Deduplication**: If a test key is already in the TE, the test-management API ignores the duplicate — no error handling needed.  
> **Scope**: Only tests linked to stories IN the active sprint. Never pull tests from other sprints.

### Step 4.4 — Verify / Transition TE to "In Dev" Status

Before any test step execution can begin, the sprint TE **must** be in `In Dev` status. This step runs every time after the sprint TE key is confirmed (found or just created).

```powershell
# Get the current TE status
$teIssue      = issue-tracker_get_issue(issueKey: $teKey)
$teStatus     = $teIssue.fields.status.name
$teStatusCat  = $teIssue.fields.status.statusCategory.key   # "new", "indeterminate", "done"
Write-Host "Sprint TE $teKey current status: $teStatus (category: $teStatusCat)"

# "indeterminate" = In Progress category (covers "In Dev", "In Progress", "Active", etc.)
if ($teStatusCat -ne "indeterminate") {
    # Resolve the transition that leads to an In-Progress/In-Dev status
    $transitions = issue-tracker_get_transitions(issueKey: $teKey)
    # Prefer a transition named "In Dev" or "Start Progress" or any that targets category indeterminate
    $inDevTrans  = $transitions | Where-Object { $_.name -in @("In Dev","In Progress","Start Progress","Start","Re-Open") } `
                               | Select-Object -First 1
    # Fallback: pick first transition with to.statusCategory.key = "indeterminate"
    if (-not $inDevTrans) {
        $inDevTrans = $transitions | Where-Object { $_.to.statusCategory.key -eq "indeterminate" } | Select-Object -First 1
    }

    if ($inDevTrans) {
        issue-tracker_transition_issue(issueKey: $teKey, transitionId: $inDevTrans.id)
        Write-Host "Sprint TE $teKey transitioned to '$($inDevTrans.to.name)' (In-Progress category)"
    } else {
        $available = ($transitions | Select-Object -ExpandProperty name) -join ', '
        Write-Warning "No In-Progress transition found for $teKey — available: $available"
        Write-Warning "Please transition $teKey manually before execution proceeds."
    }
}
```

---

## 5. Hard Blocking Rule — `test_case_execution` Cannot Proceed Without Sprint TE

This rule is enforced at **Step 0B** in the `test_case_execution` agent. It is NOT bypassed for any reason.

### Decision table

| Condition | Action |
|-----------|--------|
| TC document missing | ❌ **STOP** — output blocking message (see below) |
| TC doc present but `test-management Test Key` field is blank or missing | ❌ **STOP** — output blocking message |
| test-management Test Key present, sprint TE exists, test IS in the TE, TE status category = `indeterminate` (In Progress) | ✅ **PROCEED** to Step 1 |
| test-management Test Key present, sprint TE exists, test IS in the TE, TE status category ≠ `indeterminate` | ⚙ Transition TE to In-Progress category (Step 4.4) → ✅ **PROCEED** |
| test-management Test Key present, sprint TE exists, test NOT yet in the TE | ⚙ Add test (Step 4.3) → Transition TE (Step 4.4) → ✅ **PROCEED** |
| test-management Test Key present, NO sprint TE exists, auto-create succeeds AND TE confirmed in sprint | ⚙ Run Sections 3 + 4 (auto-create, verify in sprint, bulk-add, transition) → ✅ **PROCEED** |
| test-management Test Key present, NO sprint TE exists, auto-create succeeds BUT TE NOT confirmed in sprint (permission issue) | ⚙ Notify PO/PM (Step 3.3) → ❌ **STOP** with Sprint Presence Wait Gate message (Step 3.2a). Re-run agent once TE is in sprint. |

### Blocking message template (for hard stops)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCKED — Test Execution cannot start
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Story:   {STORY-KEY}
Reason:  {reason}

Required action:
  {action}

Run the agent below to resolve this gap, then retry:
  {agent-name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

| Reason | Required action | Agent to run |
|--------|----------------|--------------|
| TC document missing | Run test_case_preparation to create the TC document and test-management Test | `test_case_preparation` |
| `test-management Test Key` blank in TC doc | Re-run test_case_preparation — the test-management Test was not created | `test_case_preparation` |

---

## 6. Post-Execution TE Status Sync

After all steps in the execution are complete:

1. If ALL steps are PASS → call `Set-test-managementTestRunStatus -Status "PASS"` on the test run
2. If ANY step FAIL → call `Set-test-managementTestRunStatus -Status "FAIL"` and link each issue-tracker Defect to the TE via `issue-tracker_create_issue_link`
3. Evaluate the TE overall:
   - All tests in TE = PASS → transition the TE issue-tracker issue to `Done` via `issue-tracker_transition_issue`
   - Any test FAIL → leave TE in `In Progress`; add a comment listing failed tests and linked defects

---

## 7. Project Notification Configuration

**Primary source**: `.vscode/mcp.local.json` → `projectContacts.{PROJECT-KEY}`.  
AccountIds and email addresses are stored **only** in `mcp.local.json` — never in this skill or any committed file.

Agents read contacts using this pattern:

```powershell
# ── Read project contacts from mcp.local.json (sole source of accountIds) ──
$mcpLocal         = Get-Content ".vscode/mcp.local.json" -Raw | ConvertFrom-Json
$contacts         = $mcpLocal.projectContacts.STORY

$ManagerAccountId = $contacts.manager.accountId       # never hardcoded here
$PoAccountId      = $contacts.productOwner.accountId  # override by story reporter if present

# ── Other Sprint TE config ─────────────────────────────────────────────────
$ProjectKey       = "STORY"          # issue-tracker project key
$SprintBoardName  = "STORY Board"    # board name (used to resolve boardId)

# Microsoft Teams incoming webhook URLs
# Teams incoming webhooks are not available in this org (Connectors/Workflows restricted).
# Notification mode: issue-tracker comment @PO @Manager only (built-in fallback — no action needed).
# To enable Teams notifications later: add webhook URLs here once org enables them.
$TeamsWebhookUrls = @()   # Empty = issue-tracker-only mode (active fallback)
```

### STORY Project — Current Contact Registry

Stored in `.vscode/mcp.local.json → projectContacts.STORY`. AccountIds are **not** listed here.

| Role | Name | Email |
|------|------|-------|
| Product Owner | REHMAN,SUNIL | sunil_rehman@exampleqa.local |
| Manager / PM | KICINSKI,MIKE | mike.kicinski@exampleqa.local |

> **Update contacts**: Edit `.vscode/mcp.local.json` → `projectContacts.STORY` section. Agents pick up the new values automatically — no skill edit needed.

### STORY Project — Notification Settings

| Setting | Value |
|---------|-------|
| Project Key | `STORY` |
| Teams Group 1 | **CID Scurm Team Chat** — webhook disabled (org restriction); issue-tracker comment fallback active |
| Teams Group 2 | **AC1 Daily Stand-up** — webhook disabled (org restriction); issue-tracker comment fallback active |
| Sprint TE naming pattern | `Sprint TE: {SPRINT-NAME} — STORY` |
| TE search scope | Active sprint only (`status != Done`) |
| TE required status before execution | Status category = `indeterminate` (In Progress / In Dev / Active) |
| Notification mode | **issue-tracker comment @PO @Manager** (Teams webhooks disabled — `$TeamsWebhookUrls = @()`) |

---

## 8. Quick Reference — Agent Decision Tree

```
test_case_execution Step 0B (or test_case_preparation final step)
    │
    ├─ TC doc missing?
    │       YES ──► STOP / BLOCK: "Run test_case_preparation first"
    │
    ├─ test-management Test Key in TC doc?
    │       NO ──► STOP / BLOCK: "test-management Test Key missing — re-run test_case_preparation"
    │
    └─ YES ──► Get active sprint (Section 2.1)
                    │
                    └─ Sprint TE search (Section 2.2)
                            │
                            ├─ TE found, test already in it
                            │       └─ TE status = "In Dev"? ──► YES ──► PROCEED
                            │                                    NO ──► Transition to "In Dev" (§4.4) ──► PROCEED
                            │
                            ├─ TE found, test NOT in it
                            │       └─ Add test (§4.3) ──► Transition to "In Dev" (§4.4) ──► PROCEED
                            │
                            └─ No TE found
                                    ├─ Create TE (Section 3.1)
                                    ├─ Move to sprint (Section 3.2)
                                    ├─ Notify PO/PM: issue-tracker comment (Section 3.3)
                                    ├─ Notify PO/PM: Teams: "CID Scurm Team Chat" + "AC1 Daily Stand-up" (Section 3.4)
                                    ├─ Bulk-add all active sprint tests (Section 4)
                                    ├─ Transition TE to "In Dev" (§4.4)
                                    └─ PROCEED
```
