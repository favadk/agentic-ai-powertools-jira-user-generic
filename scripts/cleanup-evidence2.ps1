. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }
$runId = "6a5ff87b72d5b592fbee751e"
$step4 = "2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78"

# Remove the two duplicates by explicit ID
$idsToRemove = @("2050c501-aa9e-49e0-ae03-821794e4d75b", "b12c6bc4-cefc-4e79-98fc-3d0bda88378f")
Write-Output "Removing: $($idsToRemove -join ', ')"

$rmBody = @{
    query     = "mutation rm(`$testRunId:String!, `$stepId:String!, `$ids:[String]) { removeEvidenceFromTestRunStep(testRunId:`$testRunId, stepId:`$stepId, evidenceIds:`$ids) { removedEvidence warnings } }"
    variables = @{ testRunId = $runId; stepId = $step4; ids = $idsToRemove }
} | ConvertTo-Json -Compress -Depth 5

$rm = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $rmBody
if ($rm.errors) { Write-Output "ERROR: $($rm.errors[0].message)" }
else { Write-Output "Removed: $($rm.data.removeEvidenceFromTestRunStep.removedEvidence -join ', ')" }

Write-Output ""
Write-Output "=== Final evidence on step 4 ==="
$vBody = '{"query":"{ getTestExecution(issueId: \"1407385\") { testRuns(limit:5) { results { id steps { id status { name } actualResult comment evidence { id filename size } } } } } }"}'
$v    = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $vBody
$run  = $v.data.getTestExecution.testRuns.results | Where-Object { $_.id -eq $runId }
$s4   = $run.steps | Where-Object { $_.id -eq $step4 }
Write-Output "  Status:       $($s4.status.name)"
Write-Output "  ActualResult: $($s4.actualResult)"
Write-Output "  Comment:      $($s4.comment)"
$s4.evidence | ForEach-Object { Write-Output "  Evidence:     $($_.filename) ($($_.size) bytes)" }
