<#
.SYNOPSIS
    Registers the QA Automation Orchestrator as a scheduled Windows Task.
    Run this ONCE as Administrator to set up the automation.

.DESCRIPTION
    Creates a Windows Task Scheduler task that runs qa-automation-orchestrator.ps1
    every 15 minutes. When triggered, it polls Jira for new sprint stories and
    automatically generates test cases via Ollama.

.PARAMETER BoardId
    Jira Agile board ID (from your board URL: /jira/software/projects/PROJ/boards/123)

.PARAMETER ProjectKey
    Jira project key (e.g. OLAC)

.PARAMETER OllamaModel
    Ollama model to use. Default: llama3.2  (run: ollama pull llama3.2 first)

.PARAMETER IntervalMinutes
    How often to poll Jira for new stories. Default: 15 minutes.

.EXAMPLE
    # Run as Administrator:
    .\scripts\setup-task-scheduler.ps1 -BoardId 42 -ProjectKey OLAC

    # Poll every 10 minutes using mistral model:
    .\scripts\setup-task-scheduler.ps1 -BoardId 42 -ProjectKey OLAC -OllamaModel mistral -IntervalMinutes 10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $BoardId,
    [Parameter(Mandatory)][string] $ProjectKey,
    [string] $OllamaModel      = "llama3.2",
    [int]    $IntervalMinutes  = 15
)

$taskName    = "QA-Automation-Orchestrator"
$orchestrator = Join-Path $PSScriptRoot "qa-automation-orchestrator.ps1"
$repoRoot     = Split-Path $PSScriptRoot -Parent

if (-not (Test-Path $orchestrator)) {
    throw "Orchestrator script not found: $orchestrator"
}

# Build the PowerShell arguments string
$psArgs = "-NonInteractive -NoProfile -ExecutionPolicy Bypass " +
          "-File `"$orchestrator`" " +
          "-BoardId $BoardId " +
          "-ProjectKey $ProjectKey " +
          "-OllamaModel $OllamaModel"

Write-Host "=== QA Automation Task Scheduler Setup ==="
Write-Host "  Task name    : $taskName"
Write-Host "  Orchestrator : $orchestrator"
Write-Host "  Board ID     : $BoardId"
Write-Host "  Project Key  : $ProjectKey"
Write-Host "  Model        : $OllamaModel"
Write-Host "  Interval     : every $IntervalMinutes minutes"
Write-Host ""

# Remove existing task if it exists
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Host "Removing existing task '$taskName'..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Define task components
$action  = New-ScheduledTaskAction `
    -Execute   "powershell.exe" `
    -Argument  $psArgs `
    -WorkingDirectory $repoRoot

$trigger = New-ScheduledTaskTrigger `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -Once `
    -At (Get-Date)

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit      (New-TimeSpan -Minutes 10) `
    -MultipleInstances       IgnoreNew `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

# Register the task (runs as current user)
Register-ScheduledTask `
    -TaskName  $taskName `
    -Action    $action `
    -Trigger   $trigger `
    -Settings  $settings `
    -RunLevel  Highest `
    -Force | Out-Null

Write-Host "Task '$taskName' registered successfully."
Write-Host ""
Write-Host "--- Verify setup ---"
Write-Host "  View task  : Get-ScheduledTask -TaskName '$taskName' | Format-List"
Write-Host "  Run now    : Start-ScheduledTask -TaskName '$taskName'"
Write-Host "  View log   : Get-Content '$repoRoot\scripts\qa-automation.log' -Tail 30"
Write-Host "  Remove     : Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
Write-Host ""
Write-Host "=== Setup complete. Automation is now active. ==="
