. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }

function Invoke-Gql($body) {
    Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $body
}

# Get numeric ID of OLAC-7534
$jira = [System.Net.WebClient]::new()
$jira.Headers.Add("Authorization", "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($env:JIRA_USERNAME):$($env:JIRA_API_TOKEN)")))
$jira.Headers.Add("Accept", "application/json")

# Read Jira creds from mcp.local.json
$mcpConfig = Get-Content ".vscode\mcp.local.json" | ConvertFrom-Json
$jiraBase  = $mcpConfig.servers."jira-mcp-server".env.JIRA_BASE_URL
$jiraUser  = $mcpConfig.servers."jira-mcp-server".env.JIRA_USERNAME
$jiraToken = $mcpConfig.servers."jira-mcp-server".env.JIRA_API_TOKEN

$b64  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${jiraUser}:${jiraToken}"))
$resp = Invoke-RestMethod -Uri "$jiraBase/rest/api/2/issue/OLAC-7534?fields=id" `
    -Headers @{ Authorization = "Basic $b64"; Accept = "application/json" }
$te7534NumericId = $resp.id
Write-Output "OLAC-7534 numeric ID: $te7534NumericId"

# Get run ID for OLAC-7496 in this TE
$qGetRun = '{"query":"{ getTestExecution(issueId: \"' + $te7534NumericId + '\") { testRuns(limit:5) { results { id test { issueId } steps { id status { name } } } } } }"}'
$r = Invoke-Gql $qGetRun
$run = $r.data.getTestExecution.testRuns.results | Select-Object -First 1
$runId = $run.id
Write-Output "Run ID: $runId"
Write-Output "Steps:"
$run.steps | ForEach-Object { Write-Output "  $($_.id) -> $($_.status.name)" }

# Set all 7 steps PASSED
Write-Output ""
Write-Output "=== Setting all steps to PASSED ==="
foreach ($step in $run.steps) {
    $mut = @{
        query     = "mutation upd(`$runId:String!, `$stepId:String!) { updateTestRunStep(testRunId:`$runId, stepId:`$stepId, updateData: { status: `"PASSED`" }) { warnings } }"
        variables = @{ runId = $runId; stepId = $step.id }
    } | ConvertTo-Json -Compress -Depth 5
    $rMut = Invoke-Gql $mut
    if ($rMut.errors) { Write-Output "  ERROR $($step.id): $($rMut.errors[0].message)" }
    else { Write-Output "  PASSED: $($step.id)" }
}

# Add actualResult to step 4 (identifying it as the AC-03 fix verification step)
Write-Output ""
Write-Output "=== Setting actualResult for step 4 ==="
$step4 = ($run.steps | Select-Object -Index 3).id   # 0-based index 3 = step 4
$ar = "AC-03 FIX VERIFIED: After navigating to /docs/security/ unauthenticated, signing in via Cognito, the docs-auth flow correctly redirected to /docs/security/ (the originally requested page). returnUrl parameter is now honoured. OLAC-7531 resolved."
$mutAr = @{
    query     = "mutation upd(`$runId:String!, `$stepId:String!, `$ar:String!) { updateTestRunStep(testRunId:`$runId, stepId:`$stepId, updateData: { status: `"PASSED`", actualResult:`$ar }) { warnings } }"
    variables = @{ runId = $runId; stepId = $step4; ar = $ar }
} | ConvertTo-Json -Compress -Depth 5
$rAr = Invoke-Gql $mutAr
if ($rAr.errors) { Write-Output "ERROR: $($rAr.errors[0].message)" }
else { Write-Output "Step 4 actualResult set." }

# Set overall run status PASSED
Write-Output ""
Write-Output "=== Setting run status to PASSED ==="
$mutStatus = '{"query":"mutation { updateTestRunStatus(id: \"' + $runId + '\", status: \"PASSED\") }"}'
$rStatus = Invoke-Gql $mutStatus
if ($rStatus.errors) { Write-Output "ERROR: $($rStatus.errors[0].message)" }
else { Write-Output "Run status: $($rStatus.data.updateTestRunStatus)" }

# Save run ID for next script
$runId | Out-File "scripts\cycle2-runid.txt" -Encoding UTF8
Write-Output ""
Write-Output "=== Done. Run ID saved to scripts\cycle2-runid.txt ==="
Write-Output "Run ID: $runId"
Write-Output "Step 4 ID: $step4"
