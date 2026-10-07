. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }
function Invoke-Gql($b) { Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $b }

# OLAC-7534 numeric ID
$numericId = "1408016"

# Get run for OLAC-7496 in this TE
$q = '{"query":"{ getTestExecution(issueId: \"1408016\") { testRuns(limit:5) { results { id test { issueId } steps { id status { name } } } } } }"}'
$r = Invoke-Gql $q
if ($r.errors) { Write-Output ("GQL errors: " + ($r.errors | ConvertTo-Json -Compress)) ; exit 1 }
$runs = $r.data.getTestExecution.testRuns.results
Write-Output ("Total runs: " + $runs.Count)
$run   = $runs | Select-Object -First 1
$runId = $run.id
Write-Output ("Run ID: " + $runId)
Write-Output ("Step count: " + $run.steps.Count)
$si = 1
foreach ($step in $run.steps) {
    Write-Output ("  Step " + $si + " " + $step.id + " [" + $step.status.name + "]")
    $si++
}

# Set all steps PASSED
Write-Output ""
Write-Output "=== Setting all steps PASSED ==="
$si = 1
foreach ($step in $run.steps) {
    $mut = @{
        query     = "mutation upd(`$r:String!, `$s:String!) { updateTestRunStep(testRunId:`$r, stepId:`$s, updateData: { status: `"PASSED`" }) { warnings } }"
        variables = @{ r = $runId; s = $step.id }
    } | ConvertTo-Json -Compress -Depth 5
    $res = Invoke-Gql $mut
    if ($res.errors) { Write-Output ("  ERROR step " + $si + ": " + $res.errors[0].message) }
    else { Write-Output ("  Step " + $si + " PASSED: " + $step.id) }
    $si++
}

# Step 4 actualResult
$step4id = ($run.steps | Select-Object -Index 3).id
Write-Output ""
Write-Output ("Step 4 ID: " + $step4id)

if ($step4id) {
    $ar = "AC-03 FIX VERIFIED: After navigating to /docs/security/ unauthenticated then signing in via Cognito, the docs-auth flow correctly redirected to /docs/security/ (the originally requested page). returnUrl parameter is now honoured. Sub-task OLAC-7531 resolved."
    $mutAr = @{
        query     = "mutation upd(`$r:String!, `$s:String!, `$ar:String!) { updateTestRunStep(testRunId:`$r, stepId:`$s, updateData: { status: `"PASSED`", actualResult:`$ar }) { warnings } }"
        variables = @{ r = $runId; s = $step4id; ar = $ar }
    } | ConvertTo-Json -Compress -Depth 5
    $rAr = Invoke-Gql $mutAr
    if ($rAr.errors) { Write-Output ("ERROR step 4 AR: " + $rAr.errors[0].message) }
    else { Write-Output "Step 4 actualResult set." }
}

# Set overall PASSED
$ms = '{"query":"mutation { updateTestRunStatus(id: \"' + $runId + '\", status: \"PASSED\") }"}'
$rS = Invoke-Gql $ms
Write-Output ""
if ($rS.errors) { Write-Output ("ERROR run status: " + $rS.errors[0].message) }
else { Write-Output ("Run status: " + $rS.data.updateTestRunStatus) }

# Save
("$runId" + [Environment]::NewLine + "$step4id") | Out-File "scripts\cycle2-runid.txt" -Encoding UTF8
Write-Output ""
Write-Output ("=== Done  TE=OLAC-7534  RunID=" + $runId + "  Step4=" + $step4id)
