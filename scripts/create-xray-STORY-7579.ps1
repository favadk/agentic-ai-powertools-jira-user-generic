<#
.SYNOPSIS
    Publishes the STORY-7579 test cases to Xray: creates/updates the Xray Test issue,
    pushes all steps, and posts the Q/N clarification comment ON THE XRAY TEST ONLY.

.DESCRIPTION
    HARD CONSTRAINT: this script must never comment on the User Story STORY-7579.
    All clarification questions go on the Xray Test issue.

    Local source of truth: docs/TestCases/CID-Sprint-114/TC_STORY-7579.md

.EXAMPLE
    cd "C:\Agentic-AI\agentic-ai-powertools-jira-user-new"
    .\scripts\create-xray-STORY-7579.ps1
#>
[CmdletBinding()]
param(
    [string]$ProjectKey  = "STORY",
    [string]$StoryKey    = "STORY-7579",
    [string]$SprintSlug  = "CID-Sprint-114",
    [string]$TesterAccountId = "",   # set to @mention the QA Engineer on the Q/N comment
    [switch]$SkipQnComment
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\xray-api.ps1"

$storySummary = "Create, validate, and release a CID ghost image for Lenovo ThinkEdge SE10n Gen 2"
$tcDocPath    = "docs/TestCases/$SprintSlug/TC_$StoryKey.md"

# ---------------------------------------------------------------------------
# Test steps — TC-01 steps 1 and 2 are the mandatory smoke prerequisite gate
# (.github/skills/smoke-prerequisite-gate.md — triggers: linux update, openlab cds, kvm)
# ---------------------------------------------------------------------------
$steps = @(
    @{ Action = "TC-01 [PREREQ]: Smoke gate - run automated smoke suite"; Data = "Dir: C:\automation\06102026\UI_Protractor_Tests; BASE_URL={PENDING Q/N-05}; Cmd: npx protractor smoke.conf.js"; Expected = "All smoke tests pass. BASE_URL, command, run time and result recorded in evidence." }
    @{ Action = "TC-01 [PREREQ]: Smoke gate - run automated smoke-install suite"; Data = "Dir: C:\automation\06102026\UI_Protractor_Tests; BASE_URL={PENDING Q/N-05}; Cmd: npx protractor smokeInstallation.conf.js"; Expected = "All smoke-install tests pass. If either suite fails, stop story-specific steps and raise/link a Defect." }

    @{ Action = "TC-02 [AC-01]: Release record - confirm image published to manufacturing delivery location"; Data = "Image: {PENDING Q/N-02}"; Expected = "Image artefact present at the manufacturing delivery location and marked Released." }
    @{ Action = "TC-02 [AC-01]: Release record - verify hardware attributes recorded"; Data = "Processor / memory / storage / BIOS version / network controllers - {PENDING Q/N-01}"; Expected = "All five hardware attributes recorded and matching the physical SE10n Gen 2 unit under test." }
    @{ Action = "TC-02 [AC-01]: Release record - verify image metadata recorded"; Data = "Image name/version, release train, software baseline, creation date, checksum, minimum destination disk size - {PENDING Q/N-02}"; Expected = "All six metadata attributes recorded and non-empty." }
    @{ Action = "TC-02 [AC-01]: Release record - recompute and compare image checksum"; Data = "Checksum algorithm + value: {PENDING Q/N-02}"; Expected = "Computed checksum matches the recorded checksum exactly." }
    @{ Action = "TC-02 [AC-01]: Release record - verify restoration instructions attached"; Data = ""; Expected = "Restoration instructions present and referencing the minimum destination disk size." }

    @{ Action = "TC-03 [AC-02]: Verify installed Linux Update version on a unit from the ghost image"; Data = "Expected baseline: {PENDING Q/N-02}"; Expected = "Version equals the latest approved production Linux Update baseline." }
    @{ Action = "TC-03 [AC-02]: Verify installed CID Agent version"; Data = "Expected baseline: {PENDING Q/N-02}"; Expected = "Version equals the latest approved production CID Agent baseline." }
    @{ Action = "TC-03 [AC-02]: Compare both versions against the release record software baseline"; Data = ""; Expected = "Both versions match the recorded software baseline - no drift." }

    @{ Action = "TC-04 [AC-02]: Negative - enumerate the local AIC/KVM image cache"; Data = "Verification method: {PENDING Q/N-08}"; Expected = "AIC KVM image cache is empty - no pre-cached AIC KVM images present." }
    @{ Action = "TC-04 [AC-02]: Record free disk space on the unit"; Data = ""; Expected = "Free disk space consistent with an image carrying no pre-cached KVM payload." }

    @{ Action = "TC-05 [AC-03]: Run the representative workflow on the SE10n Gen 2 CID and capture metrics"; Data = "Workflow + metrics: {PENDING Q/N-04}"; Expected = "Metrics captured for all defined measurement points." }
    @{ Action = "TC-05 [AC-03]: Run the identical workflow on a Gen 1 CID and capture the same metrics"; Data = "Gen 1 unit: {PENDING Q/N-04}"; Expected = "Metrics captured using the identical workflow and data set." }
    @{ Action = "TC-05 [AC-03]: Compare Gen 2 vs Gen 1 against the agreed threshold"; Data = "Threshold: {PENDING Q/N-04}"; Expected = "Gen 2 meets or exceeds the agreed threshold relative to Gen 1." }
    @{ Action = "TC-05 [AC-03]: Record the comparison results in STORY-7579 before release"; Data = ""; Expected = "Comparison results present on the ticket and dated prior to the release action." }

    @{ Action = "TC-06 [AC-04]: Restore the ghost image to an SE10n Gen 2 destination unit per documented instructions"; Data = "CONSTRAINED - only one Gen 2 unit available; scope per {PENDING Q/N-03}"; Expected = "Restore completes without error and reports success." }
    @{ Action = "TC-06 [AC-04]: Capture the destination unit hardware configuration after restore"; Data = "Compare to release record - {PENDING Q/N-01}"; Expected = "Configuration matches the source configuration recorded in the release record exactly." }
    @{ Action = "TC-06 [AC-04]: Verify restored unit Linux Update and CID Agent versions"; Data = ""; Expected = "Versions match the baseline verified in TC-03." }

    @{ Action = "TC-07 [AC-04]: Boundary - restore onto a destination disk smaller than the documented minimum"; Data = "Minimum destination disk size: {PENDING Q/N-02}"; Expected = "Restore does not complete; an insufficient-disk-size condition is reported. No partially restored unit is produced." }
    @{ Action = "TC-07 [AC-04]: Boundary - restore onto a destination disk exactly at the documented minimum"; Data = ""; Expected = "Restore completes successfully." }

    @{ Action = "TC-08 [AC-05a]: Power on the restored unit and observe the full boot sequence without touching the console"; Data = ""; Expected = "Unit reaches a fully booted operational state with no prompts, key presses, or recovery/BIOS intervention." }
    @{ Action = "TC-08 [AC-05a]: Review the system log for boot-time errors"; Data = ""; Expected = "No boot-blocking errors recorded." }

    @{ Action = "TC-09 [AC-05b]: Without any manual registration action, open the CID Hub Devices page and locate the restored CID"; Data = "CID Hub: {PENDING Q/N-05}"; Expected = "Restored CID appears on the Devices page with no manual registration step performed." }
    @{ Action = "TC-09 [AC-05b]: Note last-connected time, wait for the next check-in interval, refresh the Devices page"; Data = ""; Expected = "Last-connected time advances to the newer check-in timestamp." }

    @{ Action = "TC-10 [AC-05c]: List both network interfaces and their assigned roles on the restored unit"; Data = "Expected controllers: {PENDING Q/N-01}"; Expected = "Exactly two interfaces present; one assigned Corporate role, one assigned Instrument role, matching the release record." }
    @{ Action = "TC-10 [AC-05c]: Verify outbound connectivity to CID Hub over the Corporate interface"; Data = ""; Expected = "Corporate interface reaches CID Hub successfully." }
    @{ Action = "TC-10 [AC-05c]: Verify connectivity to the instrument subnet over the Instrument interface"; Data = ""; Expected = "Instrument interface reaches the instrument subnet; Corporate interface is not used for instrument traffic." }

    @{ Action = "TC-11 [AC-06]: Inspect ac_install.sh on a CID created from the ghost image and read the registration server endpoint"; Data = "Expected production endpoint: {PENDING Q/N-05}"; Expected = "Endpoint is the production registration server - not a staging/test endpoint." }
    @{ Action = "TC-11 [AC-06]: Run the activation flow against the production CID Hub"; Data = "Activation code source: {PENDING Q/N-05}"; Expected = "Activation completes successfully with no error." }
    @{ Action = "TC-11 [AC-06]: Locate the activated CID on the production CID Hub Devices page"; Data = ""; Expected = "CID is listed and its state is available for use." }

    @{ Action = "TC-12 [AC-06]: Negative - on a scratch copy, point ac_install.sh at a non-production registration server and attempt activation"; Data = ""; Expected = "Activation does not succeed against the production CID Hub; failure is reported to the operator rather than registering the device elsewhere." }
    @{ Action = "TC-12 [AC-06]: Restore ac_install.sh to the production endpoint and re-run activation"; Data = ""; Expected = "Activation succeeds - confirming the released image configuration satisfies AC-06." }

    @{ Action = "TC-13 [AC-07]: Provision the latest approved OpenLab CDS 2.8 image onto the CID from CID Hub"; Data = "CDS 2.8 image id: {PENDING Q/N-06}"; Expected = "Provisioning starts and progresses without error." }
    @{ Action = "TC-13 [AC-07]: Wait for CDS 2.8 provisioning to complete and check the instance state"; Data = ""; Expected = "Provisioning completes successfully; the CDS 2.8 instance reports running/ready on the CID." }
    @{ Action = "TC-13 [AC-07]: Verify the provisioned CDS version"; Data = ""; Expected = "Version matches the approved CDS 2.8 image identifier." }

    @{ Action = "TC-14 [AC-07]: Provision the latest approved OpenLab CDS 3.0 image onto the CID from CID Hub"; Data = "CDS 3.0 image id: {PENDING Q/N-06}"; Expected = "Provisioning starts and progresses without error." }
    @{ Action = "TC-14 [AC-07]: Wait for CDS 3.0 provisioning to complete and check the instance state"; Data = ""; Expected = "Provisioning completes successfully; the CDS 3.0 instance reports running/ready on the CID." }
    @{ Action = "TC-14 [AC-07]: Verify the provisioned CDS version"; Data = ""; Expected = "Version matches the approved CDS 3.0 image identifier." }

    @{ Action = "TC-15 [AC-08]: Connect the supported physical GC/MS or LC/MS instrument to the Instrument NIC and configure it in OpenLab CDS"; Data = "Instrument model: {PENDING Q/N-07}. Scope: one CID controlling one instrument."; Expected = "Instrument is discovered and configured through the Instrument NIC; instrument status is online in CDS." }
    @{ Action = "TC-15 [AC-08]: Define and start the representative multi-sample sequence"; Data = "Sequence definition: {PENDING Q/N-07}"; Expected = "Sequence starts and each sample acquires in turn without operator intervention." }
    @{ Action = "TC-15 [AC-08]: Monitor the run through completion"; Data = ""; Expected = "Sequence completes fully - no instrument communication failures, no interrupted runs, no CID instability (no reboot, hang, or agent restart)." }
    @{ Action = "TC-15 [AC-08]: Open the acquired results in OpenLab CDS"; Data = ""; Expected = "Results for every sample in the sequence are present and openable in OpenLab CDS." }
    @{ Action = "TC-15 [AC-08]: Review the CID system log and CID Hub device status for the run window"; Data = ""; Expected = "No communication errors or device-offline events recorded for the run window." }

    @{ Action = "TC-16 [AC-09]: Trigger Reset to Factory on the CID from CID Hub"; Data = ""; Expected = "Reset is accepted and progresses to completion without error." }
    @{ Action = "TC-16 [AC-09]: Observe the CID after reset completes"; Data = ""; Expected = "CID returns to its factory/unactivated state and boots without manual intervention." }
    @{ Action = "TC-16 [AC-09]: Re-run the activation flow against the production CID Hub"; Data = ""; Expected = "Activation succeeds; CID is listed on the Devices page and available for use again." }

    @{ Action = "TC-17 [REGRESSION]: Confirm the existing Gen 1 CID is still listed and reporting check-ins on the Devices page"; Data = ""; Expected = "Gen 1 CID remains listed with an advancing last-connected time - unchanged by the Gen 2 image work." }
    @{ Action = "TC-17 [REGRESSION]: Confirm the Gen 1 CID provisioned OpenLab CDS instance is still reachable and operational"; Data = ""; Expected = "Gen 1 CDS instance unchanged and operational - no side effects from the Gen 2 ghost image release." }
)

Write-Host "Publishing $($steps.Count) steps for $StoryKey ..." -ForegroundColor Cyan

$result = Ensure-XrayTest `
    -ProjectKey  $ProjectKey `
    -Summary     "TC ${StoryKey}: $storySummary" `
    -StoryKey    $StoryKey `
    -Steps       $steps `
    -Description "Xray Test for $StoryKey. Local doc: $tcDocPath"

$testKey = $result.Key
if (-not $testKey) {
    throw "Xray Test was not created/updated for $StoryKey (action: $($result.Action)). Resolve the blocker and re-run."
}
Write-Host "Xray Test $testKey ($($result.Action))" -ForegroundColor Green
Write-Host "  https://jira.exampleqa.local/browse/$testKey"

# ---------------------------------------------------------------------------
# Q/N clarification comment - POSTED ON THE XRAY TEST ISSUE ONLY.
# Never post on the User Story STORY-7579.
# ---------------------------------------------------------------------------
$qnList = @(
    "Q/N-01 (blocks TC-02, TC-06, TC-10) - Please confirm the authoritative source and exact values for the SE10n Gen 2 hardware configuration (processor, memory, storage, BIOS version, network controllers). A wiki page was proposed as the single source of truth - is it available, and what is its URL? [Ask: Dev]"
    "Q/N-02 (blocks TC-02, TC-03, TC-07) - Please provide the released image metadata as test data: image name/version, release train, software baseline (exact Linux Update and CID Agent versions), creation date, checksum (algorithm + value), and minimum destination disk size. [Ask: Dev]"
    "Q/N-03 (blocks TC-06) - Only one Gen 2 SE10n unit is available. For AC-04 ('must be possible'), is a restore to a second physical unit in scope this sprint, or is a documented restore-procedure verification acceptable evidence? [Ask: PO]"
    "Q/N-04 (blocks TC-05) - For AC-03, please define the representative workflow for the Gen 2 vs Gen 1 comparison, the exact metrics to capture, and the pass/fail acceptance threshold. [Ask: PO]"
    "Q/N-05 (blocks TC-01, TC-11, TC-12) - Please confirm the production CID Hub URL, the production registration server endpoint ac_install.sh must target, the activation code source, and the BASE_URL for the smoke suites. [Ask: Dev]"
    "Q/N-06 (blocks TC-13, TC-14) - Please confirm the exact 'latest approved' OpenLab CDS 2.8 and 3.0 image identifiers/versions in the production catalogue at validation time. [Ask: Dev]"
    "Q/N-07 (blocks TC-15) - For AC-08, please confirm the specific supported instrument model (GC/MS or LC/MS) and the definition of the representative multi-sample sequence (sample count, method, expected runtime). [Ask: PO]"
    "Q/N-08 (blocks TC-04) - For AC-02, please confirm the accepted verification method proving absence of pre-cached AIC KVM images on the CID (exact command / path / CID Hub view that constitutes evidence). [Ask: Dev]"
)

if ($SkipQnComment) {
    Write-Host "Q/N comment skipped (-SkipQnComment)." -ForegroundColor Yellow
    return
}

$creds = Get-XrayCreds

$intro = @()
if ($TesterAccountId) {
    $intro += @{ type = "mention"; attrs = @{ id = $TesterAccountId } }
    $intro += @{ type = "text"; text = " " }
}
$intro += @{ type = "text"; text = "[QA - Open Questions for $testKey - review before scheduling execution]" }

$content = @(
    @{ type = "paragraph"; content = $intro }
    @{ type = "bulletList"; content = @(
        $qnList | ForEach-Object {
            @{ type = "listItem"; content = @(@{ type = "paragraph"; content = @(@{ type = "text"; text = $_ }) }) }
        }
    )}
    @{ type = "paragraph"; content = @(@{
        type  = "text"
        text  = "Please review each question. If valid, escalate to PO or Dev as appropriate. The affected test cases are marked UNCONFIRMED in $tcDocPath and must not be executed until answered. No comment has been posted on the User Story."
        marks = @(@{ type = "em" })
    })}
)

$commentBody = @{ body = @{ version = 1; type = "doc"; content = $content } } | ConvertTo-Json -Depth 20

$resp = Invoke-WebRequest -Method POST `
    -Uri "$($creds.Url)/rest/api/3/issue/$testKey/comment" `
    -Headers $creds.Headers -Body $commentBody -ContentType "application/json" -UseBasicParsing

$commentId = ($resp.Content | ConvertFrom-Json).id
Write-Host "Q/N comment posted on $testKey (commentId=$commentId)" -ForegroundColor Green
Write-Host ""
Write-Host "Next: record '| **Xray Test Key** | $testKey |' in $tcDocPath and run the sprint TE linkage (.github/skills/test-execution-sprint-linking.md)."
