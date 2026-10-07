<#
.SYNOPSIS
    Scaffolds the full QA Agent Framework into any VS Code workspace.

.DESCRIPTION
    Copies all agent/skill/doc-template files from this source repo into a
    target workspace and generates the following project-specific files:
      - .vscode/mcp.local.json                       (API credentials)
      - .github/skills/automation-repository-config.md
      - scripts/monitor-po-responses.ps1             (generated, project-specific path)
      - scripts/monitor-story-changes.ps1            (copied verbatim)
      - scripts/setup-story-monitor-scheduler.ps1    (copied verbatim)
      - scripts/monitor-state.json                   (initial state with sprintWatch config)
      - .vscode/tasks.json                           (QA monitor VS Code tasks)

.EXAMPLE
    # Interactive mode -- prompts for any value not supplied
    .\scripts\setup-qa-framework.ps1 -TargetPath "C:\MyProject"

    # Fully parameterised
    .\scripts\setup-qa-framework.ps1 `
        -TargetPath            "C:\MyProject" `
        -JiraBaseUrl           "mycompany.atlassian.net" `
        -JiraEmail             "user@company.com" `
        -JiraToken             "ATATT3x..." `
        -JiraProjectKey        "PROJ" `
        -XrayClientId          "ABC123" `
        -XrayClientSecret      "xyz..." `
        -BitbucketServer       "git.company.com" `
        -BitbucketProjectKey   "MYPROJ" `
        -BitbucketRepo         "my-e2e-tests" `
        -DefaultBranch         "main" `
        -PrTargetBranch        "release" `
        -LocalRepoPath         "C:\automation\my-project" `
        -RegisterScheduler
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TargetPath,
    [string]$JiraBaseUrl,
    [string]$JiraEmail,
    [string]$JiraToken,
    [string]$JiraProjectKey,
    [string]$XrayClientId,
    [string]$XrayClientSecret,
    [string]$BitbucketServer,
    [string]$BitbucketProjectKey,
    [string]$BitbucketRepo,
    [string]$DefaultBranch,
    [string]$PrTargetBranch,
    [string]$LocalRepoPath,
    [string]$JiraBoardId,
    [switch]$RegisterScheduler,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sourceRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Read-Value {
    param([string]$Current, [string]$Prompt, [switch]$Secret)
    if ($Current) { return $Current }
    if ($Secret) {
        $ss  = Read-Host -AsSecureString "  $Prompt"
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)
        try   { return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr) }
        finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    }
    return (Read-Host "  $Prompt").Trim()
}

function Write-Utf8 {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::UTF8)
}

# ---------------------------------------------------------------------------
# 1. Collect values interactively where not supplied
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '=== QA Agent Framework Setup ===' -ForegroundColor Cyan
Write-Host "Target: $TargetPath" -ForegroundColor Yellow
Write-Host ''

$JiraBaseUrl         = Read-Value -Current $JiraBaseUrl         -Prompt 'Jira base URL (e.g. company.atlassian.net)'
$JiraEmail           = Read-Value -Current $JiraEmail           -Prompt 'Jira email'
$JiraToken           = Read-Value -Current $JiraToken           -Prompt 'Jira API token' -Secret
$JiraProjectKey      = Read-Value -Current $JiraProjectKey      -Prompt 'Jira project key (e.g. PROJ)'
$XrayClientId        = Read-Value -Current $XrayClientId        -Prompt 'Xray Cloud client ID'
$XrayClientSecret    = Read-Value -Current $XrayClientSecret    -Prompt 'Xray Cloud client secret' -Secret
$BitbucketServer     = Read-Value -Current $BitbucketServer     -Prompt 'Bitbucket server hostname (e.g. git.company.com)'
$BitbucketProjectKey = Read-Value -Current $BitbucketProjectKey -Prompt 'Bitbucket project key'
$BitbucketRepo       = Read-Value -Current $BitbucketRepo       -Prompt 'Bitbucket repo slug'
$DefaultBranch       = Read-Value -Current $DefaultBranch       -Prompt 'Default/source branch name'
$PrTargetBranch      = Read-Value -Current $PrTargetBranch      -Prompt 'PR target branch name'
$LocalRepoPath       = Read-Value -Current $LocalRepoPath       -Prompt 'Local path to automation repo clone'
$JiraBoardId         = Read-Value -Current $JiraBoardId         -Prompt 'Jira Agile board ID (for sprint watch, e.g. 440 -- press Enter to skip)'

$JiraBaseUrl        = $JiraBaseUrl -replace '^https?://','' -replace '/$',''
$JiraUrl            = 'https://' + $JiraBaseUrl
$BitbucketUrl       = 'https://' + $BitbucketServer
$BitbucketBrowseUrl = $BitbucketUrl + '/projects/' + $BitbucketProjectKey + '/repos/' + $BitbucketRepo + '/browse'

# ---------------------------------------------------------------------------
# 2. Create folder structure
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Creating folder structure...' -ForegroundColor Cyan

$folders = @(
    '.github\agents', '.github\skills', '.vscode',
    'scripts\triggers', 'docs\_TEMPLATES', 'docs\QAPlan',
    'docs\TestCases', 'docs\TestCaseReview', 'docs\TestExecution',
    'docs\EvidenceReview', 'docs\Automation', 'docs\_REFERENCES'
)
foreach ($f in $folders) {
    $full = Join-Path $TargetPath $f
    if (-not (Test-Path $full)) {
        New-Item -ItemType Directory -Path $full -Force | Out-Null
        Write-Host ('  + ' + $f) -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------------------
# 3. Copy generic files verbatim
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Copying agent and skill files...' -ForegroundColor Cyan

Get-ChildItem (Join-Path $sourceRoot '.github\agents') -Filter '*.md' | ForEach-Object {
    $dest = Join-Path $TargetPath ('.github\agents\' + $_.Name)
    if ($Force -or -not (Test-Path $dest)) {
        Copy-Item $_.FullName $dest -Force
        Write-Host ('  Agent: ' + $_.Name) -ForegroundColor DarkGray
    }
}

Get-ChildItem (Join-Path $sourceRoot '.github\skills') -Filter '*.md' |
    Where-Object { $_.Name -ne 'automation-repository-config.md' } |
    ForEach-Object {
        $dest = Join-Path $TargetPath ('.github\skills\' + $_.Name)
        if ($Force -or -not (Test-Path $dest)) {
            Copy-Item $_.FullName $dest -Force
            Write-Host ('  Skill: ' + $_.Name) -ForegroundColor DarkGray
        }
    }

$xraySrc = Join-Path $sourceRoot 'scripts\xray-api.ps1'
if (Test-Path $xraySrc) {
    $xrayDest = Join-Path $TargetPath 'scripts\xray-api.ps1'
    if ($Force -or -not (Test-Path $xrayDest)) {
        Copy-Item $xraySrc $xrayDest -Force
        Write-Host '  Script: xray-api.ps1' -ForegroundColor DarkGray
    }
}

$tmplSrc = Join-Path $sourceRoot 'docs\_TEMPLATES'
if (Test-Path $tmplSrc) {
    Get-ChildItem $tmplSrc -Filter '*.md' | ForEach-Object {
        $dest = Join-Path $TargetPath ('docs\_TEMPLATES\' + $_.Name)
        if ($Force -or -not (Test-Path $dest)) {
            Copy-Item $_.FullName $dest -Force
            Write-Host ('  Template: ' + $_.Name) -ForegroundColor DarkGray
        }
    }
}

# ---------------------------------------------------------------------------
# 4. Generate automation-repository-config.md  (project-specific)
#    Built line-by-line to avoid here-string escaping issues.
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Generating automation-repository-config.md...' -ForegroundColor Cyan

$fence = '```'
$nl    = [System.Environment]::NewLine

$autoDoc  = '---' + $nl
$autoDoc += 'description: Bitbucket repository coordinates for the automation codebase' + $nl
$autoDoc += '---' + $nl + $nl
$autoDoc += '# Automation Repository Configuration' + $nl + $nl
$autoDoc += 'All automation agents must load this skill before reading or writing automation code.' + $nl + $nl
$autoDoc += '> **Bitbucket Server** (self-hosted) -- base URL: `' + $BitbucketUrl + '`' + $nl + $nl
$autoDoc += '---' + $nl + $nl
$autoDoc += '## Repository Coordinates' + $nl + $nl
$autoDoc += '| Setting              | Value |' + $nl
$autoDoc += '|----------------------|-------|' + $nl
$autoDoc += '| **Bitbucket Server** | `' + $BitbucketServer      + '` |' + $nl
$autoDoc += '| **Project Key**      | `' + $BitbucketProjectKey  + '` |' + $nl
$autoDoc += '| **Repository Slug**  | `' + $BitbucketRepo        + '` |' + $nl
$autoDoc += '| **Browse URL**       | `' + $BitbucketBrowseUrl   + '` |' + $nl
$autoDoc += '| **Default Branch**   | `' + $DefaultBranch        + '` |' + $nl
$autoDoc += '| **PR Target Branch** | `' + $PrTargetBranch       + '` |' + $nl + $nl
$autoDoc += '> Automation branches follow the pattern `automation/{STORY-KEY}` and PRs target `' + $PrTargetBranch + '`.' + $nl + $nl
$autoDoc += '---' + $nl + $nl
$autoDoc += '## How to Browse the Repository' + $nl + $nl
$autoDoc += $fence + $nl
$autoDoc += 'bitbucket_browse_repository(projectKey: "' + $BitbucketProjectKey + '", repoSlug: "' + $BitbucketRepo + '", path: "")' + $nl
$autoDoc += 'bitbucket_get_file_content(projectKey: "' + $BitbucketProjectKey + '", repoSlug: "' + $BitbucketRepo + '", path: "{file_path}", branch: "' + $DefaultBranch + '")' + $nl
$autoDoc += 'bitbucket_search(projectKey: "' + $BitbucketProjectKey + '", repoSlug: "' + $BitbucketRepo + '", query: "{search_term}")' + $nl
$autoDoc += $fence + $nl + $nl
$autoDoc += '---' + $nl + $nl
$autoDoc += '## Local Repository Path' + $nl + $nl
$autoDoc += 'The automation repo is cloned locally at: `' + $LocalRepoPath + '`' + $nl + $nl
$autoDoc += 'Agents must `Set-Location "' + $LocalRepoPath + '"` before running test commands.' + $nl

Write-Utf8 -Path (Join-Path $TargetPath '.github\skills\automation-repository-config.md') -Content $autoDoc
Write-Host '  Written: automation-repository-config.md' -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# 5. Generate .vscode/mcp.local.json using ConvertTo-Json
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Generating .vscode/mcp.local.json...' -ForegroundColor Cyan

$mcpObject = [ordered]@{
    servers = [ordered]@{
        jira = [ordered]@{
            env = [ordered]@{
                JIRA_URL            = $JiraUrl
                JIRA_EMAIL          = $JiraEmail
                JIRA_PERSONAL_TOKEN = $JiraToken
            }
        }
        xray = [ordered]@{
            env = [ordered]@{
                XRAY_CLIENT_ID     = $XrayClientId
                XRAY_CLIENT_SECRET = $XrayClientSecret
                JIRA_URL           = $JiraUrl
            }
        }
        bitbucket = [ordered]@{
            env = [ordered]@{
                BITBUCKET_SERVER_URL = $BitbucketUrl
                BITBUCKET_USERNAME   = $JiraEmail
                BITBUCKET_TOKEN      = $JiraToken
            }
        }
    }
}

Write-Utf8 -Path (Join-Path $TargetPath '.vscode\mcp.local.json') -Content ($mcpObject | ConvertTo-Json -Depth 10)
Write-Host '  Written: .vscode/mcp.local.json' -ForegroundColor DarkGray

$gitignorePath  = Join-Path $TargetPath '.gitignore'
$gitignoreEntry = '.vscode/mcp.local.json'
if (Test-Path $gitignorePath) {
    $existing = Get-Content $gitignorePath -Raw
    if ($existing -notlike '*mcp.local.json*') {
        Add-Content $gitignorePath ("`n# QA credentials -- DO NOT COMMIT`n" + $gitignoreEntry)
        Write-Host '  Updated .gitignore' -ForegroundColor DarkGray
    }
} else {
    Set-Content $gitignorePath ('# QA credentials -- DO NOT COMMIT' + [System.Environment]::NewLine + $gitignoreEntry)
    Write-Host '  Created .gitignore' -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# 6. Generate scripts/monitor-po-responses.ps1
#    Built line-by-line; the generated script reads creds from mcp.local.json.
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Generating scripts\monitor-po-responses.ps1...' -ForegroundColor Cyan

$q  = "'"   # single-quote shorthand for embedding in strings
$dq = '"'   # double-quote

$monLines = [System.Collections.Generic.List[string]]::new()
$monLines.Add('<#')
$monLines.Add('.SYNOPSIS')
$monLines.Add('    Polls Jira for PO responses on BLOCKED test cases and writes trigger files.')
$monLines.Add('    Auto-generated by setup-qa-framework.ps1 -- update $WorkspaceRoot if workspace moves.')
$monLines.Add('#>')
$monLines.Add('')
$monLines.Add('$WorkspaceRoot  = ' + $dq + $TargetPath + $dq)
$monLines.Add('$StateFile      = Join-Path $WorkspaceRoot ' + $dq + 'scripts\monitor-state.json' + $dq)
$monLines.Add('$TriggersFolder = Join-Path $WorkspaceRoot ' + $dq + 'scripts\triggers' + $dq)
$monLines.Add('')
$monLines.Add('$mcpCfg    = Get-Content (Join-Path $WorkspaceRoot ' + $dq + '.vscode\mcp.local.json' + $dq + ') -Raw | ConvertFrom-Json')
$monLines.Add('$jiraUrl   = $mcpCfg.servers.jira.env.JIRA_URL')
$monLines.Add('$jiraEmail = $mcpCfg.servers.jira.env.JIRA_EMAIL')
$monLines.Add('$jiraToken = $mcpCfg.servers.jira.env.JIRA_PERSONAL_TOKEN')
$monLines.Add('$encoded   = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($jiraEmail + ' + $q + ':' + $q + ' + $jiraToken))')
$monLines.Add('$headers   = @{ Authorization = ' + $dq + 'Basic $encoded' + $dq + '; Accept = ' + $dq + 'application/json' + $dq + ' }')
$monLines.Add('')
$monLines.Add('if (-not (Test-Path $TriggersFolder)) { New-Item -ItemType Directory $TriggersFolder | Out-Null }')
$monLines.Add('')
$monLines.Add('if (-not (Test-Path $StateFile)) {')
$monLines.Add('    Write-Host ' + $dq + 'No monitor-state.json found. Nothing to watch.' + $dq + ' -ForegroundColor Yellow')
$monLines.Add('    exit 0')
$monLines.Add('}')
$monLines.Add('')
$monLines.Add('$state = Get-Content $StateFile -Raw | ConvertFrom-Json')
$monLines.Add('')
$monLines.Add('if ($state.status -ne ' + $dq + 'WAITING_PO_RESPONSE' + $dq + ') {')
$monLines.Add('    Write-Host (' + $dq + 'Monitor state: ' + $dq + ' + $state.status + ' + $dq + ' -- nothing to poll.' + $dq + ') -ForegroundColor Gray')
$monLines.Add('    exit 0')
$monLines.Add('}')
$monLines.Add('')
$monLines.Add('$issueKey    = $state.issueKey')
$monLines.Add('$commentId   = $state.commentId')
$monLines.Add('$lastChecked = $state.lastCheckedAt')
$monLines.Add('Write-Host (' + $dq + 'Polling ' + $dq + ' + $issueKey + ' + $dq + ' for PO response to comment ' + $dq + ' + $commentId + ' + $dq + '...' + $dq + ')')
$monLines.Add('')
$monLines.Add('$r = Invoke-RestMethod ($jiraUrl + ' + $dq + '/rest/api/3/issue/' + $dq + ' + $issueKey + ' + $dq + '/comment' + $dq + ') -Headers $headers')
$monLines.Add('$newComments = $r.comments | Where-Object { $_.id -ne $commentId -and $_.created -gt $lastChecked }')
$monLines.Add('')
$monLines.Add('if ($newComments.Count -gt 0) {')
$monLines.Add('    $latest = $newComments | Sort-Object created | Select-Object -Last 1')
$monLines.Add('    Write-Host ' + $dq + 'PO response detected! Writing trigger file...' + $dq + ' -ForegroundColor Green')
$monLines.Add('    $trigger = @{')
$monLines.Add('        issueKey        = $issueKey')
$monLines.Add('        commentId       = $latest.id')
$monLines.Add('        authorAccountId = $latest.author.accountId')
$monLines.Add('        authorName      = $latest.author.displayName')
$monLines.Add('        body            = ($latest.body | ConvertTo-Json -Compress)')
$monLines.Add('        detectedAt      = (Get-Date -Format ' + $dq + 'o' + $dq + ')')
$monLines.Add('    }')
$monLines.Add('    $triggerFile = Join-Path $TriggersFolder ($issueKey + ' + $dq + '-response.json' + $dq + ')')
$monLines.Add('    $trigger | ConvertTo-Json -Depth 5 | Set-Content $triggerFile -Encoding UTF8')
$monLines.Add('    Write-Host (' + $dq + 'Trigger written: ' + $dq + ' + $triggerFile)')
$monLines.Add('} else {')
$monLines.Add('    Write-Host ' + $dq + 'No new PO response found.' + $dq)
$monLines.Add('    $state.lastCheckedAt = (Get-Date -Format ' + $dq + 'o' + $dq + ')')
$monLines.Add('    $state | ConvertTo-Json | Set-Content $StateFile -Encoding UTF8')
$monLines.Add('}')

Write-Utf8 -Path (Join-Path $TargetPath 'scripts\monitor-po-responses.ps1') -Content ($monLines -join [System.Environment]::NewLine)
Write-Host '  Written: scripts\monitor-po-responses.ps1' -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# 6b. Copy monitor-story-changes.ps1 and setup-story-monitor-scheduler.ps1
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Copying story-change monitor scripts...' -ForegroundColor Cyan

$scriptsToCopy = @('monitor-story-changes.ps1', 'setup-story-monitor-scheduler.ps1')
foreach ($sn in $scriptsToCopy) {
    $sSrc  = Join-Path $sourceRoot "scripts\$sn"
    $sDest = Join-Path $TargetPath "scripts\$sn"
    if (Test-Path $sSrc) {
        if ($Force -or -not (Test-Path $sDest)) {
            Copy-Item $sSrc $sDest -Force
            Write-Host "  Script: $sn" -ForegroundColor DarkGray
        }
    } else {
        Write-Warning "  Source not found: $sSrc"
    }
}

# ---------------------------------------------------------------------------
# 6c. Generate scripts/monitor-state.json (initial state with sprintWatch)
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Generating scripts\monitor-state.json...' -ForegroundColor Cyan

$stateJsonPath = Join-Path $TargetPath 'scripts\monitor-state.json'
if ($Force -or -not (Test-Path $stateJsonPath)) {
    $boardIdVal  = if ($JiraBoardId -match '^\d+$') { [int]$JiraBoardId } else { $null }
    $stateObj = [ordered]@{
        lastUpdated = (Get-Date -Format 'o')
        sprintWatch = [ordered]@{
            enabled           = ($null -ne $boardIdVal)
            boardId           = $boardIdVal
            sprintId          = $null
            sprintName        = ''
            autoAddNewStories = $true
            _note             = 'sprintName and sprintId are auto-detected from the active sprint on each run'
        }
        issues = @()
    }
    $stateObj | ConvertTo-Json -Depth 5 | Set-Content $stateJsonPath -Encoding UTF8
    Write-Host '  Written: scripts\monitor-state.json' -ForegroundColor DarkGray
} else {
    Write-Host '  Skipped (already exists -- use -Force to overwrite)' -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# 6d. Generate .vscode/tasks.json (manual trigger tasks)
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Generating .vscode\tasks.json...' -ForegroundColor Cyan

$tasksJsonPath = Join-Path $TargetPath '.vscode\tasks.json'
if ($Force -or -not (Test-Path $tasksJsonPath)) {
    $q2 = '"'
    $tasksObj = [ordered]@{
        version = '2.0.0'
        tasks   = @(
            [ordered]@{
                label       = 'QA: Run All Monitors Now'
                type        = 'shell'
                command     = "powershell.exe -NonInteractive -File $q2" + (Join-Path $TargetPath 'scripts\monitor-po-responses.ps1') + "$q2 ; powershell.exe -NonInteractive -File $q2" + (Join-Path $TargetPath 'scripts\monitor-story-changes.ps1') + $q2
                group       = 'test'
                presentation = [ordered]@{ reveal = 'always'; panel = 'new' }
            },
            [ordered]@{
                label       = 'QA: Seed Story Change Baselines'
                type        = 'shell'
                command     = "powershell.exe -NonInteractive -File $q2" + (Join-Path $TargetPath 'scripts\monitor-story-changes.ps1') + $q2
                group       = 'test'
                presentation = [ordered]@{ reveal = 'always'; panel = 'new' }
            },
            [ordered]@{
                label       = 'QA: Setup Scheduled Tasks (run as Admin)'
                type        = 'shell'
                command     = "powershell.exe -NonInteractive -File $q2" + (Join-Path $TargetPath 'scripts\setup-story-monitor-scheduler.ps1') + $q2
                group       = 'test'
                presentation = [ordered]@{ reveal = 'always'; panel = 'new' }
            }
        )
    }
    $tasksObj | ConvertTo-Json -Depth 10 | Set-Content $tasksJsonPath -Encoding UTF8
    Write-Host '  Written: .vscode\tasks.json' -ForegroundColor DarkGray
} else {
    Write-Host '  Skipped .vscode\tasks.json (already exists -- use -Force to overwrite)' -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# 7. Copy and patch copilot-instructions.md
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Copying copilot-instructions.md...' -ForegroundColor Cyan

$ciSrc  = Join-Path $sourceRoot '.github\copilot-instructions.md'
$ciDest = Join-Path $TargetPath '.github\copilot-instructions.md'
if (Test-Path $ciSrc) {
    $ciContent = (Get-Content $ciSrc -Raw) -replace '\bOLAC\b', $JiraProjectKey
    Write-Utf8 -Path $ciDest -Content $ciContent
    Write-Host ('  Written: copilot-instructions.md (project key: ' + $JiraProjectKey + ')') -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# 8. Optionally register Task Scheduler jobs (both monitors)
# ---------------------------------------------------------------------------
if ($RegisterScheduler) {
    Write-Host ''
    Write-Host 'Registering QA monitor scheduled tasks...' -ForegroundColor Cyan

    $schedulerScript = Join-Path $TargetPath 'scripts\setup-story-monitor-scheduler.ps1'
    if (Test-Path $schedulerScript) {
        # setup-story-monitor-scheduler.ps1 self-elevates via UAC when needed
        # and registers both QA-Monitor-PO-Responses and QA-Monitor-Story-Changes
        Start-Process 'powershell.exe' `
            -ArgumentList ("-NonInteractive -File `"$schedulerScript`"`"`"`" `"$TargetPath`"") `
            -Verb RunAs -Wait
        Write-Host '  Registered: QA-Monitor-PO-Responses + QA-Monitor-Story-Changes (every 30 min)' -ForegroundColor DarkGray
    } else {
        Write-Warning "  setup-story-monitor-scheduler.ps1 not found at: $schedulerScript. Run it manually to register tasks."
    }
}

# ---------------------------------------------------------------------------
# 9. Summary
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '==========================================' -ForegroundColor Green
Write-Host '  QA Framework setup complete!' -ForegroundColor Green
Write-Host '==========================================' -ForegroundColor Green
Write-Host ''
Write-Host ('Project   : ' + $JiraProjectKey)
Write-Host ('Jira      : ' + $JiraUrl)
Write-Host ('Bitbucket : ' + $BitbucketUrl + ' / ' + $BitbucketProjectKey + ' / ' + $BitbucketRepo)
Write-Host ('PR target : ' + $PrTargetBranch)
Write-Host ('Repo path : ' + $LocalRepoPath)
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host ('  1. Open ' + $q + $TargetPath + $q + ' in VS Code')
Write-Host '  2. Verify MCP servers connect: check .vscode/mcp.local.json'
Write-Host '  3. Start a QA cycle: use the sprint_story_qa_plan agent'
Write-Host '  4. Run monitor-story-changes.ps1 once to seed description baselines'
Write-Host '  5. NEVER commit .vscode/mcp.local.json -- it contains secrets'
Write-Host ''
