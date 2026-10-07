#Requires -Version 5.1
<#
.SYNOPSIS
    QA Framework Health Check - detects workflow failures and sends notifications.
.DESCRIPTION
    Runs every 60 min (Task: QA-Monitor-HealthCheck) and checks:
    1. Scheduled monitors, comment review processor, and agent trigger dispatcher are registered and have a NextRunTime
      2. Unprocessed trigger files sitting longer than $StaleMinutes
      3. monitor-state.json entries stuck in PENDING_SCRIPT_RUN
      4. Jira API connectivity
    On failure: Windows Event Log + Jira comment on each affected story.
.PARAMETER StaleMinutes
    Trigger files older than this are flagged. Default: 60.
.PARAMETER DryRun
    Log findings without posting notifications.
#>
[CmdletBinding()]
param(
    [int]   $StaleMinutes = 60,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot  = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$xrayApi   = Join-Path $repoRoot (Join-Path 'scripts' 'xray-api.ps1')
. $xrayApi

$failures  = New-Object System.Collections.Generic.List[hashtable]
$warnings  = New-Object System.Collections.Generic.List[hashtable]
$ts        = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

function Add-Failure([string]$area, [string]$msg, [string]$story = '') {
    $failures.Add(@{ area = $area; msg = $msg; story = $story })
    Write-Warning "[FAIL] [$area] $msg"
}
function Add-Warn([string]$area, [string]$msg, [string]$story = '') {
    $warnings.Add(@{ area = $area; msg = $msg; story = $story })
    Write-Host "[WARN] [$area] $msg" -ForegroundColor Yellow
}

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] QA Framework Health Check starting..." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# CHECK 1 -- Scheduled tasks have a valid NextRunTime
# ---------------------------------------------------------------------------
Write-Host "[..] Checking scheduled tasks..."
foreach ($name in @('QA-Monitor-Story-Changes','QA-Monitor-PO-Responses','QA-Process-Test-Comment-Reviews','QA-Process-Agent-Triggers')) {
    $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
    if (-not $task) {
        Add-Failure 'Scheduler' "Task '$name' NOT registered. Run setup-story-monitor-scheduler.ps1 as Admin."
        continue
    }
    if ($task.State -eq 'Disabled') {
        Add-Failure 'Scheduler' "Task '$name' is DISABLED. Run: Enable-ScheduledTask '$name'"
        continue
    }
    $info = Get-ScheduledTaskInfo -TaskName $name -ErrorAction SilentlyContinue
    if ($info -and (-not $info.NextRunTime -or $info.NextRunTime.Year -lt 2020)) {
        Add-Failure 'Scheduler' "Task '$name' has no upcoming NextRunTime. Re-run setup-story-monitor-scheduler.ps1."
    } elseif ($info -and (-not $info.LastRunTime -or $info.LastRunTime.Year -lt 2020)) {
        Add-Warn 'Scheduler' "Task '$name' has never run. Triggering now..."
        if (-not $DryRun) { Start-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue }
    } else {
        $age = if ($info.LastRunTime) { [int]((Get-Date) - $info.LastRunTime).TotalMinutes } else { 9999 }
        if ($age -gt 90) {
            Add-Warn 'Scheduler' "Task '$name' last ran $age min ago (expected <=60)."
        } else {
            Write-Host "[OK] $name | LastRun=$($info.LastRunTime.ToString('HH:mm')) NextRun=$($info.NextRunTime.ToString('HH:mm'))"
        }
        if ($info.LastTaskResult -and $info.LastTaskResult -ne 0 -and $info.LastTaskResult -ne 267009) {
            Add-Failure 'Scheduler' "Task '$name' last exit code $($info.LastTaskResult) (non-zero = failed)."
        }
    }
}

$copilotPath = Join-Path $env:APPDATA 'npm\copilot.cmd'
if (-not (Test-Path $copilotPath)) {
    Add-Failure 'CopilotCLI' "Copilot CLI not found at $copilotPath. Agent trigger handoffs cannot run."
}

# ---------------------------------------------------------------------------
# CHECK 2 -- Stale unprocessed trigger files
# ---------------------------------------------------------------------------
Write-Host "[..] Checking trigger files..."
$triggerDir = Join-Path $repoRoot (Join-Path 'scripts' 'triggers')
if (Test-Path $triggerDir) {
    Set-StrictMode -Off
    $cutoff = (Get-Date).AddMinutes(-$StaleMinutes)
    $triggerFiles = Get-ChildItem -Path $triggerDir -File | Where-Object {
        $_.Extension -eq '.json' -and $_.Name -notlike '*.processed*'
    }
    foreach ($file in $triggerFiles) {
        if ($file.LastWriteTime -lt $cutoff) {
            try {
                $t = Get-Content $file.FullName -Raw | ConvertFrom-Json
                $ageMin = [int]((Get-Date) - $file.LastWriteTime).TotalMinutes
                Add-Failure 'Triggers' "$($file.Name) unprocessed for $ageMin min (changeType=$($t.changeType)). Verify QA-Process-Test-Comment-Reviews and its Jira/Xray/Ollama prerequisites." "$($t.issueKey)"
            } catch {
                Add-Warn 'Triggers' "$($file.Name) is malformed and cannot be parsed."
            }
        }
    }
    Set-StrictMode -Version Latest
    Write-Host "[OK] Trigger check complete."
}

# ---------------------------------------------------------------------------
# CHECK 3 -- monitor-state.json stuck PENDING_SCRIPT_RUN entries
# ---------------------------------------------------------------------------
Write-Host "[..] Checking monitor-state for stuck entries..."
$stateFile = Join-Path $repoRoot (Join-Path 'scripts' 'monitor-state.json')
if (Test-Path $stateFile) {
    Set-StrictMode -Off
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    if ($state.issues) {
        foreach ($issue in $state.issues) {
            if ($issue.tcDocStatus -eq 'PENDING_SCRIPT_RUN' -and $issue.executionScript) {
                $scriptPath = Join-Path $repoRoot ($issue.executionScript -replace '/', '\')
                if (Test-Path $scriptPath) {
                    $ageHrs = [int]((Get-Date) - (Get-Item $scriptPath).LastWriteTime).TotalHours
                    if ($ageHrs -gt 1) {
                        Add-Failure 'WorkflowStuck' "$($issue.issueKey): Script '$($issue.executionScript)' generated $ageHrs hrs ago but never executed. Run: . .\scripts\xray-api.ps1; .\$($issue.executionScript)" "$($issue.issueKey)"
                    }
                }
            }
        }
    }
    Set-StrictMode -Version Latest
    Write-Host "[OK] monitor-state check complete."
}

# ---------------------------------------------------------------------------
# CHECK 4 -- Jira API connectivity
# ---------------------------------------------------------------------------
Write-Host "[..] Checking Jira API..."
try {
    $creds  = Get-XrayCreds
    $jiraUrl = if ($env:JIRA_URL) { $env:JIRA_URL } else { 'https://jira.exampleqa.local' }
    $null = Invoke-RestMethod -Uri "$jiraUrl/rest/api/3/myself" -Headers $creds.Headers -TimeoutSec 10 -ErrorAction Stop
    Write-Host "[OK] Jira API reachable."
} catch {
    Add-Failure 'JiraAPI' "Jira unreachable: $($_.Exception.Message). Monitors will silently fail."
}

# ---------------------------------------------------------------------------
# Exit clean if no issues
# ---------------------------------------------------------------------------
if ($failures.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "`n[OK] All health checks passed. $ts" -ForegroundColor Green
    exit 0
}

# ---------------------------------------------------------------------------
# Build notification message
# ---------------------------------------------------------------------------
$lines = @("QA FRAMEWORK HEALTH CHECK ALERT - $ts", "FAILURES: $($failures.Count)  WARNINGS: $($warnings.Count)", "")
if ($failures.Count -gt 0) {
    $lines += "--- FAILURES (action required) ---"
    foreach ($f in $failures) { $lines += "[$($f.area)] $($f.msg)" }
    $lines += ""
}
if ($warnings.Count -gt 0) {
    $lines += "--- WARNINGS ---"
    foreach ($w in $warnings) { $lines += "[$($w.area)] $($w.msg)" }
    $lines += ""
}
$lines += "REQUIRED ACTIONS:"
$lines += "1. Verify QA-Process-Test-Comment-Reviews can access Ollama, Jira, and Xray credentials."
$lines += "2. If scheduler tasks are missing or disabled: run setup-story-monitor-scheduler.ps1 as Admin."
$lines += "3. Inspect the failed trigger and generated review document before retrying."

$fullText = $lines -join "`n"
Write-Host "`n$fullText"

# ---------------------------------------------------------------------------
# CHANNEL 1 -- Windows Event Log (always, no config needed)
# ---------------------------------------------------------------------------
if (-not $DryRun) {
    $src = 'QAFrameworkHealthCheck'
    if (-not [System.Diagnostics.EventLog]::SourceExists($src)) {
        New-EventLog -LogName Application -Source $src -ErrorAction SilentlyContinue
    }
    $evtType = if ($failures.Count -gt 0) { 'Error' } else { 'Warning' }
    Write-EventLog -LogName Application -Source $src -EventId 7502 -EntryType $evtType -Message $fullText -ErrorAction SilentlyContinue
    Write-Host "[OK] Written to Windows Event Log (Application > QAFrameworkHealthCheck, Event ID 7502)"
}

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# CHANNEL 3 -- Jira comment on each affected story
# ---------------------------------------------------------------------------
if (-not $DryRun) {
    try {
        $creds2  = Get-XrayCreds
        $jiraUrl2 = if ($env:JIRA_URL) { $env:JIRA_URL } else { 'https://jira.exampleqa.local' }
        $affected = ($failures + $warnings) | Where-Object { $_.story } | ForEach-Object { $_.story } | Sort-Object -Unique
        foreach ($sk in $affected) {
            $issues = ($failures + $warnings) | Where-Object { $_.story -eq $sk }
            $msgLines = $issues | ForEach-Object { "[$($_.area)] $($_.msg)" }
            $adf = @{
                version = 1; type = 'doc'
                content = @(
                    @{ type='paragraph'; content=@(@{ type='text'; text="[QA Health Check] $ts"; marks=@(@{type='strong'}) }) },
                    @{ type='paragraph'; content=@(@{ type='text'; text="Automated health check detected issues blocking QA workflow:" }) }
                )
            }
            foreach ($ml in $msgLines) {
                $adf.content += @{ type='paragraph'; content=@(@{ type='text'; text=$ml }) }
            }
            $adf.content += @{ type='paragraph'; content=@(
                @{ type='text'; text='Action: verify QA-Process-Test-Comment-Reviews and its Ollama, Jira, and Xray prerequisites, then retry the scheduled task.' }
            )}
            $hdrs = $creds2.Headers.Clone()
            $hdrs['Content-Type'] = 'application/json'
            $body = @{ body = $adf } | ConvertTo-Json -Depth 20
            Invoke-RestMethod -Uri "$jiraUrl2/rest/api/3/issue/$sk/comment" -Method POST -Headers $hdrs -Body $body -ErrorAction SilentlyContinue
            Write-Host "[OK] Jira comment posted on $sk"
        }
    } catch {
        Write-Warning "[!!] Jira notification failed: $($_.Exception.Message)"
    }
}

if ($failures.Count -gt 0) { exit 1 } else { exit 0 }
