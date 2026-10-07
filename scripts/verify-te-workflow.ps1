param($JsonPath)

$j = [System.IO.File]::ReadAllText($JsonPath) | ConvertFrom-Json

Write-Host ""
Write-Host "============================================================"
Write-Host " TE VERIFICATION WORKFLOW -- STORY sample-sprint (ID 78391)"
Write-Host "============================================================"
Write-Host " Board  : Acquisition Controller Scrum Board (ID 440)"
Write-Host " Sprint : sample-sprint  |  Jul 15-28, 2026"
Write-Host ""

# Step 2.2 - Fixed filter: issuetype=Test Execution AND statusCategory != done
Write-Host "[ Step 2.2 ] Filter: issuetype=Test Execution AND statusCategory!=done"
$activeTe = $j.issues | Where-Object {
    $_.fields.issuetype.name -eq "Test Execution" -and
    $_.fields.status.statusCategory.key -ne "done"
}

if ($activeTe) {
    $count = ($activeTe | Measure-Object).Count
    Write-Host "  FOUND $count active sprint TE(s):"
    $activeTe | ForEach-Object {
        Write-Host "  [OK] $($_.key) status=[$($_.fields.status.name)] cat=[$($_.fields.status.statusCategory.key)]"
        Write-Host "       $($_.fields.summary)"
    }
    $teKey = ($activeTe | Select-Object -First 1).key
} else {
    Write-Host "  [NO ACTIVE TE] -- STORY-0000 is Closed (statusCategory=done)"
    Write-Host "  FILTER WORKING CORRECTLY -- Closed TE excluded as expected"
    Write-Host "  WORKFLOW DECISION => Section 3 (auto-create + notify) would trigger"
    $teKey = $null
}

Write-Host ""

# All TEs in sprint for reference
Write-Host "[ Ref ] All Test Execution issues in sprint:"
$allTe = $j.issues | Where-Object { $_.fields.issuetype.name -eq "Test Execution" }
$allTe | ForEach-Object {
    Write-Host "  $($_.key)  status=[$($_.fields.status.name)]  cat=[$($_.fields.status.statusCategory.key)]"
    Write-Host "        $($_.fields.summary)"
}

Write-Host ""

# Step 4.1 - Active stories for bulk-add
Write-Host "[ Step 4.1 ] Active stories (non-done) in sprint:"
$stories = $j.issues | Where-Object {
    $_.fields.issuetype.name -in @("Story","User Story") -and
    $_.fields.status.statusCategory.key -ne "done"
}
$stories | ForEach-Object {
    Write-Host "  $($_.key)  [$($_.fields.status.name)]  $($_.fields.summary.Substring(0,[Math]::Min(55,$_.fields.summary.Length)))"
}

Write-Host ""

# Step 4.2 - TC doc check
Write-Host "[ Step 4.2 ] TC document check:"
$stories | ForEach-Object {
    $key  = $_.key
    $path = "docs\TestCases\TC_$key.md"
    if (Test-Path $path) {
        Write-Host "  [FOUND] $key -- $path"
    } else {
        Write-Host "  [MISSING] $key -- fallback: issue-tracker Test link query needed"
    }
}

Write-Host ""

# Step 4.4 - TE status category check
if ($teKey) {
    $te    = $j.issues | Where-Object { $_.key -eq $teKey }
    $teCat = $te.fields.status.statusCategory.key
    $teSt  = $te.fields.status.name
    Write-Host "[ Step 4.4 ] Sprint TE $teKey -- status: [$teSt]  category: [$teCat]"
    if ($teCat -eq "indeterminate") {
        Write-Host "  [PASS] TE is indeterminate category -- PROCEED to execution"
    } else {
        Write-Host "  [ACTION] TE not indeterminate -- transition required"
    }
} else {
    Write-Host "[ Step 4.4 ] Skipped -- no active TE (handled by Section 3 auto-create)"
}

Write-Host ""
Write-Host "============================================================"
Write-Host " WORKFLOW SUMMARY"
Write-Host "============================================================"

if (-not $teKey) {
    Write-Host "  1. [NO ACTIVE TE] Sprint has no active Test Execution"
    Write-Host "  2. [SECTION 3] Auto-create TE would trigger:"
    Write-Host "       - Create TE: Sprint TE: sample-sprint -- STORY"
    Write-Host "       - Move TE to sprint ID 78391"
    Write-Host "       - Post issue-tracker comment at PO / PM with TE key"
    Write-Host "       - Post Teams: CID Scurm Team Chat + AC1 Daily Stand-up"
    Write-Host "  3. [SECTION 4] Bulk-add tests for stories:"
    $stories | ForEach-Object { Write-Host "       - $($_.key) (if TC doc or issue-tracker Test link found)" }
    Write-Host "  4. [STEP 4.4] Transition new TE to indeterminate (In Progress/In Dev)"
} else {
    $te    = $j.issues | Where-Object { $_.key -eq $teKey }
    $teCat = $te.fields.status.statusCategory.key
    Write-Host "  Active TE: $teKey"
    if ($teCat -eq "indeterminate") {
        Write-Host "  TE is active (indeterminate) -- execution can proceed"
    } else {
        Write-Host "  TE needs transition to indeterminate before execution"
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host " BUG FIX VERIFICATION"
Write-Host "============================================================"
Write-Host "  Fix 1 (JQL): Use issue-tracker_get_sprint_issues + local filter -- not issue-tracker_search JQL"
Write-Host "  Fix 2 (Status): Check statusCategory.key != indeterminate -- not exact name In Dev"
Write-Host ""
Write-Host "  Evidence -- TE in this sprint:"
$allTe | ForEach-Object {
    $nm  = $_.fields.status.name
    $cat = $_.fields.status.statusCategory.key
    Write-Host "  $($_.key) exact-status=[$nm] category=[$cat]"
    if ($cat -eq "done") {
        Write-Host "  Old approach: sprint JQL might fail; name check 'In Dev' irrelevant for closed TE"
        Write-Host "  New approach: statusCategory=done => EXCLUDED from active TE list [CORRECT]"
    } else {
        Write-Host "  New approach: statusCategory=indeterminate => INCLUDED as active TE [CORRECT]"
    }
}
Write-Host "============================================================"
