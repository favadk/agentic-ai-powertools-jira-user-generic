#Requires -Version 5.1
<#
.SYNOPSIS
    Processes pending test-management test-comment review triggers without VS Code chat.

.DESCRIPTION
    Reads PO_RESPONSE triggers created for linked test-management Test comments. For each
    trigger, it gathers the story, current test-management steps, and local TC document,
    uses the local Ollama model to classify the comment concerns, writes an
    auditable review document, and posts the review verdict to the test-management Test.

    This processor never edits test-management steps. Step changes require the existing
    test_case_preparation update path after a review identifies supported work.
#>

[CmdletBinding()]
param(
    [string] $StateFile = "",
    [string] $TriggerDirectory = "",
    [string] $Model = "llama3.2",
    [string] $OllamaUrl = "http://localhost:11434",
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not $StateFile) { $StateFile = Join-Path $PSScriptRoot "monitor-state.json" }
if (-not $TriggerDirectory) { $TriggerDirectory = Join-Path $PSScriptRoot "triggers" }
. (Join-Path $PSScriptRoot "test-management-api.ps1")

function ConvertFrom-AdfText {
    param($Node)
    if ($null -eq $Node) { return "" }
    $type = if ($Node.PSObject.Properties.Name -contains "type") { [string]$Node.type } else { "" }
    $text = if ($type -eq "text" -and $Node.PSObject.Properties.Name -contains "text") { [string]$Node.text } else { "" }
    if ($Node.PSObject.Properties.Name -contains "content") {
        foreach ($child in @($Node.content)) { $text += ConvertFrom-AdfText $child }
    }
    if ($type -in @("paragraph", "heading", "listItem")) { $text += "`n" }
    return $text
}

function Get-issue-trackerIssueText {
    param([Parameter(Mandatory)][string] $IssueKey)

    $creds = Get-test-managementCreds
    $headers = @{ Authorization = $creds.Headers.Authorization; Accept = "application/json" }
    $uri = "$($creds.Url)/rest/api/3/issue/$IssueKey`?fields=summary,description,comment"
    $issue = (Invoke-WebRequest -Method GET -Uri $uri -Headers $headers -UseBasicParsing).Content | ConvertFrom-Json
    return [pscustomobject]@{
        Summary = [string]$issue.fields.summary
        Description = (ConvertFrom-AdfText $issue.fields.description).Trim()
        Comments = @($issue.fields.comment.comments | ForEach-Object {
            "[$($_.created)] $($_.author.displayName): $((ConvertFrom-AdfText $_.body).Trim())"
        })
    }
}

function Invoke-CommentReview {
    param(
        [Parameter(Mandatory)]$Trigger,
        [Parameter(Mandatory)]$Story,
        [Parameter(Mandatory)][array]$Steps,
        [Parameter(Mandatory)][string]$TcDocument
    )

    $stepText = if ($Steps.Count) {
        ($Steps | ForEach-Object { "Action: $($_.Action)`nExpected: $($_.Expected)" }) -join "`n---`n"
    } else { "No test-management steps could be retrieved." }

    $systemPrompt = @"
You are a QA test-case reviewer. Classify each concrete concern in a reviewer comment using only the supplied acceptance criteria, test steps, and TC document. Do not invent requirements. Return JSON only with this shape:
{
  "summary": "short factual review summary",
  "concerns": [
    {
      "concern": "quoted or faithful summary",
      "verdict": "RESOLVED_NO_CHANGE|CHANGE_REVIEW_REQUIRED|EVIDENCE_REQUIRED",
      "affectedStep": "existing step identifier or Unmapped",
      "evidence": "specific supplied evidence or Missing",
      "requiredEvidence": "specific missing item or None",
      "owner": "Dev|PO|QA"
    }
  ]
}
Use EVIDENCE_REQUIRED whenever the supplied material does not prove the requested behaviour. Never propose a step rewrite.
"@
    $userPrompt = @"
Story: $($Trigger.storyKey)
Summary: $($Story.Summary)
Acceptance criteria and description:
$($Story.Description)

Reviewer comment on test-management Test $($Trigger.sourceIssueKey):
$($Trigger.commentText)

Current test-management steps:
$stepText

Local TC document:
$TcDocument
"@
    $body = @{
        model = $Model
        messages = @(@{ role = "system"; content = $systemPrompt }, @{ role = "user"; content = $userPrompt })
        stream = $false
        format = "json"
        options = @{ temperature = 0 }
    } | ConvertTo-Json -Depth 10
    $response = Invoke-WebRequest -Method POST -Uri "$($OllamaUrl.TrimEnd('/'))/api/chat" -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 600
    $raw = (($response.Content | ConvertFrom-Json).message.content -replace "(?s)^```json\s*|\s*```$", "").Trim()
    try {
        return $raw | ConvertFrom-Json
    } catch {
        $preview = $raw.Substring(0, [Math]::Min(500, $raw.Length))
        throw "Ollama returned malformed review JSON: $preview"
    }
}

function Normalize-ReviewResult {
    param(
        [Parameter(Mandatory)]$Review,
        [Parameter(Mandatory)]$Trigger
    )

    $summary = "Automated review completed with fallback classification due to incomplete model schema."
    if ($Review -and $Review.PSObject.Properties.Name -contains "summary" -and -not [string]::IsNullOrWhiteSpace([string]$Review.summary)) {
        $summary = [string]$Review.summary
    }

    $normalizedConcerns = @()
    $hasConcernsProperty = $Review -and ($Review.PSObject.Properties.Name -contains "concerns")
    if ($hasConcernsProperty -and $Review.concerns) {
        foreach ($c in @($Review.concerns)) {
            if ($null -eq $c) { continue }

            $verdict = if ($c.PSObject.Properties.Name -contains "verdict") { [string]$c.verdict } else { "" }
            if ($verdict -notin @("RESOLVED_NO_CHANGE", "CHANGE_REVIEW_REQUIRED", "EVIDENCE_REQUIRED")) {
                $verdict = "EVIDENCE_REQUIRED"
            }

            $owner = if ($c.PSObject.Properties.Name -contains "owner") { [string]$c.owner } else { "QA" }
            if ($owner -notin @("Dev", "PO", "QA")) {
                $owner = "QA"
            }

            $normalizedConcerns += [pscustomobject]@{
                concern = if ($c.PSObject.Properties.Name -contains "concern" -and -not [string]::IsNullOrWhiteSpace([string]$c.concern)) { [string]$c.concern } else { "Review concern extracted from linked comment." }
                verdict = $verdict
                affectedStep = if ($c.PSObject.Properties.Name -contains "affectedStep" -and -not [string]::IsNullOrWhiteSpace([string]$c.affectedStep)) { [string]$c.affectedStep } else { "Unmapped" }
                evidence = if ($c.PSObject.Properties.Name -contains "evidence" -and -not [string]::IsNullOrWhiteSpace([string]$c.evidence)) { [string]$c.evidence } else { "Missing" }
                requiredEvidence = if ($c.PSObject.Properties.Name -contains "requiredEvidence" -and -not [string]::IsNullOrWhiteSpace([string]$c.requiredEvidence)) { [string]$c.requiredEvidence } else { "None" }
                owner = $owner
            }
        }
    }

    if (@($normalizedConcerns).Count -eq 0) {
        $normalizedConcerns = @(
            [pscustomobject]@{
                concern = if (-not [string]::IsNullOrWhiteSpace([string]$Trigger.commentText)) { [string]$Trigger.commentText } else { "Linked test-management comment requires manual review." }
                verdict = "EVIDENCE_REQUIRED"
                affectedStep = "Unmapped"
                evidence = "Missing"
                requiredEvidence = "Model output did not provide structured concerns. Validate comment intent and map to AC-linked step evidence."
                owner = "QA"
            }
        )
    }

    return [pscustomobject]@{
        summary = $summary
        concerns = @($normalizedConcerns)
    }
}

function New-ReviewCommentBody {
    param([Parameter(Mandatory)]$Review)

    $lines = @("[Automated Test Comment Review]", $Review.summary, "")
    foreach ($concern in @($Review.concerns)) {
        $lines += "- $($concern.verdict): $($concern.concern)"
        $lines += "  Evidence: $($concern.evidence)"
        if ($concern.requiredEvidence -and $concern.requiredEvidence -ne "None") {
            $lines += "  Required evidence ($($concern.owner)): $($concern.requiredEvidence)"
        }
    }
    $lines += ""
    $lines += "No test-management test steps were changed by this automated review."
    return $lines -join "`n"
}

function Add-issue-trackerComment {
    param([Parameter(Mandatory)][string]$IssueKey, [Parameter(Mandatory)][string]$Text)

    $creds = Get-test-managementCreds
    $body = @{ body = @{ version = 1; type = "doc"; content = @(@{ type = "paragraph"; content = @(@{ type = "text"; text = $Text }) }) } } | ConvertTo-Json -Depth 10
    Invoke-WebRequest -Method POST -Uri "$($creds.Url)/rest/api/3/issue/$IssueKey/comment" -Headers $creds.Headers -Body $body -UseBasicParsing | Out-Null
}

function Update-TcDocumentFromReview {
    param(
        [Parameter(Mandatory)][string]$TcPath,
        [Parameter(Mandatory)]$Trigger,
        [Parameter(Mandatory)]$Review
    )

    if (-not (Test-Path $TcPath)) { return }
    $tcText = Get-Content -Raw $TcPath
    if ($tcText -match [regex]::Escape("Comment ID $($Trigger.commentId):")) {
        return
    }

    $reviewedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
    $summaryLine = if ($Review.summary) { [string]$Review.summary } else { "Automated review recorded." }
    $evidenceRequiredCount = @($Review.concerns | Where-Object { $_.verdict -eq "EVIDENCE_REQUIRED" }).Count
    $changeRequiredCount = @($Review.concerns | Where-Object { $_.verdict -eq "CHANGE_REVIEW_REQUIRED" }).Count

    $entryLines = @(
        "",
        "## Comment Review Sync",
        "",
        "- Reviewed At: $reviewedAt",
        "- Source Issue: $($Trigger.sourceIssueKey) ($($Trigger.sourceIssueType))",
        "- Comment ID $($Trigger.commentId): $($Trigger.commentText)",
        "- Review Summary: $summaryLine",
        "- Verdict Counts: EVIDENCE_REQUIRED=$evidenceRequiredCount, CHANGE_REVIEW_REQUIRED=$changeRequiredCount"
    )

    Add-Content -Path $TcPath -Value ($entryLines -join "`r`n") -Encoding UTF8
}

if (-not (Test-Path $StateFile)) { throw "Monitor state file not found: $StateFile" }
$state = Get-Content -Raw $StateFile | ConvertFrom-Json
$triggerFiles = Get-ChildItem -Path $TriggerDirectory -Filter "*-response*.json" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike "*.processed.json" }

foreach ($triggerFile in $triggerFiles) {
    $trigger = Get-Content -Raw $triggerFile.FullName | ConvertFrom-Json
    if ($trigger.changeType -ne "PO_RESPONSE") { continue }
    if ($trigger.sourceIssueType -notin @("test-management_TEST", "STORY")) { continue }

    Write-Host "[Review Processor] Processing comment $($trigger.commentId) on $($trigger.sourceIssueKey)."
    $tcPath = [string]$trigger.tcDocPath
    if (-not (Test-Path $tcPath)) { throw "TC document not found: $tcPath" }

    $story = Get-issue-trackerIssueText -IssueKey $trigger.storyKey
    $steps = @(Get-test-managementCloudTestSteps -TestKey $trigger.test-managementTestKey)
    $tcDocument = Get-Content -Raw $tcPath
    $reviewRaw = Invoke-CommentReview -Trigger $trigger -Story $story -Steps $steps -TcDocument $tcDocument
    $review = Normalize-ReviewResult -Review $reviewRaw -Trigger $trigger

    $reviewDirectory = Join-Path $repoRoot "docs\TestCaseReview"
    if (-not (Test-Path $reviewDirectory)) { New-Item -ItemType Directory -Path $reviewDirectory | Out-Null }
    $reviewPath = Join-Path $reviewDirectory "TCR_$($trigger.test-managementTestKey)_Comments.md"
    $sectionLines = @("", "## Review Entry", "", "| Field | Value |", "| --- | --- |", "| Story | $($trigger.storyKey) |", "| Source Test | $($trigger.sourceIssueKey) |", "| Comment ID | $($trigger.commentId) |", "| Reviewed | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K') |", "", "### Reviewer Comment", "", $trigger.commentText, "", "### Findings", "")
    foreach ($concern in @($review.concerns)) {
        $sectionLines += "#### $($concern.verdict) - $($concern.affectedStep)"
        $sectionLines += ""
        $sectionLines += "Concern: $($concern.concern)"
        $sectionLines += ""
        $sectionLines += "- Affected step: $($concern.affectedStep)"
        $sectionLines += "- Evidence: $($concern.evidence)"
        $sectionLines += "- Required evidence: $($concern.requiredEvidence)"
        $sectionLines += "- Owner: $($concern.owner)"
        $sectionLines += ""
    }
    if (-not $DryRun) {
        if (-not (Test-Path $reviewPath)) {
            @("# Comment Review - $($trigger.test-managementTestKey)", "") | Set-Content -Path $reviewPath -Encoding UTF8
        }
        Add-Content -Path $reviewPath -Value ($sectionLines -join "`r`n") -Encoding UTF8
    }

    if (-not $DryRun) {
        Update-TcDocumentFromReview -TcPath $tcPath -Trigger $trigger -Review $review
    }

    $commentText = New-ReviewCommentBody -Review $review
    $commentTargetIssue = $null
    if ($trigger.test-managementTestKey -and [string]$trigger.test-managementTestKey -notmatch '^\s*$') {
        $commentTargetIssue = [string]$trigger.test-managementTestKey
    } elseif ($trigger.resolutionIssueKey -and [string]$trigger.resolutionIssueKey -notmatch '^\s*$') {
        $commentTargetIssue = [string]$trigger.resolutionIssueKey
    }
    $reviewAlreadyPosted = $false
    if ($trigger -and $trigger.PSObject.Properties.Name -contains "reviewCommentPosted" -and $trigger.reviewCommentPosted) {
        $reviewAlreadyPosted = $true
    }
    if (-not $DryRun -and -not $reviewAlreadyPosted -and $commentTargetIssue) {
        Add-issue-trackerComment -IssueKey $commentTargetIssue -Text $commentText
        $trigger | Add-Member -MemberType NoteProperty -Name "reviewCommentPosted" -Value $true -Force
        $trigger | Add-Member -MemberType NoteProperty -Name "reviewCommentPostedAt" -Value (Get-Date).ToString("o") -Force
        $trigger | ConvertTo-Json -Depth 10 | Set-Content -Path $triggerFile.FullName -Encoding UTF8
    }

    if (-not $DryRun) {
        $stateIssue = @($state.issues | Where-Object { $_.issueKey -eq $trigger.issueKey }) | Select-Object -First 1
        if ($stateIssue -and $stateIssue.detectedResponses) {
            $response = @($stateIssue.detectedResponses | Where-Object { [string]$_.commentId -eq [string]$trigger.commentId }) | Select-Object -First 1
            if ($response) {
                $response | Add-Member -MemberType NoteProperty -Name "processed" -Value $true -Force
                $response | Add-Member -MemberType NoteProperty -Name "processedAt" -Value (Get-Date).ToString("o") -Force
            }
            $stateIssue.status = "UPDATED_AWAITING_REVIEW"
        }
        $state | ConvertTo-Json -Depth 12 | Set-Content -Path $StateFile -Encoding UTF8
        $processedPath = $triggerFile.FullName -replace "\.json$", ".processed.json"
        Move-Item -Path $triggerFile.FullName -Destination $processedPath -Force
    }
    Write-Host "[Review Processor] Completed $($trigger.sourceIssueKey)."
}