<#
.SYNOPSIS
    Generates structured QA test cases from a issue-tracker story's Acceptance Criteria
    using a locally running Ollama LLM instance.

.USAGE
    # Dot-source from the orchestrator:
    . .\scripts\generate-test-cases-ollama.ps1

    # Or call directly:
    $testCases = Invoke-OllamaTestCaseGeneration `
        -StorySummary "User can reset their password" `
        -AcceptanceCriteria "AC-01: User receives email within 60s..." `
        -Model "llama3.2"

.NOTES
    Requires Ollama running locally: https://ollama.com
    Recommended models (pull before use):
        ollama pull llama3.2        (default, good balance)
        ollama pull llama3.2:1b     (faster, lighter)
        ollama pull mistral         (alternative, good structure)
#>

# ---------------------------------------------------------------------------
# Helper: strip HTML tags from issue-tracker rendered fields
# ---------------------------------------------------------------------------
function ConvertFrom-HtmlToText {
    param([string]$Html)
    if (-not $Html) { return "" }
    $text = $Html `
        -replace '<br\s*/?>', "`n" `
        -replace '</p>',      "`n" `
        -replace '</li>',     "`n" `
        -replace '</tr>',     "`n" `
        -replace '<[^>]+>',   '' `
        -replace '&nbsp;',    ' ' `
        -replace '&amp;',     '&' `
        -replace '&lt;',      '<' `
        -replace '&gt;',      '>' `
        -replace '&quot;',    '"' `
        -replace '&#39;',     "'" `
        -replace '\n{3,}',    "`n`n"
    return $text.Trim()
}

# ---------------------------------------------------------------------------
# Helper: extract plain text from Atlassian Document Format (ADF) JSON
# ---------------------------------------------------------------------------
function ConvertFrom-AdfToText {
    param([object]$Adf)
    if ($null -eq $Adf) { return "" }
    if ($Adf -is [string]) { return $Adf }

    $lines = [System.Collections.Generic.List[string]]::new()

    function Read-Node($node) {
        if ($null -eq $node) { return }
        switch ($node.type) {
            "text"       { $script:lines.Add($node.text) }
            "hardBreak"  { $script:lines.Add("`n") }
            "paragraph"  {
                if ($node.content) { foreach ($c in $node.content) { Read-Node $c } }
                $script:lines.Add("`n")
            }
            "bulletList" {
                if ($node.content) { foreach ($c in $node.content) { Read-Node $c } }
            }
            "orderedList" {
                if ($node.content) { foreach ($c in $node.content) { Read-Node $c } }
            }
            "listItem"   {
                $script:lines.Add("- ")
                if ($node.content) { foreach ($c in $node.content) { Read-Node $c } }
            }
            default {
                if ($node.content) { foreach ($c in $node.content) { Read-Node $c } }
            }
        }
    }

    Read-Node $Adf
    return ($lines -join '').Trim()
}

# ---------------------------------------------------------------------------
# Main: call Ollama and return parsed test case array
# ---------------------------------------------------------------------------
function Invoke-OllamaTestCaseGeneration {
    <#
    .SYNOPSIS
        Calls a local Ollama LLM to generate test cases from story AC.

    .PARAMETER StorySummary        Story title/summary from issue-tracker
    .PARAMETER AcceptanceCriteria  AC text (plain text, HTML, or ADF object)
    .PARAMETER Description         Optional story description for extra context
    .PARAMETER Model               Ollama model name (default: llama3.2)
    .PARAMETER OllamaUrl           Ollama base URL (default: http://localhost:11434)

    .OUTPUTS   Array of PSCustomObjects with fields:
               title, type, priority, ac_ref, steps[]
               Returns $null on failure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StorySummary,
        [Parameter(Mandatory)]       $AcceptanceCriteria,
        [string]$Description = "",
        [string]$Model       = "llama3.2",
        [string]$OllamaUrl   = "http://localhost:11434"
    )

    # Normalise AC to plain text
    $typeName = $AcceptanceCriteria.GetType().Name
    if ($typeName -eq "PSCustomObject") {
        $acText = ConvertFrom-AdfToText $AcceptanceCriteria
    } elseif ($typeName -eq "String") {
        if ($AcceptanceCriteria -match '<[a-zA-Z]') {
            $acText = ConvertFrom-HtmlToText $AcceptanceCriteria
        } else {
            $acText = $AcceptanceCriteria
        }
    } else {
        $acText = "$AcceptanceCriteria"
    }

    if (-not $acText -or $acText.Trim().Length -lt 10) {
        Write-Warning "  AC text is empty or too short - cannot generate test cases."
        return $null
    }

    if ($Description -is [string]) {
        $descText = $Description
    } else {
        $descText = ConvertFrom-AdfToText $Description
    }

    # Build system prompt using explicit string concatenation to avoid encoding issues
    $systemPrompt = "You are a senior QA Test Case Author. " +
        "Given a issue-tracker User Story and its Acceptance Criteria, generate comprehensive, structured test cases.`n`n" +
        "RULES:`n" +
        "1. Each AC item gets at minimum: 1 Happy Path test case AND 1 Negative test case.`n" +
        "2. Add Boundary test cases where numeric, date, or length limits appear in the AC.`n" +
        "3. Each test case must have 3 to 6 concrete, specific steps.`n" +
        "4. Steps must be actionable and specific - 'Navigate to the Reports screen' NOT 'Open the app'.`n" +
        "5. Expected results must be exact - 'Error message reads: Email is required' NOT 'Error appears'.`n" +
        "6. Test data must be realistic but never use real production credentials.`n`n" +
        "OUTPUT: Return ONLY a valid JSON array - no explanation, no markdown fences, no extra text.`n`n" +
        "Schema:`n" +
        "[`n" +
        "  {`n" +
        "    `"title`": `"Short descriptive TC title`",`n" +
        "    `"type`": `"Happy Path`",`n" +
        "    `"priority`": `"High`",`n" +
        "    `"ac_ref`": `"AC-01`",`n" +
        "    `"steps`": [`n" +
        "      { `"action`": `"Specific user action`", `"data`": `"test value or empty string`", `"expected`": `"Exact expected outcome`" }`n" +
        "    ]`n" +
        "  }`n" +
        "]"

    $userPrompt = "Story Summary: $StorySummary`n`nDescription: $descText`n`nAcceptance Criteria:`n$acText`n`nGenerate all required test cases covering every AC item."

    $body = @{
        model    = $Model
        messages = @(
            @{ role = "system"; content = $systemPrompt }
            @{ role = "user";   content = $userPrompt   }
        )
        stream  = $false
        options = @{ temperature = 0.2 }
    } | ConvertTo-Json -Depth 10

    $endpoint = "$($OllamaUrl.TrimEnd('/'))/api/chat"

    try {
        Write-Host "  [Ollama] Generating test cases via $Model..."
        $resp = Invoke-WebRequest -Method POST -Uri $endpoint `
            -Body $body -ContentType "application/json" `
            -UseBasicParsing -ErrorAction Stop -TimeoutSec 600

        $rawContent = ($resp.Content | ConvertFrom-Json).message.content

        # Strip markdown fences if model added them, then extract the JSON array
        $jsonStr = $rawContent
        if ($rawContent -match '(?s)```[a-z]*\s*(\[[\s\S]+\])\s*```') {
            $jsonStr = $Matches[1]
        } elseif ($rawContent -match '(?s)(\[[\s\S]+\])') {
            $jsonStr = $Matches[1]
        }

        # Save raw to temp file and load back - avoids PS5.1 ConvertFrom-Json size limits
        $tmpFile = Join-Path $env:TEMP "ollama-tc-$(Get-Random).json"
        $jsonStr | Set-Content $tmpFile -Encoding UTF8
        $testCases = Get-Content $tmpFile -Raw -Encoding UTF8 | ConvertFrom-Json
        Remove-Item $tmpFile -ErrorAction SilentlyContinue

        Write-Host "  [Ollama] Generated $($testCases.Count) test case(s)."
        return $testCases
    }
    catch {
        Write-Warning "  [Ollama] Call failed: $_"
        Write-Warning "  Ensure Ollama is running: ollama serve"
        Write-Warning "  Ensure model is pulled:   ollama pull $Model"
        return $null
    }
}

Write-Verbose "generate-test-cases-ollama.ps1 loaded. Function: Invoke-OllamaTestCaseGeneration"
