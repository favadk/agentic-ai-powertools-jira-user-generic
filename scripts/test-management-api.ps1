<#
.SYNOPSIS
    test-management REST API helper functions for the QA lifecycle agents.
    Supports: creating Test issues, adding steps, creating Test Executions,
    updating step results, and attaching screenshot evidence per step.

.USAGE
    # Dot-source from an agent or terminal session:
    . .\scripts\test-management-api.ps1

    # All functions will read credentials from .vscode/mcp.local.json automatically.
    # Override by setting $env:issue-tracker_EMAIL and $env:issue-tracker_PERSONAL_TOKEN before dot-sourcing.
#>

# PS 5.1 defaults to TLS 1.0; Atlassian Cloud requires TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# ---------------------------------------------------------------------------
# Credential bootstrap
# ---------------------------------------------------------------------------

function Get-test-managementCreds {
    $email = $env:issue-tracker_EMAIL
    $token = $env:issue-tracker_PERSONAL_TOKEN
    $url   = $env:issue-tracker_URL

    if (-not $email -or -not $token) {
        $localPath = Join-Path $PSScriptRoot "..\\.vscode\\mcp.local.json"
        if (Test-Path $localPath) {
            $cfg = Get-Content $localPath -Raw | ConvertFrom-Json
            $issue-trackerEnvCfg = $cfg.servers.issue-tracker.env
            $savedMode = $null
            Set-StrictMode -Off
            # Support both legacy (issue-tracker_EMAIL/issue-tracker_PERSONAL_TOKEN) and Cloud (issue-tracker_USERNAME/issue-tracker_TOKEN) vars
            if (-not $email) { $email = $issue-trackerEnvCfg.issue-tracker_EMAIL; if (-not $email) { $email = $issue-trackerEnvCfg.issue-tracker_USERNAME } }
            if (-not $token) { $token = $issue-trackerEnvCfg.issue-tracker_PERSONAL_TOKEN; if (-not $token) { $token = $issue-trackerEnvCfg.issue-tracker_TOKEN } }
            if (-not $url)   { $url   = $issue-trackerEnvCfg.issue-tracker_URL }
            Set-StrictMode -Version Latest
        }
    }

    if (-not $email -or -not $token) {
        throw "issue-tracker credentials not found. Set issue-tracker_EMAIL and issue-tracker_PERSONAL_TOKEN env vars, or ensure .vscode/mcp.local.json exists."
    }

    if (-not $url) { throw "issue-tracker base URL not found. Set issue-tracker_BASE_URL env var, or ensure .vscode/mcp.local.json exists with issue-trackerBaseUrl." }
    $url = $url.TrimEnd("/")
    $encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("${email}:${token}"))

    return @{
        Url     = $url
        Headers = @{
            Authorization  = "Basic $encoded"
            Accept         = "application/json"
            "Content-Type" = "application/json"
        }
    }
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

function Invoke-issue-trackerApi {
    param(
        [string]$Method,
        [string]$Path,
        [hashtable]$Creds,
        [object]$Body = $null,
        [string]$ContentType = "application/json"
    )

    $uri = "$($Creds.Url)$Path"
    $headers = $Creds.Headers.Clone()

    if ($ContentType -ne "application/json") {
        $headers["Content-Type"] = $ContentType
    }

    $params = @{
        Method  = $Method
        Uri     = $uri
        Headers = $headers
        UseBasicParsing = $true
        ErrorAction = "Stop"
    }

    if ($Body) {
        $params.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 10 }
    }

    try {
        $resp = Invoke-WebRequest @params
    } catch [System.Net.WebException] {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $errBody = $reader.ReadToEnd()
        throw "issue-tracker API $Method $Path failed [$($_.Exception.Response.StatusCode)]: $errBody"
    }
    if ($resp.Content) { return $resp.Content | ConvertFrom-Json }
    return $null
}

function Invoke-test-managementApi {
    param(
        [string]$Method,
        [string]$Path,
        [hashtable]$Creds,
        [object]$Body = $null
    )
    return Invoke-issue-trackerApi -Method $Method -Path $Path -Creds $Creds -Body $Body
}

# ---------------------------------------------------------------------------
# Story status gate — only allow "In Dev" or "Ready for Dev" stories
# ---------------------------------------------------------------------------

function Get-StoryStatus {
    <#
    .SYNOPSIS
        Returns the issue-tracker status name for a given issue (story OR test-management Test).
        Strategy 1: issue-tracker API v3 GET (works when Browse permission is granted).
        Strategy 2: test-management Cloud GraphQL issue-tracker(fields:["status"]) — fallback for
                    Test issues or issues where the REST API returns 404/403.
        Returns $null only when both strategies fail.
    .PARAMETER IssueKey   Any issue-tracker issue key (e.g. STORY-0000, STORY-0000)
    .PARAMETER StoryKey   Alias for IssueKey — kept for backwards compatibility
    #>
    param(
        [string]$IssueKey  = "",
        [string]$StoryKey  = ""    # legacy alias
    )
    if (-not $IssueKey) { $IssueKey = $StoryKey }
    if (-not $IssueKey) { throw "Get-StoryStatus: IssueKey is required." }

    # -- Strategy 1: issue-tracker REST API v3 ----------------------------------------
    $creds   = Get-test-managementCreds
    $uri     = "$($creds.Url)/rest/api/3/issue/$IssueKey`?fields=status"
    $headers = @{ Authorization = $creds.Headers.Authorization; Accept = "application/json" }
    try {
        $resp = Invoke-WebRequest -Method GET -Uri $uri -Headers $headers -UseBasicParsing -ErrorAction Stop
        $status = ($resp.Content | ConvertFrom-Json).fields.status.name
        if ($status) { return $status }
    } catch {
        Write-Verbose "[Get-StoryStatus] issue-tracker REST failed for $IssueKey ($(($_.Exception.Message -split '\n')[0])). Trying test-management GraphQL fallback..."
    }

    # -- Strategy 2: test-management Cloud GraphQL fallback ------------------------------
    try {
        $token    = Get-test-managementCloudToken
        $headers2 = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
        $queryStr = "{ getTests(jql: `"key = $IssueKey`", limit: 1) { results { issue-tracker(fields: [`"status`"]) } } }"
        $gqlBody  = @{ query = $queryStr } | ConvertTo-Json -Depth 5
        $resp2    = Invoke-WebRequest -Method POST -Uri "https://us.test-management.cloud.gettest-management.app/api/v2/graphql" `
                        -Headers $headers2 -Body $gqlBody -UseBasicParsing -ErrorAction Stop
        $results  = ($resp2.Content | ConvertFrom-Json).data.getTests.results
        if ($results -and $results.Count -gt 0) {
            $statusObj = $results[0].issue-tracker.status
            # GraphQL returns status as object {name:"Active"} or plain string depending on test-management version
            $status = if ($statusObj -is [string]) { $statusObj } else { $statusObj.name }
            if ($status) {
                Write-Verbose "[Get-StoryStatus] test-management GraphQL returned status '$status' for $IssueKey"
                return $status
            }
        }
    } catch {
        Write-Verbose "[Get-StoryStatus] test-management GraphQL fallback also failed for $IssueKey`: $_"
    }

    Write-Warning "[Get-StoryStatus] Could not determine status for $IssueKey via any method."
    return $null
}

function Assert-StoryInDev {
    <#
    .SYNOPSIS
        Returns $true when the story is in an allowed status ("In Dev" or "Ready for Dev").
        Returns $false and writes a warning when the story is in a non-qualifying status.
        Fails open (returns $true with a warning) when status cannot be determined.
    .PARAMETER StoryKey   User Story key to check (e.g. STORY-0000)
    .PARAMETER Allowed    Override the default allowed status names.
    #>
    param(
        [Parameter(Mandatory)][string]$StoryKey,
        [string[]]$Allowed = @("In Dev","Ready for Dev")
    )

    $status = Get-StoryStatus -StoryKey $StoryKey

    if ($null -eq $status) {
        Write-Warning "[Status Gate] Could not verify status for $StoryKey (no permission or issue not found). Proceeding with caution — verify manually."
        return $true   # fail-open: allow when status is unreadable
    }

    if ($Allowed -contains $status) {
        Write-Host "  [Status Gate] $StoryKey is '$status' — allowed. Proceeding." -ForegroundColor Green
        return $true
    }

    Write-Warning "[Status Gate] BLOCKED: $StoryKey status is '$status'. Only '$($Allowed -join "' or '")' stories are processed. Skipping."
    return $false
}

# ---------------------------------------------------------------------------
# 1. Create test-management Test issue with steps
# ---------------------------------------------------------------------------

function New-test-managementTest {
    <#
    .SYNOPSIS
        Creates an test-management Test issue and populates its test steps.

    .PARAMETER ProjectKey  issue-tracker project key (e.g. "STORY")
    .PARAMETER Summary     Test issue summary (e.g. "TC STORY-0000: Restrict help to auth users")
    .PARAMETER StoryKey    User Story key to link via "Tests" link
    .PARAMETER Steps       Array of hashtables: @{ Action="..."; Data="..."; Expected="..." }
    .PARAMETER Description Optional description / preconditions text
    .PARAMETER AssigneeAccountId  Optional issue-tracker accountId to assign the test to after creation

    .OUTPUTS   The created Test issue key (e.g. "STORY-0000")
    #>
    param(
        [Parameter(Mandatory)][string]$ProjectKey,
        [Parameter(Mandatory)][string]$Summary,
        [Parameter(Mandatory)][string]$StoryKey,
        [Parameter(Mandatory)][array]$Steps,
        [string]$Description = "",
        [string]$AssigneeAccountId = ""
    )

    $creds = Get-test-managementCreds

    # --- Story status gate ---
    if (-not (Assert-StoryInDev -StoryKey $StoryKey)) {
        Write-Warning "New-test-managementTest aborted for $StoryKey — story is not In Dev or Ready for Dev."
        return $null
    }

    # --- Create Test issue ---
    $issueBody = @{
        fields = @{
            project   = @{ key = $ProjectKey }
            summary   = $Summary
            issuetype = @{ name = "Test" }
            description = $Description
        }
    }

    Write-Host "Creating test-management Test issue in $ProjectKey..."
    $created = Invoke-issue-trackerApi -Method POST -Path "/rest/api/2/issue" -Creds $creds -Body $issueBody
    $testKey = $created.key
    Write-Host "  Created: $testKey"

    # --- Assign to tester if provided ---
    if ($AssigneeAccountId) {
        try {
            $assignBody = @{ accountId = $AssigneeAccountId } | ConvertTo-Json
            Invoke-issue-trackerApi -Method PUT -Path "/rest/api/3/issue/$testKey/assignee" -Creds $creds -Body ($assignBody | ConvertFrom-Json)
            Write-Host "  Assigned $testKey to accountId $AssigneeAccountId"
        } catch {
            Write-Warning "  Could not assign $testKey`: $_"
        }
    }

    # --- Add test steps via test-management API ---
    Write-Host "  Adding $($Steps.Count) test steps..."
    $stepsAdded = 0
    $test-managementApiAvailable = $true
    foreach ($step in $Steps) {
        $stepBody = @{
            step   = $step.Action
            data   = if ($step.Data)     { $step.Data }     else { "" }
            result = if ($step.Expected) { $step.Expected } else { "" }
        }
        try {
            Invoke-test-managementApi -Method POST -Path "/rest/raven/1.0/api/test/$testKey/step" -Creds $creds -Body $stepBody | Out-Null
            $stepsAdded++
        } catch {
            if ($test-managementApiAvailable) {
                $test-managementApiAvailable = $false
                # Server/DC API unavailable - try test-management Cloud API
                Write-Host "  Server step API unavailable - trying test-management Cloud API..." -ForegroundColor Yellow
                $cloudOk = Set-test-managementCloudTestSteps `
                    -TestKey    $testKey `
                    -ProjectKey $ProjectKey `
                    -Summary    $Summary `
                    -Steps      $Steps
                if (-not $cloudOk) {
                    Write-Warning "  Both step APIs unavailable. Add steps manually at: $($creds.Url)/browse/$testKey"
                }
            }
            break
        }
    }
    if ($stepsAdded -gt 0) {
        Write-Host "  Steps added: $stepsAdded / $($Steps.Count)"
    }

    # --- Link Test to User Story ---
    Write-Host "  Linking $testKey to $StoryKey..."
    $linkBody = @{
        type         = @{ name = "Tests" }
        inwardIssue  = @{ key = $testKey }
        outwardIssue = @{ key = $StoryKey }
    }
    try {
        Invoke-issue-trackerApi -Method POST -Path "/rest/api/2/issueLink" -Creds $creds -Body $linkBody | Out-Null
        Write-Host "  Linked: $testKey Tests $StoryKey"
    } catch {
        Write-Warning "  Could not create 'Tests' link  -  link type may differ. Link manually: $testKey -> $StoryKey"
    }

    return $testKey
}

# ---------------------------------------------------------------------------
# 2. Create Test Execution + add Tests + link to User Story
# ---------------------------------------------------------------------------

function New-test-managementTestExecution {
    <#
    .SYNOPSIS
        Creates an test-management Test Execution issue, adds one or more Test issues to it,
        and links the execution back to the User Story.

    .PARAMETER ProjectKey   issue-tracker project key
    .PARAMETER StoryKey     User Story key (e.g. STORY-0000)
    .PARAMETER TestKeys     Array of Test issue keys to include (e.g. @("STORY-0000"))
    .PARAMETER Summary      Optional summary override. Defaults to "Test Execution: {StoryKey}"
    .PARAMETER Environment  Test environment label (e.g. "SIT", "UAT")

    .OUTPUTS   The created Test Execution issue key
    #>
    param(
        [Parameter(Mandatory)][string]$ProjectKey,
        [Parameter(Mandatory)][string]$StoryKey,
        [Parameter(Mandatory)][array]$TestKeys,
        [string]$Summary = "",
        [string]$Environment = "SIT",
        [string]$FixVersion = ""   # Optional override; auto-detected from story if empty
    )

    $creds = Get-test-managementCreds

    if (-not $Summary) { $Summary = "Test Execution: $StoryKey  -  $Environment" }

    # --- Auto-detect fix version from story ---
    $fixVersionsField = @()
    if ($FixVersion) {
        $fixVersionsField = @(@{ name = $FixVersion })
        Write-Host "  Using fix version (override): $FixVersion"
    } else {
        try {
            $storyResp = Invoke-WebRequest -Method GET -Uri "$($creds.Url)/rest/api/2/issue/$StoryKey`?fields=fixVersions" `
                -Headers $creds.Headers -UseBasicParsing -ErrorAction Stop
            $storyFV = ($storyResp.Content | ConvertFrom-Json).fields.fixVersions
            if ($storyFV -and $storyFV.Count -gt 0) {
                $fixVersionsField = @($storyFV | ForEach-Object { @{ id = $_.id } })
                Write-Host "  Auto-detected fix version(s) from $StoryKey`: $($storyFV.name -join ', ')"
            }
        } catch {
            Write-Warning "  Could not auto-detect fix version from $StoryKey. Proceeding without it."
        }
    }

    # --- Create Test Execution issue ---
    $teFields = @{
        project     = @{ key = $ProjectKey }
        summary     = $Summary
        issuetype   = @{ name = "Test Execution" }
        description = "Test Execution for $StoryKey. Environment: $Environment."
    }
    if ($fixVersionsField.Count -gt 0) { $teFields.fixVersions = $fixVersionsField }

    $issueBody = @{ fields = $teFields }

    Write-Host "Creating Test Execution issue..."
    $created = Invoke-issue-trackerApi -Method POST -Path "/rest/api/2/issue" -Creds $creds -Body $issueBody
    $execKey = $created.key
    Write-Host "  Created: $execKey"

    # --- Resolve numeric issue-tracker ID for the new TE (needed for test-management Cloud GraphQL) ---
    $execId = $null
    try {
        $execResp = Invoke-WebRequest -Method GET -Uri "$($creds.Url)/rest/api/2/issue/$execKey`?fields=id" `
            -Headers $creds.Headers -UseBasicParsing -ErrorAction Stop
        $execId = ($execResp.Content | ConvertFrom-Json).id
    } catch {
        Write-Warning "  Could not resolve numeric ID for $execKey. test-management Cloud test-addition may fall back to issue-tracker link."
    }

    # --- Add Tests to the Execution via test-management Cloud GraphQL (primary) ---
    $test-managementToken = $null
    try { $test-managementToken = Get-test-managementCloudToken } catch { Write-Verbose "  test-management Cloud token unavailable." }

    foreach ($testKey in $TestKeys) {
        Write-Host "  Adding $testKey to $execKey..."
        $added = $false

        # Strategy 1: test-management Cloud GraphQL mutation (works for test-management Cloud instances)
        if ($test-managementToken -and $execId) {
            try {
                $testIdResp = Invoke-WebRequest -Method GET -Uri "$($creds.Url)/rest/api/2/issue/$testKey`?fields=id" `
                    -Headers $creds.Headers -UseBasicParsing -ErrorAction Stop
                $testId = ($testIdResp.Content | ConvertFrom-Json).id
                $gqlHeaders = @{ Authorization = "Bearer $test-managementToken"; "Content-Type" = "application/json" }
                $gqlMutation = "{`"query`":`"mutation { addTestsToTestExecution(issueId: \`"$execId\`", testIssueIds: [\`"$testId\`"]) { addedTests warning } }`"}"
                $gqlResp = Invoke-WebRequest -Method POST -Uri "https://us.test-management.cloud.gettest-management.app/api/v2/graphql" `
                    -Headers $gqlHeaders -Body $gqlMutation -UseBasicParsing -ErrorAction Stop
                $gqlResult = ($gqlResp.Content | ConvertFrom-Json).data.addTestsToTestExecution
                if ($gqlResult.addedTests -contains $testId) {
                    Write-Host "  Added $testKey (via test-management Cloud GraphQL)"
                    $added = $true
                } elseif ($gqlResult.warning) {
                    Write-Warning "  test-management Cloud warned: $($gqlResult.warning)"
                }
            } catch {
                Write-Verbose "  test-management Cloud GraphQL failed for $testKey`: $_"
            }
        }

        # Strategy 2: test-management Server/DC REST API fallback
        if (-not $added) {
            try {
                Invoke-test-managementApi -Method POST -Path "/rest/raven/1.0/api/testexec/$execKey/test" `
                    -Creds $creds -Body @{ add = @($testKey) } | Out-Null
                Write-Host "  Added $testKey (via test-management Server API)"
                $added = $true
            } catch {
                Write-Verbose "  test-management Server API also failed for $testKey."
            }
        }

        if (-not $added) {
            Write-Warning "  Could not add $testKey to $execKey via test-management API. Add manually in test-management."
        }
    }

    # NOTE: Sprint TEs are containers for test-management Tests — no issue link to the story is created here.
    # The test-management Test (not the TE) holds the "Tests" relationship to the story.
    return $execKey
}

# ---------------------------------------------------------------------------
# 3. Get Test Run ID (needed to update step results / attach evidence)
# ---------------------------------------------------------------------------

function Get-test-managementTestRunId {
    <#
    .SYNOPSIS
        Returns the test-management Test Run internal ID for a given Test in a Test Execution.
    #>
    param(
        [Parameter(Mandatory)][string]$TestExecKey,
        [Parameter(Mandatory)][string]$TestKey
    )

    $creds = Get-test-managementCreds
    $result = Invoke-test-managementApi -Method GET `
        -Path "/rest/raven/1.0/api/testrun?testExecIssueKey=$TestExecKey&testIssueKey=$TestKey" `
        -Creds $creds
    return $result.id
}

# ---------------------------------------------------------------------------
# 4. Get all steps for a Test Run
# ---------------------------------------------------------------------------

function Get-test-managementTestRunSteps {
    <#
    .SYNOPSIS
        Returns all steps for a test run (with their IDs for result updates).
    #>
    param(
        [Parameter(Mandatory)][string]$TestRunId
    )

    $creds = Get-test-managementCreds
    return Invoke-test-managementApi -Method GET -Path "/rest/raven/1.0/api/testrun/$TestRunId/step" -Creds $creds
}

# ---------------------------------------------------------------------------
# 5. Set step result (PASS / FAIL / EXECUTING / TODO / BLOCKED)
# ---------------------------------------------------------------------------

function Set-test-managementStepResult {
    <#
    .SYNOPSIS
        Updates the result status of a single test step in a test run.

    .PARAMETER TestRunId    Internal test-management test run ID
    .PARAMETER StepId       Step ID from Get-test-managementTestRunSteps
    .PARAMETER Status       One of: PASS, FAIL, EXECUTING, TODO, BLOCKED
    .PARAMETER Comment      Optional comment / actual result text
    #>
    param(
        [Parameter(Mandatory)][string]$TestRunId,
        [Parameter(Mandatory)][string]$StepId,
        [Parameter(Mandatory)][ValidateSet("PASS","FAIL","EXECUTING","TODO","BLOCKED")][string]$Status,
        [string]$Comment = ""
    )

    $creds = Get-test-managementCreds
    $body = @{ status = $Status }
    if ($Comment) { $body.comment = $Comment }

    Invoke-test-managementApi -Method PUT `
        -Path "/rest/raven/1.0/api/testrun/$TestRunId/step/$StepId" `
        -Creds $creds -Body $body | Out-Null

    Write-Host "  Step $StepId -> $Status"
}

# ---------------------------------------------------------------------------
# 6. Attach evidence (screenshot) to a test step
# ---------------------------------------------------------------------------

function Add-test-managementStepEvidence {
    <#
    .SYNOPSIS
        Attaches a file (screenshot) as evidence to a specific test step in a test run.

    .PARAMETER TestRunId    Internal test-management test run ID
    .PARAMETER StepId       Step ID
    .PARAMETER FilePath     Absolute or relative path to the screenshot file
    #>
    param(
        [Parameter(Mandatory)][string]$TestRunId,
        [Parameter(Mandatory)][string]$StepId,
        [Parameter(Mandatory)][string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Warning "Evidence file not found: $FilePath  -  skipping attachment."
        return
    }

    $creds = Get-test-managementCreds
    $fileName = Split-Path $FilePath -Leaf
    $mimeType = switch ([System.IO.Path]::GetExtension($FilePath).ToLower()) {
        ".png"  { "image/png" }
        ".jpg"  { "image/jpeg" }
        ".jpeg" { "image/jpeg" }
        ".gif"  { "image/gif" }
        ".bmp"  { "image/bmp" }
        ".webp" { "image/webp" }
        ".pdf"  { "application/pdf" }
        default { "application/octet-stream" }
    }

    $uri = "$($creds.Url)/rest/raven/1.0/api/testrun/$TestRunId/step/$StepId/attachment"
    $encoded = $creds.Headers.Authorization

    # Use curl for multipart upload (Invoke-WebRequest doesn't handle multipart well in PS 5.1)
    $result = curl.exe -s -w "`nHTTP:%{http_code}" `
        -u "$($creds.Headers.Authorization -replace 'Basic ','')" `
        --data-binary "@$FilePath" `
        -H "X-Atlassian-Token: no-check" `
        -H "Content-Type: $mimeType" `
        -H "Authorization: $($creds.Headers.Authorization)" `
        "$uri" --max-time 30

    if ($result -match "HTTP:2\d\d") {
        Write-Host "  Evidence attached: $fileName -> step $StepId"
    } else {
        Write-Warning "  Attachment may have failed. Response: $result"
    }
}

# ---------------------------------------------------------------------------
# 7. Update overall Test Run status
# ---------------------------------------------------------------------------

function Set-test-managementTestRunStatus {
    <#
    .SYNOPSIS
        Sets the overall status of a test run (PASS / FAIL / EXECUTING / ABORTED).
    #>
    param(
        [Parameter(Mandatory)][string]$TestRunId,
        [Parameter(Mandatory)][ValidateSet("PASS","FAIL","EXECUTING","ABORTED","TODO")][string]$Status
    )

    $creds = Get-test-managementCreds
    Invoke-test-managementApi -Method PUT `
        -Path "/rest/raven/1.0/api/testrun/$TestRunId/status?status=$Status" `
        -Creds $creds | Out-Null

    Write-Host "Test Run $TestRunId overall status -> $Status"
}

# ---------------------------------------------------------------------------
# 8. Convenience: Show test run steps summary
# ---------------------------------------------------------------------------

function Show-test-managementTestRunSteps {
    <#
    .SYNOPSIS
        Prints a summary table of all steps in a test run with their current status.
    #>
    param(
        [Parameter(Mandatory)][string]$TestExecKey,
        [Parameter(Mandatory)][string]$TestKey
    )

    $runId = Get-test-managementTestRunId -TestExecKey $TestExecKey -TestKey $TestKey
    $steps = Get-test-managementTestRunSteps -TestRunId $runId

    Write-Host "`nTest Run $runId  -  Steps:"
    Write-Host ("-" * 80)
    $i = 1
    foreach ($s in $steps) {
        Write-Host "[$i] ID:$($s.id) | Status:$($s.status) | Action: $($s.step.raw -replace '\n',' ' | Select-Object -First 1)"
        $i++
    }
    Write-Host ("-" * 80)
    return @{ RunId = $runId; Steps = $steps }
}

# ---------------------------------------------------------------------------
# 9. test-management Cloud REST API v2 - Authenticate (requires Client ID + Client Secret)
# ---------------------------------------------------------------------------

function Get-test-managementCloudToken {
    <#
    .SYNOPSIS
        Authenticates with the test-management Cloud REST API v2 and returns a Bearer token.
        Credentials read from env vars test-management_CLIENT_ID and test-management_CLIENT_SECRET,
        or from .vscode/mcp.local.json under servers.test-management.env.

    .OUTPUTS   JWT token string to use as "Bearer <token>" in Authorization header.
    #>

    $clientId     = $env:test-management_CLIENT_ID
    $clientSecret = $env:test-management_CLIENT_SECRET

    if (-not $clientId -or -not $clientSecret) {
        $localPath = Join-Path $PSScriptRoot "..\\.vscode\\mcp.local.json"
        if (Test-Path $localPath) {
            $cfg = Get-Content $localPath -Raw | ConvertFrom-Json
            if ($cfg.servers.test-management) {
                if (-not $clientId)     { $clientId     = $cfg.servers.test-management.env.test-management_CLIENT_ID }
                if (-not $clientSecret) { $clientSecret = $cfg.servers.test-management.env.test-management_CLIENT_SECRET }
            }
        }
    }

    if (-not $clientId -or -not $clientSecret) {
        throw "test-management Cloud credentials not found.`nSet test-management_CLIENT_ID and test-management_CLIENT_SECRET env vars, or add them to .vscode/mcp.local.json under servers.test-management.env."
    }

    $body = @{ client_id = $clientId; client_secret = $clientSecret } | ConvertTo-Json
    $resp = Invoke-WebRequest -Method POST `
        -Uri "https://test-management.cloud.gettest-management.app/api/v2/authenticate" `
        -Body $body `
        -ContentType "application/json" `
        -UseBasicParsing -ErrorAction Stop

    # Response is a quoted JWT string, strip surrounding quotes
    $token = ($resp.Content | ConvertFrom-Json)
    Write-Host "test-management Cloud token obtained."
    return $token
}

# ---------------------------------------------------------------------------
# 10. test-management Cloud REST API v2 - Import/update test steps for an existing Test issue
# ---------------------------------------------------------------------------

function Import-test-managementCloudTestSteps {
    <#
    .SYNOPSIS
        Imports (adds/replaces) test steps into an existing test-management Test issue
        using the test-management Cloud REST API v2. Does NOT require BULK_CHANGE permission.

    .PARAMETER JsonFilePath   Path to a test-management JSON import file (array of test objects).
                              Use scripts/test-management-import-STORY-0000.json for STORY-0000.
    .PARAMETER test-managementToken      Bearer token from Get-test-managementCloudToken. If omitted,
                              Get-test-managementCloudToken is called automatically.
    .PARAMETER Region         test-management Cloud region base URL. Defaults to US region.

    .EXAMPLE
        $tok = Get-test-managementCloudToken
        Import-test-managementCloudTestSteps -JsonFilePath "scripts\test-management-import-STORY-0000.json" -test-managementToken $tok
    #>
    param(
        [Parameter(Mandatory)][string]$JsonFilePath,
        [string]$test-managementToken = "",
        [string]$Region = "https://us.test-management.cloud.gettest-management.app"
    )

    if (-not (Test-Path $JsonFilePath)) {
        throw "Import file not found: $JsonFilePath"
    }

    if (-not $test-managementToken) {
        $test-managementToken = Get-test-managementCloudToken
    }

    $jsonContent = Get-Content $JsonFilePath -Raw -Encoding UTF8

    $headers = @{
        Authorization  = "Bearer $test-managementToken"
        "Content-Type" = "application/json"
    }

    $uri = "$Region/api/v2/import/test"
    Write-Host "Importing test steps to test-management Cloud..."
    Write-Host "  Endpoint: $uri"

    $resp = Invoke-WebRequest -Method POST -Uri $uri `
        -Headers $headers -Body $jsonContent `
        -UseBasicParsing -ErrorAction Stop

    $result = $resp.Content | ConvertFrom-Json
    Write-Host "  Import complete. HTTP $($resp.StatusCode)"
    if ($result) { Write-Host "  Result: $($result | ConvertTo-Json -Depth 3)" }
    return $result
}

# ---------------------------------------------------------------------------
# 11. Set test steps on an existing test-management Cloud Test issue (inline - no file needed)
# ---------------------------------------------------------------------------

function Set-test-managementCloudTestSteps {
    <#
    .SYNOPSIS
        Adds steps to an existing test-management Cloud Test issue one at a time via the
        addTestStep GraphQL mutation (test-management Cloud API v2).
        Returns $true on success, $false if any steps failed.

    .PARAMETER TestKey      Existing test-management Test issue key (e.g. "STORY-0000")
    .PARAMETER ProjectKey   issue-tracker project key (e.g. "STORY") — used to look up numeric ID
    .PARAMETER Summary      Unused — kept for signature compatibility
    .PARAMETER Steps        Array of hashtables: @{ Action; Data; Expected }
    .PARAMETER Region       test-management Cloud region. Defaults to US.
    #>
    param(
        [Parameter(Mandatory)][string]$TestKey,
        [Parameter(Mandatory)][string]$ProjectKey,
        [string]$Summary = "",
        [Parameter(Mandatory)][array]$Steps,
        [string]$Region = "https://us.test-management.cloud.gettest-management.app"
    )

    # Resolve numeric issue-tracker issue ID (required by GraphQL)
    $creds = Get-test-managementCreds
    try {
        $issueData = (Invoke-WebRequest -Uri ($creds.Url+"/rest/api/3/issue/$TestKey`?fields=id") -Headers $creds.Headers -UseBasicParsing).Content | ConvertFrom-Json
        $numericId = $issueData.id
    } catch {
        Write-Warning "  [Set-test-managementCloudTestSteps] Could not resolve numeric ID for $TestKey`: $_"
        return $false
    }

    $token   = Get-test-managementCloudToken
    $headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
    $gqlUrl  = "$Region/api/v2/graphql"

    $added = 0; $failed = 0
    foreach ($s in $Steps) {
        $a = $(if ($s.Action)   { $s.Action }   else { "" }) -replace '\\', '\\\\' -replace '"', '\"'
        $d = $(if ($s.Data)     { $s.Data }     else { "" }) -replace '\\', '\\\\' -replace '"', '\"'
        $r = $(if ($s.Expected) { $s.Expected } else { "" }) -replace '\\', '\\\\' -replace '"', '\"'

        $mutation = '{"query":"mutation { addTestStep(issueId: \"' + $numericId + '\", step: { action: \"' + $a + '\", data: \"' + $d + '\", result: \"' + $r + '\" }) { id } }"}'
        try {
            $resp = Invoke-WebRequest -Method POST -Uri $gqlUrl -Headers $headers -Body $mutation -UseBasicParsing -ErrorAction Stop
            $parsed = $resp.Content | ConvertFrom-Json
            Set-StrictMode -Off
            $hasErrors = ($parsed.errors -and $parsed.errors.Count -gt 0)
            Set-StrictMode -Version Latest
            if ($hasErrors) { $failed++; Write-Warning "  [Cloud] Step error: $($parsed.errors[0].message)" }
            else { $added++ }
        } catch { $failed++; Write-Warning "  [Cloud] Step request failed: $_" }
    }

    if ($failed -eq 0) {
        Write-Host "  [Cloud] All $added steps added to $TestKey via GraphQL." -ForegroundColor Green
        return $true
    } else {
        Write-Warning "  [Cloud] $added steps added, $failed failed for $TestKey."
        return ($failed -lt $Steps.Count)
    }
}

# ---------------------------------------------------------------------------
# Find existing test-management Test issue(s) already linked to a User Story
# ---------------------------------------------------------------------------

function Find-Existingtest-managementTest {
    <#
    .SYNOPSIS
        Returns the first test-management Test issue key linked to the given User Story,
        or $null if none is found.

    .PARAMETER StoryKey   User Story key to check (e.g. STORY-0000)

    .OUTPUTS   String: existing Test issue key, or $null
    #>
    param([Parameter(Mandatory)][string]$StoryKey)

    $creds = Get-test-managementCreds

    # Strategy 1: check the issue's own links for any linked "Test" issue type
    try {
        $issue = Invoke-issue-trackerApi -Method GET `
            -Path "/rest/api/2/issue/$StoryKey`?fields=issuelinks" `
            -Creds $creds

        foreach ($link in $issue.fields.issuelinks) {
            $linked = if ($link.inwardIssue)  { $link.inwardIssue  } `
                      else                    { $link.outwardIssue }
            if ($linked -and $linked.fields.issuetype.name -eq "Test") {
                Write-Host "  [Find-Existingtest-managementTest] Found linked Test: $($linked.key)"
                return $linked.key
            }
        }
    } catch {
        Write-Warning "  [Find-Existingtest-managementTest] Could not retrieve issue links for $StoryKey`: $_"
    }

    # Strategy 2: JQL search - Test issues that mention the story key in their summary
    try {
        $jql     = [System.Uri]::EscapeDataString("project = `"$($StoryKey -replace '-\d+$','')`" AND issuetype = Test AND summary ~ `"$StoryKey`" ORDER BY created DESC")
        $results = Invoke-issue-trackerApi -Method GET `
            -Path "/rest/api/3/issue/search?jql=$jql&maxResults=1&fields=summary,issuetype" `
            -Creds $creds

        if ($results.issues -and $results.issues.Count -gt 0) {
            $found = $results.issues[0].key
            Write-Host "  [Find-Existingtest-managementTest] Found via JQL: $found"
            return $found
        }
    } catch {
        Write-Warning "  [Find-Existingtest-managementTest] JQL search failed: $_"
    }

    Write-Host "  [Find-Existingtest-managementTest] No existing Test issue found for $StoryKey"
    return $null
}

# ---------------------------------------------------------------------------
# Get step count for an existing test-management Test issue
# ---------------------------------------------------------------------------

function Get-test-managementTestStepCount {
    <#
    .SYNOPSIS
        Returns the number of steps on an existing test-management Test issue.
        Returns -1 if the test-management step API is unavailable (issue-tracker Cloud).

    .PARAMETER TestKey   test-management Test issue key (e.g. STORY-0000)
    #>
    param([Parameter(Mandatory)][string]$TestKey)

    $creds = Get-test-managementCreds
    try {
        $steps = Invoke-test-managementApi -Method GET `
            -Path "/rest/raven/1.0/api/test/$TestKey/step" `
            -Creds $creds
        $count = if ($steps) { @($steps).Count } else { 0 }
        Write-Host "  [Get-test-managementTestStepCount] $TestKey has $count step(s)."
        return $count
    } catch {
        Write-Warning "  [Get-test-managementTestStepCount] test-management step API unavailable for $TestKey (issue-tracker Cloud). Cannot verify step count remotely."
        return -1
    }
}

# ---------------------------------------------------------------------------
# Ensure test-management Test: create or reuse, add steps only if missing
# ---------------------------------------------------------------------------

function Ensure-test-managementTest {
    <#
    .SYNOPSIS
        Idempotent wrapper around New-test-managementTest.
        1. Checks if a Test issue already exists and is linked to the story.
        2. If it exists and has steps: returns existing key without changes.
        3. If it exists but has 0 steps (or step count unknown on Cloud):
              adds steps and returns existing key.
        4. If no Test exists: creates a new one and returns the new key.

    .OUTPUTS   Hashtable @{ Key = "STORY-XXXX"; Action = "created"|"updated"|"skipped" }
    #>
    param(
        [Parameter(Mandatory)][string]$ProjectKey,
        [Parameter(Mandatory)][string]$Summary,
        [Parameter(Mandatory)][string]$StoryKey,
        [Parameter(Mandatory)][array]$Steps,
        [string]$Description = ""
    )

    $creds = Get-test-managementCreds

    # --- Story status gate ---
    if (-not (Assert-StoryInDev -StoryKey $StoryKey)) {
        Write-Warning "Ensure-test-managementTest aborted for $StoryKey — story is not In Dev or Ready for Dev."
        return @{ Key = $null; Action = "blocked" }
    }

    # -- Step 1: look for an existing linked Test --
    $existingKey = Find-Existingtest-managementTest -StoryKey $StoryKey

    if ($existingKey) {
        $stepCount = Get-test-managementTestStepCount -TestKey $existingKey

        if ($stepCount -gt 0) {
            Write-Host "  [Ensure-test-managementTest] $existingKey already exists with $stepCount step(s) - skipping creation." -ForegroundColor Cyan
            return @{ Key = $existingKey; Action = "skipped" }
        }

        # stepCount is 0 or -1 (Cloud API unavailable) - add steps to existing issue
        $verb = if ($stepCount -eq 0) { "0 steps found" } else { "step count unknown (Cloud API)" }
        Write-Host "  [Ensure-test-managementTest] $existingKey exists but $verb - adding steps..." -ForegroundColor Yellow

        $stepsAdded   = 0
        $apiAvailable = $true
        foreach ($step in $Steps) {
            $stepBody = @{
                step   = $step.Action
                data   = if ($step.Data)     { $step.Data }     else { "" }
                result = if ($step.Expected) { $step.Expected } else { "" }
            }
            try {
                Invoke-test-managementApi -Method POST `
                    -Path "/rest/raven/1.0/api/test/$existingKey/step" `
                    -Creds $creds -Body $stepBody | Out-Null
                $stepsAdded++
            } catch {
                if ($apiAvailable) {
                    $apiAvailable = $false
                    # Server/DC API unavailable - try test-management Cloud API
                    Write-Host "  Server step API unavailable - trying test-management Cloud API..." -ForegroundColor Yellow
                    $cloudOk = Set-test-managementCloudTestSteps `
                        -TestKey    $existingKey `
                        -ProjectKey $ProjectKey `
                        -Summary    $Summary `
                        -Steps      $Steps
                    if (-not $cloudOk) {
                        Write-Warning "  Both step APIs unavailable. Add steps manually at: $($creds.Url)/browse/$existingKey"
                    }
                }
                break
            }
        }
        if ($stepsAdded -gt 0) { Write-Host "  Added $stepsAdded step(s) to $existingKey." }

        return @{ Key = $existingKey; Action = "updated" }
    }

    # -- Step 2: no existing Test found - create new --
    Write-Host "  [Ensure-test-managementTest] No existing Test for $StoryKey - creating new..." -ForegroundColor Cyan
    $newKey = New-test-managementTest `
        -ProjectKey  $ProjectKey `
        -Summary     $Summary `
        -StoryKey    $StoryKey `
        -Steps       $Steps `
        -Description $Description

    return @{ Key = $newKey; Action = "created" }
}

# ---------------------------------------------------------------------------
# Workflow: update an Active test-management Test when a new story impacts it
#   Active ? [review] ? Open ? [prep resolves findings + story context] ? Ready for Test Review
# ---------------------------------------------------------------------------

function Get-issue-trackerStoryDetail {
    <#
    .SYNOPSIS
        Fetches the full detail of a issue-tracker story including description, acceptance criteria,
        and ALL comments — so the prep agent can detect mid-sprint enhancements.
        Returns a structured hashtable. Falls back to $null on auth/404 failure.

    .PARAMETER StoryKey   Any issue-tracker issue key (story, task, test, etc.)
    .OUTPUTS   @{ Key; Summary; Description; AcceptanceCriteria; Comments; CommentCount }
    #>
    param([Parameter(Mandatory)][string]$StoryKey)

    $creds   = Get-test-managementCreds
    $headers = @{ Authorization = $creds.Headers.Authorization; Accept = "application/json" }

    # -- Issue fields ---------------------------------------------------------
    $detail = $null
    try {
        $uri  = "$($creds.Url)/rest/api/3/issue/$StoryKey`?fields=summary,description,comment,customfield_10014,customfield_10016"
        $resp = Invoke-WebRequest -Method GET -Uri $uri -Headers $headers -UseBasicParsing -ErrorAction Stop
        $detail = $resp.Content | ConvertFrom-Json
    } catch {
        Write-Warning "  [Get-issue-trackerStoryDetail] Cannot read issue $StoryKey`: $_"
        return $null
    }

    # -- Extract plain text from ADF description -------------------------------
    function ConvertFrom-AdfToText($node) {
        if (-not $node) { return "" }
        Set-StrictMode -Off
        $text = ""
        if ($node.type -eq "text")      { $text += $node.text }
        if ($node.content)              { foreach ($c in $node.content) { $text += ConvertFrom-AdfToText $c } }
        if ($node.type -in @("paragraph","heading","listItem","bulletList","orderedList")) { $text += "`n" }
        Set-StrictMode -Version Latest
        return $text
    }

    $descText = ConvertFrom-AdfToText $detail.fields.description
    # Try standard AC field (customfield_10014 = Acceptance Criteria in many issue-tracker configs)
    $acText   = ConvertFrom-AdfToText $detail.fields.customfield_10014
    if (-not $acText.Trim()) { $acText = ConvertFrom-AdfToText $detail.fields.customfield_10016 }

    # -- Extract comments ------------------------------------------------------
    $comments = @()
    foreach ($c in $detail.fields.comment.comments) {
        $author  = $c.author.displayName
        $created = $c.created -replace "T.*",""
        $body    = ConvertFrom-AdfToText $c.body
        $comments += "[${created}] ${author}: $body"
    }

    return @{
        Key                 = $StoryKey
        Summary             = $detail.fields.summary
        Description         = $descText.Trim()
        AcceptanceCriteria  = $acText.Trim()
        Comments            = $comments
        CommentCount        = $comments.Count
    }
}

function Get-issue-trackerIssueTransitions {
    <#
    .SYNOPSIS
        Returns all available workflow transitions for a issue-tracker issue.
    .PARAMETER IssueKey   Any issue-tracker issue key (Test, Story, etc.)
    .OUTPUTS   Array of transition objects with .id and .name properties.
    #>
    param([Parameter(Mandatory)][string]$IssueKey)

    $creds   = Get-test-managementCreds
    $uri     = "$($creds.Url)/rest/api/3/issue/$IssueKey/transitions"
    $headers = @{ Authorization = $creds.Headers.Authorization; Accept = "application/json" }
    try {
        $resp = Invoke-WebRequest -Method GET -Uri $uri -Headers $headers -UseBasicParsing -ErrorAction Stop
        return ($resp.Content | ConvertFrom-Json).transitions
    } catch {
        Write-Warning "  [Get-issue-trackerIssueTransitions] Failed for $IssueKey`: $_"
        return $null
    }
}

function Invoke-issue-trackerTransition {
    <#
    .SYNOPSIS
        Executes a named workflow transition on a issue-tracker issue.
        Returns $true on success, $false on failure.
    .PARAMETER IssueKey        issue-tracker issue key to transition (e.g. STORY-0000)
    .PARAMETER TransitionName  Exact name of the target transition (e.g. "Open", "Ready for Test Review")
    #>
    param(
        [Parameter(Mandatory)][string]$IssueKey,
        [Parameter(Mandatory)][string]$TransitionName
    )

    $transitions = Get-issue-trackerIssueTransitions -IssueKey $IssueKey
    if (-not $transitions) {
        Write-Warning "  [Invoke-issue-trackerTransition] No transitions available for $IssueKey."
        return $false
    }

    $t = $transitions | Where-Object { $_.name -eq $TransitionName } | Select-Object -First 1
    if (-not $t) {
        $available = ($transitions | Select-Object -ExpandProperty name) -join ", "
        Write-Warning "  [Invoke-issue-trackerTransition] Transition '$TransitionName' not found for $IssueKey."
        Write-Warning "    Available transitions: $available"
        return $false
    }

    $creds   = Get-test-managementCreds
    $uri     = "$($creds.Url)/rest/api/3/issue/$IssueKey/transitions"
    $headers = @{ Authorization = $creds.Headers.Authorization; "Content-Type" = "application/json"; Accept = "application/json" }
    $body    = @{ transition = @{ id = $t.id } } | ConvertTo-Json -Depth 5

    try {
        Invoke-WebRequest -Method POST -Uri $uri -Headers $headers -Body $body -UseBasicParsing -ErrorAction Stop | Out-Null
        Write-Host "  [Transition] $IssueKey  ?  '$TransitionName'" -ForegroundColor Cyan
        return $true
    } catch {
        Write-Warning "  [Invoke-issue-trackerTransition] Transition failed for $IssueKey to '$TransitionName': $_"
        return $false
    }
}

function Get-test-managementCloudTestSteps {
    <#
    .SYNOPSIS
        Retrieves the current steps from an existing test-management Cloud Test issue via GraphQL.
        Returns an array of @{ Action; Data; Expected } hashtables (empty array if none).
    .PARAMETER TestKey   test-management Test issue key (e.g. STORY-0000)
    .PARAMETER Region    test-management Cloud region. Defaults to US.
    #>
    param(
        [Parameter(Mandatory)][string]$TestKey,
        [string]$Region = "https://us.test-management.cloud.gettest-management.app"
    )

    $token      = Get-test-managementCloudToken
    $headers    = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
    $queryStr   = "{ getTests(jql: `"key = $TestKey`", limit: 1) { results { steps { action data result } } } }"
    $gqlBody    = @{ query = $queryStr } | ConvertTo-Json -Depth 5

    try {
        $resp = Invoke-WebRequest -Method POST -Uri "$Region/api/v2/graphql" `
            -Headers $headers -Body $gqlBody -UseBasicParsing -ErrorAction Stop
        $results = ($resp.Content | ConvertFrom-Json).data.getTests.results
        if (-not $results -or $results.Count -eq 0 -or -not $results[0].steps) { return @() }
        return @($results[0].steps | ForEach-Object { @{ Action = $_.action; Data = $_.data; Expected = $_.result } })
    } catch {
        Write-Warning "  [Get-test-managementCloudTestSteps] GraphQL query failed for $TestKey`: $_"
        return @()
    }
}

function Update-test-managementTestForStory {
    <#
    .SYNOPSIS
        Updates an existing Active test-management Test issue to accommodate changes introduced
        by a new or impacting User Story.

        Workflow enforced:
          Active  ?  Open  ?  [append new steps to existing steps]  ?  Ready for Test Review

    .PARAMETER StoryKey         The NEW/impacting User Story key (used in audit comment)
    .PARAMETER TestKey          Existing test-management Test issue key to update.
                                If omitted, Find-Existingtest-managementTest is called using LinkedStoryKey.
    .PARAMETER LinkedStoryKey   Story that currently owns the Test (used only when TestKey is omitted).
    .PARAMETER NewSteps         Array of @{ Action="..."; Data="..."; Expected="..." } to APPEND.
    .PARAMETER ProjectKey       issue-tracker project key. Default "STORY".
    .PARAMETER Region           test-management Cloud region. Default US.

    .OUTPUTS   Hashtable: @{ TestKey; StoryKey; StepsAdded; TotalSteps; FinalStatus }
               Returns $null on failure.

    .EXAMPLE
        $steps = @(
            @{ Action="Navigate to Help"; Data=""; Expected="Help page loads" }
        )
        Update-test-managementTestForStory -StoryKey "STORY-0000" -TestKey "STORY-0000" -NewSteps $steps
    #>
    param(
        [Parameter(Mandatory)][string]$StoryKey,
        [string]$TestKey         = "",
        [string]$LinkedStoryKey  = "",
        [Parameter(Mandatory)][array]$NewSteps,
        [string]$ProjectKey      = "STORY",
        [string]$Region          = "https://us.test-management.cloud.gettest-management.app"
    )

    # -- 1. Resolve TestKey --------------------------------------------------
    if (-not $TestKey) {
        $lookupKey = if ($LinkedStoryKey) { $LinkedStoryKey } else { $StoryKey }
        Write-Host "  [Update] Finding existing Test for $lookupKey..."
        $TestKey = Find-Existingtest-managementTest -StoryKey $lookupKey
        if (-not $TestKey) {
            Write-Warning "  [Update-test-managementTestForStory] No existing test-management Test found for $lookupKey."
            Write-Warning "    Use New-test-managementTest / Ensure-test-managementTest to create one first."
            return $null
        }
    }
    Write-Host "  [Update] Target Test issue: $TestKey"

    # -- 2. Verify status is Active ------------------------------------------
    $currentStatus = Get-StoryStatus -StoryKey $TestKey
    Write-Host "  [Update] $TestKey current status: '$currentStatus'"

    if ($currentStatus -ne "Active") {
        Write-Warning "  [Update-test-managementTestForStory] BLOCKED: $TestKey is '$currentStatus', expected 'Active'."
        Write-Warning "    Only tests in 'Active' status can be updated via this workflow."
        return $null
    }

    # -- 3. Transition  Active ? Open ----------------------------------------
    Write-Host "  [Update] Transitioning $TestKey Active ? Open..." -ForegroundColor Yellow
    if (-not (Invoke-issue-trackerTransition -IssueKey $TestKey -TransitionName "Open")) {
        Write-Warning "  [Update-test-managementTestForStory] Cannot transition $TestKey to 'Open'. Aborting."
        return $null
    }

    # -- 4. Fetch existing steps ----------------------------------------------
    Write-Host "  [Update] Fetching existing steps from $TestKey..."
    $existingSteps = Get-test-managementCloudTestSteps -TestKey $TestKey -Region $Region
    Write-Host "  [Update] Existing steps: $(@($existingSteps).Count)  |  New steps to append: $(@($NewSteps).Count)"

    # -- 5. Merge existing + new ----------------------------------------------
    $mergedSteps = @($existingSteps) + @($NewSteps)

    # -- 6. Upload merged steps -----------------------------------------------
    Write-Host "  [Update] Uploading $(@($mergedSteps).Count) merged step(s) to $TestKey..."
    $uploaded = Set-test-managementCloudTestSteps `
        -TestKey    $TestKey `
        -ProjectKey $ProjectKey `
        -Summary    "$TestKey - updated for $StoryKey" `
        -Steps      $mergedSteps `
        -Region     $Region

    if (-not $uploaded) {
        Write-Warning "  [Update-test-managementTestForStory] Step upload FAILED. $TestKey left in 'Open' — review and transition manually."
        return $null
    }

    # -- 7. Add audit comment -------------------------------------------------
    $creds = Get-test-managementCreds
    $commentBody = @{
        body = @{
            version = 1
            type    = "doc"
            content = @(@{
                type    = "paragraph"
                content = @(@{
                    type = "text"
                    text = "Test steps updated by automation on $(Get-Date -Format 'yyyy-MM-dd') to accommodate changes from story $StoryKey. $(@($NewSteps).Count) new step(s) appended ($(@($existingSteps).Count) existing preserved). Total: $(@($mergedSteps).Count) steps."
                })
            })
        }
    }
    $commentUri     = "$($creds.Url)/rest/api/3/issue/$TestKey/comment"
    $commentHeaders = @{ Authorization = $creds.Headers.Authorization; "Content-Type" = "application/json"; Accept = "application/json" }
    try {
        Invoke-WebRequest -Method POST -Uri $commentUri -Headers $commentHeaders `
            -Body ($commentBody | ConvertTo-Json -Depth 10) -UseBasicParsing -ErrorAction Stop | Out-Null
        Write-Host "  [Update] Audit comment added to $TestKey." -ForegroundColor Gray
    } catch {
        Write-Warning "  [Update-test-managementTestForStory] Could not add audit comment: $_"
    }

    # -- 8. Transition  Open ? Ready for Test Review --------------------------
    Write-Host "  [Update] Transitioning $TestKey Open ? 'Ready for Test Review'..." -ForegroundColor Yellow
    $finalOk = Invoke-issue-trackerTransition -IssueKey $TestKey -TransitionName "Ready for Test Review"
    if (-not $finalOk) {
        Write-Warning "  [Update-test-managementTestForStory] Steps uploaded but transition to 'Ready for Test Review' failed."
        Write-Warning "    Transition $TestKey manually in issue-tracker."
    }

    $finalStatus = if ($finalOk) { "Ready for Test Review" } else { "Open (manual transition required)" }
    Write-Host "  [Update-test-managementTestForStory] COMPLETE: $TestKey ? '$finalStatus'  ($(@($mergedSteps).Count) total steps)" -ForegroundColor Green

    return @{
        TestKey     = $TestKey
        StoryKey    = $StoryKey
        StepsAdded  = @($NewSteps).Count
        TotalSteps  = @($mergedSteps).Count
        FinalStatus = $finalStatus
    }
}

Write-Host "test-management-api.ps1 loaded. Functions available:"
Write-Host "  New-test-managementTest, New-test-managementTestExecution, Get-test-managementTestRunId"
Write-Host "  Get-test-managementTestRunSteps, Set-test-managementStepResult, Add-test-managementStepEvidence"
Write-Host "  Set-test-managementTestRunStatus, Show-test-managementTestRunSteps"
Write-Host "  Get-test-managementCloudToken, Import-test-managementCloudTestSteps, Set-test-managementCloudTestSteps  [test-management Cloud API v2]"
Write-Host "  Find-Existingtest-managementTest, Get-test-managementTestStepCount, Ensure-test-managementTest  [idempotent helpers]"
Write-Host "  Get-StoryStatus, Assert-StoryInDev  [status gate: In Dev | Ready for Dev]"
Write-Host "  Get-issue-trackerIssueTransitions, Invoke-issue-trackerTransition  [workflow transition helpers]"
Write-Host "  Get-test-managementCloudTestSteps  [read existing steps via GraphQL]"
Write-Host "  Get-issue-trackerStoryDetail  [fetch description + comments + AC for agent context]"
Write-Host "  Update-test-managementTestForStory  [Active?Open?append steps?Ready for Test Review]"





