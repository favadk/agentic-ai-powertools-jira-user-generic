[CmdletBinding()]
param(
    [string]$StoryKey = 'STORY-0000',
    [string]$RepoPath = 'C:\automation\06102026\UI_Protractor_Tests',
    [string]$BaseUrl = '',
    [string]$EvidenceDirectory = '',
    [string]$OldCidName = '',
    [switch]$UpgradeOnly,
    [switch]$InstallOnly,
    [switch]$StatusOnly,
    [switch]$SkipInstallSmoke
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $BaseUrl) { $BaseUrl = $env:BASE_URL }
if (-not $BaseUrl) { $BaseUrl = 'https://app.example.com }
if (-not $EvidenceDirectory) { $EvidenceDirectory = Join-Path $PSScriptRoot "..\docs\TestExecution\evidence\$StoryKey" }
if (-not $OldCidName) { $OldCidName = $env:OLD_CID_NAME }
if (-not ($InstallOnly -or $UpgradeOnly -or $StatusOnly)) {
    if ($env:STORY_7566_SCENARIO -eq 'INSTALL_ONLY') { $InstallOnly = $true }
    elseif ($env:STORY_7566_SCENARIO -eq 'UPGRADE_ONLY') { $UpgradeOnly = $true }
    elseif ($env:STORY_7566_SCENARIO -eq 'STATUS_ONLY') { $StatusOnly = $true }
}
if ($UpgradeOnly) { $SkipInstallSmoke = $true }
if ($StatusOnly) { $SkipInstallSmoke = $true }

$specPath = Join-Path $RepoPath 'Tests\Feature tests\STORY-0000.spec.js'
$configPath = Join-Path $RepoPath 'test.conf.js'
$installConfigPath = Join-Path $RepoPath 'smokeInstallation.conf.js'

if (-not (Test-Path -LiteralPath $RepoPath -PathType Container)) {
    throw "Automation repo not found at: $RepoPath"
}
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Protractor config not found at: $configPath"
}
if (-not (Test-Path -LiteralPath $specPath -PathType Leaf)) {
    throw "Spec not found at: $specPath"
}
if (-not $SkipInstallSmoke -and -not (Test-Path -LiteralPath $installConfigPath -PathType Leaf)) {
    throw "Smoke installation config not found at: $installConfigPath"
}
if (-not $SkipInstallSmoke) {
    if (-not $env:IP_ADDRESS) { throw "IP_ADDRESS is required to run smoke installation evidence for $StoryKey" }
    if (-not $env:OLS_NAME) { throw "OLS_NAME is required to run smoke installation evidence for $StoryKey" }
}
New-Item -ItemType Directory -Force -Path $EvidenceDirectory | Out-Null
Get-ChildItem -Path $EvidenceDirectory -File -ErrorAction SilentlyContinue | Remove-Item -Force

Push-Location $RepoPath
try {
    Write-Host "Running automation for $StoryKey against $BaseUrl"
    $env:BASE_URL = $BaseUrl
    $env:STORY_7566_EVIDENCE_DIR = (Resolve-Path $EvidenceDirectory).Path
    $env:OLD_CID_NAME = $OldCidName
    if ($StatusOnly) { $env:STORY_7566_SCENARIO = 'STATUS_ONLY' }
    elseif ($InstallOnly) { $env:STORY_7566_SCENARIO = 'INSTALL_ONLY' }
    elseif ($UpgradeOnly) { $env:STORY_7566_SCENARIO = 'UPGRADE_ONLY' }
    else { $env:STORY_7566_SCENARIO = 'FULL' }
    if (-not $SkipInstallSmoke) {
        $smokeLogPath = Join-Path $EvidenceDirectory 'TC-STORY-0000-01-smoke-install-output.txt'
        $env:STORY_7566_SMOKE_INSTALL_EVIDENCE_FILE = $smokeLogPath
        Write-Host "Running smoke installation evidence for $StoryKey"
        $smokeOutput = & npx protractor $installConfigPath 2>&1
        $smokeExitCode = $LASTEXITCODE
        $smokeOutput | Set-Content -Path $smokeLogPath -Encoding UTF8
        $smokeOutput | Write-Output
        if ($smokeExitCode -ne 0) {
            throw "Smoke installation evidence failed for $StoryKey (exit code $smokeExitCode)"
        }
    }

    & npx protractor $configPath --specs $specPath --capabilities.chromeOptions.args="--headless,--no-sandbox,--disable-dev-shm-usage"
    if ($LASTEXITCODE -ne 0) {
        throw "Protractor execution failed for $StoryKey (exit code $LASTEXITCODE)"
    }
    $manifestPath = Join-Path $EvidenceDirectory 'STORY-0000-evidence-manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Automation evidence manifest was not created: $manifestPath"
    }
    Write-Host "Automation runner completed successfully for $StoryKey"
}
finally {
    Pop-Location
}
