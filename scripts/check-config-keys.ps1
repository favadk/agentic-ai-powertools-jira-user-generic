cd C:\Agentic-AI\agentic-ai-powertools-issue-tracker-user-generic
$cfg = Get-Content ".vscode\mcp.local.json" | ConvertFrom-Json
$issue-trackerSrv = $cfg.servers."issue-tracker-mcp-server".env
$issue-trackerSrv | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
Write-Output "---"
# Also show test-management server keys
$test-managementSrv = $cfg.servers."test-management-mcp-server".env
$test-managementSrv | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
