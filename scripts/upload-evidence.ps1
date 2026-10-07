. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }

$runId = "6a5ff87b72d5b592fbee751e"
$step4 = "2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78"
$base  = "C:\Agentic-AI\agentic-ai-powertools-jira-user-new\docs\TestExecution\evidence\OLAC-7456-Cycle1"

$evidenceFiles = @(
    @{ Name = "evidence-step4-01-cognito-signin.png";             Mime = "image/png" },
    @{ Name = "evidence-step4-02-cognito-filled.png";             Mime = "image/png" },
    @{ Name = "evidence-step4-03-post-signin-wrong-redirect.png"; Mime = "image/png" }
)

Write-Output "=== Uploading evidence to step 4 ==="
foreach ($ev in $evidenceFiles) {
    $fp  = "$base\$($ev.Name)"
    $b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($fp))
    Write-Output "Uploading $($ev.Name)..."
    $body = @{
        query     = "mutation addEv(`$testRunId:String!, `$stepId:String!, `$evidence:[AttachmentDataInput]) { addEvidenceToTestRunStep(testRunId:`$testRunId, stepId:`$stepId, evidence:`$evidence) { addedEvidence warnings } }"
        variables = @{ testRunId = $runId; stepId = $step4; evidence = @(@{ filename = $ev.Name; mimeType = $ev.Mime; data = $b64 }) }
    } | ConvertTo-Json -Compress -Depth 5
    $r = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $body
    if ($r.errors) { Write-Output "  ERROR: $($r.errors[0].message)" }
    else { Write-Output "  Added: $($r.data.addEvidenceToTestRunStep.addedEvidence -join ', ')" }
}

Write-Output ""
Write-Output "=== Verifying evidence on step 4 ==="
$vBody = '{"query":"{ getTestExecution(issueId: \"1407385\") { testRuns(limit:5) { results { id steps { id status { name } evidence { filename size } } } } } }"}'
$v = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $vBody
$run = $v.data.getTestExecution.testRuns.results | Where-Object { $_.id -eq $runId }
$s4  = $run.steps | Where-Object { $_.id -eq $step4 }
Write-Output "  Step 4 Status: $($s4.status.name)"
if ($s4.evidence) {
    $s4.evidence | ForEach-Object { Write-Output "  Evidence: $($_.filename) ($($_.size) bytes)" }
} else {
    Write-Output "  Evidence: (none)"
}
