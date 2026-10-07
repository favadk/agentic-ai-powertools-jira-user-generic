---
description: Xray Cloud integration patterns using the xray-api.ps1 helper script for test creation, execution, and step management
---

# Xray Integration

## Prerequisites

The Xray helper script must be dot-sourced before use:

```powershell
cd "C:\Agentic-AI\agentic-ai-powertools-jira-user-generic"
. .\scripts\xray-api.ps1
```

Available functions: `New-XrayTest`, `New-XrayTestExecution`, `Show-XrayTestRunSteps`, `Get-XrayTestRunId`, `Get-XrayTestRunSteps`, `Set-XrayStepResult`, `Add-XrayStepEvidence`, `Set-XrayTestRunStatus`

---

## Creating an Xray Test Issue

Use `New-XrayTest` to create one Xray Test issue per User Story. All test cases become steps within that single issue.

```powershell
$steps = @(
    @{ Action = "TC-01 [AC-01]: {TC title} — Step 1: {action}"; Data = "{test data}"; Expected = "{expected result}" },
    @{ Action = "TC-01 [AC-01]: {TC title} — Step 2: {action}"; Data = "";            Expected = "{expected result}" }
    # ... one entry per step across ALL test cases
)

$testKey = New-XrayTest `
    -ProjectKey  "{PROJECT-KEY}" `
    -Summary     "TC {STORY-KEY}: {Story Summary}" `
    -StoryKey    "{STORY-KEY}" `
    -Steps       $steps `
    -Description "Xray Test for {STORY-KEY}. Local doc: docs/TestCases/TC_{STORY-KEY}.md"

Write-Host "Xray Test created: $testKey"
```

**Step prefix rule**: Prefix every step `Action` with `TC-{nn} [{AC-ref}]:` so the Xray execution view shows which test case and AC each step belongs to.

After creation: record the Xray Test key in the TC document header as `Xray Test Key: {KEY}`.

---

## Creating a Test Execution

```powershell
$execKey = New-XrayTestExecution `
    -ProjectKey   "{PROJECT-KEY}" `
    -StoryKey     "{STORY-KEY}" `
    -TestKeys     @("{XRAY-TEST-KEY}") `
    -Environment  "{ENVIRONMENT}" `
    -Summary      "Test Execution Cycle {N}: {STORY-KEY} — {Story Summary}"

Write-Host "Test Execution created: $execKey"
# View at: https://app.example.com
```

---

## Getting Test Run Steps

```powershell
$runData = Show-XrayTestRunSteps -TestExecKey $execKey -TestKey "{XRAY-TEST-KEY}"
$runId   = $runData.RunId
$steps   = $runData.Steps
Write-Host "Test Run ID: $runId | Steps: $($steps.Count)"
```

---

## Setting Step Results and Attaching Evidence

```powershell
# Set step result
Set-XrayStepResult `
    -TestRunId $runId `
    -StepId    "{step.id}" `
    -Status    "{PASS|FAIL|BLOCKED|TODO}" `
    -Comment   "{actual result text}"

# Attach screenshot evidence
Add-XrayStepEvidence `
    -TestRunId $runId `
    -StepId    "{step.id}" `
    -FilePath  "{path/to/screenshot.png}"
```

---

## Setting Overall Test Run Status

```powershell
$overallStatus = if ($failCount -gt 0) { "FAIL" } elseif ($blockedCount -gt 0) { "ABORTED" } else { "PASS" }
Set-XrayTestRunStatus -TestRunId $runId -Status $overallStatus
```

---

## Fallback If Xray API Fails

If the Xray step API returns a non-2xx response:
- The Jira Test issue was still created (Jira API succeeded).
- Add steps manually: open the issue in browser and use Xray's built-in step editor.
- Note in the TC document: `Xray steps must be added manually — API not available`.
- Do **NOT** block the user — the local TC document is the authoritative source.

---

## Xray Cloud Direct API (Xray.Mcp.exe)

For bulk import via the Xray Cloud REST API, use the `XrayImportTestSteps` tool from the Xray MCP server:
- Auth endpoint: `POST https://xray.cloud.getxray.app/api/v2/authenticate`
- Import endpoint: `POST https://us.xray.cloud.getxray.app/api/v2/import/test`
- Credentials: set `XRAY_CLIENT_ID` and `XRAY_CLIENT_SECRET` in `.vscode/mcp.local.json` under the `xray` server entry.
- Example payload: see `scripts/xray-import-STORY-0000.json`.
