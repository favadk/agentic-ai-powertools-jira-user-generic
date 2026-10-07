. .\scripts\xray-api.ps1
$tok = Get-XrayCloudToken
$gql = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }
function Invoke-Gql($query) {
    $body = @{ query = $query } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $body
}

$runId = "6a5ff87b72d5b592fbee751e"
$step4 = "2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78"

$actualResult = "AC-03 DEFECT: After navigating to /docs/security/ while unauthenticated and completing sign-in via Cognito, the docs-auth flow redirected to hub root / instead of returning to the original /docs/security/ path. The returnUrl parameter is not honoured. Finding raised: OLAC-7531 (Sub-task, High, Open)."
$comment      = "Finding: OLAC-7531 - returnUrl not honoured post sign-in redirect. AC-03 violated. Sub-task linked to parent story OLAC-7456."

Write-Output "=== Setting actualResult + comment on step 4 ==="
$m = "mutation { updateTestRunStep(testRunId: `"$runId`", stepId: `"$step4`", updateData: { status: `"FAILED`", actualResult: `"$actualResult`", comment: `"$comment`" }) { warnings } }"
$mr = Invoke-Gql $m
if ($mr.errors) { Write-Output "ERROR: $($mr.errors[0].message)" }
else { Write-Output "Done. Warnings: $($mr.data.updateTestRunStep.warnings)" }

Write-Output ""
Write-Output "=== Verifying step 4 ==="
$v = Invoke-Gql "{ getTestExecution(issueId: `"1407385`") { testRuns(limit:5) { results { id steps { id status { name } actualResult comment } } } } }"
$s4 = (($v.data.getTestExecution.testRuns.results | Where-Object { $_.id -eq $runId }).steps | Where-Object { $_.id -eq $step4 })
Write-Output "  Status:       $($s4.status.name)"
Write-Output "  ActualResult: $($s4.actualResult)"
Write-Output "  Comment:      $($s4.comment)"
