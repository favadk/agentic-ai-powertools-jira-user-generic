. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }

$runId = "6a5ff87b72d5b592fbee751e"
$step4 = "2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78"
$base  = "C:\Agentic-AI\agentic-ai-powertools-jira-user-new\docs\TestExecution\evidence\OLAC-7456-Cycle1"

# Read and base64-encode one file as a test
$testFile = "$base\evidence-step4-01-cognito-signin.png"
$b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($testFile))

Write-Output "File size: $([System.IO.File]::ReadAllBytes($testFile).Length) bytes"
Write-Output "Base64 length: $($b64.Length) chars"
Write-Output ""

# Try mutation with base64 data - attempt 1: use AttachmentInput structure
$mutBody = @{
    query = "mutation addEv(`$testRunId:String!, `$stepId:String!, `$evidence:[AttachmentDataInput]) { addEvidenceToTestRunStep(testRunId:`$testRunId, stepId:`$stepId, evidence:`$evidence) { addedEvidence warnings } }"
    variables = @{
        testRunId = $runId
        stepId    = $step4
        evidence  = @(@{
            filename = "evidence-step4-01-cognito-signin.png"
            mimeType = "image/png"
            data     = $b64
        })
    }
} | ConvertTo-Json -Compress -Depth 5

$r = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $mutBody
if ($r.errors) {
    Write-Output "ERROR with AttachmentDataInput: $($r.errors[0].message)"
} else {
    Write-Output "SUCCESS: $($r.data | ConvertTo-Json -Compress)"
}

# Try mutation attempt 2: no type hint, just inline
$mut2 = '{"query":"mutation { addEvidenceToTestRunStep(testRunId: \"' + $runId + '\", stepId: \"' + $step4 + '\", evidence: [{ filename: \"test.png\", mimeType: \"image/png\", data: \"' + $b64.Substring(0,20) + '\" }]) { addedEvidence warnings } }"}'
Write-Output ""
Write-Output "=== Attempt 2 (inline, truncated b64) ==="
$r2 = Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $mut2
if ($r2.errors) {
    Write-Output "ERROR: $($r2.errors | ConvertTo-Json -Compress)"
} else {
    Write-Output "SUCCESS: $($r2.data | ConvertTo-Json -Compress)"
}
