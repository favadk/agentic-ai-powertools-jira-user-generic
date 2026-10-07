---
description: test-management Cloud integration patterns using the test-management-api.ps1 helper script for test creation, execution, and step management
---

# test-management Integration

## Prerequisites

The test-management helper script must be dot-sourced before use:

```powershell
cd "C:\Agentic-AI\agentic-ai-powertools-issue-tracker-user-generic"
. .\scripts\test-management-api.ps1
```

Available functions: `New-test-managementTest`, `New-test-managementTestExecution`, `Show-test-managementTestRunSteps`, `Get-test-managementTestRunId`, `Get-test-managementTestRunSteps`, `Set-test-managementStepResult`, `Add-test-managementStepEvidence`, `Set-test-managementTestRunStatus`

---

## Creating an test-management Test Issue

Use `New-test-managementTest` to create one test-management Test issue per User Story. All test cases become steps within that single issue.

```powershell
$steps = @(
    @{ Action = "TC-01 [AC-01]: {TC title} — Step 1: {action}"; Data = "{test data}"; Expected = "{expected result}" },
    @{ Action = "TC-01 [AC-01]: {TC title} — Step 2: {action}"; Data = "";            Expected = "{expected result}" }
    # ... one entry per step across ALL test cases
)

$testKey = New-test-managementTest `
    -ProjectKey  "{PROJECT-KEY}" `
    -Summary     "TC {STORY-KEY}: {Story Summary}" `
    -StoryKey    "{STORY-KEY}" `
    -Steps       $steps `
    -Description "test-management Test for {STORY-KEY}. Local doc: docs/TestCases/TC_{STORY-KEY}.md"

Write-Host "test-management Test created: $testKey"
```

**Step prefix rule**: Prefix every step `Action` with `TC-{nn} [{AC-ref}]:` so the test-management execution view shows which test case and AC each step belongs to.

After creation: record the test-management Test key in the TC document header as `test-management Test Key: {KEY}`.

---

## Creating a Test Execution

```powershell
$execKey = New-test-managementTestExecution `
    -ProjectKey   "{PROJECT-KEY}" `
    -StoryKey     "{STORY-KEY}" `
    -TestKeys     @("{test-management-TEST-KEY}") `
    -Environment  "{ENVIRONMENT}" `
    -Summary      "Test Execution Cycle {N}: {STORY-KEY} — {Story Summary}"

Write-Host "Test Execution created: $execKey"
# View at: https://app.example.com
```

---

## Getting Test Run Steps

```powershell
$runData = Show-test-managementTestRunSteps -TestExecKey $execKey -TestKey "{test-management-TEST-KEY}"
$runId   = $runData.RunId
$steps   = $runData.Steps
Write-Host "Test Run ID: $runId | Steps: $($steps.Count)"
```

---

## Setting Step Results and Attaching Evidence

```powershell
# Set step result
Set-test-managementStepResult `
    -TestRunId $runId `
    -StepId    "{step.id}" `
    -Status    "{PASS|FAIL|BLOCKED|TODO}" `
    -Comment   "{actual result text}"

# Attach screenshot evidence
Add-test-managementStepEvidence `
    -TestRunId $runId `
    -StepId    "{step.id}" `
    -FilePath  "{path/to/screenshot.png}"
```

---

## Setting Overall Test Run Status

```powershell
$overallStatus = if ($failCount -gt 0) { "FAIL" } elseif ($blockedCount -gt 0) { "ABORTED" } else { "PASS" }
Set-test-managementTestRunStatus -TestRunId $runId -Status $overallStatus
```

---

## Fallback If test-management API Fails

If the test-management step API returns a non-2xx response:
- The issue-tracker Test issue was still created (issue-tracker API succeeded).
- Add steps manually: open the issue in browser and use test-management's built-in step editor.
- Note in the TC document: `test-management steps must be added manually — API not available`.
- Do **NOT** block the user — the local TC document is the authoritative source.

---

## test-management Cloud Direct API (test-management.Mcp.exe)

For bulk import via the test-management Cloud REST API, use the `test-managementImportTestSteps` tool from the test-management MCP server:
- Auth endpoint: `POST https://test-management.cloud.gettest-management.app/api/v2/authenticate`
- Import endpoint: `POST https://us.test-management.cloud.gettest-management.app/api/v2/import/test`
- Credentials: set `test-management_CLIENT_ID` and `test-management_CLIENT_SECRET` in `.vscode/mcp.local.json` under the `test-management` server entry.
- Example payload: see `scripts/test-management-import-STORY-0000.json`.
