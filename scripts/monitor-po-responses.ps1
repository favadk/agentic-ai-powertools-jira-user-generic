#Requires -Version 5.1
<#
.SYNOPSIS
    Polls Jira for new comments on watched/blocked test case issues.
    When a new comment is detected, shows a Windows toast notification,
    logs the response, and writes a trigger file so the story_monitor
    agent can auto-update the test case and re-trigger review.

.DESCRIPTION
    Reads scripts/monitor-state.json for the watch list.
    For each watched issue it fetches all comments added AFTER lastCommentIdSeen.
    If any non-self comment is found on the story or linked test issue, it:
      1. Records the response in monitor-state.json
      2. Shows a Windows toast notification
      3. Writes a trigger file to scripts/triggers/{issueKey}-response.json
      4. Optionally posts an acknowledgement comment to Jira

    Run this on a schedule (every 30 min) via Task Scheduler.
    See: scripts/setup-po-monitor-scheduler.ps1 to register the schedule.

.PARAMETER StateFile
    Path to monitor-state.json. Default: scripts/monitor-state.json in repo root.

.PARAMETER PostAck
    If set, posts an auto-acknowledgement comment to Jira when a new comment is found.

.EXAMPLE
    .\scripts\monitor-po-responses.ps1
    .\scripts\monitor-po-responses.ps1 -PostAck
#>

[CmdletBinding()]
param(
    [string] $StateFile = "",
    [switch] $PostAck
)

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# --- Resolve paths ---
$repoRoot  = Split-Path $PSScriptRoot -Parent
if (-not $StateFile) { $StateFile = Join-Path $PSScriptRoot "monitor-state.json" }
$triggersDir = Join-Path $PSScriptRoot "triggers"
if (-not (Test-Path $triggersDir)) { New-Item -ItemType Directory -Path $triggersDir | Out-Null }

# --- Load credentials ---
. (Join-Path $PSScriptRoot "xray-api.ps1") 2>$null
$creds = Get-XrayCreds   # returns $creds.Url and $creds.Headers

# --- Load state ---
$state = Get-Content $StateFile -Raw | ConvertFrom-Json

$now = (Get-Date).ToUniversalTime().ToString("o")
$anyUpdates = $false

Write-Host ""
Write-Host "================================================"
Write-Host " Comment Monitor - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host "================================================"

# Support both legacy schema (watchedIssues) and current schema (issues)
$watchedIssues = @()
if ($state.watchedIssues) {
    $watchedIssues = @($state.watchedIssues)
} elseif ($state.issues) {
    $watchedIssues = @($state.issues)
}

# Enforce current-sprint-only monitoring when sprint watch is configured.
$sw = $state.sprintWatch
if ($sw -and $sw.enabled -and $sw.boardId) {
    try {
        $terminalStatuses = @('Done','Closed','Released','Cancelled','Won''t Do','Resolved')
        $activeSprintResp = Invoke-WebRequest -Method GET -Uri "$($creds.Url)/rest/agile/1.0/board/$($sw.boardId)/sprint?state=active" -Headers $creds.Headers -UseBasicParsing | ConvertFrom-Json
        if ($activeSprintResp.values -and $activeSprintResp.values.Count -gt 0) {
            $activeSprint = $activeSprintResp.values[0]
            if ($activeSprint.id -ne $sw.sprintId -or $activeSprint.name -ne $sw.sprintName) {
                $sw | Add-Member -MemberType NoteProperty -Name "sprintId" -Value $activeSprint.id -Force
                $sw | Add-Member -MemberType NoteProperty -Name "sprintName" -Value $activeSprint.name -Force
                $state | Add-Member -MemberType NoteProperty -Name "sprintWatch" -Value $sw -Force
            }

            $sprintIssueResp = Invoke-WebRequest -Method GET -Uri "$($creds.Url)/rest/agile/1.0/sprint/$($sw.sprintId)/issue?fields=key,issuetype,status&maxResults=100" -Headers $creds.Headers -UseBasicParsing | ConvertFrom-Json
            $currentSprintKeys = @{}
            foreach ($si in $sprintIssueResp.issues) {
                if ($si.fields.issuetype.name -eq 'Story' -and $si.fields.status.name -notin $terminalStatuses) {
                    $currentSprintKeys[$si.key] = $true
                }
            }

            if ($currentSprintKeys.Count -gt 0) {
                $preCount = $watchedIssues.Count
                $watchedIssues = @($watchedIssues | Where-Object { $currentSprintKeys.ContainsKey($_.issueKey) })
                $filteredCount = $preCount - $watchedIssues.Count
                if ($filteredCount -gt 0) {
                    Write-Host " Ignoring $filteredCount legacy/out-of-sprint issue(s)."
                }
            }
        }
    } catch {
        Write-Warning "Current sprint filter could not be applied: $_"
    }
}

Write-Host " Watching $($watchedIssues.Count) issue(s)"
Write-Host ""

$selfAccountId = $null
try {
    $selfAccount = Invoke-WebRequest -Method GET -Uri "$($creds.Url)/rest/api/3/myself" -Headers $creds.Headers -UseBasicParsing | ConvertFrom-Json
    if ($selfAccount.accountId) {
        $selfAccountId = [string]$selfAccount.accountId
    }
} catch {
    Write-Warning "Could not resolve current Jira user for self-comment filtering: $_"
}

foreach ($issue in $watchedIssues) {

    if ($issue.status -notin @("WAITING_PO_RESPONSE", "ACTIVE", "UPDATED_AWAITING_REVIEW", "PO_RESPONDED")) {
        Write-Host "[$($issue.issueKey)] Skipping - status: $($issue.status)"
        continue
    }

    # Ensure previously captured but unprocessed comments are still routed.
    if ($issue.PSObject.Properties.Name -contains "detectedResponses" -and $issue.detectedResponses) {
        foreach ($pendingResponse in @($issue.detectedResponses | Where-Object { -not $_.processed })) {
            if (-not $pendingResponse.commentId -or -not $pendingResponse.sourceIssueKey) { continue }

            $pendingSourceIssueType = if ([string]$pendingResponse.sourceIssueKey -eq [string]$issue.issueKey) { "STORY" } else { "XRAY_TEST" }
            $pendingTriggerFile = Join-Path $triggersDir "$($issue.issueKey)-response-$($pendingResponse.commentId).json"
            if (-not (Test-Path $pendingTriggerFile)) {
                @{
                    changeType         = "PO_RESPONSE"
                    sourceIssueKey     = [string]$pendingResponse.sourceIssueKey
                    sourceIssueType    = $pendingSourceIssueType
                    resolutionIssueKey = [string]$pendingResponse.sourceIssueKey
                    issueKey           = $issue.issueKey
                    storyKey           = if ($issue.storyKey) { $issue.storyKey } else { $issue.issueKey }
                    xrayTestKey        = if ($issue.xrayTestKey) { $issue.xrayTestKey } else { $issue.issueKey }
                    tcDocPath          = Join-Path $repoRoot $issue.tcDocPath
                    tcrDocPath         = Join-Path $repoRoot $issue.tcrDocPath
                    blockedStep        = $issue.blockedStep
                    blockedReason      = $issue.blockedReason
                    poDisplayName      = if ($pendingResponse.displayName) { [string]$pendingResponse.displayName } else { $null }
                    poEmail            = $null
                    commentId          = [string]$pendingResponse.commentId
                    commentText        = if ($pendingResponse.commentText) { [string]$pendingResponse.commentText } else { "[No comment text captured]" }
                    detectedAt         = if ($pendingResponse.detectedAt) { [string]$pendingResponse.detectedAt } else { $now }
                } | ConvertTo-Json -Depth 5 | Set-Content $pendingTriggerFile
                Write-Host "[$($issue.issueKey)] Backfilled trigger for unprocessed comment $($pendingResponse.commentId): $pendingTriggerFile"
            }
        }
    }

    # Build issue comment streams to monitor: story + optional linked test issue.
    $commentTargets = @($issue.issueKey)
    if ($issue.PSObject.Properties.Name -contains "qnWatchIssue" -and $issue.qnWatchIssue) {
        $commentTargets += [string]$issue.qnWatchIssue
    } elseif ($issue.PSObject.Properties.Name -contains "xrayTestKey" -and $issue.xrayTestKey) {
        $commentTargets += [string]$issue.xrayTestKey
    }
    $commentTargets = @($commentTargets | Where-Object { $_ } | Select-Object -Unique)

    # Build per-target cursor map (backward-compatible with legacy lastCommentIdSeen).
    $cursorMap = @{}
    if ($issue.PSObject.Properties.Name -contains "lastCommentIdSeenByIssue" -and $issue.lastCommentIdSeenByIssue) {
        foreach ($p in $issue.lastCommentIdSeenByIssue.PSObject.Properties) {
            $cursorMap[$p.Name] = [string]$p.Value
        }
    }
    if (($issue.PSObject.Properties.Name -contains "lastCommentIdSeen") -and $issue.lastCommentIdSeen -and -not $cursorMap.ContainsKey($issue.issueKey)) {
        $cursorMap[$issue.issueKey] = [string]$issue.lastCommentIdSeen
    }

    foreach ($targetKey in $commentTargets) {
        $lastSeenId = 0L
        if ($cursorMap.ContainsKey($targetKey)) {
            [void][long]::TryParse([string]$cursorMap[$targetKey], [ref]$lastSeenId)
        }

        Write-Host "[$($issue.issueKey)] Checking comments on $targetKey since comment ID $lastSeenId..."

        try {
            $commentUri = "{0}/rest/api/3/issue/{1}/comment?orderBy=created&maxResults=50" -f $creds.Url, $targetKey
            $resp = Invoke-WebRequest -Method GET -Uri $commentUri -Headers $creds.Headers -UseBasicParsing | ConvertFrom-Json
        } catch {
            Write-Warning "[$($issue.issueKey)] Failed to fetch comments for ${targetKey}: $_"
            continue
        }

        $allComments = @($resp.comments)
        $newComments = @()
        foreach ($c in $allComments) {
            $commentIdLong = 0L
            [void][long]::TryParse([string]$c.id, [ref]$commentIdLong)
            if ($commentIdLong -gt $lastSeenId) {
                $newComments += $c
            }
        }

        if ($newComments.Count -eq 0) {
            Write-Host "[$($issue.issueKey)] No new comments on $targetKey."
            continue
        }

        Write-Host "[$($issue.issueKey)] Found $($newComments.Count) new comment(s) on $targetKey."
        $matchingComments = @($newComments | Where-Object {
            $_.author.accountId -and ($null -eq $selfAccountId -or [string]$_.author.accountId -ne $selfAccountId)
        })

        if ($matchingComments.Count -eq 0) {
            Write-Host "[$($issue.issueKey)] No actionable comments found on $targetKey."
            $newestId = ($allComments | ForEach-Object { [long]$_.id } | Measure-Object -Maximum).Maximum
            $cursorMap[$targetKey] = [string]$newestId
            $anyUpdates = $true
            continue
        }

        foreach ($comment in $matchingComments) {
            $alreadyTracked = $false
            if ($issue.PSObject.Properties.Name -contains "detectedResponses" -and $issue.detectedResponses) {
                $existing = @($issue.detectedResponses | Where-Object {
                    [string]$_.commentId -eq [string]$comment.id -and [string]$_.sourceIssueKey -eq [string]$targetKey
                }) | Select-Object -First 1
                if ($existing) { $alreadyTracked = $true }
            }

            if ($alreadyTracked) {
                Write-Host "[$($issue.issueKey)] Comment $($comment.id) on $targetKey already tracked; skipping re-queue."
                $cursorMap[$targetKey] = [string]$comment.id
                $anyUpdates = $true
                continue
            }

            $commentAuthor = $null
            if ($comment.author) {
                $commentAuthor = $comment.author.displayName
            }

            $commentText = ""
            try {
                $commentText = ($comment.body.content | ForEach-Object {
                    $_.content | ForEach-Object { $_.text }
                }) -join " "
            } catch {
                $commentText = "[Could not extract text - view in Jira]"
            }

            Write-Host ""
            Write-Host "  *** COMMENT DETECTED ***"
            Write-Host "  Source : $targetKey"
            Write-Host "  From   : $commentAuthor"
            Write-Host "  At     : $($comment.created)"
            Write-Host "  Comment: $($commentText.Substring(0, [Math]::Min(200, $commentText.Length)))..."
            Write-Host ""

            $detectedEntry = @{
                sourceIssueKey = $targetKey
                commentId      = $comment.id
                accountId      = $comment.author.accountId
                displayName    = $commentAuthor
                email          = $null
                created        = $comment.created
                commentText    = $commentText
                detectedAt     = $now
                processed      = $false
            }

            if (-not ($issue.PSObject.Properties.Name -contains "detectedResponses") -or -not $issue.detectedResponses) {
                $issue | Add-Member -MemberType NoteProperty -Name "detectedResponses" -Value @() -Force
            }
            $issue.detectedResponses += $detectedEntry
            $issue | Add-Member -MemberType NoteProperty -Name "status" -Value "PO_RESPONDED" -Force
            $cursorMap[$targetKey] = [string]$comment.id
            if ($targetKey -eq $issue.issueKey) {
                $issue | Add-Member -MemberType NoteProperty -Name "lastCommentIdSeen" -Value $comment.id -Force
            }
            $anyUpdates = $true

            $triggerFile = Join-Path $triggersDir "$($issue.issueKey)-response-$($comment.id).json"
            $sourceIssueType = if ($targetKey -eq $issue.issueKey) { "STORY" } else { "XRAY_TEST" }
            @{
                changeType         = "PO_RESPONSE"
                sourceIssueKey     = $targetKey
                sourceIssueType    = $sourceIssueType
                resolutionIssueKey = $targetKey
                issueKey           = $issue.issueKey
                storyKey           = if ($issue.storyKey) { $issue.storyKey } else { $issue.issueKey }
                xrayTestKey        = if ($issue.xrayTestKey) { $issue.xrayTestKey } else { $issue.issueKey }
                tcDocPath          = Join-Path $repoRoot $issue.tcDocPath
                tcrDocPath         = Join-Path $repoRoot $issue.tcrDocPath
                blockedStep        = $issue.blockedStep
                blockedReason      = $issue.blockedReason
                poDisplayName      = $commentAuthor
                poEmail            = $null
                commentId          = $comment.id
                commentText        = $commentText
                detectedAt         = $now
            } | ConvertTo-Json -Depth 5 | Set-Content $triggerFile
            Write-Host "  Trigger file written: $triggerFile"

            if ($state.settings.notifyWindowsToast) {
                try {
                    $msg = "$commentAuthor commented on $targetKey for story $($issue.issueKey). Open VS Code and run the story_monitor agent."
                    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
                    $template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
                    $xml      = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent($template)
                    $xml.GetElementsByTagName("text")[0].AppendChild($xml.CreateTextNode("QA Monitor: Comment Detected")) | Out-Null
                    $xml.GetElementsByTagName("text")[1].AppendChild($xml.CreateTextNode($msg)) | Out-Null
                    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
                    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("QA Monitor").Show($toast)
                } catch {
                    Write-Warning "Toast notification failed (non-critical): $_"
                }
            }

            if ($PostAck) {
                $ackBody = @{
                    body = @{
                        version = 1; type = "doc"
                        content = @(
                            @{ type = "paragraph"; content = @(
                                @{ type = "text"; text = "[QA Monitor] Comment detected from $commentAuthor at $($comment.created). The automated test review workflow will assess this feedback against the linked TC and Xray steps." }
                            )}
                        )
                    }
                } | ConvertTo-Json -Depth 10
                try {
                    Invoke-WebRequest -Method POST -Uri "$($creds.Url)/rest/api/3/issue/$targetKey/comment" `
                        -Headers $creds.Headers -Body $ackBody -UseBasicParsing | Out-Null
                    Write-Host "  Auto-ack comment posted to $targetKey."
                } catch {
                    Write-Warning "  Failed to post ack comment: $_"
                }
            }
        }
    }

    if ($cursorMap.Count -gt 0) {
        $issue | Add-Member -MemberType NoteProperty -Name "lastCommentIdSeenByIssue" -Value ([pscustomobject]$cursorMap) -Force
        if ($cursorMap.ContainsKey($issue.issueKey)) {
            $issue | Add-Member -MemberType NoteProperty -Name "lastCommentIdSeen" -Value $cursorMap[$issue.issueKey] -Force
        }
    }
}

# Update lastChecked timestamp
$state | Add-Member -MemberType NoteProperty -Name "_lastRun" -Value $now -Force

# Save state
$state | ConvertTo-Json -Depth 10 | Set-Content $StateFile
Write-Host ""
Write-Host "State saved to: $StateFile"

# Summary
$pendingIssues = $watchedIssues | Where-Object {
    if ($_.status -ne "PO_RESPONDED") { return $false }
    $responses = @($_.detectedResponses)
    return (@($responses | Where-Object { -not $_.processed }).Count -gt 0)
}
if ($pendingIssues.Count -gt 0) {
    Write-Host ""
    Write-Host "================================================"
    Write-Host " ACTION REQUIRED: comments pending processing"
    Write-Host "================================================"
    foreach ($p in $pendingIssues) {
        Write-Host "  Issue : $($p.issueKey)"
        Write-Host "  TC Doc: $($p.tcDocPath)"
        Write-Host "  Trigger: scripts\triggers\$($p.issueKey)-response.json"
        Write-Host ""
        Write-Host "  --> QA-Process-Test-Comment-Reviews will process linked Xray comment triggers on its next run."
        Write-Host ""
    }
} else {
    Write-Host "No comments pending. All issues up to date."
}
Write-Host ""
