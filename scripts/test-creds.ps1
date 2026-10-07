. "$PSScriptRoot\test-management-api.ps1"
$c = Get-test-managementCreds
Write-Output "URL: $($c.issue-trackerUrl)"
Write-Output "User: $($c.Username)"
Write-Output "HasToken: $($c.Token.Length -gt 0)"
