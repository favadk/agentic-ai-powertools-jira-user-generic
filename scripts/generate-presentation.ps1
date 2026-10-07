# Generate VP/Director presentation for the Agentic AI QA Framework
# Requires: Microsoft PowerPoint (COM automation)

param(
    [string]$OutputPath = "$PSScriptRoot\..\docs\Agentic-AI-QA-Framework-Presentation.pptx"
)

$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

Write-Host "Creating presentation: $OutputPath"

# -- COM setup -------------------------------------------------------------
$ppt  = New-Object -ComObject PowerPoint.Application
$ppt.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue
$pres = $ppt.Presentations.Add([Microsoft.Office.Core.MsoTriState]::msoTrue)

# -- Theme colors (RGB helpers) --------------------------------------------
function Rgb([int]$r,[int]$g,[int]$b){ $b*65536 + $g*256 + $r }   # BGR for COM
$NAVY    = Rgb 0   51  102    # #003366
$BLUE    = Rgb 0   112 192    # #0070C0
$LTBLUE  = Rgb 189 215 238    # #BDD7EE
$WHITE   = Rgb 255 255 255    # #FFFFFF
$DARK    = Rgb 31  56  100    # #1F3864
$ORANGE  = Rgb 255 102 0      # #FF6600
$GREEN   = Rgb 0   176 80     # #00B050
$LGRAY   = Rgb 242 242 242    # #F2F2F2
$DGRAY   = Rgb 89  89  89     # #595959

# -- Slide layout constants -------------------------------------------------
$ppLayoutTitle    = 1
$ppLayoutText     = 2
$ppLayoutBlank    = 12

# Width / height helpers (EMUs: 1 inch = 914400)
$SW = $pres.PageSetup.SlideWidth    # ~720 pt
$SH = $pres.PageSetup.SlideHeight   # ~540 pt

# -- Helper functions ------------------------------------------------------
function Add-Slide([int]$layout){
    $idx = $pres.Slides.Count + 1
    $s   = $pres.Slides.Add($idx, $layout)
    return $s
}

function Set-BG([object]$slide,[int]$color){
    $slide.Background.Fill.ForeColor.RGB = $color
    $slide.Background.Fill.Solid()
}

function Add-TextBox([object]$slide,[string]$text,[float]$l,[float]$t,[float]$w,[float]$h,
                     [int]$fontSize=18,[bool]$bold=$false,[int]$color=0,[int]$align=1){
    $tb = $slide.Shapes.AddTextbox(1,$l,$t,$w,$h)
    $tf = $tb.TextFrame
    $tf.WordWrap = [Microsoft.Office.Core.MsoTriState]::msoTrue
    $tf.AutoSize = 1   # ppAutoSizeShapeToFitText
    $tr = $tf.TextRange
    $tr.Text = $text
    $tr.Font.Size  = $fontSize
    $tr.Font.Bold  = if($bold){[Microsoft.Office.Core.MsoTriState]::msoTrue}else{[Microsoft.Office.Core.MsoTriState]::msoFalse}
    $tr.Font.Color.RGB = $color
    $tr.ParagraphFormat.Alignment = $align   # 1=left 2=center 3=right
    return $tb
}

function Add-Rect([object]$slide,[int]$color,[float]$l,[float]$t,[float]$w,[float]$h){
    $r = $slide.Shapes.AddShape(1,$l,$t,$w,$h)   # msoShapeRectangle=1
    $r.Fill.ForeColor.RGB = $color
    $r.Fill.Solid()
    $r.Line.Visible = [Microsoft.Office.Core.MsoTriState]::msoFalse
    return $r
}

function Add-HeaderBar([object]$slide,[string]$title,[int]$bg=$NAVY,[int]$fg=$WHITE){
    Add-Rect $slide $bg 0 0 $SW 72 | Out-Null
    Add-TextBox $slide $title 20 12 ($SW-40) 50 28 $true $fg 2 | Out-Null
}

function Add-SlideNum([object]$slide,[int]$num,[int]$total){
    Add-TextBox $slide "$num / $total" ($SW-80) ($SH-30) 70 24 12 $false $DGRAY 3 | Out-Null
}

# -------------------------------------------------------------------------
# SLIDE 1 � Title
# -------------------------------------------------------------------------
$s1 = Add-Slide $ppLayoutBlank
Set-BG $s1 $NAVY

# Decorative bar
Add-Rect $s1 $BLUE 0 ($SH-100) $SW 100 | Out-Null

# Title
$tTitle = Add-TextBox $s1 "Agentic AI QA Framework" 40 100 ($SW-80) 100 44 $true $WHITE 2
# Subtitle
Add-TextBox $s1 "Automating the Full QA Lifecycle with GitHub Copilot" 40 210 ($SW-80) 60 22 $false $LTBLUE 2 | Out-Null
# Tag line
Add-TextBox $s1 "Jira  |  Xray  |  Bitbucket  |  GitHub Copilot" 40 280 ($SW-80) 40 16 $false $LTBLUE 2 | Out-Null
# Footer
Add-TextBox $s1 "Engineering Productivity � Technology Strategy" 40 ($SH-85) ($SW-80) 30 14 $false $WHITE 2 | Out-Null

Write-Host "  Slide 1 done"

# -------------------------------------------------------------------------
# SLIDE 2 � Agenda
# -------------------------------------------------------------------------
$s2 = Add-Slide $ppLayoutBlank
Set-BG $s2 $WHITE
Add-HeaderBar $s2 "Agenda"
Add-SlideNum $s2 2 14

$agenda = @(
    "1.  The Problem � QA bottlenecks in Agile sprints",
    "2.  The Solution � Agentic AI QA Framework",
    "3.  Architecture Overview",
    "4.  8-Stage QA Lifecycle",
    "5.  Team Auto-Discovery",
    "6.  Before vs After � Time & Effort Savings",
    "7.  Business Impact & ROI",
    "8.  One-Command Setup",
    "9.  Adoption Roadmap",
    "10. Environment Compatibility Matrix",
    "11. Q & A"
)

Add-TextBox $s2 ($agenda -join "`n") 60 90 ($SW-120) 400 18 $false $DARK 1 | Out-Null

Write-Host "  Slide 2 done"

# -------------------------------------------------------------------------
# SLIDE 3 � The Problem
# -------------------------------------------------------------------------
$s3 = Add-Slide $ppLayoutBlank
Set-BG $s3 $WHITE
Add-HeaderBar $s3 "The Problem � QA Bottlenecks in Agile Sprints" $NAVY $WHITE
Add-SlideNum $s3 3 14

$problems = @(
    [PSCustomObject]@{Icon="?"; Title="Slow test case creation"; Desc="2�4 hours per story, manually written and uploaded to Xray"},
    [PSCustomObject]@{Icon="??"; Title="Context switching"; Desc="Jira ? Xray ? Bitbucket ? VS Code � each switch costs time and introduces errors"},
    [PSCustomObject]@{Icon="??"; Title="Inconsistent quality"; Desc="Test cases vary in depth and structure across team members and sprints"},
    [PSCustomObject]@{Icon="??"; Title="No BLOCKED AC tracking"; Desc="When PO clarification is needed, no automated mechanism tracks the reply or resumes work"},
    [PSCustomObject]@{Icon="??"; Title="Zero portability"; Desc="QA tooling configured for one project cannot be reused on another without significant rework"},
    [PSCustomObject]@{Icon="?"; Title="Automation gap"; Desc="Test case documentation and automation code are disconnected; manual bridging required"}
)

$y = 90
foreach ($p in $problems) {
    Add-Rect $s3 $LTBLUE 40 $y 20 20 | Out-Null
    Add-TextBox $s3 "$($p.Icon)  $($p.Title)" 68 ($y-2) 300 24 13 $true $NAVY 1 | Out-Null
    Add-TextBox $s3 $p.Desc 68 ($y+18) 580 22 11 $false $DGRAY 1 | Out-Null
    $y += 62
}

Write-Host "  Slide 3 done"

# -------------------------------------------------------------------------
# SLIDE 4 � The Solution
# -------------------------------------------------------------------------
$s4 = Add-Slide $ppLayoutBlank
Set-BG $s4 $WHITE
Add-HeaderBar $s4 "The Solution � Agentic AI QA Framework"
Add-SlideNum $s4 4 14

Add-TextBox $s4 "A suite of 13 GitHub Copilot agents that automate every stage of the QA lifecycle � from test case creation through automation publishing � for any Jira/Xray/Bitbucket project." 40 85 ($SW-80) 50 15 $false $DARK 1 | Out-Null

$cols = @(
    [PSCustomObject]@{Title="Agent-Driven"; Items=@("13 specialist agents","Natural language interface","No code changes needed","Works inside VS Code")},
    [PSCustomObject]@{Title="Fully Integrated"; Items=@("Jira REST API v3","Xray Cloud API","Bitbucket Server","Confluence")},
    [PSCustomObject]@{Title="Zero-Friction Setup"; Items=@("Single PowerShell command","Auto-generates config","Project-agnostic framework","Team-shareable via Git")}
)

$x = 30
foreach ($col in $cols) {
    Add-Rect $s4 $NAVY $x 145 200 30 | Out-Null
    Add-TextBox $s4 $col.Title ($x+5) 148 190 26 14 $true $WHITE 2 | Out-Null
    $itemText = ($col.Items | ForEach-Object { "?  $_" }) -join "`n"
    Add-TextBox $s4 $itemText ($x+5) 180 190 180 12 $false $DARK 1 | Out-Null
    $x += 215
}

# Bottom call-out
Add-Rect $s4 $LTBLUE 30 390 ($SW-60) 110 | Out-Null
Add-TextBox $s4 "Key Differentiator" 50 395 200 24 13 $true $NAVY 1 | Out-Null
Add-TextBox $s4 "The framework is self-bootstrapping: one command sets it up for any new project in minutes, copying all agents, skills, and config templates automatically." 50 415 ($SW-100) 80 13 $false $DARK 1 | Out-Null

Write-Host "  Slide 4 done"

# -------------------------------------------------------------------------
# SLIDE 5 � Architecture Overview
# -------------------------------------------------------------------------
$s5 = Add-Slide $ppLayoutBlank
Set-BG $s5 $WHITE
Add-HeaderBar $s5 "Architecture Overview"
Add-SlideNum $s5 5 14

# Layers (bottom-up)
$layers = @(
    [PSCustomObject]@{Label="External APIs";     Detail="Jira Cloud  |  Xray Cloud  |  Bitbucket Server  |  Confluence";   Color=$LGRAY; FColor=$DGRAY},
    [PSCustomObject]@{Label="MCP Server Layer";  Detail="Jira MCP  |  Xray MCP  |  Bitbucket MCP  |  Confluence MCP";     Color=$LTBLUE; FColor=$NAVY},
    [PSCustomObject]@{Label="Skill Library";     Detail="13 shared skills: team discovery, Xray patterns, automation config, env compatibility, naming conventions"; Color=$BLUE; FColor=$WHITE},
    [PSCustomObject]@{Label="Agent Layer";        Detail="13 QA lifecycle agents � each orchestrates a specific stage end-to-end";              Color=$NAVY; FColor=$WHITE},
    [PSCustomObject]@{Label="Developer / QA";    Detail="GitHub Copilot Chat inside VS Code � natural language commands";                        Color=$DARK; FColor=$WHITE}
)

$y = 95
foreach ($layer in $layers) {
    Add-Rect $s5 $layer.Color 30 $y ($SW-60) 62 | Out-Null
    Add-TextBox $s5 $layer.Label 40 ($y+6) 180 22 13 $true $layer.FColor 1 | Out-Null
    Add-TextBox $s5 $layer.Detail 230 ($y+8) ($SW-260) 46 11 $false $layer.FColor 1 | Out-Null
    $y += 70
}

Write-Host "  Slide 5 done"

# -------------------------------------------------------------------------
# SLIDE 6 � 8-Stage QA Lifecycle
# -------------------------------------------------------------------------
$s6 = Add-Slide $ppLayoutBlank
Set-BG $s6 $WHITE
Add-HeaderBar $s6 "8-Stage QA Lifecycle � Fully Automated"
Add-SlideNum $s6 6 14

$stages = @(
    [PSCustomObject]@{N="0"; Label="Sprint QA Plan";         Agent="sprint_story_qa_plan";          Output="QAP_{KEY}.md"},
    [PSCustomObject]@{N="1"; Label="Test Case Preparation";  Agent="test_case_preparation";         Output="TC_{KEY}.md + Xray Test"},
    [PSCustomObject]@{N="2"; Label="Test Case Review";       Agent="test_case_review";              Output="TCR_{KEY}.md"},
    [PSCustomObject]@{N="3"; Label="Test Execution";         Agent="test_case_execution";           Output="TE_{KEY}.md + Xray results"},
    [PSCustomObject]@{N="4"; Label="Evidence Review";        Agent="test_case_evidence_review";     Output="ER_{KEY}.md"},
    [PSCustomObject]@{N="5"; Label="Automation Code";        Agent="automation_code_preparation";   Output="AUT_{KEY}.md + Bitbucket PR"},
    [PSCustomObject]@{N="6"; Label="Automation Review";      Agent="automation_code_review";        Output="AUTR_{KEY}.md"},
    [PSCustomObject]@{N="7"; Label="Run & Publish";          Agent="automation_run_publish";        Output="AUTRPT_{KEY}.md + Jira defects"}
)

$y = 88; $x = 28
foreach ($stg in $stages) {
    $isAuto = [int]$stg.N -ge 5
    $bgColor = if($isAuto){ $ORANGE }else{ $NAVY }
    Add-Rect $s6 $bgColor $x $y 32 32 | Out-Null
    Add-TextBox $s6 $stg.N ($x+2) ($y+6) 28 22 14 $true $WHITE 2 | Out-Null
    Add-TextBox $s6 $stg.Label ($x+38) $y 200 18 11 $true $DARK 1 | Out-Null
    Add-TextBox $s6 $stg.Agent ($x+38) ($y+18) 200 16 9 $false $DGRAY 1 | Out-Null
    Add-TextBox $s6 $stg.Output ($x+38) ($y+34) 200 16 9 $false $BLUE 1 | Out-Null
    $y += 54
}

Add-Rect $s6 $ORANGE ($SW-170) 310 140 22 | Out-Null
Add-TextBox $s6 "  Automation stages (5-7)" ($SW-170) 310 140 22 10 $false $WHITE 1 | Out-Null

Write-Host "  Slide 6 done"

# -------------------------------------------------------------------------
# SLIDE 7 � Team Auto-Discovery
# -------------------------------------------------------------------------
$s7 = Add-Slide $ppLayoutBlank
Set-BG $s7 $WHITE
Add-HeaderBar $s7 "Team Auto-Discovery � Zero Manual Configuration"
Add-SlideNum $s7 7 14

Add-TextBox $s7 "Every agent automatically identifies the 5-person team for any story � no user input required." 40 85 ($SW-80) 30 14 $false $DARK 1 | Out-Null

$roles = @(
    [PSCustomObject]@{Role="Product Owner (PO)"; Source="Jira story fields.reporter"},
    [PSCustomObject]@{Role="Developer";           Source="Sub-task with: implementation / development / backend / frontend keywords"},
    [PSCustomObject]@{Role="Tester";              Source="Sub-task with: testing / qa / test case creation / verification keywords"},
    [PSCustomObject]@{Role="TC Reviewer";         Source="Sub-task with: test case review / tc review keywords (not execution)"},
    [PSCustomObject]@{Role="Evidence Reviewer";   Source="Sub-task with: execution review / evidence review keywords"}
)

$y = 125
foreach ($r in $roles) {
    Add-Rect $s7 $BLUE 30 $y 14 14 | Out-Null
    Add-TextBox $s7 $r.Role 55 ($y-2) 180 20 13 $true $NAVY 1 | Out-Null
    Add-TextBox $s7 $r.Source 240 ($y-2) 400 20 12 $false $DGRAY 1 | Out-Null
    $y += 44
}

Add-Rect $s7 $LTBLUE 30 365 ($SW-60) 80 | Out-Null
Add-TextBox $s7 "Conflict detection built-in" 50 368 250 20 12 $true $NAVY 1 | Out-Null
Add-TextBox $s7 "If PO == Dev (same person), the agent detects the conflict and automatically falls back to the story assignee for the Dev role � no errors, no manual override needed." 50 385 ($SW-90) 55 11 $false $DARK 1 | Out-Null

Write-Host "  Slide 7 done"

# ─────────────────────────────────────────────────────────────────────────
# SLIDE 8 - Environment Compatibility Matrix
# ─────────────────────────────────────────────────────────────────────────
$s8 = Add-Slide $ppLayoutBlank
Set-BG $s8 $WHITE
Add-HeaderBar $s8 "Environment Compatibility - Built-in Cross-Platform Coverage"
Add-SlideNum $s8 8 14

Add-TextBox $s8 "A new skill auto-detects required browsers, OS, databases, and devices from story AC keywords, then drives structured coverage and separate Xray executions per environment." 40 85 ($SW-80) 45 13 $false $DARK 1 | Out-Null

$eCols = @(
    [PSCustomObject]@{Title="Auto-Detection"; Items=@("Scans story AC and labels","Detects Browser / OS / DB / Device","Feature-area tier matching","Zero manual input needed")},
    [PSCustomObject]@{Title="Coverage Tiers"; Items=@("P1 Full matrix - auth/security","P2 Primary + secondary (default)","P3 Smoke only - backend/admin","Set once per project")},
    [PSCustomObject]@{Title="Agent Outputs"; Items=@("Env Coverage table in TC doc","Separate Xray exec per env","Env-visible screenshot proof","Env-labelled defect reports")}
)
$x = 30
foreach ($ec in $eCols) {
    Add-Rect $s8 $BLUE $x 140 200 30 | Out-Null
    Add-TextBox $s8 $ec.Title ($x+5) 143 190 26 13 $true $WHITE 2 | Out-Null
    $eItems = ($ec.Items | ForEach-Object { "[+] $_" }) -join "`n"
    Add-TextBox $s8 $eItems ($x+5) 178 190 180 11 $false $DARK 1 | Out-Null
    $x += 215
}
Add-Rect $s8 $LTBLUE 30 378 ($SW-60) 122 | Out-Null
Add-TextBox $s8 "EnvironmentMatrixTemplate.md - configure once per project, read by all agents" 50 383 ($SW-90) 20 12 $true $NAVY 1 | Out-Null
Add-TextBox $s8 "Supported:  Chrome / Firefox / Edge / Safari    |    Windows 11 / Win10 / macOS    |    SQL Server 2022/2019" 50 406 ($SW-90) 18 10 $false $DARK 1 | Out-Null
Add-TextBox $s8 "Feature overrides:  Auth = P1 full matrix   |   UI Forms = P2   |   Background services = P3 smoke" 50 428 ($SW-90) 18 10 $false $DGRAY 1 | Out-Null
Add-TextBox $s8 "Bootstrapper copies the matrix template automatically - teams fill it in once. Zero ongoing maintenance." 50 450 ($SW-90) 18 10 $false $DARK 1 | Out-Null

Write-Host "  Slide 8 done"
# ─────────────────────────────────────────────────────────────────────────
# SLIDE 9 -- Sprint TE Management
# ─────────────────────────────────────────────────────────────────────────
$s9 = Add-Slide $ppLayoutBlank
Set-BG $s9 $WHITE
Add-HeaderBar $s9 "Sprint TE Management - Auto-Link, Gate & Notify"
Add-SlideNum $s9 9 14

Add-TextBox $s9 "Every Xray Test must be linked to a Sprint Test Execution (TE) before execution begins. The framework automates TE creation, notification, and gating end-to-end." 40 85 ($SW-80) 42 13 $false $DARK 1 | Out-Null

$teFeatures = @(
    [PSCustomObject]@{Title="Auto-TE Creation";    Desc="No sprint TE? One is created automatically and moved into the active sprint.";                     Color=$NAVY},
    [PSCustomObject]@{Title="Teams Notification";  Desc="Posts to 'CID Scurm Team Chat' and 'AC1 Daily Stand-up' with TE key for PO/PM action.";           Color=$BLUE},
    [PSCustomObject]@{Title="Hard Execution Gate"; Desc="Step 0B in test_case_execution: fully blocked if test is not linked to a sprint TE.";              Color=$GREEN},
    [PSCustomObject]@{Title="In Dev Required";     Desc="Sprint TE is auto-transitioned to 'In Dev' status before execution steps can run.";               Color=$NAVY}
)

$x = 25
foreach ($f in $teFeatures) {
    Add-Rect $s9 $f.Color $x 138 155 36 | Out-Null
    Add-TextBox $s9 $f.Title ($x+5) 141 145 30 12 $true $WHITE 1 | Out-Null
    Add-TextBox $s9 $f.Desc ($x+5) 182 145 110 10 $false $DARK 1 | Out-Null
    $x += 168
}

Add-Rect $s9 $LTBLUE 30 372 ($SW-60) 128 | Out-Null
Add-TextBox $s9 "Skill: test-execution-sprint-linking.md  |  Applied in: test_case_preparation (step 7e) + test_case_execution (step 0B)" 50 378 ($SW-90) 26 11 $false $NAVY 1 | Out-Null
Add-TextBox $s9 "OLAC Teams channels:  CID Scurm Team Chat   |   AC1 Daily Stand-up" 50 408 ($SW-90) 20 11 $true $DARK 1 | Out-Null
Add-TextBox $s9 "Bulk-add: all active sprint tests are added to the TE in a single call  |  Fallback: Jira comment @PO @PM if Teams unavailable" 50 432 ($SW-90) 20 11 $false $DGRAY 1 | Out-Null
Add-TextBox $s9 "TE must be in 'In Dev' status  |  Framework auto-transitions if needed  |  Jira get_transitions + transition_issue" 50 456 ($SW-90) 20 11 $false $DGRAY 1 | Out-Null
Add-TextBox $s9 "If test not in sprint TE: BLOCKED message shown with remediation steps  |  Run test_case_preparation to resolve" 50 478 ($SW-90) 20 11 $false $DGRAY 1 | Out-Null

Write-Host "  Slide 9 done"

# -------------------------------------------------------------------------
# SLIDE 10 � Before vs After
# -------------------------------------------------------------------------
$s10 = Add-Slide $ppLayoutBlank
Set-BG $s10 $WHITE
Add-HeaderBar $s10 "Before vs After � Time & Effort Savings"
Add-SlideNum $s10 10 14

# Column headers
Add-Rect $s10 $DGRAY 30 88 310 28 | Out-Null
Add-TextBox $s10 "Task" 35 91 305 22 12 $true $WHITE 1 | Out-Null
Add-Rect $s10 $DGRAY 345 88 155 28 | Out-Null
Add-TextBox $s10 "Before" 350 91 145 22 12 $true $WHITE 2 | Out-Null
Add-Rect $s10 $GREEN 505 88 155 28 | Out-Null
Add-TextBox $s10 "After (Framework)" 510 91 145 22 12 $true $WHITE 2 | Out-Null

$rows = @(
    [PSCustomObject]@{Task="Test case document"; Before="2�4 hrs / story"; After="< 5 min"},
    [PSCustomObject]@{Task="Xray Test creation + steps"; Before="30�60 min"; After="Automatic"},
    [PSCustomObject]@{Task="TC review document"; Before="1�2 hrs"; After="< 10 min"},
    [PSCustomObject]@{Task="Execution report + Xray results"; Before="1�3 hrs"; After="< 20 min"},
    [PSCustomObject]@{Task="BLOCKED AC � PO tracking"; Before="Manual (often missed)"; After="Automated 30-min poll"},
    [PSCustomObject]@{Task="Automation spec + PR creation"; Before="2�4 hrs / story"; After="< 15 min"},
    [PSCustomObject]@{Task="Framework setup for new project"; Before="Days of config"; After="1 command, ~5 min"}
)

$y = 120; $alt = $false
foreach ($row in $rows) {
    $bg = if($alt){ $LGRAY }else{ $WHITE }
    Add-Rect $s10 $bg 30 $y 630 28 | Out-Null
    Add-TextBox $s10 $row.Task 35 ($y+4) 305 22 11 $false $DARK 1 | Out-Null
    Add-TextBox $s10 $row.Before 350 ($y+4) 145 22 11 $false $DGRAY 2 | Out-Null
    Add-TextBox $s10 $row.After 510 ($y+4) 145 22 11 $true $GREEN 2 | Out-Null
    $y += 30; $alt = -not $alt
}

Write-Host "  Slide 10 done"

# -------------------------------------------------------------------------
# SLIDE 11 � Business Impact / ROI
# -------------------------------------------------------------------------
$s11 = Add-Slide $ppLayoutBlank
Set-BG $s11 $WHITE
Add-HeaderBar $s11 "Business Impact & ROI"
Add-SlideNum $s11 11 14

$impacts = @(
    [PSCustomObject]@{Title="~80% reduction"; Sub="in QA admin time per story"; Color=$GREEN},
    [PSCustomObject]@{Title="Zero rework"; Sub="from Xray step mismatches"; Color=$BLUE},
    [PSCustomObject]@{Title="100% traceability"; Sub="AC ? Test Case ? Xray ? Evidence"; Color=$NAVY}
)

$x = 30
foreach ($imp in $impacts) {
    Add-Rect $s11 $imp.Color $x 90 200 90 | Out-Null
    Add-TextBox $s11 $imp.Title ($x+10) 100 180 50 22 $true $WHITE 2 | Out-Null
    Add-TextBox $s11 $imp.Sub ($x+10) 148 180 28 11 $false $WHITE 2 | Out-Null
    $x += 215
}

$benefits = @(
    "Faster sprint completion � QA no longer the bottleneck",
    "Consistent, audit-ready QA artifacts on every story",
    "PO clarification loops tracked automatically � no forgotten responses",
    "Automation code generated same-day as test case completion",
    "Onboard new team members to QA process in hours, not weeks",
    "Cross-env failures caught early - matrix coverage auto-scoped per story",
    "Framework reusable across all projects � one investment, infinite return"
)

$y = 205
foreach ($b in $benefits) {
    Add-Rect $s11 $BLUE 40 ($y+4) 12 12 | Out-Null
    Add-TextBox $s11 $b 62 $y ($SW-100) 24 13 $false $DARK 1 | Out-Null
    $y += 40
}

Write-Host "  Slide 11 done"

# -------------------------------------------------------------------------
# SLIDE 12 � One-Command Setup
# -------------------------------------------------------------------------
$s12 = Add-Slide $ppLayoutBlank
Set-BG $s12 $WHITE
Add-HeaderBar $s12 "One-Command Setup � Any Project, Any Team"
Add-SlideNum $s12 12 14

Add-TextBox $s12 "Setting up the framework for a brand-new project takes under 5 minutes:" 40 88 ($SW-80) 28 13 $false $DARK 1 | Out-Null

# Code box
Add-Rect $s12 $DARK 30 120 ($SW-60) 155 | Out-Null
$cmd = @(
    '.\scripts\setup-qa-framework.ps1 `',
    '    -TargetPath       "C:\Projects\MyNewProject" `',
    '    -JiraBaseUrl      "mycompany.atlassian.net" `',
    '    -JiraProjectKey   "PROJ" `',
    '    -XrayClientId     "..." `',
    '    -BitbucketServer  "git.company.com" `',
    '    -RegisterScheduler'
)
Add-TextBox $s12 ($cmd -join "`n") 45 126 ($SW-90) 144 11 $false $GREEN 1 | Out-Null

$steps = @(
    "Copies 13 agents + 14 skills into the target workspace",
    "Generates mcp.local.json with project-specific API credentials",
    "Creates all QA document folders with .gitkeep placeholders",
    "Generates the automation repository config skill",
    "Optionally registers the PO Response Monitor Task Scheduler job",
    "Updates .gitignore to protect secrets"
)

$y = 285
Add-TextBox $s12 "What it does:" 40 $y 200 20 12 $true $NAVY 1 | Out-Null
$y += 22
foreach ($st in $steps) {
    Add-Rect $s12 $GREEN 40 ($y+5) 10 10 | Out-Null
    Add-TextBox $s12 $st 58 $y ($SW-90) 20 11 $false $DARK 1 | Out-Null
    $y += 28
}

Write-Host "  Slide 12 done"

# -------------------------------------------------------------------------
# SLIDE 13 � Adoption Roadmap
# -------------------------------------------------------------------------
$s13 = Add-Slide $ppLayoutBlank
Set-BG $s13 $WHITE
Add-HeaderBar $s13 "Adoption Roadmap"
Add-SlideNum $s13 13 14

$phases = @(
    [PSCustomObject]@{Phase="Phase 1 � Pilot"; Duration="Sprint 1�2"; Items=@("Deploy to 1 project team","Full TC lifecycle (stages 1�4)","Collect time-savings metrics","Refine agent instructions"); Color=$NAVY},
    [PSCustomObject]@{Phase="Phase 2 � Expand"; Duration="Sprint 3�4"; Items=@("Onboard 2�3 more projects","Enable automation stages 5�7","Activate PO Response Monitor","Document team-specific patterns"); Color=$BLUE},
    [PSCustomObject]@{Phase="Phase 3 � Scale"; Duration="Q3+"; Items=@("Central Git repo for all projects","Self-service setup via bootstrapper","Metrics dashboard (Confluence)","Extend to new frameworks"); Color=$GREEN}
)

$x = 20
foreach ($ph in $phases) {
    Add-Rect $s13 $ph.Color $x 88 210 34 | Out-Null
    Add-TextBox $s13 $ph.Phase ($x+5) 90 200 18 13 $true $WHITE 1 | Out-Null
    Add-TextBox $s13 $ph.Duration ($x+5) 108 200 14 10 $false $WHITE 1 | Out-Null
    $itemText = ($ph.Items | ForEach-Object { "� $_" }) -join "`n"
    Add-TextBox $s13 $itemText ($x+5) 130 200 180 11 $false $DARK 1 | Out-Null
    $x += 225
}

Add-Rect $s13 $LTBLUE 20 370 ($SW-40) 120 | Out-Null
Add-TextBox $s13 "Prerequisites (already in place for Phase 1):" 40 375 500 20 12 $true $NAVY 1 | Out-Null
$prereqs = "?  GitHub Copilot Enterprise license    ?  Jira Cloud API token    ?  Xray Cloud credentials    ?  VS Code on developer machines"
Add-TextBox $s13 $prereqs 40 398 ($SW-80) 40 11 $false $DARK 1 | Out-Null
Add-TextBox $s13 "Est. Phase 1 effort: 0.5 days for initial setup + 1 sprint of parallel running to validate time savings." 40 440 ($SW-80) 40 11 $false $DGRAY 1 | Out-Null

Write-Host "  Slide 13 done"

# -------------------------------------------------------------------------
# SLIDE 14 � Q&A / Thank You
# -------------------------------------------------------------------------
$s14 = Add-Slide $ppLayoutBlank
Set-BG $s14 $NAVY

Add-Rect $s14 $BLUE 0 ($SH-100) $SW 100 | Out-Null
Add-TextBox $s14 "Thank You" 40 140 ($SW-80) 80 54 $true $WHITE 2 | Out-Null
Add-TextBox $s14 "Questions & Discussion" 40 230 ($SW-80) 50 24 $false $LTBLUE 2 | Out-Null

Add-TextBox $s14 "Framework repo:" 40 340 160 24 13 $true $WHITE 1 | Out-Null
Add-TextBox $s14 "bitbucket.exampleqa.local/scm/siddev/agentic-ai-powertools.git" 205 340 ($SW-240) 24 11 $false $LTBLUE 1 | Out-Null

Write-Host "  Slide 14 done"

# -- Save ------------------------------------------------------------------
$pres.SaveAs($OutputPath, 24)   # 24 = ppSaveAsOpenXMLPresentation (.pptx)
$pres.Close()
$ppt.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt)  | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Host ""
Write-Host "Presentation saved: $OutputPath" -ForegroundColor Green
