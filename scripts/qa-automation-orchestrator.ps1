<#
.SYNOPSIS
    QA Automation Orchestrator — automatically processes new Jira sprint stories
    through the QA lifecycle (TC generation, Xray issue creation, Jira comment)
    using a local Ollama LLM for test case generation.

.DESCRIPTION
    This script is designed to run on a schedule (Windows Task Scheduler).
    On each run it:
      1. Fetches all stories in the current active sprint for the given board
      2. Compares against a local state file to find NEW unprocessed stories
      3. For each new story:
         a. Fetches full Jira story details and AC
         b. Calls local Ollama to generate test cases from AC
         c. Saves a TC_<STORY-KEY>.md document locally
         d. Creates an Xray Test issue in Jira with all steps populated
         e. Posts a comment on the Jira story with the Xray Test link
         f. Marks the story as processed in the state file

.PARAMETER BoardId
    Jira Agile board ID (find it in the board URL: /jira/software/projects/PROJ/boards/123)

.PARAMETER ProjectKey
    Jira project key (e.g. STORY, CDS2REP)

.PARAMETER OllamaModel
    Ollama model to use for test case generation. Default: llama3.2
    Pull first: ollama pull llama3.2

.PARAMETER OllamaUrl
    Ollama local server URL. Default: http://localhost:11434

.PARAMETER JiraAcField
    Jira field name holding Acceptance Criteria. Default: description
    Common alternatives: customfield_10016, customfield_10020

.PARAMETER DryRun
    Validate and generate locally without creating any Jira/Xray issues.

.EXAMPLE
    # Normal run:
    .\scripts\qa-automation-orchestrator.ps1 -BoardId 42 -ProjectKey STORY

    # Dry run (no Jira changes):
    .\scripts\qa-automation-orchestrator.ps1 -BoardId 42 -ProjectKey STORY -DryRun

    # Use a different model:
    .\scripts\qa-automation-orchestrator.ps1 -BoardId 42 -ProjectKey STORY -OllamaModel mistral

.NOTES
    Prerequisites:
    - Ollama installed and running locally (https://ollama.com)
    - Ollama model pulled: ollama pull llama3.2
    - Jira credentials in .vscode/mcp.local.json or as environment variables:
        $env:JIRA_EMAIL, $env:JIRA_PERSONAL_TOKEN, $env:JIRA_URL
    - scripts/xray-api.ps1 and scripts/generate-test-cases-ollama.ps1 present

    State file: scripts/qa-automation-state.json
    Logs:       scripts/qa-automation.log
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $BoardId,
    [Parameter(Mandatory)][string] $ProjectKey,
    [string] $OllamaModel  = "llama3.2",
    [string] $OllamaUrl    = "http://localhost:11434",
    [string] $JiraAcField  = "description",
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Bootstrap: dot-source helpers
# ---------------------------------------------------------------------------
$scriptDir   = $PSScriptRoot
$repoRoot    = Split-Path $scriptDir -Parent
$xrayScript  = Join-Path $scriptDir "xray-api.ps1"
$ollamaScript = Join-Path $scriptDir "generate-test-cases-ollama.ps1"

if (-not (Test-Path $xrayScript))   { throw "Missing: $xrayScript" }
if (-not (Test-Path $ollamaScript)) { throw "Missing: $ollamaScript" }

. $xrayScript
. $ollamaScript

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
$logFile = Join-Path $scriptDir "qa-automation.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Write-Host $entry
    Add-Content -Path $logFile -Value $entry -Encoding UTF8
}

# ---------------------------------------------------------------------------
# State file: tracks which story keys have been processed
# ---------------------------------------------------------------------------
$statePath = Join-Path $scriptDir "qa-automation-state.json"

function Get-State {
    if (Test-Path $statePath) {
        return Get-Content $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    return [PSCustomObject]@{
        lastRun          = ""
        processedStories = @()
    }
}

function Save-State ($state) {
    # Ensure processedStories is always an array
    if ($state.processedStories -isnot [array]) {
        $state.processedStories = @($state.processedStories)
    }
    $state | ConvertTo-Json -Depth 5 | Set-Content $statePath -Encoding UTF8
}

# ---------------------------------------------------------------------------
# Jira helpers
# ---------------------------------------------------------------------------
function Get-ActiveSprint ($boardId, $creds) {
    $resp = Invoke-JiraApi -Method GET `
        -Path "/rest/agile/1.0/board/$boardId/sprint?state=active" `
        -Creds $creds
    $sprint = $resp.values | Select-Object -First 1
    if (-not $sprint) { throw "No active sprint found for board $boardId" }
    return $sprint
}

function Get-SprintStories ($sprintId, $creds) {
    $startAt   = 0
    $maxResults = 50
    $allIssues = @()

    do {
        $resp = Invoke-JiraApi -Method GET `
            -Path "/rest/agile/1.0/sprint/$sprintId/issue?jql=issuetype=Story&startAt=$startAt&maxResults=$maxResults&fields=summary,status,issuetype" `
            -Creds $creds
        $allIssues += $resp.issues
        $startAt   += $maxResults
    } while ($allIssues.Count -lt $resp.total)

    return $allIssues
}

function Get-FullStoryDetails ($storyKey, $creds) {
    # Request rendered fields so description comes back as HTML (easier to strip than ADF)
    return Invoke-JiraApi -Method GET `
        -Path "/rest/api/2/issue/$storyKey`?expand=renderedFields&fields=summary,description,customfield_10016,customfield_10020,sprint,fixVersions,$JiraAcField" `
        -Creds $creds
}

function Extract-AcceptanceCriteria ($issue, $acField) {
    # Try the configured AC field first, then fall back to description
    $value = $issue.renderedFields.$acField
    if (-not $value) { $value = $issue.renderedFields.description }
    if (-not $value) { $value = $issue.fields.$acField }
    if (-not $value) { $value = $issue.fields.description }
    return $value
}

# ---------------------------------------------------------------------------
# Document builder
# ---------------------------------------------------------------------------
function Build-TcDocument ($storyKey, $summary, $sprintName, $testCases) {
    $date    = Get-Date -Format "yyyy-MM-dd"
    $tcNum   = 1
    $sections = ""

    foreach ($tc in $testCases) {
        $id     = "TC-$storyKey-$($tcNum.ToString('D2'))"
        $steps  = ""
        $stepNo = 1

        foreach ($s in $tc.steps) {
            $action   = (if ($s.PSObject.Properties['action']   -and $s.action)   { $s.action }   else { "" }) -replace '\|', '\|'
            $data     = (if ($s.PSObject.Properties['data']     -and $s.data)     { $s.data }     else { "" }) -replace '\|', '\|'
            $expected = (if ($s.PSObject.Properties['expected'] -and $s.expected) { $s.expected } else { "" }) -replace '\|', '\|'
            $steps   += "| $stepNo | $action | $data | $expected |`n"
            $stepNo++
        }

        $sections += @"

### $id - $($tc.title)

| Field        | Value              |
|--------------|--------------------|
| **TC ID**    | $id                |
| **AC Ref**   | $($tc.ac_ref)      |
| **Type**     | $($tc.type)        |
| **Priority** | $($tc.priority)    |

**Steps**

| Step | Action | Test Data | Expected Result |
|------|--------|-----------|----------------|
$steps
---
"@
        $tcNum++
    }

    return @"
# Test Cases - ${storyKey}: $summary

## Document Information

| Field          | Value                   |
|----------------|-------------------------|
| **Story Key**  | $storyKey               |
| **Sprint**     | $sprintName             |
| **Prepared By**| QA Automation (Ollama)  |
| **Date**       | $date                   |
| **Status**     | Draft - Pending Review  |
| **TC Count**   | $($testCases.Count)     |

---

## Test Cases
$sections

---
*Auto-generated by qa-automation-orchestrator.ps1 using Ollama model: $OllamaModel*
*Review and adjust steps before executing. Execution requires human tester.*
"@
}

# ---------------------------------------------------------------------------
# Convert test cases -> Xray steps array (flat - all TCs into one Test issue)
# ---------------------------------------------------------------------------
function Convert-ToXraySteps ($testCases) {
    $steps = @()
    $tcNum = 1
    foreach ($tc in $testCases) {
        $prefix  = "TC-$tcNum [$($tc.ac_ref)] $($tc.type): $($tc.title)"
        $stepNo  = 1
        foreach ($s in $tc.steps) {
            $steps += @{
                Action   = "$prefix - Step $stepNo`: $($s.action)"
                Data     = if ($s.PSObject.Properties['data']     -and $s.data)     { $s.data }     else { "" }
                Expected = if ($s.PSObject.Properties['expected'] -and $s.expected) { $s.expected } else { "" }
            }
            $stepNo++
        }
        $tcNum++
    }
    return $steps
}

# ---------------------------------------------------------------------------
# Post Jira comment
# ---------------------------------------------------------------------------
function Add-JiraAutomationComment ($storyKey, $xrayTestKey, $tcCount, $stepCount, $creds, $jiraUrl) {
    $link = "$jiraUrl/browse/$xrayTestKey"
    $localDoc = "docs/TestCases/TC_$storyKey.md"

    $comment = @"
*[QA Automation]* Test cases have been automatically generated for this story.

|| Field || Value ||
| Xray Test Issue | [$xrayTestKey|$link] |
| Steps Created | $stepCount |
| Test Cases | $tcCount |
| Local Document | $localDoc |
| Generated By | Ollama / $OllamaModel |

The Xray Test is linked to this story and ready for execution once the feature is deployed to the test environment.
Please review the test cases and amend any steps before execution.
"@

    $body = @{ body = $comment }
    try {
        Invoke-JiraApi -Method POST -Path "/rest/api/2/issue/$storyKey/comment" -Creds $creds -Body $body | Out-Null
        Write-Log "  Comment posted on $storyKey"
    } catch {
        Write-Log "  Could not post comment on $storyKey`: $_" "WARN"
    }
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
Write-Log "=== QA Automation Orchestrator started ==="
Write-Log "  Board: $BoardId | Project: $ProjectKey | Model: $OllamaModel"
if ($DryRun) { Write-Log "  [DRY RUN] No Jira/Xray changes will be made - dry run active." "WARN" }

$state = Get-State
$creds = Get-XrayCreds

# 1. Get active sprint
Write-Log "Fetching active sprint for board $BoardId..."
$sprint = Get-ActiveSprint -boardId $BoardId -creds $creds
Write-Log "  Sprint: $($sprint.name) (ID: $($sprint.id))"

# 2. Get all stories in sprint
Write-Log "Fetching sprint stories..."
$stories = Get-SprintStories -sprintId $sprint.id -creds $creds
Write-Log "  Total stories in sprint: $($stories.Count)"

# 3. Filter to unprocessed stories
$processed = if ($state.processedStories) { @($state.processedStories) } else { @() }
$newStories = $stories | Where-Object { $_.key -notin $processed }
Write-Log "  New unprocessed stories: $($newStories.Count)"

if ($newStories.Count -eq 0) {
    Write-Log "No new stories to process. Orchestrator complete."
    $state.lastRun = (Get-Date -Format "o")
    Save-State $state
    exit 0
}

# 4. Process each new story
$successCount = 0
$failCount    = 0

foreach ($story in $newStories) {
    $storyKey = $story.key
    Write-Log ""
    Write-Log "--- Processing $storyKey : $($story.fields.summary) ---"

    try {
        # 4a. Fetch full story with rendered fields
        $full = Get-FullStoryDetails -storyKey $storyKey -creds $creds
        $ac   = Extract-AcceptanceCriteria -issue $full -acField $JiraAcField

        if (-not $ac) {
            Write-Log "  No AC found for $storyKey - skipping." "WARN"
            # Still mark as seen so we don't retry every run
            $processed += $storyKey
            continue
        }

        # 4b. Generate test cases via Ollama
        $testCases = Invoke-OllamaTestCaseGeneration `
            -StorySummary       $full.fields.summary `
            -AcceptanceCriteria $ac `
            -Model              $OllamaModel `
            -OllamaUrl          $OllamaUrl

        if (-not $testCases -or $testCases.Count -eq 0) {
            Write-Log "  Ollama returned no test cases for $storyKey - skipping." "WARN"
            $failCount++
            continue
        }

        # 4c. Save local TC document
        $tcDir  = Join-Path $repoRoot "docs\TestCases"
        $tcFile = Join-Path $tcDir "TC_$storyKey.md"
        $sprintName = $sprint.name

        if (-not $DryRun) {
            if (-not (Test-Path $tcDir)) { New-Item -ItemType Directory -Path $tcDir | Out-Null }
            $content = Build-TcDocument -storyKey $storyKey -summary $full.fields.summary `
                           -sprintName $sprintName -testCases $testCases
            Set-Content -Path $tcFile -Value $content -Encoding UTF8
            Write-Log "  Saved: docs/TestCases/TC_$storyKey.md"
        } else {
            Write-Log "  [DRY RUN] Would save: docs/TestCases/TC_$storyKey.md"
        }

        # 4d. Create Xray Test issue with all steps
        $xraySteps = Convert-ToXraySteps -testCases $testCases

        if (-not $DryRun) {
            $xrayResult = Ensure-XrayTest `
                -ProjectKey  $ProjectKey `
                -Summary     "TC $storyKey`: $($full.fields.summary)" `
                -StoryKey    $storyKey `
                -Steps       $xraySteps `
                -Description "Auto-generated Xray Test for $storyKey. Local doc: docs/TestCases/TC_$storyKey.md. Generated by Ollama ($OllamaModel)."

            $xrayTestKey = $xrayResult.Key
            $xrayAction  = $xrayResult.Action
            Write-Log "  Xray Test $xrayAction`: $xrayTestKey ($($xraySteps.Count) steps)"

            # 4e. Post comment on story (skip if test already existed with steps)
            if ($xrayAction -ne "skipped") {
                Add-JiraAutomationComment `
                    -storyKey    $storyKey `
                    -xrayTestKey $xrayTestKey `
                    -tcCount     $testCases.Count `
                    -stepCount   $xraySteps.Count `
                    -creds       $creds `
                    -jiraUrl     $creds.Url
            } else {
                Write-Log "  Comment skipped - Test $xrayTestKey already had steps."
            }
        } else {
            Write-Log "  [DRY RUN] Would create Xray Test with $($xraySteps.Count) steps for $storyKey"
        }

        # 4f. Mark story processed
        $processed += $storyKey
        $successCount++
        Write-Log "  $storyKey DONE."

    } catch {
        Write-Log "  ERROR processing $storyKey`: $_" "ERROR"
        $failCount++
    }
}

# 5. Save state
$state.processedStories = $processed
$state.lastRun          = (Get-Date -Format "o")
Save-State $state

Write-Log ""
Write-Log "=== Orchestrator complete: $successCount succeeded, $failCount failed ==="
