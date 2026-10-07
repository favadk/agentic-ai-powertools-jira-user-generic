<#
.SYNOPSIS
    Starts the QA Framework Setup Wizard as a local HTTP server and opens the browser.
.DESCRIPTION
    Spins up a lightweight PowerShell HttpListener on http://localhost:7420.
    The wizard runs fully in the browser and calls back to the server to:
      - Detect whether the target project already exists (Setup vs Update)
      - Execute setup-qa-framework.ps1 with all provided config
      - Stream real-time progress back to the browser
      - Seed monitor baselines and kick off the first QA lifecycle run
.EXAMPLE
    .\setup-wizard\Start-SetupWizard.ps1
#>

$Port      = 7420
$Root      = $PSScriptRoot
$Scripts   = Join-Path $Root '..' 'scripts'
$listener  = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()

Write-Host ""
Write-Host "=== Agentic AI QA Framework Setup Wizard ===" -ForegroundColor Cyan
Write-Host "  Server : http://localhost:$Port" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""
Start-Process "http://localhost:$Port/"

# ── progress log shared between setup job and SSE responses ──
$global:progressLog = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$global:setupDone   = $false
$global:setupResult = 'pending'  # pending | success | error

function Send-Response($ctx, [int]$code, [string]$contentType, [string]$body) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $ctx.Response.StatusCode      = $code
    $ctx.Response.ContentType     = "$contentType; charset=utf-8"
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.OutputStream.Close()
}

function Add-Cors($ctx) {
    $ctx.Response.Headers.Add('Access-Control-Allow-Origin','*')
    $ctx.Response.Headers.Add('Access-Control-Allow-Methods','GET,POST,OPTIONS')
    $ctx.Response.Headers.Add('Access-Control-Allow-Headers','Content-Type')
}

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        Add-Cors $ctx
        $method = $ctx.Request.HttpMethod
        $path   = $ctx.Request.Url.AbsolutePath

        # ── OPTIONS preflight ──
        if ($method -eq 'OPTIONS') {
            $ctx.Response.StatusCode = 204
            $ctx.Response.OutputStream.Close(); continue
        }

        # ── Serve wizard HTML ──
        if ($path -eq '/' -or $path -eq '/index.html') {
            $html = Get-Content (Join-Path $Root 'index.html') -Raw -Encoding UTF8
            Send-Response $ctx 200 'text/html' $html; continue
        }

        # ── GET /api/status  ─  detect new vs existing project ──
        if ($method -eq 'GET' -and $path -eq '/api/status') {
            $qs     = $ctx.Request.QueryString
            $target = $qs['target']
            $exists = $target -and (Test-Path (Join-Path $target '.github' 'agents'))
            $monitorRunning = $false
            if ($exists) {
                $tasks = Get-ScheduledTask -TaskName 'QA-Monitor-*' -ErrorAction SilentlyContinue
                $monitorRunning = ($null -ne $tasks) -and ($tasks | Where-Object State -eq 'Running' | Measure-Object).Count -gt 0
            }
            $json = @{ exists = $exists; monitorRunning = $monitorRunning } | ConvertTo-Json
            Send-Response $ctx 200 'application/json' $json; continue
        }

        # ── GET /api/progress  ─  SSE stream of log lines ──
        if ($method -eq 'GET' -and $path -eq '/api/progress') {
            $ctx.Response.StatusCode  = 200
            $ctx.Response.ContentType = 'text/event-stream; charset=utf-8'
            $ctx.Response.Headers.Add('Cache-Control','no-cache')
            $ctx.Response.Headers.Add('Connection','keep-alive')
            $writer = [System.IO.StreamWriter]::new($ctx.Response.OutputStream)
            $writer.AutoFlush = $true
            $sent = 0
            while (-not $global:setupDone -or $sent -lt $global:progressLog.Count) {
                $lines = @(); $null = $global:progressLog.ToArray() | Select-Object -Skip $sent | ForEach-Object { $lines += $_ }
                foreach ($line in $lines) {
                    $writer.WriteLine("data: $($line -replace "`n",' ')`n")
                    $sent++
                }
                Start-Sleep -Milliseconds 250
            }
            $writer.WriteLine("data: __DONE__:$global:setupResult`n")
            $writer.Close()
            $ctx.Response.OutputStream.Close(); continue
        }

        # ── POST /api/setup  ─  execute setup + start QA lifecycle ──
        if ($method -eq 'POST' -and $path -eq '/api/setup') {
            $body   = (New-Object System.IO.StreamReader($ctx.Request.InputStream)).ReadToEnd()
            $cfg    = $body | ConvertFrom-Json
            Send-Response $ctx 202 'application/json' '{"status":"started"}'

            # Reset shared state
            $global:progressLog  = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
            $global:setupDone    = $false
            $global:setupResult  = 'pending'

            # Run setup in background job so server stays responsive
            $scriptPath = Resolve-Path (Join-Path $Scripts 'setup-qa-framework.ps1')
            $ollamaPath = Resolve-Path (Join-Path $Scripts 'ollama-setup.ps1')
            $monitorPath= Resolve-Path (Join-Path $Scripts 'monitor-story-changes.ps1')
            $schedPath  = Resolve-Path (Join-Path $Scripts 'setup-story-monitor-scheduler.ps1')

            Start-Job -Name 'QA-Setup' -ScriptBlock {
                param($cfg, $scriptPath, $ollamaPath, $monitorPath, $schedPath, $logQueue)
                function Log([string]$msg) { $logQueue.Enqueue("[$(Get-Date -Format 'HH:mm:ss')] $msg") }

                try {
                    # ── Ollama (if needed) ──
                    if ($cfg.llmProvider -in 'ollama','hybrid') {
                        $model = if ($cfg.ollamaModel) { $cfg.ollamaModel } else { 'llama3.2' }
                        $url   = if ($cfg.ollamaUrl)   { $cfg.ollamaUrl   } else { 'http://localhost:11434' }
                        Log "🦙 Checking Ollama ($model)..."
                        $ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue
                        if (-not $ollamaCmd) {
                            Log "📥 Ollama not found — downloading installer..."
                            $tmp = "$env:TEMP\ollama-setup.exe"
                            Invoke-WebRequest 'https://ollama.com/download/OllamaSetup.exe' -OutFile $tmp
                            Start-Process $tmp '/silent' -Wait
                            $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('PATH','User')
                            Log "✅ Ollama installed."
                        } else {
                            Log "✅ Ollama already installed: $(ollama --version 2>&1)"
                        }
                        $running = try { (Invoke-RestMethod "$url/" -TimeoutSec 3 -EA Stop) -ne $null } catch { $false }
                        if (-not $running) {
                            Log "🚀 Starting Ollama service..."
                            Start-Process 'ollama' 'serve' -WindowStyle Hidden
                            Start-Sleep 4
                        } else { Log "✅ Ollama service running." }
                        $present = (ollama list 2>&1) | Select-String $model
                        if (-not $present) {
                            Log "📥 Pulling model '$model'..."
                            ollama pull $model 2>&1 | ForEach-Object { Log $_ }
                        } else { Log "✅ Model '$model' already present." }
                        & $ollamaPath -Verify -SmokeTest -Model $model -OllamaUrl $url 2>&1 | ForEach-Object { Log $_ }
                    }

                    # ── Framework setup ──
                    Log "⚙️  Running setup-qa-framework.ps1..."
                    $params = @{
                        TargetPath          = $cfg.targetPath
                        JiraBaseUrl         = $cfg.jiraBaseUrl
                        JiraEmail           = $cfg.jiraEmail
                        JiraToken           = $cfg.jiraToken
                        JiraProjectKey      = $cfg.jiraProjectKey
                        XrayClientId        = $cfg.xrayClientId
                        XrayClientSecret    = $cfg.xrayClientSecret
                        BitbucketServer     = $cfg.bitbucketServer
                        BitbucketProjectKey = $cfg.bitbucketProjectKey
                        BitbucketRepo       = $cfg.bitbucketRepo
                        DefaultBranch       = $cfg.defaultBranch
                        PrTargetBranch      = $cfg.prTargetBranch
                        LocalRepoPath       = $cfg.localRepoPath
                    }
                    if ($cfg.jiraBoardId)   { $params.JiraBoardId = $cfg.jiraBoardId }
                    if ($cfg.registerScheduler) { $params.RegisterScheduler = $true }

                    & $scriptPath @params 2>&1 | ForEach-Object { Log $_ }
                    Log "✅ Framework setup complete."

                    # ── Seed monitor baselines ──
                    Log "🌱 Seeding story-change baselines (first run — no triggers fired)..."
                    Set-Location $cfg.targetPath
                    . (Join-Path $cfg.targetPath 'scripts' 'xray-api.ps1')
                    & $monitorPath 2>&1 | ForEach-Object { Log $_ }
                    Log "✅ Baselines seeded."

                    # ── Register scheduled tasks ──
                    if ($cfg.registerScheduler) {
                        Log "🕐 Registering Windows Scheduled Tasks..."
                        & $schedPath 2>&1 | ForEach-Object { Log $_ }
                        Log "✅ Monitors scheduled — running every 30 min."
                    }

                    # ── First monitor run (live trigger detection) ──
                    Log "🔍 Running first monitor cycle (detecting any pending story changes)..."
                    & (Join-Path $cfg.targetPath 'scripts' 'monitor-story-changes.ps1') -PostAck 2>&1 | ForEach-Object { Log $_ }
                    & (Join-Path $cfg.targetPath 'scripts' 'monitor-po-responses.ps1')  -PostAck 2>&1 | ForEach-Object { Log $_ }
                    Log "✅ QA lifecycle monitor is active."
                    Log "🎉 Setup complete! The automated QA lifecycle is now running."
                    $global:setupResult = 'success'
                } catch {
                    Log "❌ Error: $_"
                    $global:setupResult = 'error'
                } finally {
                    $global:setupDone = $true
                }
            } -ArgumentList $cfg, $scriptPath, $ollamaPath, $monitorPath, $schedPath, $global:progressLog
            continue
        }

        Send-Response $ctx 404 'text/plain' 'Not found'

    } catch [System.Net.HttpListenerException] {
        break
    } catch {
        Write-Warning "Server error: $_"
    }
}

$listener.Stop()

