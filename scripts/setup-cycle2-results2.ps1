. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }

function Invoke-Gql($body) {
    Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $body
}

$mcpConfig = Get-Content ".vscode\mcp.local.json" | ConvertFrom-Json
$jiraBase  = $mcpConfig.servers."jira-mcp-server".env.JIRA_BASE_URL
$jiraUser  = $mcpConfig.servers."jira-mcp-server".env.JIRA_USERNAME
$jiraToken = $mcpConfig.servers."jira-mcp-server".env.JIRA_API_TOKEN
Write-Output "Jira Base: $jiraBase"

$creds = "${jiraUser}:${jiraToken}"
$b64   = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($creds))
$jHdrs = @{ Authorization = "Basic $b64"; Accept = "application/json" }

$resp = Invoke-RestMethod -Uri "$jiraBase/rest/api/2/issue/STORY-7534?fields=id" -Headers $jHdrs
$te7534NumericId = $resp.id
Write-Output "STORY-7534 numeric ID: $te7534NumericId"

# Get run ID for STORY-7496 in this TE
$qBody = '{"query":"{ getTestExecution(issueId: \"' + $te7534NumericId + '\") { testRuns(limit:5) { results { id test { issueId } steps { id status { name } } } } } }"}'
$r    = Invoke-Gql $qBody
$run  = $r.data.getTestExecution.testRuns.results | Select-Object -First 1
$runId = $run.id
Write-Output "Run ID: $runId"
Write-Output "Step count: $($run.steps.Count)"
$run.steps | ForEach-Object -Begin { $si=1 } -Process { Write-Output "  Step $si $($_.id)"; $si++ }

# Set all 7 steps PASSED
Write-Output ""
Write-Output "=== Setting all steps PASSED ==="
$i = 1
foreach ($step in $run.steps) {
    $mut = @{
        query     = "mutation upd(`$runId:String!, `$stepId:String!) { updateTestRunStep(testRunId:`$runId, stepId:`$stepId, updateData: { status: `"PASSED`" }) { warnings } }"
        variables = @{ runId = $runId; stepId = $step.id }
    } | ConvertTo-Json -Compress -Depth 5
    $rMut = Invoke-Gql $mut
    if ($rMut.errors) { Write-Output "  ERROR step $i $($rMut.errors[0].message)" }
    else { Write-Output "  Step $i PASSED: $($step.id)" }
    $i++
}

# Identify step 4 (0-based index 3)
$step4id = ($run.steps | Select-Object -Index 3).id
Write-Output ""
Write-Output "Step 4 ID: $step4id"

# Set step 4 actualResult
if ($step4id) {
    $ar = "AC-03 FIX VERIFIED: After navigating to /docs/security/ unauthenticated, signing in via Cognito, the docs-auth flow correctly redirected to /docs/security/ (the originally requested page). returnUrl parameter is now honoured. STORY-7531 resolved."
    $mutAr = @{
        query     = "mutation upd(`$runId:String!, `$stepId:String!, `$ar:String!) { updateTestRunStep(testRunId:`$runId, stepId:`$stepId, updateData: { status: `"PASSED`", actualResult:`$ar }) { warnings } }"
        variables = @{ runId = $runId; stepId = $step4id; ar = $ar }
    } | ConvertTo-Json -Compress -Depth 5
    $rAr = Invoke-Gql $mutAr
    if ($rAr.errors) { Write-Output "ERROR step 4 AR: $($rAr.errors[0].message)" }
    else { Write-Output "Step 4 actualResult set." }
}

# Set overall run PASSED
$mutStatus = '{"query":"mutation { updateTestRunStatus(id: \"' + $runId + '\", status: \"PASSED\") }"}'
$rStatus = Invoke-Gql $mutStatus
Write-Output ""
if ($rStatus.errors) { Write-Output "ERROR run status: $($rStatus.errors[0].message)" }
else { Write-Output "Run status: $($rStatus.data.updateTestRunStatus)" }

# Save for evidence upload
"$runId`n$step4id" | Out-File "scripts\cycle2-runid.txt" -Encoding UTF8
Write-Output ""
Write-Output "=== Complete ==="
Write-Output "TE:    STORY-7534"
Write-Output "RunID: $runId"
Write-Output "Step4: $step4id"
