$jiraUrl = 'https://jira.exampleqa.local'
$user = 'favad.khan@exampleqa.local'
$token = 'DUMMY_JIRA_TOKEN_FOR_LOCAL_TESTING_ONLY'
$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${user}:${token}"))
$body = '{"transition":{"id":"61"},"update":{},"fields":{}}'
$body = '{"transition":{"id":"61"},"fields":{"customfield_10218":"CID Hub 1.4.0 8e67828d"}}'
try {
    Invoke-RestMethod -Uri "$jiraUrl/rest/api/3/issue/STORY-7528/transitions" `
        -Method POST `
        -Headers @{Authorization="Basic $cred"; 'Content-Type'='application/json'} `
        -Body $body
    Write-Host "STORY-7528 transitioned to Test Results Review"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    Write-Host $reader.ReadToEnd()
}
