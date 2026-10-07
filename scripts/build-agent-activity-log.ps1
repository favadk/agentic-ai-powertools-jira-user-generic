#Requires -Version 5.1
<#!
.SYNOPSIS
    Builds dashboard activity data from QA artifacts and monitor triggers.

.DESCRIPTION
    Generates scripts/agent-activity-log.json with:
      - changeLogUpdates: updates performed by agents
      - pendingUserActions: actions pending from user side

    Sources scanned:
      - docs/QAPlan/QAP_*.md
      - docs/TestCaseReview/TCR_*_Comments.md
      - docs/Automation/AUTRPT_*.md
      - scripts/triggers/*.json and *.processed.json
#>

[CmdletBinding()]
param(
    [string] $RepoRoot = "",
    [string] $OutputFile = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) {
    $RepoRoot = Split-Path $PSScriptRoot -Parent
}
if (-not $OutputFile) {
    $OutputFile = Join-Path $PSScriptRoot "agent-activity-log.json"
}

$docsRoot = Join-Path $RepoRoot "docs"
$qaPlanRoot = Join-Path $docsRoot "QAPlan"
$reviewRoot = Join-Path $docsRoot "TestCaseReview"
$automationRoot = Join-Path $docsRoot "Automation"
$triggersRoot = Join-Path $PSScriptRoot "triggers"

$stageAgentMap = @{
    "Test Case Preparation"     = "test_case_preparation"
    "Test Case Review"          = "test_case_review"
    "Test Case Execution"       = "test_case_execution"
    "Execution Evidence Review" = "test_case_evidence_review"
    "Automation Code Preparation" = "automation_code_preparation"
    "Automation Code Review"    = "automation_code_review"
    "Automation Run & Publish"  = "automation_run_publish"
}

$changeLog = New-Object System.Collections.Generic.List[object]
$pendingActions = New-Object System.Collections.Generic.List[object]

function Get-IsoUtc {
    param([datetime] $Date)
    return $Date.ToUniversalTime().ToString("o")
}

function Get-ProjectFromKey {
    param([string] $StoryKey)
    if (-not $StoryKey) { return "UNKNOWN" }
    if ($StoryKey -match "^([A-Za-z]+)-\d+$") { return $matches[1].ToUpper() }
    return "UNKNOWN"
}

function Get-NormalizedStatus {
    param([string] $Status)
    $s = [string]$Status
    $s = $s -replace "✅", ""
    $s = $s -replace "⏳", ""
    $s = $s -replace "🟢", ""
    $s = $s.Trim()
    return $s.ToUpper()
}

function Convert-RelativePath {
    param([string] $PathValue)
    if (-not $PathValue) { return $null }
    $p = $PathValue.Trim()
    $p = $p -replace "\\", "/"
    if ($p.StartsWith("../")) {
        $p = $p.Substring(3)
    }
    if ($p.StartsWith("./")) {
        $p = $p.Substring(2)
    }
    return $p
}

function Resolve-ArtifactDate {
    param(
        [string] $RelativePath,
        [datetime] $Fallback
    )

    if (-not $RelativePath) {
        return $Fallback
    }

    $trimmed = Convert-RelativePath -PathValue $RelativePath
    if (-not $trimmed) {
        return $Fallback
    }

    $full = Join-Path $RepoRoot ($trimmed -replace "/", "\\")
    if (Test-Path $full) {
        return (Get-Item $full).LastWriteTimeUtc
    }

    return $Fallback
}

function Add-ChangeLogEntry {
    param($Entry)
    $changeLog.Add([pscustomobject]$Entry) | Out-Null
}

function Add-PendingActionEntry {
    param($Entry)
    $pendingActions.Add([pscustomobject]$Entry) | Out-Null
}

function Get-LatestKnownSprint {
    param(
        [array] $Entries,
        [string] $TimeField
    )

    $withSprint = @($Entries | Where-Object {
        $_.sprint -and [string]$_.sprint -ne "UNKNOWN"
    })
    if (-not $withSprint -or $withSprint.Count -eq 0) {
        return $null
    }

    $ordered = @($withSprint | Sort-Object {
        try { [datetime]($_.$TimeField) } catch { [datetime]::MinValue }
    } -Descending)

    if ($ordered.Count -gt 0) {
        return [string]$ordered[0].sprint
    }
    return $null
}

# 1) Parse QA plans for lifecycle stage progress and pending actions.
if (Test-Path $qaPlanRoot) {
    $plans = Get-ChildItem -Path $qaPlanRoot -Filter "QAP_*.md" -File -ErrorAction SilentlyContinue
    foreach ($plan in $plans) {
        $lines = Get-Content -Path $plan.FullName
        $storyKey = $null
        $sprint = $null

        foreach ($line in $lines) {
            if (-not $storyKey -and $line -match "\*\*User Story:\*\*\s*([A-Za-z]+-\d+)") {
                $storyKey = $matches[1].ToUpper()
            }
            if (-not $sprint -and $line -match "\*\*Sprint:\*\*\s*(.+)$") {
                $sprint = $matches[1].Trim() -replace "\s+", "-"
            }
        }

        if (-not $storyKey) { continue }
        if (-not $sprint) { $sprint = "UNKNOWN" }

        $project = Get-ProjectFromKey -StoryKey $storyKey

        foreach ($line in $lines) {
            if ($line -notmatch "^\|\s*\d+\s*\|") { continue }
            if ($line -notmatch "^\|\s*\d+\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*(.+?)\s*\|$") { continue }

            $stage = $matches[1].Trim()
            $statusRaw = $matches[2].Trim()
            $owner = $matches[3].Trim()
            $artifactCell = $matches[4].Trim()

            $artifactPath = $null
            if ($artifactCell -match "\[[^\]]+\]\(([^)]+)\)") {
                $artifactPath = Convert-RelativePath -PathValue $matches[1]
            } elseif ($artifactCell -and $artifactCell -ne "-") {
                $artifactPath = Convert-RelativePath -PathValue $artifactCell
            }

            $normalizedStatus = Get-NormalizedStatus -Status $statusRaw
            $stageAgent = if ($stageAgentMap.ContainsKey($stage)) { $stageAgentMap[$stage] } else { "story_monitor" }
            $eventDate = Resolve-ArtifactDate -RelativePath $artifactPath -Fallback $plan.LastWriteTimeUtc

            if ($normalizedStatus -match "DONE|COMPLETED|READY|APPROVED") {
                Add-ChangeLogEntry -Entry @{
                    id = "qa-" + $storyKey + "-" + ($stage -replace "\s+", "-").ToLower()
                    timestamp = Get-IsoUtc -Date $eventDate
                    project = $project
                    sprint = $sprint
                    storyKey = $storyKey
                    agent = $stageAgent
                    changeType = "STAGE_STATUS_UPDATE"
                    summary = "$stage marked $statusRaw in QA plan."
                    artifact = if ($artifactPath) { $artifactPath } else { "docs/QAPlan/$($plan.Name)" }
                    status = "COMPLETED"
                    requiresUserAction = $false
                }
            }

            if ($normalizedStatus -match "PENDING|IN PREPARATION|IN PROGRESS") {
                Add-PendingActionEntry -Entry @{
                    id = "pending-qa-" + $storyKey + "-" + ($stage -replace "\s+", "-").ToLower()
                    project = $project
                    sprint = $sprint
                    storyKey = $storyKey
                    title = "Complete stage: $stage"
                    requestedBy = $stageAgent
                    requestedAt = Get-IsoUtc -Date $plan.LastWriteTimeUtc
                    dueDate = $null
                    priority = "MEDIUM"
                    status = "PENDING"
                    actionDetail = "Stage '$stage' is pending in QA plan and needs user coordination or approval to proceed."
                    reference = "docs/QAPlan/$($plan.Name)"
                }
            }
        }
    }
}

# 2) Parse monitor trigger files for story_monitor activity timeline.
if (Test-Path $triggersRoot) {
    $triggerFiles = Get-ChildItem -Path $triggersRoot -Filter "*.json*" -File -ErrorAction SilentlyContinue
    foreach ($tf in $triggerFiles) {
        try {
            $raw = Get-Content -Path $tf.FullName -Raw
            if (-not $raw) { continue }
            $trigger = $raw | ConvertFrom-Json

            $storyKey = if ($trigger.storyKey) { [string]$trigger.storyKey } elseif ($trigger.issueKey) { [string]$trigger.issueKey } else { $null }
            if (-not $storyKey) { continue }

            $project = Get-ProjectFromKey -StoryKey $storyKey
            $changeType = if ($trigger.changeType) { [string]$trigger.changeType } else { "TRIGGER_EVENT" }
            $detectedAt = $null
            if ($trigger.detectedAt) {
                try { $detectedAt = [datetime]$trigger.detectedAt } catch { $detectedAt = $tf.LastWriteTimeUtc }
            } else {
                $detectedAt = $tf.LastWriteTimeUtc
            }

            $newStatus = if ($trigger.newStatus) { [string]$trigger.newStatus } else { $null }
            $summary = switch ($changeType) {
                "PO_RESPONSE" { "PO response trigger detected for $storyKey."; break }
                "DESCRIPTION_CHANGE" { "Story description or AC change detected for $storyKey."; break }
                "STATUS_CHANGE" {
                    if ($newStatus) { "Story status changed to $newStatus for $storyKey." }
                    else { "Story status change detected for $storyKey." }
                    break
                }
                Default { "$changeType trigger detected for $storyKey." }
            }

            $entryStatus = if ($tf.Name -match "\.processed(\.json)?$") { "COMPLETED" } else { "IN_PROGRESS" }

            Add-ChangeLogEntry -Entry @{
                id = "trigger-" + ($tf.BaseName -replace "[^a-zA-Z0-9-]", "-").ToLower()
                timestamp = Get-IsoUtc -Date $detectedAt
                project = $project
                sprint = if ($trigger.sprintSlug) { [string]$trigger.sprintSlug } else { "UNKNOWN" }
                storyKey = $storyKey
                agent = "story_monitor"
                changeType = $changeType
                summary = $summary
                artifact = "scripts/triggers/$($tf.Name)"
                status = $entryStatus
                requiresUserAction = $false
            }

            if ($changeType -eq "PO_RESPONSE" -and $tf.Name -notlike "*.processed.json") {
                Add-PendingActionEntry -Entry @{
                    id = "pending-trigger-" + ($tf.BaseName -replace "[^a-zA-Z0-9-]", "-").ToLower()
                    project = $project
                    sprint = if ($trigger.sprintSlug) { [string]$trigger.sprintSlug } else { "UNKNOWN" }
                    storyKey = $storyKey
                    title = "Review unresolved PO response"
                    requestedBy = "story_monitor"
                    requestedAt = Get-IsoUtc -Date $detectedAt
                    dueDate = $null
                    priority = "HIGH"
                    status = "PENDING"
                    actionDetail = "A PO response trigger is pending processing and may require user confirmation for test updates."
                    reference = "scripts/triggers/$($tf.Name)"
                }
            }
        } catch {
            continue
        }
    }
}

# 3) Parse TestCaseReview comments for explicit EVIDENCE_REQUIRED actions.
if (Test-Path $reviewRoot) {
    $reviewFiles = Get-ChildItem -Path $reviewRoot -Filter "TCR_*_Comments.md" -File -ErrorAction SilentlyContinue
    foreach ($rf in $reviewFiles) {
        $lines = Get-Content -Path $rf.FullName
        $storyKey = $null
        foreach ($line in $lines) {
            if (-not $storyKey -and $line -match "\|\s*Story\s*\|\s*([A-Za-z]+-\d+)\s*\|") {
                $storyKey = $matches[1].ToUpper()
            }
        }
        if (-not $storyKey) { continue }

        $project = Get-ProjectFromKey -StoryKey $storyKey
        $sprint = "UNKNOWN"

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -notmatch "^###\s+EVIDENCE_REQUIRED\s+-\s+(.+)$") { continue }

            $stepName = $matches[1].Trim()
            $requiredEvidence = "Missing evidence details"
            $owner = "QA"

            for ($j = $i + 1; $j -lt [Math]::Min($i + 12, $lines.Count); $j++) {
                if ($lines[$j] -match "^- Required evidence:\s*(.+)$") {
                    $requiredEvidence = $matches[1].Trim()
                }
                if ($lines[$j] -match "^- Owner:\s*(.+)$") {
                    $owner = $matches[1].Trim()
                }
            }

            Add-PendingActionEntry -Entry @{
                id = "evidence-" + $storyKey + "-" + (($stepName -replace "[^a-zA-Z0-9-]", "-").ToLower())
                project = $project
                sprint = $sprint
                storyKey = $storyKey
                title = "Provide evidence for $stepName"
                requestedBy = "test_case_review"
                requestedAt = Get-IsoUtc -Date $rf.LastWriteTimeUtc
                dueDate = $null
                priority = "HIGH"
                status = "PENDING"
                actionDetail = "$requiredEvidence (Owner: $owner)."
                reference = "docs/TestCaseReview/$($rf.Name)"
            }
        }
    }
}

# 4) Parse automation run reports for explicit publish-pending actions.
if (Test-Path $automationRoot) {
    $autReports = Get-ChildItem -Path $automationRoot -Filter "AUTRPT_*.md" -File -ErrorAction SilentlyContinue
    foreach ($ar in $autReports) {
        $lines = Get-Content -Path $ar.FullName
        $storyKey = $null

        foreach ($line in $lines) {
            if (-not $storyKey -and $line -match "\|\s*Story Key\s*\|\s*([A-Za-z]+-\d+)\s*\|") {
                $storyKey = $matches[1].ToUpper()
            }
        }
        if (-not $storyKey -and $ar.Name -match "AUTRPT_([A-Za-z]+-\d+)_") {
            $storyKey = $matches[1].ToUpper()
        }
        if (-not $storyKey) { continue }

        $project = Get-ProjectFromKey -StoryKey $storyKey

        $issue-trackerPending = $false
        $knowledge-basePending = $false
        foreach ($line in $lines) {
            if ($line -match "\|\s*issue-tracker comment\s*\|\s*.*Pending") { $issue-trackerPending = $true }
            if ($line -match "\|\s*knowledge-base\s*\|\s*.*Pending") { $knowledge-basePending = $true }
        }

        if ($issue-trackerPending -or $knowledge-basePending) {
            $target = if ($issue-trackerPending -and $knowledge-basePending) { "issue-tracker and knowledge-base" } elseif ($issue-trackerPending) { "issue-tracker" } else { "knowledge-base" }
            Add-PendingActionEntry -Entry @{
                id = "publish-" + $storyKey + "-" + ($ar.BaseName.ToLower())
                project = $project
                sprint = "UNKNOWN"
                storyKey = $storyKey
                title = "Approve automation publish to $target"
                requestedBy = "automation_run_publish"
                requestedAt = Get-IsoUtc -Date $ar.LastWriteTimeUtc
                dueDate = $null
                priority = "MEDIUM"
                status = "PENDING"
                actionDetail = "Automation report publication is pending user confirmation for $target."
                reference = "docs/Automation/$($ar.Name)"
            }
        }
    }
}

# Deduplicate entries by id and sort.
$changeLogFinal = @($changeLog | Group-Object id | ForEach-Object { $_.Group | Select-Object -First 1 })
$pendingFinal = @($pendingActions | Group-Object id | ForEach-Object { $_.Group | Select-Object -First 1 })

$changeLogFinal = @($changeLogFinal | Sort-Object { [datetime]$_.timestamp } -Descending)
$pendingFinal = @($pendingFinal | Sort-Object { [datetime]$_.requestedAt } -Descending)

$currentSprint = Get-LatestKnownSprint -Entries $changeLogFinal -TimeField "timestamp"
if (-not $currentSprint) {
    $currentSprint = Get-LatestKnownSprint -Entries $pendingFinal -TimeField "requestedAt"
}
if (-not $currentSprint) {
    $currentSprint = "UNKNOWN"
}

$output = [pscustomobject]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString("o")
    currentSprint = $currentSprint
    changeLogUpdates = $changeLogFinal
    pendingUserActions = $pendingFinal
}

$output | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputFile -Encoding UTF8

Write-Host "Built activity log: $OutputFile"
Write-Host "Current sprint      : $currentSprint"
Write-Host "Change log entries : $($changeLogFinal.Count)"
Write-Host "Pending actions    : $($pendingFinal.Count)"
