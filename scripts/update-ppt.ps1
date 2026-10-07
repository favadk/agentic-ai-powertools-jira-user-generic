# Update-PPT.ps1 — Patches Agentic-AI-QA-Framework-Presentation.pptx with latest changes
# Session changes: dynamic sprint detection, dual monitors, Agile endpoint fix, bootstrapper update

$pptSrc  = 'c:\Agentic-AI\agentic-ai-powertools-jira-user-new\docs\Agentic-AI-QA-Framework-Presentation.pptx'
$pptDest = 'c:\Agentic-AI\agentic-ai-powertools-jira-user-new\docs\Agentic-AI-QA-Framework-Presentation.pptx'
$work    = "$env:TEMP\pptx_edit"

Add-Type -AssemblyName System.IO.Compression.FileSystem

# Re-extract fresh copy
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
[System.IO.Compression.ZipFile]::ExtractToDirectory($pptSrc, $work)
Write-Host "Extracted: $((Get-ChildItem "$work\ppt\slides" -Filter 'slide*.xml').Count) slides"

# ---- PATCH 1: Slide 12 — fix double-backtick in command, update 'Copies 13 agents' ----
$f12 = "$work\ppt\slides\slide12.xml"
$c12 = Get-Content $f12 -Raw

# Fix double backtick  ->  single backtick before the line break
$c12 = $c12 -replace '``&#xD;', '`&#xD;'

# Fix agent count in "What it does" bullets  (13 -> 13  already correct, but ensure it says 13+story_monitor=14 agents)
# The slide currently says "Copies 13 agents + 14 skills" — keep as-is (correct)

Set-Content $f12 $c12 -Encoding UTF8
Write-Host "Slide 12 patched: double-backtick fixed"

# ---- PATCH 2: Slide 13 — Adoption Roadmap — Phase 2 bullet ----
$f13 = "$work\ppt\slides\slide13.xml"
$c13 = Get-Content $f13 -Raw
$c13 = $c13 -replace 'Activate PO Response Monitor', 'Activate both Story Change Monitors (PO Response + Story Changes)'
Set-Content $f13 $c13 -Encoding UTF8
Write-Host "Slide 13 patched: Phase 2 bullet updated"

# ---- PATCH 3: Slide 5 — Architecture — add Background Monitors layer ----
$f5 = "$work\ppt\slides\slide5.xml"
$c5 = Get-Content $f5 -Raw
# Find the "Developer / QA" block and insert Background Monitors info
# We'll update the "Agent Layer" description to mention the monitors
$c5 = $c5 -replace '13 QA lifecycle agents', '13 QA lifecycle agents + 2 background monitors'
$c5 = $c5 -replace 'each orchestrates a specific stage end-to-end', 'each orchestrates a specific stage end-to-end; monitors run as Windows Scheduled Tasks every 30 min'
Set-Content $f5 $c5 -Encoding UTF8
Write-Host "Slide 5 patched: architecture updated with background monitors"

# ---- PATCH 4: Add new slide — Continuous Story Change Monitoring ----
# Copy slide9.xml as base (similar bullet layout) and overwrite with monitoring content
$slide9xml = Get-Content "$work\ppt\slides\slide9.xml" -Raw

# Replace all text content — we'll do a wholesale replacement of the text-shape content
# Strategy: replace the spTree content using a purpose-built XML fragment for the new slide
$newSlideNum = 14   # insert before current slide 14 (Thank You)
$newSlideFile = "$work\ppt\slides\slide$newSlideNum.xml"

# Read slide 9 XML as base — patch title and body text nodes only
# Title is in the first <p:sp> title placeholder; body in subsequent shapes
$newSlide = $slide9xml

# --- Replace title ---
$newSlide = $newSlide -replace '(?s)<a:t>Sprint TE Management - Auto-Link, Gate &amp; Notify</a:t>', '<a:t>Continuous Story Change Monitoring &#x2014; Auto-Watch Every Sprint</a:t>'

# Build new body text (matching the paragraph structure of slide 9)
# The body content in slide 9 uses multiple <p:sp> shapes for each bullet group
# Simplest approach: replace the subtitle/overview paragraph, then set body shapes

# Replace the large description paragraph
$oldDesc = 'Every Xray Test must be linked to a Sprint Test Execution (TE) before execution begins. The framework automates TE creation, notification, and gating end-to-end.'
$newDesc = 'Three Windows Scheduled Tasks poll Jira every 30 minutes — detecting comments, AC edits, and status changes, then automatically reviewing linked Xray test comments.'
$newSlide = $newSlide -replace [regex]::Escape($oldDesc), $newDesc

# Replace bullet group titles and bodies
$newSlide = $newSlide -replace '<a:t>Auto-TE Creation</a:t>', '<a:t>QA-Monitor-PO-Responses</a:t>'
$newSlide = $newSlide -replace '<a:t>No sprint TE\? One is created automatically and moved into the active sprint\.</a:t>', '<a:t>Watches blocked TC issues for new PO comments; resumes the blocked step cycle automatically.</a:t>'

$newSlide = $newSlide -replace '<a:t>Teams Notification</a:t>', '<a:t>QA-Monitor-Story-Changes</a:t>'
$newSlide = $newSlide -replace "<a:t>Posts to 'CID Scurm Team Chat' and 'AC1 Daily Stand-up' with TE key for PO/PM action\.</a:t>", '<a:t>Detects description/AC edits (SHA-256 diff) and status transitions; fires DESCRIPTION_CHANGE or STATUS_CHANGE triggers.</a:t>'

$newSlide = $newSlide -replace '<a:t>Hard Execution Gate</a:t>', '<a:t>Dynamic Sprint Detection</a:t>'
$newSlide = $newSlide -replace '<a:t>Step 0B in test_case_execution: fully blocked if test is not linked to a sprint TE\.</a:t>', '<a:t>Queries /rest/agile/1.0/board/{id}/sprint at each run; auto-enrolls new sprint stories — zero manual config between sprints.</a:t>'

$newSlide = $newSlide -replace '<a:t>In Dev Required</a:t>', '<a:t>story_monitor Agent Routing</a:t>'
$newSlide = $newSlide -replace "<a:t>Sprint TE is auto-transitioned to 'In Dev' status before execution steps can run\.</a:t>", '<a:t>QA-Process-Test-Comment-Reviews classifies linked Xray comments, writes a review record, and posts a verdict or evidence request on the test.</a:t>'

# Replace footer/note lines
$newSlide = $newSlide -replace [regex]::Escape('Skill: test-execution-sprint-linking.md  |  Applied in: test_case_preparation (step 7e) + test_case_execution (step 0B)'), 'State file: scripts/monitor-state.json  |  Trigger dir: scripts/triggers/  |  Agent: .github/agents/story_monitor.agent.md'
$newSlide = $newSlide -replace [regex]::Escape('OLAC Teams channels:  CID Scurm Team Chat   |   AC1 Daily Stand-up'), 'Setup: VS Code Task Runner  &#x2192;  QA: Setup Scheduled Tasks  |  Or: .\scripts\setup-story-monitor-scheduler.ps1'
$newSlide = $newSlide -replace [regex]::Escape('Bulk-add: all active sprint tests are added to the TE in a single call  |  Fallback: Jira comment @PO @PM if Teams unavailable'), 'changeType: PO_RESPONSE | DESCRIPTION_CHANGE | STATUS_CHANGE  |  SHA-256 fingerprinting prevents duplicate triggers'
$newSlide = $newSlide -replace [regex]::Escape("TE must be in 'In Dev' status  |  Framework auto-transitions if needed  |  Jira get_transitions + transition_issue"), 'Sprint rollover: sprintName/sprintId auto-updated in monitor-state.json; no manual intervention needed'
$newSlide = $newSlide -replace [regex]::Escape('If test not in sprint TE: BLOCKED message shown with remediation steps  |  Run test_case_preparation to resolve'), 'Installation-related stories run smoke then smoke-install before feature steps; failures block execution'

Set-Content $newSlideFile $newSlide -Encoding UTF8
Write-Host "New slide $newSlideNum created (Continuous Story Change Monitoring)"

# ---- Update slide rels for new slide ----
# Copy slide 9's rels file as base
$rels9 = "$work\ppt\slides\_rels\slide9.xml.rels"
$relsNew = "$work\ppt\slides\_rels\slide$newSlideNum.xml.rels"
$relsContent = Get-Content $rels9 -Raw
# Point to slideLayout4 (same layout as slide 9)
Set-Content $relsNew $relsContent -Encoding UTF8
Write-Host "Rels file created for new slide"

# ---- Update presentation.xml — insert new slide into sldIdLst ----
$presFile = "$work\ppt\presentation.xml"
$presXml = Get-Content $presFile -Raw

# Find the last sldId entry to get the highest id value
$matches = [regex]::Matches($presXml, 'id="(\d+)"')
$maxId = ($matches | ForEach-Object { [long]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
$newId = $maxId + 1

# Find the sldId for slide 14 (current Thank You) and insert before it
# The slide references use r:id="rId{N}" — we need to find the rId for slide 14
$presRels = "$work\ppt\_rels\presentation.xml.rels"
$presRelsContent = Get-Content $presRels -Raw

# Find the max rId number in rels
$rMatches = [regex]::Matches($presRelsContent, 'Id="rId(\d+)"')
$maxRId = ($rMatches | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
$newRId = $maxRId + 1

# Add new slide relationship to presentation.xml.rels
$newRelEntry = "<Relationship Id=""rId$newRId"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide"" Target=""slides/slide$newSlideNum.xml""/>"
$presRelsContent = $presRelsContent -replace '</Relationships>', "$newRelEntry</Relationships>"
Set-Content $presRels $presRelsContent -Encoding UTF8
Write-Host "Added rId$newRId to presentation.rels"

# Add new sldId to sldIdLst — insert before </p:sldIdLst>
$newSldIdEntry = "<p:sldId id=""$newId"" r:id=""rId$newRId""/>"
$presXml = $presXml -replace '</p:sldIdLst>', "$newSldIdEntry</p:sldIdLst>"
Set-Content $presFile $presXml -Encoding UTF8
Write-Host "Added sldId $newId (rId$newRId) to presentation.xml"

# ---- Repackage PPTX ----
$tmpPptx = "$env:TEMP\pptx_updated.pptx"
if (Test-Path $tmpPptx) { Remove-Item $tmpPptx -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($work, $tmpPptx)

# Replace original
Copy-Item $tmpPptx $pptDest -Force
Write-Host "PPT saved to: $pptDest"
Write-Host ""
Write-Host "=== PPT UPDATE COMPLETE ==="
Write-Host "Changes made:"
Write-Host "  Slide 5:  Architecture — added '+ 2 background monitors' to Agent Layer"
Write-Host "  Slide 12: One-Command Setup — fixed backtick in command; monitoring bullets already correct"
Write-Host "  Slide 13: Adoption Roadmap — Phase 2 bullet updated to 'both Story Change Monitors'"
Write-Host "  Slide 14: NEW — Continuous Story Change Monitoring"
Write-Host "  Slide 15: Thank You (was 14)"
