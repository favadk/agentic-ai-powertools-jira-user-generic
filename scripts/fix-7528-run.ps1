. .\scripts\xray-api.ps1
$tok  = Get-XrayCloudToken
$gql  = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }
function Invoke-Gql($b) { Invoke-RestMethod -Uri $gql -Method POST -Headers $hdrs -Body $b }

# Cycle 1 run in OLAC-7528
$runId   = "6a5ff87b72d5b592fbee751e"
$step4id = "2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78"

# --- Update step 4: PASSED + fix-verification actualResult ---
$ar = "PASSED after fix (re-verified 2026-07-22): After navigating to /docs/security/ unauthenticated and completing Cognito sign-in, docs-auth correctly redirected to /docs/security/. returnUrl is now honoured. OLAC-7531 resolved."
$mutStep4 = @{
    query     = "mutation upd(`$r:String!, `$s:String!, `$ar:String!) { updateTestRunStep(testRunId:`$r, stepId:`$s, updateData: { status: `"PASSED`", actualResult:`$ar }) { warnings } }"
    variables = @{ r = $runId; s = $step4id; ar = $ar }
} | ConvertTo-Json -Compress -Depth 5
$r4 = Invoke-Gql $mutStep4
if ($r4.errors) { Write-Output ("ERROR step4: " + $r4.errors[0].message) }
else { Write-Output "Step 4 updated to PASSED." }

# --- Upload Cycle 2 evidence screenshots to OLAC-7528 step 4 ---
$evDir = "docs\TestExecution\evidence\OLAC-7456-Cycle2"
$files = @(
    @{ Name = "fixverif-step4-01-cognito-redirect.png"; Mime = "image/png"; Path = "$evDir\step4-01-unauthenticated-cognito-redirect.png" },
    @{ Name = "fixverif-step4-02-credentials.png";      Mime = "image/png"; Path = "$evDir\step4-02-credentials-entered.png" },
    @{ Name = "fixverif-step4-03-pass-docs-security.png"; Mime = "image/png"; Path = "$evDir\step4-03-post-signin-correct-redirect-PASS.png" }
)
Write-Output "=== Uploading fix-verification evidence to OLAC-7528 step 4 ==="
foreach ($ev in $files) {
    if (-not (Test-Path $ev.Path)) { Write-Output ("MISSING: " + $ev.Path); continue }
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $ev.Path))
    $b64   = [Convert]::ToBase64String($bytes)
    $body  = @{
        query     = "mutation add(`$runId:String!, `$stepId:String!, `$ev:[AttachmentDataInput]) { addEvidenceToTestRunStep(testRunId:`$runId, stepId:`$stepId, evidence:`$ev) { addedEvidence warnings } }"
        variables = @{ runId = $runId; stepId = $step4id; ev = @(@{ filename = $ev.Name; mimeType = $ev.Mime; data = $b64 }) }
    } | ConvertTo-Json -Compress -Depth 6
    $res = Invoke-Gql $body
    if ($res.errors) { Write-Output ("  ERROR " + $ev.Name + ": " + $res.errors[0].message) }
    else { Write-Output ("  Uploaded: " + $ev.Name) }
}

# --- Set overall run PASSED ---
$ms  = '{"query":"mutation { updateTestRunStatus(id: \"' + $runId + '\", status: \"PASSED\") }"}'
$rS  = Invoke-Gql $ms
if ($rS.errors) { Write-Output ("ERROR run status: " + $rS.errors[0].message) }
else { Write-Output ("Run status set to: " + $rS.data.updateTestRunStatus) }

Write-Output ""
Write-Output "=== OLAC-7528 run updated to PASSED ==="
