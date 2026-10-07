. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }
function Invoke-Gql($b) { Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $b }

$runId   = "6a6134f372d5b592fbf526e9"
$step4id = "2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78"
$evDir   = "docs\TestExecution\evidence\STORY-0000-Cycle2"

$files = @(
    @{ Name = "cycle2-step4-01-unauthenticated-cognito-redirect.png"; Mime = "image/png"; Path = "$evDir\step4-01-unauthenticated-cognito-redirect.png" },
    @{ Name = "cycle2-step4-02-credentials-entered.png";               Mime = "image/png"; Path = "$evDir\step4-02-credentials-entered.png" },
    @{ Name = "cycle2-step4-03-post-signin-correct-redirect-PASS.png"; Mime = "image/png"; Path = "$evDir\step4-03-post-signin-correct-redirect-PASS.png" }
)

Write-Output "=== Uploading Cycle 2 evidence to step 4 ==="
foreach ($ev in $files) {
    if (-not (Test-Path $ev.Path)) {
        Write-Output ("MISSING: " + $ev.Path)
        continue
    }
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $ev.Path))
    $b64   = [Convert]::ToBase64String($bytes)
    $body  = @{
        query     = "mutation add(`$runId:String!, `$stepId:String!, `$ev:[AttachmentDataInput]) { addEvidenceToTestRunStep(testRunId:`$runId, stepId:`$stepId, evidence:`$ev) { addedEvidence warnings } }"
        variables = @{
            runId  = $runId
            stepId = $step4id
            ev     = @(@{ filename = $ev.Name; mimeType = $ev.Mime; data = $b64 })
        }
    } | ConvertTo-Json -Compress -Depth 6
    $res = Invoke-Gql $body
    if ($res.errors) {
        Write-Output ("  ERROR " + $ev.Name + ": " + $res.errors[0].message)
    } else {
        $added = $res.data.addEvidenceToTestRunStep.addedEvidence
        Write-Output ("  Uploaded: " + $ev.Name + " -> id=" + $added[0].id)
    }
}
Write-Output ""
Write-Output "=== Evidence upload complete ==="
