cd "C:\Agentic-AI\agentic-ai-powertools-issue-tracker-user-generic"
. ".\scripts\test-management-api.ps1"
$tok = Get-test-managementCloudToken
$ep = "https://us.test-management.cloud.gettest-management.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $tok"; "Content-Type" = "application/json" }
$body = @{
    query = "mutation upd(`$id:String!) { updateTestRunStatus(id:`$id, status:`"PASSED`") }"
    variables = @{ id = "6a5ff87b72d5b592fbee751e" }
} | ConvertTo-Json -Compress
$r = Invoke-RestMethod -Uri $ep -Method Post -Headers $hdrs -Body $body -ContentType "application/json"
if ($r.errors) { Write-Output ("ERRORS: " + ($r.errors | ConvertTo-Json)) }
else { Write-Output "Test run status set to PASSED OK" }
