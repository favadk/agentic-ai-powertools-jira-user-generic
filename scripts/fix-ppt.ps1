# Fix-PPT.ps1 — Removes duplicate slide entries and fixes slide 9 Teams content
$pptFile = 'c:\Agentic-AI\agentic-ai-powertools-jira-user-new\docs\Agentic-AI-QA-Framework-Presentation.pptx'
$work    = "$env:TEMP\pptx_fix"

Add-Type -AssemblyName System.IO.Compression.FileSystem

if (Test-Path $work) { Remove-Item $work -Recurse -Force }
[System.IO.Compression.ZipFile]::ExtractToDirectory($pptFile, $work)
Write-Host "Extracted. Slides: $((Get-ChildItem "$work\ppt\slides" -Filter 'slide*.xml').Count)"

# --- FIX 1: Remove duplicate sldId entries (270/rId20 and 272/rId22) ---
$presFile = "$work\ppt\presentation.xml"
$px = Get-Content $presFile -Raw

# Remove the duplicate entries
$px = $px -replace '<p:sldId id="270"[^/]*/>', ''
$px = $px -replace '<p:sldId id="272"[^/]*/>', ''
Set-Content $presFile $px -Encoding UTF8
Write-Host "Fix 1: Removed duplicate sldId 270 and 272"

# --- FIX 2: Remove duplicate rels (rId20 and rId22) ---
$relsFile = "$work\ppt\_rels\presentation.xml.rels"
$rl = Get-Content $relsFile -Raw
$rl = $rl -replace '<Relationship Id="rId20"[^/]*/>', ''
$rl = $rl -replace '<Relationship Id="rId22"[^/]*/>', ''
Set-Content $relsFile $rl -Encoding UTF8
Write-Host "Fix 2: Removed duplicate rId20 and rId22"

# --- FIX 3: Slide 9 — Replace Teams-specific content with Jira fallback reality ---
$f9 = "$work\ppt\slides\slide9.xml"
$c9 = Get-Content $f9 -Raw

# Title: keep same "Sprint TE Management"
# Bullet 2 title: "Teams Notification" -> "Jira Notification (Default)"
$c9 = $c9 -replace '>Teams Notification<', '>Jira Comment Notification (Default)<'
# Bullet 2 body: remove Teams channel references
$c9 = $c9 -replace [regex]::Escape("Posts to 'CID Scurm Team Chat' and 'AC1 Daily Stand-up' with TE key for PO/PM action."),
    'Posts a Jira comment tagging @PO and @PM with the new TE key. Teams webhook is optional (configure in automation-repository-config.md).'

# Footer: remove OLAC-specific Teams channel names
$c9 = $c9 -replace [regex]::Escape('OLAC Teams channels:  CID Scurm Team Chat   |   AC1 Daily Stand-up'),
    'Default: Jira comment  |  Optional: Teams webhook URL configured in automation-repository-config.md'

# Footer: simplify fallback line
$c9 = $c9 -replace [regex]::Escape('Bulk-add: all active sprint tests are added to the TE in a single call  |  Fallback: Jira comment @PO @PM if Teams unavailable'),
    'Bulk-add: all active sprint tests added to the TE in a single call  |  Setup wizard: configure webhook URL at project init time'

Set-Content $f9 $c9 -Encoding UTF8
Write-Host "Fix 3: Slide 9 updated — Teams -> Jira comment (default)"

# --- Repackage ---
$tmp = "$env:TEMP\pptx_fixed.pptx"
if (Test-Path $tmp) { Remove-Item $tmp -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($work, $tmp)
Copy-Item $tmp $pptFile -Force
Write-Host "PPT saved and fixed successfully"
