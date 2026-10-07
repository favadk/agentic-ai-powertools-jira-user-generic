#Requires -Version 5.1
<#!
.SYNOPSIS
    Polls Jira for story/defect description and status changes and writes trigger files.

.DESCRIPTION
    - Reads scripts/monitor-state.json
    - Optionally auto-adds issues from the active sprint (sprintWatch)
    - Detects DESCRIPTION_CHANGE and STATUS_CHANGE
    - Auto-registers linked Defect/Bug issues

.PARAMETER StateFile
    Path to monitor-state.json (default: scripts/monitor-state.json)

.PARAMETER PostAck
    If set, posts an informational Jira comment when description change is detected.
#>

[CmdletBinding()]
param(
    [string] $StateFile = "",
    [switch] $PostAck
)

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not $StateFile) { $StateFile = Join-Path $PSScriptRoot "monitor-state.json" }
$triggersDir = Join-Path $PSScriptRoot "triggers"
if (-not (Test-Path $triggersDir)) { New-Item -ItemType Directory -Path $triggersDir | Out-Null }

. (Join-Path $PSScriptRoot "xray-api.ps1") 2>$null
$creds = Get-XrayCreds

function Get-AdfPlainText {
    param([object]$Node)
    if ($null -eq $Node) { return "" }

    $buf = [System.Text.StringBuilder]::new()
    if ($Node.type -eq "text" -and $Node.text) {
        [void]$buf.Append($Node.text)
    }

    if ($Node.content) {
        foreach ($child in $Node.content) {
            $t = Get-AdfPlainText -Node $child
            if ($t) {
                [void]$buf.Append($t)
                [void]$buf.Append(" ")
            }
        }
    }

    return $buf.ToString().Trim()
}

function Get-DescriptionHash {
    param([string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash($bytes)
    return ([System.BitConverter]::ToString($hash) -replace "-", "").ToLower()
}

$state = Get-Content $StateFile -Raw | ConvertFrom-Json
$now = (Get-Date).ToUniversalTime().ToString("o")
$anyUpdates = $false

Write-Host ""
Write-Host "========================================================"
Write-Host " Story Change Monitor - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host "========================================================"

$watchList = [System.Collections.ArrayList]::new()
if ($state.issues) {
    foreach ($i in $state.issues) { [void]$watchList.Add($i) }
}

$currentSprintIssueKeys = @{}
$currentSprintIssueStatus = @{}
$terminalStatuses = @('Done','Closed','Released','Cancelled','Won''t Do','Resolved')

$sw = $state.sprintWatch
if ($sw -and $sw.enabled) {
    Write-Host " Sprint watch enabled: Board $($sw.boardId)"

    try {
        $activeSprintResp = Invoke-WebRequest -Method GET -Uri "$($creds.Url)/rest/agile/1.0/board/$($sw.boardId)/sprint?state=active" -Headers $creds.Headers -UseBasicParsing | ConvertFrom-Json
        if ($activeSprintResp.values -and $activeSprintResp.values.Count -gt 0) {
            $activeSprint = $activeSprintResp.values[0]
            if ($activeSprint.id -ne $sw.sprintId -or $activeSprint.name -ne $sw.sprintName) {
                Write-Host "  Sprint changed: '$($sw.sprintName)' -> '$($activeSprint.name)' (ID $($activeSprint.id))"
                $sw | Add-Member -MemberType NoteProperty -Name "sprintId" -Value $activeSprint.id -Force
                $sw | Add-Member -MemberType NoteProperty -Name "sprintName" -Value $activeSprint.name -Force
                $state | Add-Member -MemberType NoteProperty -Name "sprintWatch" -Value $sw -Force
                $anyUpdates = $true
            } else {
                Write-Host "  Active sprint: '$($sw.sprintName)' (confirmed)"
            }
        }
    } catch {
        Write-Warning "  Could not detect active sprint dynamically: $_"
    }

    if ($sw.sprintId) {
        try {
            $sprintSlug = ($sw.sprintName -replace "\s+", "-")
            $actionableStatuses = @('In Progress','In Dev','Ready for Dev','Waiting for Verification','Ready for QA','In QA','Ready for Testing','Testing','In Testing')
            $sprintIssuesResp = Invoke-WebRequest -Method GET -Uri "$($creds.Url)/rest/agile/1.0/sprint/$($sw.sprintId)/issue?fields=key,summary,issuetype,status&maxResults=100" -Headers $creds.Headers -UseBasicParsing | ConvertFrom-Json

            foreach ($si in $sprintIssuesResp.issues) {
                if ($si.fields.issuetype.name -ne 'Story') { continue }
                if ($si.fields.status.name -in $terminalStatuses) { continue }

                $currentSprintIssueKeys[$si.key] = $true
                $currentSprintIssueStatus[$si.key] = $si.fields.status.name

                $exists = $watchList | Where-Object { $_.issueKey -eq $si.key }
                if ($exists) {
                    $previousSprintSlug = [string]$exists.sprintSlug
                    $previousStatus = [string]$exists.lastSeenStatus
                    if ($previousSprintSlug -and $previousSprintSlug -ne $sprintSlug) {
                        $xrayKey = if ($exists.xrayTestKey) { [string]$exists.xrayTestKey } else { "" }
                        $exists | Add-Member -MemberType NoteProperty -Name "previousSprintSlug" -Value $previousSprintSlug -Force
                        $exists | Add-Member -MemberType NoteProperty -Name "sprintSlug" -Value $sprintSlug -Force
                        $exists | Add-Member -MemberType NoteProperty -Name "tcDocPath" -Value "docs/TestCases/$sprintSlug/TC_$($si.key).md" -Force
                        $exists | Add-Member -MemberType NoteProperty -Name "lastSeenStatus" -Value $si.fields.status.name -Force
                        $state | Add-Member -MemberType NoteProperty -Name "issues" -Value $watchList.ToArray() -Force
                        $anyUpdates = $true

                        $triggerFile = Join-Path $triggersDir "$($si.key)-sprint-change.json"
                        @{
                            issueKey          = $si.key
                            storyKey          = $si.key
                            issueType         = $si.fields.issuetype.name
                            previousSprintSlug = $previousSprintSlug
                            sprintSlug        = $sprintSlug
                            xrayTestKey       = $xrayKey
                            tcDocPath         = Join-Path $repoRoot "docs/TestCases/$sprintSlug/TC_$($si.key).md"
                            changeType        = "SPRINT_CHANGE"
                            oldStatus         = $previousStatus
                            newStatus         = $si.fields.status.name
                            changedAt         = $now
                            detectedAt        = $now
                        } | ConvertTo-Json -Depth 5 | Set-Content $triggerFile
                        Write-Host "  Sprint carry-over detected: $($si.key) '$previousSprintSlug' -> '$sprintSlug'"
                    }
                    continue
                }
                if (-not $sw.autoAddNewStories) { continue }

                $currentStatus = $si.fields.status.name
                Write-Host "  Auto-adding: $($si.key) [$currentStatus] -- $($si.fields.summary)"

                $newEntry = [PSCustomObject]@{
                    issueKey        = $si.key
                    xrayTestKey     = $null
                    sprintSlug      = $sprintSlug
                    tcDocPath       = "docs/TestCases/$sprintSlug/TC_$($si.key).md"
                    tcrDocPath      = "docs/TestCaseReview/TCR_$($si.key).md"
                    descriptionHash = $null
                    lastSeenUpdated = $null
                    lastSeenStatus  = $currentStatus
                    status          = "ACTIVE"
                    detectedChanges = @()
                }

                [void]$watchList.Add($newEntry)
                $stateList = [System.Collections.ArrayList]@($state.issues)
                [void]$stateList.Add($newEntry)
                $state | Add-Member -MemberType NoteProperty -Name "issues" -Value $stateList.ToArray() -Force
                $anyUpdates = $true

                if ($currentStatus -in $actionableStatuses) {
                    $triggerFile = Join-Path $triggersDir "$($si.key)-status-change.json"
                    @{
                        issueKey    = $si.key
                        storyKey    = $si.key
                        issueType   = $si.fields.issuetype.name
                        sprintSlug  = $sprintSlug
                        xrayTestKey = ""
                        tcDocPath   = Join-Path $repoRoot "docs/TestCases/$sprintSlug/TC_$($si.key).md"
                        changeType  = "STATUS_CHANGE"
                        oldStatus   = $null
                        newStatus   = $currentStatus
                        changedAt   = $now
                        detectedAt  = $now
                        autoAdded   = $true
                    } | ConvertTo-Json -Depth 5 | Set-Content $triggerFile
                }
            }
        } catch {
            Write-Warning "  Sprint issue fetch failed: $_"
        }
    }
}

# Enforce current-sprint-only processing
if ($currentSprintIssueKeys.Count -gt 0) {
    $filteredWatchList = [System.Collections.ArrayList]::new()
    foreach ($w in $watchList) {
        if ($currentSprintIssueKeys.ContainsKey($w.issueKey)) {
            [void]$filteredWatchList.Add($w)
        }
    }

    $legacyCount = $watchList.Count - $filteredWatchList.Count
    if ($legacyCount -gt 0) {
        Write-Host " Ignoring $legacyCount legacy/out-of-sprint issue(s)."
    }
    $watchList = $filteredWatchList

    # Keep trigger directory focused on current sprint only.
    $triggerFiles = Get-ChildItem $triggersDir -Filter "*.json" -ErrorAction SilentlyContinue
    foreach ($tf in $triggerFiles) {
        $removeFile = $false

        if ($tf.Name -like "*-windows-update.json" -or $tf.Name -like "*-ready-to-run.json") {
            $removeFile = $true
        } else {
            try {
                $td = Get-Content $tf.FullName -Raw | ConvertFrom-Json
                if ($td.changeType -in @("WINDOWS_UPDATE", "READY_TO_RUN")) {
                    $removeFile = $true
                } elseif ($td.issueKey -and (-not $currentSprintIssueKeys.ContainsKey([string]$td.issueKey))) {
                    $removeFile = $true
                } elseif ($td.issueKey -and $currentSprintIssueStatus.ContainsKey([string]$td.issueKey) -and $currentSprintIssueStatus[[string]$td.issueKey] -in $terminalStatuses) {
                    $removeFile = $true
                } elseif ($td.changeType -eq "CREATE_TEST_CASE" -and $td.issueKey) {
                    $stateIssue = $state.issues | Where-Object { $_.issueKey -eq [string]$td.issueKey } | Select-Object -First 1
                    if ($stateIssue) {
                        $hasXray = $false
                        if ($stateIssue.PSObject.Properties.Name -contains "xrayTestKey") {
                            $hasXray = -not [string]::IsNullOrWhiteSpace([string]$stateIssue.xrayTestKey)
                        }

                        $hasTcDoc = $false
                        if ($stateIssue.PSObject.Properties.Name -contains "tcDocPath" -and -not [string]::IsNullOrWhiteSpace([string]$stateIssue.tcDocPath)) {
                            $hasTcDoc = Test-Path (Join-Path $repoRoot [string]$stateIssue.tcDocPath)
                        }

                        if ($hasXray -or $hasTcDoc) {
                            $removeFile = $true
                        }
                    }
                }
            } catch {
                # Keep non-parseable trigger files untouched here; explicit cleanup is handled separately.
            }
        }

        if ($removeFile) {
            Remove-Item $tf.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host " Watching $($watchList.Count) issue(s)"
Write-Host ""

foreach ($issue in $watchList) {
    Write-Host "[$($issue.issueKey)] Checking..."

    try {
        $issResp = Invoke-WebRequest -Method GET -Uri "$($creds.Url)/rest/api/3/issue/$($issue.issueKey)?fields=summary,description,updated,status,issuetype,issuelinks,subtasks" -Headers $creds.Headers -UseBasicParsing | ConvertFrom-Json
    } catch {
        Write-Warning "  [$($issue.issueKey)] Fetch failed: $_"
        continue
    }

    $f = $issResp.fields
    $jiraUpdated = $f.updated
    $jiraStatus = $f.status.name

    # Track the execution subtask independently of the parent story updated timestamp.
    # A subtask transition must be able to fire execution even when the story itself is unchanged.
    $executionSubtask = @($f.subtasks | Where-Object { $_.fields.summary -match '(?i)execute\s+test\s+case|test\s+case\s+execution' }) | Select-Object -First 1
    if ($executionSubtask) {
        $subtaskStatus = [string]$executionSubtask.fields.status.name
        $previousSubtaskStatus = if ($issue.executeTestCaseSubtaskStatus) { [string]$issue.executeTestCaseSubtaskStatus } else { "" }
        $issue | Add-Member -MemberType NoteProperty -Name "executeTestCaseSubtaskKey" -Value $executionSubtask.key -Force
        $issue | Add-Member -MemberType NoteProperty -Name "executeTestCaseSubtaskStatus" -Value $subtaskStatus -Force

        $enteredDev = $subtaskStatus -match '(?i)^in\s+dev$|^dev$|^in\s+progress$'
        $wasInDev = $previousSubtaskStatus -match '(?i)^in\s+dev$|^dev$|^in\s+progress$'
        if ($enteredDev -and (-not $wasInDev)) {
            $xrayKey = if ($issue.xrayTestKey) { [string]$issue.xrayTestKey } else { "" }
            $teKey = if ($issue.teKey) { [string]$issue.teKey } else { "" }
            $handoffTrigger = Join-Path $triggersDir "$($issue.issueKey)-execute-test-case.json"
            if (-not (Test-Path $handoffTrigger)) {
                @{
                    issueKey       = $issue.issueKey
                    storyKey       = $issue.issueKey
                    issueType      = "Story"
                    subtaskKey     = $executionSubtask.key
                    subtaskStatus  = $subtaskStatus
                    xrayTestKey    = $xrayKey
                    teKey          = $teKey
                    tcDocPath      = if ($issue.tcDocPath) { Join-Path $repoRoot $issue.tcDocPath } else { "" }
                    changeType     = "EXECUTE_TEST_CASE"
                    detectedAt     = $now
                    status         = "PENDING_DISPATCH"
                } | ConvertTo-Json -Depth 6 | Set-Content $handoffTrigger
                Write-Host "  Execute Test Case subtask entered '$subtaskStatus': $($executionSubtask.key)"
            }
            $anyUpdates = $true
        }
    }

    if ($jiraStatus -in $terminalStatuses) {
        Write-Host "  Skipping terminal status story: $jiraStatus"

        $terminalTriggers = Get-ChildItem $triggersDir -Filter "$($issue.issueKey)-*.json" -ErrorAction SilentlyContinue
        foreach ($tt in $terminalTriggers) {
            Remove-Item $tt.FullName -Force -ErrorAction SilentlyContinue
        }

        $issue | Add-Member -MemberType NoteProperty -Name "status" -Value "RESOLVED" -Force
        $issue | Add-Member -MemberType NoteProperty -Name "lastSeenStatus" -Value $jiraStatus -Force
        $issue | Add-Member -MemberType NoteProperty -Name "lastSeenUpdated" -Value $jiraUpdated -Force
        $anyUpdates = $true
        continue
    }

    $jiraDescText = if ($f.description) { Get-AdfPlainText -Node $f.description } else { "" }
    $newHash = Get-DescriptionHash -Text $jiraDescText

    if (-not $issue.lastSeenUpdated) {
        Write-Host "  First run - seeding baseline"
        $issue | Add-Member -MemberType NoteProperty -Name "descriptionHash" -Value $newHash -Force
        $issue | Add-Member -MemberType NoteProperty -Name "lastSeenUpdated" -Value $jiraUpdated -Force
        if (-not $issue.lastSeenStatus) {
            $issue | Add-Member -MemberType NoteProperty -Name "lastSeenStatus" -Value $jiraStatus -Force
        }
        $anyUpdates = $true
        continue
    }

    $wasUpdated = [datetime]$jiraUpdated -gt [datetime]$issue.lastSeenUpdated
    if (-not $wasUpdated) {
        Write-Host "  No changes since $($issue.lastSeenUpdated)"
        continue
    }

    Write-Host "  Updated at $jiraUpdated (was $($issue.lastSeenUpdated))"

    if ($newHash -ne $issue.descriptionHash) {
        Write-Host "  Description change detected"

        $xrayKey = if ($issue.xrayTestKey) { $issue.xrayTestKey } else { "" }
        $tcDoc = if ($issue.tcDocPath) { Join-Path $repoRoot $issue.tcDocPath } else { "" }
        $tcrDoc = if ($issue.tcrDocPath) { Join-Path $repoRoot $issue.tcrDocPath } else { "" }

        $triggerFile = Join-Path $triggersDir "$($issue.issueKey)-description.json"
        @{
            issueKey       = $issue.issueKey
            storyKey       = $issue.issueKey
            xrayTestKey    = $xrayKey
            tcDocPath      = $tcDoc
            tcrDocPath     = $tcrDoc
            changeType     = "DESCRIPTION_CHANGE"
            newDescription = $jiraDescText
            changedAt      = $jiraUpdated
            detectedAt     = $now
        } | ConvertTo-Json -Depth 5 | Set-Content $triggerFile

        if ($PostAck) {
            $ackBody = @{
                body = @{
                    version = 1
                    type = "doc"
                    content = @(
                        @{
                            type = "paragraph"
                            content = @(
                                @{ type = "text"; text = "[QA Monitor] Story description change detected at $jiraUpdated. story_monitor should process this update." }
                            )
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10

            try {
                Invoke-WebRequest -Method POST -Uri "$($creds.Url)/rest/api/3/issue/$($issue.issueKey)/comment" -Headers $creds.Headers -Body $ackBody -UseBasicParsing | Out-Null
            } catch {
                Write-Warning "  Failed to post description-change ack: $_"
            }
        }

        $issue | Add-Member -MemberType NoteProperty -Name "descriptionHash" -Value $newHash -Force
        $anyUpdates = $true
    }

    if ($jiraStatus -ne $issue.lastSeenStatus -and $null -ne $issue.lastSeenStatus) {
        Write-Host "  Status change detected: $($issue.lastSeenStatus) -> $jiraStatus"

        $xrayKey = if ($issue.xrayTestKey) { $issue.xrayTestKey } else { "" }
        $tcDoc = if ($issue.tcDocPath) { Join-Path $repoRoot $issue.tcDocPath } else { "" }
        $sprintSlug = if ($issue.sprintSlug) { $issue.sprintSlug } else { "" }

        $statusTrigger = Join-Path $triggersDir "$($issue.issueKey)-status-change.json"
        @{
            issueKey    = $issue.issueKey
            storyKey    = $issue.issueKey
            issueType   = $f.issuetype.name
            sprintSlug  = $sprintSlug
            xrayTestKey = $xrayKey
            tcDocPath   = $tcDoc
            changeType  = "STATUS_CHANGE"
            oldStatus   = $issue.lastSeenStatus
            newStatus   = $jiraStatus
            changedAt   = $jiraUpdated
            detectedAt  = $now
        } | ConvertTo-Json -Depth 5 | Set-Content $statusTrigger

        $issue | Add-Member -MemberType NoteProperty -Name "lastSeenStatus" -Value $jiraStatus -Force
        $anyUpdates = $true
    }

    if ($f.issuelinks) {
        $xrayKey = if ($issue.xrayTestKey) { $issue.xrayTestKey } else { "" }

        foreach ($link in $f.issuelinks) {
            $linked = $null
            if ($link.inwardIssue) {
                $linked = $link.inwardIssue
            } elseif ($link.outwardIssue) {
                $linked = $link.outwardIssue
            }
            if ($null -eq $linked) { continue }

            $linkedType = $linked.fields.issuetype.name
            if ($linkedType -notin @("Bug", "Defect")) { continue }

            $linkedKey = $linked.key
            $alreadyWatched = $watchList | Where-Object { $_.issueKey -eq $linkedKey }
            if ($alreadyWatched) { continue }

            Write-Host "  Auto-registering linked $linkedType : $linkedKey"

            $newDefect = [PSCustomObject]@{
                issueKey        = $linkedKey
                xrayTestKey     = $xrayKey
                tcDocPath       = if ($issue.tcDocPath) { $issue.tcDocPath } else { "" }
                tcrDocPath      = if ($issue.tcrDocPath) { $issue.tcrDocPath } else { "" }
                descriptionHash = $null
                lastSeenUpdated = $null
                lastSeenStatus  = $null
                status          = "ACTIVE"
                parentStory     = $issue.issueKey
                detectedChanges = @()
            }

            [void]$watchList.Add($newDefect)
            $stateList = [System.Collections.ArrayList]@($state.issues)
            [void]$stateList.Add($newDefect)
            $state | Add-Member -MemberType NoteProperty -Name "issues" -Value $stateList.ToArray() -Force
            $anyUpdates = $true
        }
    }

    $issue | Add-Member -MemberType NoteProperty -Name "lastSeenUpdated" -Value $jiraUpdated -Force
}

if ($anyUpdates) {
    $state | Add-Member -MemberType NoteProperty -Name "_lastChangeMonitorRun" -Value $now -Force
    $state | ConvertTo-Json -Depth 10 | Set-Content $StateFile
    Write-Host ""
    Write-Host "State saved: $StateFile"
}

$pending = Get-ChildItem (Join-Path $triggersDir "*.json") -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike "*.processed.json" }

Write-Host ""
if ($pending.Count -gt 0) {
    Write-Host "========================================================"
    Write-Host " ACTION REQUIRED - $($pending.Count) trigger(s) pending"
    Write-Host "========================================================"
    foreach ($t in $pending) {
        try {
            $td = Get-Content $t.FullName -Raw | ConvertFrom-Json
            Write-Host "  Issue  : $($td.issueKey)"
            Write-Host "  Change : $($td.changeType)"
            Write-Host "  File   : $($t.Name)"
            Write-Host "  Run    : @story_monitor process $($td.issueKey)"
        } catch {
            Write-Host "  File   : $($t.Name) (could not parse)"
        }
        Write-Host ""
    }
} else {
    Write-Host "No pending triggers. All issues up to date."
}
Write-Host ""
