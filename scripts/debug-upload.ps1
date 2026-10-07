cd "C:\Agentic-AI\agentic-ai-powertools-jira-user-generic"
. ".\scripts\xray-api.ps1"
$token = Get-XrayCloudToken
$ep = "https://us.xray.cloud.getxray.app/api/v2/graphql"
$hdrs = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes(".\docs\TestExecution\evidence\STORY-0000-FullRun\step1-01-hub-redirects-to-cognito-unauth.png"))
# First introspect to see the correct field names
$iq = '{"query":"{__type(name:\"AttachmentDataInput\"){name inputFields{name type{name kind ofType{name kind}}}}}"}'
$ir = Invoke-RestMethod -Uri $ep -Method Post -Headers $hdrs -Body $iq -ContentType "application/json"
Write-Host "AttachmentDataInput fields: $($ir | ConvertTo-Json -Depth 10)"

$q = 'mutation AddEv($testRunId:String!,$stepId:String!,$evidence:[AttachmentDataInput!]!){addEvidenceToTestRunStep(testRunId:$testRunId,stepId:$stepId,evidence:$evidence){addedEvidence{id filename}warnings}}'
$body = @{query=$q;variables=@{testRunId="6a5ff87b72d5b592fbee751e";stepId="1d664a4c-f24b-41fd-9b21-7afadb81787b";evidence=@(@{filename="s1.png";mimeType="image/png";data=$b64})}} | ConvertTo-Json -Depth 20
try {
    $r = Invoke-WebRequest -Uri $ep -Method Post -Headers $hdrs -Body $body -ContentType "application/json"
    Write-Host "OK: $($r.Content.Substring(0,300))"
} catch {
    Write-Host "FAIL: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $s = $_.Exception.Response.GetResponseStream()
        $rd = [System.IO.StreamReader]::new($s)
        Write-Host "BODY: $($rd.ReadToEnd())"
    }
}
