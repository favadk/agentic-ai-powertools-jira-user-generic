#Requires -Version 5.1
<##
.SYNOPSIS
    Dispatches QA monitor triggers into verified execution handoffs.
.DESCRIPTION
    Processes SPRINT_CHANGE and QA STATUS_CHANGE trigger files. It verifies the
    story is in the active sprint, ensures the current-sprint TE contains the
    Xray Test and has an Xray run, then writes EXECUTE_TEST_CASE handoff files.
    Uses the legacy PowerShell/Xray implementation. It prepares an exact Xray
    run only when a configured automation runner is available. A missing runner
    blocks the handoff and never changes the Xray run status.
#>
[CmdletBinding()]
param(
    [string]$TriggerDirectory = "",
    [string]$StateFile = "",
    [string]$AutomationRunner = "",
    [switch]$DryRun,
    [switch]$QueueOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$repoRoot = Split-Path $scriptDir -Parent
if (-not $TriggerDirectory) { $TriggerDirectory = Join-Path $scriptDir "triggers" }
if (-not $StateFile) { $StateFile = Join-Path $scriptDir "monitor-state.json" }
if (-not $AutomationRunner) { $AutomationRunner = Join-Path $scriptDir "automation-runner.ps1" }
. (Join-Path $scriptDir "xray-api.ps1")
$creds = Get-XrayCreds

function Get-JiraJson([string]$path) {
    return Invoke-JiraApi -Method GET -Path $path -Creds $creds
}

function Invoke-JiraJson([string]$method, [string]$path, [object]$body) {
    return Invoke-JiraApi -Method $method -Path $path -Creds $creds -Body $body
}

function Get-ActiveSprint($boardId) {
    $resp = Get-JiraJson "/rest/agile/1.0/board/$boardId/sprint?state=active"
    $sprint = @($resp.values) | Select-Object -First 1
    if (-not $sprint) { throw "No active sprint found for board $boardId" }
    return $sprint
}

function Get-SprintIssues($sprintId) {
    $resp = Get-JiraJson "/rest/agile/1.0/sprint/$sprintId/issue?maxResults=100&fields=key,summary,issuetype,status"
    return @($resp.issues)
}

function Get-StateEntry($state, [string]$storyKey) {
    return @($state.issues | Where-Object { $_.issueKey -eq $storyKey }) | Select-Object -First 1
}

function Get-XrayRun([string]$teKey, [string]$testKey) {
    $token = Get-XrayCloudToken
    $teId = (Get-JiraJson "/rest/api/2/issue/$teKey`?fields=id").id
    $headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
    $query = "{ getTestExecution(issueId: `"$teId`") { testRuns(limit: 100) { results { id test { jira(fields: [`"key`"] ) } } } } }"
    $body = @{ query = $query } | ConvertTo-Json -Depth 5
    $response = Invoke-WebRequest -Method POST -Uri "https://us.xray.cloud.getxray.app/api/v2/graphql" -Headers $headers -Body $body -UseBasicParsing
    $result = ($response.Content | ConvertFrom-Json).data.getTestExecution.testRuns.results
    return @($result | Where-Object { $_.test.jira.key -eq $testKey }) | Select-Object -First 1
}

function Ensure-XrayTestOnExecution([string]$teKey, [string]$testKey) {
    $run = Get-XrayRun -teKey $teKey -testKey $testKey
    if ($run) { return $run }

    $token = Get-XrayCloudToken
    $teId = (Get-JiraJson "/rest/api/2/issue/$teKey`?fields=id").id
    $testId = (Get-JiraJson "/rest/api/2/issue/$testKey`?fields=id").id
    $headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
    $query = "mutation { addTestsToTestExecution(issueId: `"$teId`", testIssueIds: [`"$testId`"]) { addedTests warning } }"
    $body = @{ query = $query } | ConvertTo-Json -Depth 5
    $response = Invoke-WebRequest -Method POST -Uri "https://us.xray.cloud.getxray.app/api/v2/graphql" -Headers $headers -Body $body -UseBasicParsing
    $mutation = ($response.Content | ConvertFrom-Json).data.addTestsToTestExecution
    $run = Get-XrayRun -teKey $teKey -testKey $testKey
    if (-not $run) { throw "Xray Test $testKey is not attached to TE $teKey or has no test run. Warning: $($mutation.warning)" }
    return $run
}

function Invoke-XrayGraphQl([string]$token, [string]$query, [object]$variables = $null) {
    $headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
    $payload = @{ query = $query }
    if ($variables) { $payload.variables = $variables }
    $body = $payload | ConvertTo-Json -Depth 20
    $response = Invoke-RestMethod -Method POST -Uri "https://us.xray.cloud.getxray.app/api/v2/graphql" -Headers $headers -Body $body
    if ($response.PSObject.Properties.Name -contains "errors" -and $response.errors) { throw ($response.errors | ConvertTo-Json -Compress -Depth 10) }
    return $response.data
}

function Get-AutomationEvidenceManifest([string]$storyKey) {
    $manifestPath = Join-Path $repoRoot "docs\TestExecution\evidence\$storyKey\STORY-7566-evidence-manifest.json"
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Automation evidence manifest not found: $manifestPath"
    }
    return Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-EvidenceMimeType([string]$filePath) {
    switch ([System.IO.Path]::GetExtension($filePath).ToLowerInvariant()) {
        ".png"  { return "image/png" }
        ".jpg"  { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".gif"  { return "image/gif" }
        ".webp" { return "image/webp" }
        ".json" { return "application/json" }
        ".txt"  { return "text/plain" }
        default { return "application/octet-stream" }
    }
}

function Sync-AutomationResultsToXray($handoff, $run) {
    $manifest = @(Get-AutomationEvidenceManifest -storyKey $handoff.storyKey | ForEach-Object { $_ })
    if ($manifest.Count -eq 0) { throw "Automation evidence manifest has no entries for $($handoff.storyKey)" }

    $token = Get-XrayCloudToken
    $steps = @($run.steps)

    foreach ($entry in $manifest) {
        $stepIndex = [int]$entry.stepIndex
        if ($stepIndex -lt 1 -or $stepIndex -gt $steps.Count) {
            throw "Evidence manifest stepIndex $stepIndex is outside Xray step count $($steps.Count)"
        }
        $step = $steps[$stepIndex - 1]
        $actualResult = [string]$entry.actualResult
        $status = if ([string]$entry.status) { [string]$entry.status } else { "PASSED" }

        Invoke-XrayGraphQl -token $token `
            -query "mutation upd(`$runId:String!, `$stepId:String!, `$status:String!, `$actualResult:String!) { updateTestRunStep(testRunId:`$runId, stepId:`$stepId, updateData: { status: `$status, actualResult: `$actualResult }) { warnings } }" `
            -variables @{ runId = [string]$run.id; stepId = [string]$step.id; status = $status; actualResult = $actualResult } | Out-Null

        foreach ($filePathValue in @($entry.files)) {
            $filePath = [string]$filePathValue
            if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) { throw "Evidence file not found: $filePath" }
            $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $filePath).Path)
            $evidence = @(@{
                filename = Split-Path $filePath -Leaf
                mimeType = Get-EvidenceMimeType -filePath $filePath
                data = [Convert]::ToBase64String($bytes)
            })
            Invoke-XrayGraphQl -token $token `
                -query "mutation add(`$runId:String!, `$stepId:String!, `$evidence:[AttachmentDataInput]) { addEvidenceToTestRunStep(testRunId:`$runId, stepId:`$stepId, evidence:`$evidence) { addedEvidence warnings } }" `
                -variables @{ runId = [string]$run.id; stepId = [string]$step.id; evidence = $evidence } | Out-Null
        }

        Write-Host "  Synced automation evidence for Xray step $stepIndex ($($step.id))"
    }
}

function Add-ExecuteHandoff($trigger, [string]$teKey, [string]$testKey, $run, [string]$sourcePath) {
    $handoffPath = Join-Path $TriggerDirectory "$($trigger.storyKey)-execute-test-case.json"
    if (Test-Path $handoffPath) {
        $existing = Get-Content $handoffPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $dispatchStatus = if ($existing.PSObject.Properties.Name -contains "dispatchStatus") { [string]$existing.dispatchStatus } else { "" }
        if ($existing.status -in @("RUNNING", "COMPLETED") -or $dispatchStatus -eq "DISPATCHED") { return $false }
        if ($sourcePath -ne $handoffPath) { return $false }
    }
    $handoff = [ordered]@{
        issueKey = $trigger.storyKey
        storyKey = $trigger.storyKey
        issueType = "Story"
        changeType = "EXECUTE_TEST_CASE"
        sourceChangeType = $trigger.changeType
        sprintId = [int]$script:activeSprint.id
        sprintName = [string]$script:activeSprint.name
        teKey = $teKey
        xrayTestKey = $testKey
        xrayTestRunId = [string]$run.id
        tcDocPath = [string]$trigger.tcDocPath
        detectedAt = (Get-Date).ToUniversalTime().ToString("o")
        status = "READY_FOR_AGENT"
        note = "TE and Xray test run verified. Invoke test_case_execution; record every result against this run."
    }
    if (-not $DryRun) { $handoff | ConvertTo-Json -Depth 8 | Set-Content $handoffPath -Encoding UTF8 }
    return $true
}

function Start-LegacyTestCaseExecution($handoff) {
    if (-not (Test-Path -LiteralPath $AutomationRunner -PathType Leaf)) {
        throw "Automation runner is not configured: $AutomationRunner"
    }

    $token = Get-XrayCloudToken
    $teId = (Get-JiraJson "/rest/api/2/issue/$($handoff.teKey)`?fields=id").id
    $headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
    $query = "{ getTestExecution(issueId: `"$teId`") { testRuns(limit: 100) { results { id test { jira(fields: [`"key`"]) } steps { id status { name } } } } } }"
    $body = @{ query = $query } | ConvertTo-Json -Depth 8
    $result = (Invoke-WebRequest -Method POST -Uri "https://us.xray.cloud.getxray.app/api/v2/graphql" -Headers $headers -Body $body -UseBasicParsing).Content | ConvertFrom-Json
    $run = @($result.data.getTestExecution.testRuns.results | Where-Object { $_.test.jira.key -eq $handoff.xrayTestKey }) | Select-Object -First 1
    if (-not $run -or @($run.steps).Count -eq 0) { throw "Xray Cloud could not resolve a run with steps for $($handoff.xrayTestKey) in $($handoff.teKey)" }
    if ([string]$run.id -ne [string]$handoff.xrayTestRunId) { throw "Resolved Xray run $($run.id) does not match handoff run $($handoff.xrayTestRunId)" }
    $mutation = "mutation { updateTestRunStatus(id: `"$($run.id)`", status: `"EXECUTING`") }"
    $mutationBody = @{ query = $mutation } | ConvertTo-Json -Depth 5
    Invoke-WebRequest -Method POST -Uri "https://us.xray.cloud.getxray.app/api/v2/graphql" -Headers $headers -Body $mutationBody -UseBasicParsing | Out-Null
    & $AutomationRunner -StoryKey $handoff.storyKey
    if ($LASTEXITCODE -ne 0) { throw "Automation runner failed for $($handoff.storyKey) with exit code $LASTEXITCODE" }
    Sync-AutomationResultsToXray -handoff $handoff -run $run
    Write-Host "Legacy execution completed: TE=$($handoff.teKey) Run=$($run.id) Steps=$(@($run.steps).Count)"
}

$state = Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json
$script:activeSprint = Get-ActiveSprint -boardId $state.sprintWatch.boardId
$sprintIssues = @(Get-SprintIssues -sprintId $script:activeSprint.id)
$storyKeys = @($sprintIssues | Where-Object { $_.fields.issuetype.name -eq "Story" } | ForEach-Object { $_.key })
$triggerFiles = @(Get-ChildItem -Path $TriggerDirectory -Filter "*.json" -File -ErrorAction SilentlyContinue)

foreach ($file in $triggerFiles) {
    $trigger = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($trigger.changeType -notin @("SPRINT_CHANGE", "STATUS_CHANGE", "EXECUTE_TEST_CASE")) { continue }
    $storyKey = [string]$trigger.storyKey
    if (-not $storyKey -or $storyKey -notin $storyKeys) { continue }

    $entry = Get-StateEntry -state $state -storyKey $storyKey
    $testKey = [string]$trigger.xrayTestKey
    if (-not $testKey -and $entry) { $testKey = [string]$entry.xrayTestKey }
    if (-not $testKey) { Write-Warning "$storyKey has no Xray Test key; leaving trigger pending."; continue }

    $teKey = [string]$trigger.teKey
    if (-not $teKey -and $entry) { $teKey = [string]$entry.teKey }
    if ($trigger.changeType -eq "SPRINT_CHANGE" -and $entry.previousSprintSlug -and $entry.previousSprintSlug -ne $script:activeSprint.name) {
        $teKey = [string]$entry.teKey
    }
    if (-not $teKey -or @($sprintIssues | Where-Object { $_.key -eq $teKey -and $_.fields.issuetype.name -eq "Test Execution" }).Count -eq 0) {
        Write-Warning "$storyKey has no verified current-sprint TE; leaving trigger pending for story_monitor provisioning."; continue
    }

    try {
        $run = Ensure-XrayTestOnExecution -teKey $teKey -testKey $testKey
        if (Add-ExecuteHandoff -trigger $trigger -teKey $teKey -testKey $testKey -run $run -sourcePath $file.FullName) {
            Write-Host "[$storyKey] EXECUTE_TEST_CASE handoff queued: TE=$teKey Run=$($run.id)"
            if (-not $DryRun -and -not $QueueOnly) {
                $handoff = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                $handoff | Add-Member -MemberType NoteProperty -Name "teKey" -Value $teKey -Force
                $handoff | Add-Member -MemberType NoteProperty -Name "xrayTestKey" -Value $testKey -Force
                $handoff | Add-Member -MemberType NoteProperty -Name "xrayTestRunId" -Value ([string]$run.id) -Force
                $handoff | Add-Member -MemberType NoteProperty -Name "status" -Value "RUNNING" -Force
                $handoff | ConvertTo-Json -Depth 8 | Set-Content $file.FullName -Encoding UTF8
                try {
                    Start-LegacyTestCaseExecution -handoff $handoff
                    $handoff | Add-Member -MemberType NoteProperty -Name "status" -Value "XRAY_RESULTS_SYNCED" -Force
                    $handoff | Add-Member -MemberType NoteProperty -Name "dispatchStatus" -Value "AUTOMATION_EVIDENCE_ATTACHED" -Force
                } catch {
                    $handoff | Add-Member -MemberType NoteProperty -Name "status" -Value "BLOCKED" -Force
                    $dispatchStatus = if ($_.Exception.Message -like "Automation runner is not configured*") { "BLOCKED_AUTOMATION_RUNNER_MISSING" } else { "AUTOMATION_EXECUTION_OR_SYNC_FAILED" }
                    $handoff | Add-Member -MemberType NoteProperty -Name "dispatchStatus" -Value $dispatchStatus -Force
                    $handoff | Add-Member -MemberType NoteProperty -Name "error" -Value $_.Exception.Message -Force
                    $handoff | ConvertTo-Json -Depth 8 | Set-Content $file.FullName -Encoding UTF8
                    Write-Warning "[$storyKey] Execution blocked: $($_.Exception.Message)"
                    continue
                }
                $handoff | ConvertTo-Json -Depth 8 | Set-Content $file.FullName -Encoding UTF8
            }
        }
    } catch {
        Write-Warning "[$storyKey] Execution handoff blocked: $($_.Exception.Message)"
    }
}
