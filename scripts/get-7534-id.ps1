. .\scripts\xray-api.ps1
$creds    = Get-XrayCreds
$jiraBase = $creds.Url
$jHdrs    = $creds.Headers
Write-Output ('Jira base: ' + $jiraBase)
$resp      = Invoke-RestMethod -Uri ($jiraBase + '/rest/api/2/issue/OLAC-7534?fields=id') -Headers $jHdrs
$numericId = $resp.id
Write-Output ('OLAC-7534 numeric ID: ' + $numericId)
