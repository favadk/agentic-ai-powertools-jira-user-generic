#Requires -Version 5.1
<#
.SYNOPSIS
    Registers QA monitoring scripts as Windows Scheduled Tasks (every 30 min).
    Must be run once as Administrator.

.PARAMETER IntervalMinutes
    Poll interval in minutes. Default: 30

.EXAMPLE
    # Run PowerShell as Administrator, then:
    .\scripts\setup-story-monitor-scheduler.ps1

    # Custom interval:
    .\scripts\setup-story-monitor-scheduler.ps1 -IntervalMinutes 15
#>

[CmdletBinding()]
param(
    [int] $IntervalMinutes = 30
)

# Self-elevate if not already running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -IntervalMinutes $IntervalMinutes"
    Start-Process powershell.exe -Verb RunAs -ArgumentList $psArgs
    exit
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$psExe    = (Get-Command powershell.exe).Source
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10) `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew

$trigger = New-ScheduledTaskTrigger `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -Once -At (Get-Date).AddMinutes(1)

# --- Task 1: PO Response Monitor ---
$a1 = New-ScheduledTaskAction -Execute $psExe `
    -Argument "-NonInteractive -NoProfile -ExecutionPolicy Bypass -File `"$repoRoot\scripts\monitor-po-responses.ps1`" -PostAck" `
    -WorkingDirectory $repoRoot

Register-ScheduledTask -TaskName "QA-Monitor-PO-Responses" `
    -Action $a1 -Trigger $trigger -Settings $settings `
    -RunLevel Highest -Force | Out-Null
Write-Host "[OK] QA-Monitor-PO-Responses registered (every $IntervalMinutes min)"

# --- Task 2: Story Change Monitor ---
$a2 = New-ScheduledTaskAction -Execute $psExe `
    -Argument "-NonInteractive -NoProfile -ExecutionPolicy Bypass -File `"$repoRoot\scripts\monitor-story-changes.ps1`" -PostAck" `
    -WorkingDirectory $repoRoot

Register-ScheduledTask -TaskName "QA-Monitor-Story-Changes" `
    -Action $a2 -Trigger $trigger -Settings $settings `
    -RunLevel Highest -Force | Out-Null
Write-Host "[OK] QA-Monitor-Story-Changes registered (every $IntervalMinutes min)"

# --- Task 3: Xray Test Comment Review Processor ---
$triggerReviewProcessor = New-ScheduledTaskTrigger `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -Once -At (Get-Date).AddMinutes(3)

$a3 = New-ScheduledTaskAction -Execute $psExe `
    -Argument "-NonInteractive -NoProfile -ExecutionPolicy Bypass -File `"$repoRoot\scripts\process-qa-review-triggers.ps1`"" `
    -WorkingDirectory $repoRoot

Register-ScheduledTask -TaskName "QA-Process-Test-Comment-Reviews" `
    -Action $a3 -Trigger $triggerReviewProcessor -Settings $settings `
    -RunLevel Highest -Force | Out-Null
Write-Host "[OK] QA-Process-Test-Comment-Reviews registered (every $IntervalMinutes min, after monitors)"

# --- Task 4: QA Agent Trigger Dispatcher ---
$triggerDispatcher = New-ScheduledTaskTrigger `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -Once -At (Get-Date).AddMinutes(4)

$a4 = New-ScheduledTaskAction -Execute $psExe `
    -Argument "-NonInteractive -NoProfile -ExecutionPolicy Bypass -File `"$repoRoot\scripts\process-qa-agent-triggers.ps1`"" `
    -WorkingDirectory $repoRoot

Register-ScheduledTask -TaskName "QA-Process-Agent-Triggers" `
    -Action $a4 -Trigger $triggerDispatcher -Settings $settings `
    -RunLevel Highest -Force | Out-Null
Write-Host "[OK] QA-Process-Agent-Triggers registered (every $IntervalMinutes min, after monitors)"

# --- Task 5: Health Check (every 60 min) ---
$triggerHealth = New-ScheduledTaskTrigger `
    -RepetitionInterval (New-TimeSpan -Minutes 60) `
    -Once -At (Get-Date).AddMinutes(2)

$a4 = New-ScheduledTaskAction -Execute $psExe `
    -Argument "-NonInteractive -NoProfile -ExecutionPolicy Bypass -File `"$repoRoot\scripts\monitor-health-check.ps1`"" `
    -WorkingDirectory $repoRoot

Register-ScheduledTask -TaskName "QA-Monitor-HealthCheck" `
    -Action $a4 -Trigger $triggerHealth -Settings $settings `
    -RunLevel Highest -Force | Out-Null
Write-Host "[OK] QA-Monitor-HealthCheck registered (every 60 min)"
Write-Host "     Sends Teams + Jira + EventLog notifications on workflow failures."
Write-Host "     Set env var TEAMS_WEBHOOK_URL to enable Teams alerts."

Write-Host ""
Write-Host "Both monitors, comment review, and agent trigger dispatcher are now active. The dispatcher invokes the installed Copilot CLI for verified execution handoffs. Next run in ~$IntervalMinutes minutes."
Write-Host "To run immediately: Start-ScheduledTask 'QA-Process-Test-Comment-Reviews'"
