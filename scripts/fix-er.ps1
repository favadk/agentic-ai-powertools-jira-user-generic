$f = "C:\Agentic-AI\agentic-ai-powertools-jira-user-new\docs\EvidenceReview\ER_OLAC-7456_Cycle1.md"
$content = [System.IO.File]::ReadAllLines($f)
Write-Host ("Current lines: " + $content.Length)
$keep = $content[0..181]
[System.IO.File]::WriteAllLines($f, $keep, [System.Text.UTF8Encoding]::new($true))
Write-Host "Truncated to 182 lines."
