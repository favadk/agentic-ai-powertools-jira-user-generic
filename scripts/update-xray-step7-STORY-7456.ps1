<#
.SYNOPSIS
    Updates Xray Step 7 on STORY-7496 to reflect AC-05 Option B — PO confirmed 2026-07-20.

    PO (REHMAN,SUNIL) clarified that a page refresh (F5) after CID Hub session expiry
    does NOT redirect the user to login. Already-open help pages remain accessible until
    the browser session ends.

.USAGE
    From the repository root:
        . .\scripts\xray-api.ps1
        .\scripts\update-xray-step7-STORY-7456.ps1
#>

. "$PSScriptRoot\xray-api.ps1"

$xrayIssueId = "1400561"   # STORY-7496 Jira numeric ID
$xrayTestKey = "STORY-7496"

Write-Host "" 
Write-Host "=== Xray Step 7 Update -- STORY-7496 (TC-STORY-7456-12 / AC-05) ===" -ForegroundColor Cyan
Write-Host "PO confirmed Option B: page remains accessible after session expiry." -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Get Xray Cloud token ─────────────────────────────────────────────
Write-Host "[1/4] Obtaining Xray Cloud token..."
$token = Get-XrayCloudToken

# ── Step 2: Fetch all steps for STORY-7496 via GraphQL ────────────────────────
Write-Host "[2/4] Fetching current test steps for $xrayTestKey (issueId: $xrayIssueId)..."
$getStepsQuery = @{
    query = @"
{
  getTest(issueId: "$xrayIssueId") {
    steps {
      id
      action
      result
    }
  }
}
"@
} | ConvertTo-Json -Compress

$headers = @{
    Authorization  = "Bearer $token"
    "Content-Type" = "application/json"
}

$stepsResp = Invoke-WebRequest -Method POST `
    -Uri "https://us.xray.cloud.getxray.app/api/v2/graphql" `
    -Headers $headers -Body $getStepsQuery -UseBasicParsing -ErrorAction Stop

$stepsData = ($stepsResp.Content | ConvertFrom-Json).data.getTest.steps

if (-not $stepsData -or $stepsData.Count -lt 7) {
    Write-Error "Unexpected: found $($stepsData.Count) steps on $xrayTestKey. Expected at least 7. Aborting."
    exit 1
}

Write-Host "  Found $($stepsData.Count) steps on $xrayTestKey."
$step7 = $stepsData[6]   # 0-indexed: Step 7 = index 6
Write-Host "  Step 7 ID  : $($step7.id)"
Write-Host "  Step 7 action (current): $($step7.action)"
Write-Host "  Step 7 result (current): $($step7.result)"

# ── Step 3: Apply updateTestStep mutation ─────────────────────────────────────
Write-Host ""
Write-Host "[3/4] Applying updateTestStep mutation for Step 7 (Option B -- PO confirmed 2026-07-20)..."

$updatedAction = "Authenticate with CID Hub and open an online help page (browser tab remains open). Let the CID Hub session expire (or perform an explicit logout from CID Hub). Without closing the browser tab, press F5 to refresh the already-open help page."
$updatedResult = "- Help page remains accessible after the F5 refresh`n- No redirect to the CID Hub login screen occurs`n- Session timeout or logout from CID Hub does not affect already-open documentation pages`n- Page becomes inaccessible only when the browser session itself ends (close all windows, clear cookies, or restart the machine)"

$updateMutation = @{
    query = @"
mutation {
  updateTestStep(stepId: "$($step7.id)", step: {
    action: "$($updatedAction -replace '"','\"')",
    result: "$($updatedResult -replace '"','\"' -replace "`n",'\n')"
  }) {
    warnings
  }
}
"@
} | ConvertTo-Json -Compress

$updateResp = Invoke-WebRequest -Method POST `
    -Uri "https://us.xray.cloud.getxray.app/api/v2/graphql" `
    -Headers $headers -Body $updateMutation -UseBasicParsing -ErrorAction Stop

$updatedStep = ($updateResp.Content | ConvertFrom-Json).data.updateTestStep

if ($null -ne $updatedStep) {
    Write-Host "  Step 7 updated successfully." -ForegroundColor Green
    if ($updatedStep.warnings) {
        Write-Host "  Warnings: $($updatedStep.warnings -join ', ')" -ForegroundColor Yellow
    }
} else {
    Write-Warning "updateTestStep returned no data. Raw response:"
    Write-Host $updateResp.Content
}

# ── Step 4: Summary ───────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/4] Summary" -ForegroundColor Green
Write-Host "  Xray Test   : $xrayTestKey (issueId: $xrayIssueId)"
Write-Host "  Step        : Step 7 (index 6)"
  Write-Host "  Status      : UNBLOCKED -- Option B confirmed by PO (REHMAN,SUNIL) on 2026-07-20"
Write-Host "  Next action : Run test_case_review Mode C on STORY-7496 (KHAN,FAVAD)"
Write-Host ""
