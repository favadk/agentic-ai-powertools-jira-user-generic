. "$PSScriptRoot\xray-api.ps1"
$c = Get-XrayCreds
Write-Output "URL: $($c.JiraUrl)"
Write-Output "User: $($c.Username)"
Write-Output "HasToken: $($c.Token.Length -gt 0)"
