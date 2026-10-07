. .\scripts\test-management-api.ps1
$tok  = Get-test-managementCloudToken
$gql  = "https://us.test-management.cloud.gettest-management.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }
$runId = "6a5ff87b72d5b592fbee751e"
$step4 = "2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78"

$vBody = '{"query":"{ getTestExecution(issueId: \"1407385\") { testRuns(limit:5) { results { id steps { id evidence { id filename size } } } } } }"}'
$v    = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $vBody
$run  = $v.data.getTestExecution.testRuns.results | Where-Object { $_.id -eq $runId }
$s4   = $run.steps | Where-Object { $_.id -eq $step4 }

Write-Output "Current evidence on step 4:"
$s4.evidence | ForEach-Object { Write-Output "  ID=$($_.id)  file=$($_.filename)  size=$($_.size)" }

# Identify IDs to remove: test.png (any) and the smaller duplicate of evidence-step4-01 (the 19569-byte one that appears twice - keep latest, remove first)
$toRemove = $s4.evidence | Where-Object { $_.filename -eq "test.png" } | Select-Object -ExpandProperty id
# Also find duplicate evidence-step4-01 (should appear twice with same size 19569 - remove the first occurrence)
$dups = $s4.evidence | Where-Object { $_.filename -eq "evidence-step4-01-cognito-signin.png" }
if ($dups.Count -gt 1) {
    $toRemove += ($dups | Select-Object -First 1).id
}

if ($toRemove.Count -eq 0) {
    Write-Output "No duplicates to remove."
} else {
    Write-Output ""
    Write-Output "Removing IDs: $($toRemove -join ', ')"
    $rmBody = @{
        query     = "mutation rm(`$testRunId:String!, `$stepId:String!, `$ids:[String]) { removeEvidenceFromTestRunStep(testRunId:`$testRunId, stepId:`$stepId, evidenceIds:`$ids) { removedEvidence warnings } }"
        variables = @{ testRunId = $runId; stepId = $step4; ids = $toRemove }
    } | ConvertTo-Json -Compress -Depth 5
    $rm = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $rmBody
    if ($rm.errors) { Write-Output "ERROR: $($rm.errors[0].message)" }
    else { Write-Output "Removed: $($rm.data.removeEvidenceFromTestRunStep.removedEvidence -join ', ')" }
}

Write-Output ""
Write-Output "=== Final evidence on step 4 ==="
$v2   = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $vBody
$run2 = $v2.data.getTestExecution.testRuns.results | Where-Object { $_.id -eq $runId }
$s4b  = $run2.steps | Where-Object { $_.id -eq $step4 }
$s4b.evidence | ForEach-Object { Write-Output "  $($_.filename) ($($_.size) bytes)" }
