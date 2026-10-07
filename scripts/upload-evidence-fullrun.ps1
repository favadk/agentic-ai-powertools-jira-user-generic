param()
Set-Location "C:\Agentic-AI\agentic-ai-powertools-jira-user-generic"
. ".\scripts\xray-api.ps1"

$token = Get-XrayCloudToken
Write-Output "Token length: $($token.Length)"

$runId = "6a5ff87b72d5b592fbee751e"
$ep = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
$dir = ".\docs\TestExecution\evidence\STORY-0000-FullRun"

$sids = @{
    1 = "1d664a4c-f24b-41fd-9b21-7afadb81787b"
    2 = "9aac8aa4-0f12-433d-b131-1f44efbffeaa"
    3 = "d6e35aa0-1a0f-4cec-8034-5ae689379c95"
    4 = "2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78"
    5 = "87b04cd4-995a-4d74-b116-7cc45c4393f9"
    6 = "bd67bfa7-0f5e-4f57-b817-e464659ace4c"
    7 = "0238d135-84fe-4ea0-850f-1ddd35640e10"
}

$sevs = @{
    1 = @("step1-01-hub-redirects-to-cognito-unauth.png","step1-02-user-logged-in-hub-dashboard.png","step1-03-user-docs-loaded-via-help.png")
    2 = @("step2-01-admin-docs-loaded-no-auth.png","step2-02-support-docs-loaded-no-auth.png")
    3 = @("step3-01-unauth-hub-redirects-to-signin.png","step3-02-docs-accessible-ac_docs_auth-cookie-persists-ac05.png")
    4 = @("step4-02-cognito-signin-page-hub-unauthenticated.png","step4-04-post-signin-docs-security-accessible-PASS.png")
    5 = @("step5-01-docs-open-before-logout.png","step5-02-hub-logged-out-cognito-signin-shown.png","step5-03-docs-still-accessible-after-hub-logout-PASS.png","step5-04-internal-nav-link-accessible-after-logout-PASS.png")
    6 = @("step6-01-user-signed-in-hub-dashboard.png","step6-02-help-dropdown-visible.png","step6-03-docs-opened-via-help-icon-no-auth-prompt-PASS.png")
    7 = @("step7-01-f5-refresh-docs-still-accessible-post-logout-PASS.png")
}

$m = "mutation add(`$runId:String!, `$stepId:String!, `$ev:[AttachmentDataInput]) { addEvidenceToTestRunStep(testRunId:`$runId, stepId:`$stepId, evidence:`$ev) { addedEvidence warnings } }"

function Invoke-Gql($b) { Invoke-RestMethod -Uri $ep -Method POST -Headers $hdrs -Body $b }

for ($i = 1; $i -le 7; $i++) {
    $sid = $sids[$i]; $arr = @()
    foreach ($f in $sevs[$i]) {
        $p = Join-Path $dir $f
        if (Test-Path $p) {
            $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $p))
            $arr += @{ filename=$f; mimeType="image/png"; data=[Convert]::ToBase64String($bytes) }
        } else { Write-Warning "Missing: $f" }
    }
    if ($arr.Count -gt 0) {
        $body = @{ query=$m; variables=@{ runId=$runId; stepId=$sid; ev=$arr } } | ConvertTo-Json -Compress -Depth 6
        try {
            $r = Invoke-Gql $body
            if ($r.errors) { Write-Warning "Step $i errors: $($r.errors[0].message)" }
            else { Write-Output "Step $i : $($r.data.addEvidenceToTestRunStep.addedEvidence -join ', ') uploaded" }
        } catch { Write-Warning "Step $i : $($_.Exception.Message)" }
    }
}
Write-Output "COMPLETE"
