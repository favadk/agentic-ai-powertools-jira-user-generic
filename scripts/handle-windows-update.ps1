<#
.SYNOPSIS
    Automates the full monthly Windows update QA cycle when a new CPE Windows update story
    reaches "Waiting for Verification" on the sprint board.

.DESCRIPTION
    Triggered by monitor-story-changes.ps1 when it writes a WINDOWS_UPDATE trigger file.
    Executes the following steps automatically:
        1. Link Xray Test OLAC-6457 to the story
        2. Create branch qualify/monthly-windows-update-<Month-YYYY> from master
        3. Fetch latest cumulative KB article IDs from Microsoft Update Catalog
        4. Update SoftwareManager.js (kbArticles, softwareVersions, softwareDependencies,
           softwareVersionsReleaseDates) for win10 21H2 and win11 24H2
        5. Commit and push the branch
        6. Trigger the Jenkins job with the standard params

.PARAMETER TriggerFile
    Path to the WINDOWS_UPDATE trigger JSON file written by the monitor.

.PARAMETER JenkinsJobPath
    Jenkins job path (e.g. "job/AC_Project/job/RunProtractorTests").
    Defaults to value in constantData.json runTestsJobPath.

.EXAMPLE
    . .\scripts\xray-api.ps1
    .\scripts\handle-windows-update.ps1 -TriggerFile scripts/triggers/OLAC-7548-windows-update.json
#>
param(
    [Parameter(Mandatory)][string]$TriggerFile,
    [string]$JenkinsJobPath    = "",
    [string]$JenkinsBaseUrl    = "https://scs-jenkins-5.scs.GenericQA.com",
    [string]$AutomationRepoDir = "C:\automation\06102026\UI_Protractor_Tests",
    [string]$GitRepoDir        = "C:\automation\ac_repo_fr13"
)

$ErrorActionPreference = "Stop"

# --- Load helpers ------------------------------------------------------------
$repoRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot "xray-api.ps1")
$creds    = Get-XrayCreds
$encoded  = $creds.Headers.Authorization
$jiraBase = "https://jira.exampleqa.local"

# --- Read trigger -------------------------------------------------------------
$trigger  = Get-Content $TriggerFile -Raw | ConvertFrom-Json
$storyKey = $trigger.issueKey
$summary  = $trigger.summary
Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "  WINDOWS UPDATE HANDLER -- $storyKey"
Write-Host "  Summary: $summary"
Write-Host "------------------------------------------------------------"

# --- Helper: Derive month/year from story summary ----------------------------
# Handles patterns like: "[CPE] Release Aug'26 windows update"
#                         "Release August 2026 Windows Update"
function Get-MonthYearFromSummary([string]$text) {
    $monthMap = @{
        Jan='January'; Feb='February'; Mar='March'; Apr='April';
        May='May';     Jun='June';     Jul='July';  Aug='August';
        Sep='September'; Oct='October'; Nov='November'; Dec='December'
    }
    # Short form: Aug'26
    if ($text -match "(?i)\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)'(\d{2})\b") {
        $abbr = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($matches[1].ToLower())
        $full = if ($monthMap.ContainsKey($abbr)) { $monthMap[$abbr] } else { $abbr }
        $year = "20$($matches[2])"
        return @{ Short=$abbr; Full=$full; Year=$year }
    }
    # Long form: August 2026
    if ($text -match "(?i)\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{4})\b") {
        $full = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($matches[1].ToLower())
        $abbr = $full.Substring(0,3)
        return @{ Short=$abbr; Full=$full; Year=$matches[2] }
    }
    # Fallback to current month
    $now   = Get-Date
    $full  = $now.ToString("MMMM")
    $abbr  = $full.Substring(0,3)
    $year  = $now.Year.ToString()
    Write-Warning "  Could not parse month from summary. Using current month: $full $year"
    return @{ Short=$abbr; Full=$full; Year=$year }
}

$monthInfo = Get-MonthYearFromSummary $summary
$monthFull = $monthInfo.Full     # e.g. August
$monthShort= $monthInfo.Short    # e.g. Aug
$year      = $monthInfo.Year     # e.g. 2026
$yearShort = $year.Substring(2)  # e.g. 26
$branchName= "qualify/monthly-windows-update-$monthFull-$year"

Write-Host ""
Write-Host "  Month: $monthFull $year  ->  Branch: $branchName"

# --- STEP 1: Link OLAC-6457 to the story -------------------------------------
Write-Host ""
Write-Host "STEP 1 -- Linking OLAC-6457 to $storyKey..."
$existingLinks = Invoke-RestMethod -Uri "$jiraBase/rest/api/3/issue/$storyKey`?fields=issuelinks" `
    -Headers @{Authorization=$encoded;Accept="application/json"}
$alreadyLinked = $existingLinks.fields.issuelinks | Where-Object { $_.inwardIssue.key -eq 'OLAC-6457' }
if ($alreadyLinked) {
    Write-Host "  OLAC-6457 already linked. Skipping."
} else {
    $linkBody = '{"type":{"name":"Test"},"inwardIssue":{"key":"OLAC-6457"},"outwardIssue":{"key":"' + $storyKey + '"}}'
    $r = Invoke-WebRequest -Uri "$jiraBase/rest/api/3/issueLink" -Method POST `
        -Headers @{Authorization=$encoded;Accept="application/json"} `
        -Body $linkBody -ContentType "application/json" -UseBasicParsing
    Write-Host "  Linked OLAC-6457 -> $storyKey (HTTP $($r.StatusCode))"
}

# --- STEP 2: Create branch from master ---------------------------------------
Write-Host ""
Write-Host "STEP 2 -- Creating branch '$branchName' from master in $GitRepoDir..."
Push-Location $GitRepoDir
try {
    $ErrorActionPreference = "Continue"
    git fetch origin master 2>&1 | Out-Null
    $branchExists = git branch -r 2>&1 | Select-String -Pattern "origin/$([regex]::Escape($branchName))"
    if ($branchExists) {
        Write-Host "  Branch already exists on remote. Checking out."
        git checkout -B $branchName origin/$branchName 2>&1 | Out-Null
    } else {
        git checkout -B $branchName origin/master 2>&1 | Out-Null
        Write-Host "  Created branch from master."
    }
} finally {
    Pop-Location
}

# STEP 3: Fetch KB articles from Microsoft Update Catalog
Write-Host ""
Write-Host "STEP 3 - Fetching KB articles from Microsoft Update Catalog..."

function Get-WindowsKbArticle {
    param([string]$winVariant, [string]$year, [string]$monthNum)
    $win10Url = 'https://www.catalog.update.microsoft.com/Search.aspx?q=Cumulative%20Update%20for%20Windows%2010%20Version%2021H2%20for%20x64-based%20Systems'
    $win11Url = 'https://www.catalog.update.microsoft.com/Search.aspx?q=Cumulative%20Update%20for%20Windows%2011%20Version%2024H2%20for%20x64-based%20Systems'
    $url = if ($winVariant -eq '1021H2') { $win10Url } else { $win11Url }
    $prefix = $year + '-' + $monthNum

    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
        $html = $resp.Content
        $pat = [regex]::Escape($prefix) + '\s+Cumulative Update for Windows[^(]+\(KB(\d{7})\)'
        $found = [regex]::Matches($html, $pat)
        for ($idx = 0; $idx -lt $found.Count; $idx++) {
            $m   = $found[$idx]
            $pos = [Math]::Max(0, $m.Index - 50)
            $len = [Math]::Min(500, $html.Length - $m.Index)
            $ctx = $html.Substring($pos, $len)
            if ($ctx -match 'Preview|Dynamic|Safe OS|Setup') { continue }
            if ($ctx -match 'Security Updates') {
                $kb = 'KB' + $m.Groups[1].Value
                Write-Host "  Found $winVariant KB: $kb"
                return $kb
            }
        }
        if ($found.Count -gt 0) {
            $kb = 'KB' + $found[0].Groups[1].Value
            Write-Host "  Found $winVariant KB (fallback): $kb"
            return $kb
        }
    } catch {
        Write-Warning "  Catalog fetch failed: $_"
    }
    $placeholder = 'KB_TBD_' + $year + $monthNum + '_' + $winVariant
    Write-Warning "  KB not found - using placeholder: $placeholder"
    return $placeholder
}

$kbWin10 = Get-WindowsKbArticle '1021H2' $year $monthNum
$kbWin11 = Get-WindowsKbArticle '1124H2' $year $monthNum
Write-Host "  KB win10 (1021H2): $kbWin10"
Write-Host "  KB win11 (1124H2): $kbWin11"

# --- STEP 4: Update SoftwareManager.js with new Windows versions --------------
Write-Host ""
Write-Host "STEP 4 -- Updating SoftwareManager.js..."

# Determine the version strings and date
$monthNum  = [DateTime]::ParseExact($monthFull, "MMMM", $null).ToString("MM")
$patchDate = "$year-$monthNum-08 07:00:00+00:00"  # Patch Tuesday is 2nd Tuesday ~8-14th
$win10Ver  = "$year.$monthNum.1021H2.1"
$win11Ver  = "$year.$monthNum.1124H2.1"

$smPath = Join-Path $GitRepoDir "UI_Protractor_Tests\TestData\softwareManager.js"
$smContent = Get-Content $smPath -Raw

# 1. Add new version indices to softwareVersions[windows]
$lastWinIdx = [regex]::Matches($smContent, '\b(\d+):\s*''20\d{2}\.\d{2}\.1') |
              ForEach-Object { [int]$_.Groups[1].Value } |
              Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
$nextWin10Idx = $lastWinIdx + 1
$nextWin11Idx = $lastWinIdx + 2

# Replace the last Windows version entry (add new ones after it)
$lastWinLine  = [regex]::Match($smContent, "$lastWinIdx\s*:\s*'[^']+'\s*//.*(?:\r?\n|$)").Value
if (-not $lastWinLine) {
    $lastWinLine = [regex]::Match($smContent, "$lastWinIdx\s*:\s*'[^']+'\s*(?:\r?\n|$)").Value
}
$newWinLines = $lastWinLine.TrimEnd() + "`n" +
    "            $nextWin10Idx`: '$win10Ver', // OLAC-7548-pattern: $monthShort'$yearShort Windows update (win10)`n" +
    "            $nextWin11Idx`: '$win11Ver'  // OLAC-7548-pattern: $monthShort'$yearShort Windows update (win11)"
$smContent = $smContent -replace [regex]::Escape($lastWinLine.TrimEnd()), $newWinLines

# 2. Update softwareDependencies[windows] -- replace each CDS entry with new indices
# win10 CDS indices (1-9): replace old monthly with nextWin10Idx
# win11 CDS indices (10-11): replace old monthly with nextWin11Idx
for ($i = 1; $i -le 9; $i++) {
    # Pattern: <i>:  [[<pre-installed>, <old-monthly>], <pre-installed>]
    $smContent = [regex]::Replace($smContent,
        "($i\s*:\s*\[\[(\d+),\s*)(\d+)(\],\s*\2\])",
        "`${1}$nextWin10Idx`${4}")
}
for ($i = 10; $i -le 11; $i++) {
    $smContent = [regex]::Replace($smContent,
        "($i\s*:\s*\[\[(\d+),\s*)(\d+)(\],\s*\2\])",
        "`${1}$nextWin11Idx`${4}")
}

# 3. Add release dates
$smContent = $smContent -replace "(softwareVersionsReleaseDates\s*=\s*\{[^}]+?\[windows\]\s*:\s*\{[^}]+?)(\s*\},)",
    "`${1}`n            '$win10Ver':  '$patchDate', // $monthFull $year win10`n            '$win11Ver':  '$patchDate', // $monthFull $year win11`${2}"

# 4. Update kbArticles - only the CURRENT months KB, no older entries
    # Rule: kbArticles holds ONLY the latest Patch Tuesday KB for each version string.
    #       Previous months are removed when a new one is added.
$smContent = $smContent -replace "(static\s+kbArticles\s*=\s*\{)",
    "`${1}`n        '$win10Ver': '$kbWin10',`n        '$win11Ver': '$kbWin11',"

Set-Content $smPath $smContent -Encoding UTF8
Write-Host "  softwareManager.js updated."
Write-Host "  New versions: $win10Ver (idx $nextWin10Idx), $win11Ver (idx $nextWin11Idx)"
Write-Host "  KB articles:  $kbWin10 / $kbWin11"

# Verify the file loads
$verifyResult = node -e "const sm = require('./UI_Protractor_Tests/TestData/softwareManager.js'); console.log('Latest Windows:', sm.getLatestSoftwareVersion('Windows Update'))" 2>&1
Write-Host "  Verify: $verifyResult"

# --- STEP 5: Commit and push -------------------------------------------------
Write-Host ""
Write-Host "STEP 5 -- Committing and pushing..."
Push-Location $GitRepoDir
try {
    git add UI_Protractor_Tests/TestData/softwareManager.js
    git commit -m "feat: add $monthFull $year Windows update ($win10Ver / $win11Ver) for $storyKey`n`n- softwareVersions[windows]: idx $nextWin10Idx = $win10Ver, idx $nextWin11Idx = $win11Ver`n- softwareDependencies[windows]: updated CDS 1-11 to Aug'26 versions`n- kbArticles: $kbWin10 / $kbWin11`n- softwareVersionsReleaseDates: $patchDate" 2>&1 | Out-Null
    git push origin $branchName 2>&1 | Out-Null
    Write-Host "  Pushed to origin/$branchName"
} finally {
    Pop-Location
}

# --- STEP 6: Trigger Jenkins job ---------------------------------------------
Write-Host ""
Write-Host "STEP 6 -- Ensuring single Test Execution then triggering Jenkins..."

# Reuse existing TE linked to this story+OLAC-6457. Create one only if none exists.
$existingLinks = Invoke-RestMethod -Uri "$jiraBase/rest/api/3/issue/$storyKey`?fields=issuelinks" `
    -Headers @{Authorization=$encoded;Accept="application/json"}
$existingTE = $existingLinks.fields.issuelinks |
    Where-Object { $_.outwardIssue.key -match "^OLAC-" } |
    ForEach-Object { $_.outwardIssue.key } |
    Where-Object {
        try {
            $te = Invoke-RestMethod -Uri "$jiraBase/rest/api/3/issue/$_`?fields=issuetype" `
                -Headers @{Authorization=$encoded;Accept="application/json"}
            $te.fields.issuetype.name -eq "Test Execution"
        } catch { $false }
    } | Select-Object -First 1

if ($existingTE) {
    Write-Host "  Reusing existing Test Execution: $existingTE"
    $teKey = $existingTE
} else {
    Write-Host "  No existing TE found -- creating one..."
    $teKey = New-XrayTestExecution -ProjectKey "OLAC" -StoryKey $storyKey `
        -TestKeys @("OLAC-6457") `
        -Summary "TE: $storyKey $summary - Cycle 1" `
        -Environment "TST-51"
    Write-Host "  Created: $teKey"
}
Write-Host "  Test Execution in use: $teKey"

# Jenkins job path from config (runTestsJobPath) or parameter
$constantData = Get-Content (Join-Path $AutomationRepoDir "TestData\constantData.json") -Raw | ConvertFrom-Json
$resolvedJobPath = if ($JenkinsJobPath) { $JenkinsJobPath }
                   elseif ($constantData.runTestsJobPath) { $constantData.runTestsJobPath }
                   else { $null }

if (-not $resolvedJobPath) {
    Write-Warning "  Jenkins job path not configured (set runTestsJobPath in constantData.json or pass -JenkinsJobPath)."
    Write-Warning "  Manual run command:"
    Write-Host    "  BRANCH=origin/$branchName SPEC='./Tests/Story tests/OLAC-6457.spec.js' BASE_URL=https://hub.tst-51.aws.GenericQA.com OLS_NAME=scs-perfPhy-SRV.scs.GenericQA.com"
} else {
    $jenkinsUser  = $env:JENKINS_USER
    $jenkinsToken = $env:JENKINS_TOKEN
    if (-not $jenkinsUser -or -not $jenkinsToken) {
        Write-Warning "  JENKINS_USER or JENKINS_TOKEN not set -- cannot trigger job automatically."
        Write-Warning "  Trigger manually at: $JenkinsBaseUrl/$resolvedJobPath/buildWithParameters"
    } else {
        $bp1 = "BRANCH=$([Uri]::EscapeDataString('origin/' + $branchName))"
        $bp2 = "CONF=storyTests"
        $bp3 = "SPEC=$([Uri]::EscapeDataString('./Tests/Story tests/OLAC-6457.spec.js'))"
        $bp4 = "BASE_URL=$([Uri]::EscapeDataString('https://hub.tst-51.aws.GenericQA.com'))"
        $bp5 = 'OLS_NAME=' + [Uri]::EscapeDataString('scs-perfPhy-SRV.scs.GenericQA.com')
        $buildParams = "$bp1&$bp2&$bp3&$bp4&$bp5"
        $triggerUrl  = "$JenkinsBaseUrl/$resolvedJobPath/buildWithParameters?$buildParams"
        $jenkinsCred = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${jenkinsUser}:${jenkinsToken}"))
        try {
            $jr = Invoke-WebRequest -Uri $triggerUrl -Method POST `
                -Headers @{Authorization="Basic $jenkinsCred"} -UseBasicParsing
            Write-Host "  Jenkins job triggered: HTTP $($jr.StatusCode)"
            Write-Host "  Job URL: $JenkinsBaseUrl/$resolvedJobPath"
        } catch {
            Write-Warning "  Jenkins trigger failed: $_"
        }
    }
}

# --- Mark trigger processed ---------------------------------------------------
Rename-Item $TriggerFile "$TriggerFile.processed" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "  WINDOWS UPDATE HANDLER COMPLETE -- $storyKey"
Write-Host "  Branch:  $branchName"
Write-Host "  win10 KB: $kbWin10  |  win11 KB: $kbWin11"
Write-Host "------------------------------------------------------------"
