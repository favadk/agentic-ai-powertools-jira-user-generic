. .\scripts\xray-api.ps1
$creds    = Get-XrayCreds
$jiraBase = $creds.Url
$jHdrs    = $creds.Headers
Write-Output ('Jira base: ' + $jiraBase)
$resp      = Invoke-RestMethod -Uri ($jiraBase + '/rest/api/2/issue/STORY-7534?fields=id') -Headers $jHdrs
$numericId = $resp.id
Write-Output ('STORY-7534 numeric ID: ' + $numericId)
