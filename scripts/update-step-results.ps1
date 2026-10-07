cd "C:\Agentic-AI\agentic-ai-powertools-jira-user-generic"
. ".\scripts\xray-api.ps1"
$tok = Get-XrayCloudToken
$ep = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }
function Invoke-Gql($b) { Invoke-RestMethod -Uri $ep -Method POST -Headers $hdrs -Body $b }

$runId = "6a5ff87b72d5b592fbee751e"
$stepResults = @{
    "1d664a4c-f24b-41fd-9b21-7afadb81787b" = @{ status="PASSED"; result="PASS: User role authenticated via Cognito and accessed docs via Help icon. Hub redirects unauthenticated users to Cognito sign-in. Docs loaded via Help with no additional auth prompt." }
    "9aac8aa4-0f12-433d-b131-1f44efbffeaa" = @{ status="PASSED"; result="PASS: Admin and Support roles both authenticated and accessed docs without additional auth prompt. AC-01a verified across all three roles." }
    "d6e35aa0-1a0f-4cec-8034-5ae689379c95" = @{ status="PASSED"; result="PASS: Hub blocks unauthenticated access and redirects to Cognito (AC-02). Note: ac_docs_auth cookie persists after hub logout — this is expected per AC-05 (no auto-expiry on hub logout)." }
    "2cb9dfec-5f85-4d8c-aaa7-fb885b7a7c78" = @{ status="PASSED"; result="PASS (STORY-0000 fix verified): Cognito sign-in page shown when hub session expired. After sign-in, docs/security page loads successfully. AC-03 returnUrl behaviour working post-fix." }
    "87b04cd4-995a-4d74-b116-7cc45c4393f9" = @{ status="PASSED"; result="PASS: Docs remained accessible after hub logout (no refresh, then internal nav link). ac_docs_auth cookie persists independently of hub Cognito session. AC-05 confirmed." }
    "bd67bfa7-0f5e-4f57-b817-e464659ace4c" = @{ status="PASSED"; result="PASS: Help (?) icon opens docs in new tab with no additional auth prompt for User role (TC-13 regression). Dropdown visible and docs tab opened successfully." }
    "0238d135-84fe-4ea0-850f-1ddd35640e10" = @{ status="PASSED"; result="PASS: F5 refresh of docs/security page after hub logout — page remained accessible. ac_docs_auth cookie still valid, docs served without re-auth." }
}

foreach ($stepId in $stepResults.Keys) {
    $sr = $stepResults[$stepId]
    $ar = $sr.result -replace '"', '\"'
    $body = @{
        query = "mutation upd(`$r:String!, `$s:String!, `$ar:String!) { updateTestRunStep(testRunId:`$r, stepId:`$s, updateData: { status: `"PASSED`", actualResult:`$ar }) { warnings } }"
        variables = @{ r=$runId; s=$stepId; ar=$sr.result }
    } | ConvertTo-Json -Compress -Depth 5
    $r = Invoke-Gql $body
    if ($r.errors) { Write-Output "ERROR $stepId : $($r.errors[0].message)" }
    else { Write-Output "Updated step $stepId PASSED. Warnings: $($r.data.updateTestRunStep.warnings)" }
}

Write-Output "Step results updated."
