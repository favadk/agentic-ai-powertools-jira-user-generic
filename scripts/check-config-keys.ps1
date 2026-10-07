cd C:\Agentic-AI\agentic-ai-powertools-jira-user-generic
$cfg = Get-Content ".vscode\mcp.local.json" | ConvertFrom-Json
$jiraSrv = $cfg.servers."jira-mcp-server".env
$jiraSrv | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
Write-Output "---"
# Also show xray server keys
$xraySrv = $cfg.servers."xray-mcp-server".env
$xraySrv | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
