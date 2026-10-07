<#
.SYNOPSIS
    Ollama local LLM setup helper for the QA Automation workflow.

.DESCRIPTION
    Installs, verifies, and smoke-tests the local Ollama instance used by
    qa-automation-orchestrator.ps1 and generate-test-cases-ollama.ps1.

    Modes:
      -Verify   : Check Ollama API is reachable and the required model is present.
      -Pull     : Pull (download) the specified model if not already present.
      -SmokeTest: Send a test prompt and print the response.
      -Status   : Show all locally available models and their sizes.
      (no flag) : Run Verify + SmokeTest.

.PARAMETER Verify
    Verify Ollama is running and the model exists.

.PARAMETER Pull
    Pull the model if not already installed.

.PARAMETER SmokeTest
    Run a quick generation test prompt.

.PARAMETER Status
    List all locally installed models.

.PARAMETER Model
    Ollama model name to use. Default: llama3.2

.PARAMETER OllamaUrl
    Ollama API base URL. Default: http://localhost:11434

.EXAMPLE
    # Full setup verification (default when no flags given)
    .\scripts\ollama-setup.ps1

    # Just check which models are installed
    .\scripts\ollama-setup.ps1 -Status

    # Pull model then verify
    .\scripts\ollama-setup.ps1 -Pull -Verify

    # Use a different model
    .\scripts\ollama-setup.ps1 -Model mistral -Verify -SmokeTest

.NOTES
    Install Ollama: https://ollama.com/download/windows
    After install, restart your terminal so PATH is refreshed.
    Ollama runs a background Windows service on port 11434 automatically.
#>

[CmdletBinding()]
param(
    [switch]$Verify,
    [switch]$Pull,
    [switch]$SmokeTest,
    [switch]$Status,
    [string]$Model     = "llama3.2",
    [string]$OllamaUrl = "http://localhost:11434"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Ok   ([string]$msg) { Write-Host "  [OK]  $msg" -ForegroundColor Green  }
function Write-Warn ([string]$msg) { Write-Host "  [!!]  $msg" -ForegroundColor Yellow }
function Write-Fail ([string]$msg) { Write-Host "  [ERR] $msg" -ForegroundColor Red    }
function Write-Info ([string]$msg) { Write-Host "        $msg" -ForegroundColor Cyan   }

function Test-OllamaApi {
    param([string]$Url)
    try {
        $null = Invoke-RestMethod -Uri "$Url/api/tags" -TimeoutSec 5 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-InstalledModels {
    param([string]$Url)
    try {
        $resp = Invoke-RestMethod -Uri "$Url/api/tags" -TimeoutSec 10 -ErrorAction Stop
        return $resp.models
    } catch {
        return $null
    }
}

# ---------------------------------------------------------------------------
# Default: run Verify + SmokeTest when no flags given
# ---------------------------------------------------------------------------
if (-not ($Verify -or $Pull -or $SmokeTest -or $Status)) {
    $Verify    = $true
    $SmokeTest = $true
}

Write-Host ""
Write-Host "=== Ollama Local LLM Setup Helper ===" -ForegroundColor White
Write-Host "    Model  : $Model"
Write-Host "    API URL: $OllamaUrl"
Write-Host ""

# ---------------------------------------------------------------------------
# Pre-flight: detect existing Ollama installation (never reinstall if present)
# ---------------------------------------------------------------------------
$ollamaExe = Get-Command ollama -ErrorAction SilentlyContinue
if ($ollamaExe) {
    Write-Ok "Ollama already installed at: $($ollamaExe.Source)"
    Write-Ok "Version: $(ollama --version 2>&1)"
} else {
    Write-Warn "Ollama not found in PATH."
    Write-Info "Install from: https://ollama.com/download/windows"
    Write-Info "After install, restart your terminal to refresh PATH."
    if (-not ($Pull -or $Verify -or $SmokeTest -or $Status)) { exit 1 }
}

# ---------------------------------------------------------------------------
# STATUS: list all installed models
# ---------------------------------------------------------------------------
if ($Status) {
    Write-Host "--- Installed Models ---"
    $models = Get-InstalledModels $OllamaUrl
    if ($null -eq $models) {
        Write-Fail "Ollama API not reachable at $OllamaUrl"
        Write-Info "Start Ollama: run 'ollama serve' or open the Ollama app."
    } elseif ($models.Count -eq 0) {
        Write-Warn "No models installed. Pull one: ollama pull llama3.2"
    } else {
        foreach ($m in $models) {
            $sizeGb = [math]::Round($m.size / 1GB, 1)
            Write-Ok "$($m.name)  ($sizeGb GB)"
        }
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# VERIFY: check API reachable, CLI on PATH, model installed
# ---------------------------------------------------------------------------
if ($Verify) {
    Write-Host "--- Verifying Ollama ---"

    # 1. API reachable?
    if (Test-OllamaApi $OllamaUrl) {
        Write-Ok "Ollama API is reachable at $OllamaUrl"
    } else {
        Write-Fail "Cannot reach Ollama API at $OllamaUrl"
        Write-Info "Fix: Install from https://ollama.com/download/windows"
        Write-Info "     Or start manually: ollama serve"
        Write-Host ""
        exit 1
    }

    # 2. CLI on PATH?
    $cliCmd  = Get-Command ollama -ErrorAction SilentlyContinue
    $cliPath = if ($cliCmd) { $cliCmd.Source } else { $null }
    if ($cliPath) {
        Write-Ok "ollama CLI found: $cliPath"
    } else {
        Write-Warn "ollama CLI not found on PATH (server is running - API-only mode is fine)"
        Write-Info "To fix: restart terminal after install, or add Ollama to PATH manually"
    }

    # 3. Model installed?
    $models    = Get-InstalledModels $OllamaUrl
    $modelBase = $Model.Split(':')[0]
    $found     = $models | Where-Object { $_.name -like "$modelBase*" }
    if ($found) {
        $sizeGb = [math]::Round($found[0].size / 1GB, 1)
        Write-Ok "Model '$Model' is installed ($sizeGb GB)"
    } else {
        Write-Warn "Model '$Model' not found locally."
        Write-Info "Pull it now: ollama pull $Model"
        Write-Info "Or run this script with -Pull flag."
    }

    Write-Host ""
}

# ---------------------------------------------------------------------------
# PULL: download the model if not already installed
# ---------------------------------------------------------------------------
if ($Pull) {
    Write-Host "--- Pulling model: $Model ---"

    $models    = Get-InstalledModels $OllamaUrl
    $modelBase = $Model.Split(':')[0]
    $found     = $models | Where-Object { $_.name -like "$modelBase*" }

    if ($found) {
        Write-Ok "Model '$Model' already installed - skipping pull."
    } else {
        Write-Info "Downloading $Model - this may take a few minutes (~1-4 GB)..."
        $cliCmd  = Get-Command ollama -ErrorAction SilentlyContinue
        $cliPath = if ($cliCmd) { $cliCmd.Source } else { $null }
        if ($cliPath) {
            & ollama pull $Model
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Model '$Model' pulled successfully."
            } else {
                Write-Fail "ollama pull exited with code $LASTEXITCODE"
            }
        } else {
            Write-Fail "ollama CLI not on PATH - cannot pull automatically."
            Write-Info "Run manually in a new terminal: ollama pull $Model"
        }
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# SMOKE TEST: send a test prompt, verify model responds
# ---------------------------------------------------------------------------
if ($SmokeTest) {
    Write-Host "--- Smoke Test: sending prompt to $Model ---"

    if (-not (Test-OllamaApi $OllamaUrl)) {
        Write-Fail "Ollama API not reachable - cannot run smoke test."
        exit 1
    }

    $body = @{
        model    = $Model
        messages = @(
            @{ role = "user"; content = "In exactly one sentence, confirm you are ready to generate QA test cases." }
        )
        stream   = $false
    } | ConvertTo-Json -Compress

    try {
        Write-Info "Waiting for model response (first call may take 10-20 s)..."
        $resp = Invoke-RestMethod -Method POST `
                                  -Uri "$OllamaUrl/api/chat" `
                                  -Body $body `
                                  -ContentType "application/json" `
                                  -TimeoutSec 120 `
                                  -ErrorAction Stop

        $reply = $resp.message.content
        Write-Ok "Model responded:"
        Write-Host ""
        Write-Host "    $reply" -ForegroundColor White
        Write-Host ""
        Write-Ok "Smoke test passed - Ollama is ready for QA automation."
    } catch {
        Write-Fail "Smoke test failed: $($_.Exception.Message)"
        Write-Info "Check that model '$Model' is installed: .\scripts\ollama-setup.ps1 -Status"
    }

    Write-Host ""
}

Write-Host "Done." -ForegroundColor White
