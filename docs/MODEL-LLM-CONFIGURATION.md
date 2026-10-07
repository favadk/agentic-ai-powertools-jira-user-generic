# Model & LLM Configuration Guide

**Version**: 1.0  
**Date**: 2026-08-14  

---

## Overview

The Agentic AI QA Framework uses **GitHub Copilot agents** powered by specified LLM models. This guide ensures consistent model selection across all deployments and customizations.

---

## Recommended Model Matrix

### Primary Models (Production)

| Agent | Recommended Model | Reason | Min Version |
|-------|-------------------|--------|-------------|
| **test_case_preparation** | GPT-4o (claude-3-5-sonnet fallback) | Complex AC parsing, test step generation | Latest |
| **test_case_review** | GPT-4o | Comparative analysis (ACs vs test steps) | Latest |
| **test_case_execution** | Claude-3.5-Sonnet | Step-by-step guidance, nuanced instructions | Latest |
| **test_case_evidence_review** | Claude-3.5-Sonnet | Visual/qualitative assessment of evidence | Latest |
| **automation_code_preparation** | GPT-4o | Code generation (Protractor specs) | Latest |
| **automation_code_review** | GPT-4o | Code quality analysis, coverage | Latest |
| **automation_run_publish** | Claude-3.5-Sonnet | Result parsing, decision trees | Latest |
| **story_monitor** | Claude-3.5-Sonnet | JSON trigger routing, state management | Latest |
| **sprint_story_qa_plan** | GPT-4o | Bulk QA plan generation across stories | Latest |

### Fallback Models

If primary model is unavailable, fallback sequence:
```
GPT-4o → Claude-3.5-Sonnet → Claude-3-Opus → GPT-4
```

---

## Model Specifications

### GPT-4o (OpenAI)

**Best for:**
- Complex reasoning (AC parsing, test case generation)
- Code generation (automation specs)
- Bulk operations (sprint QA plans)

**Deployment:**
```yaml
# docker-compose.yml environment
COPILOT_MODEL_PRIMARY=gpt-4o
OPENAI_API_KEY=${OPENAI_API_KEY}
OPENAI_ORG_ID=${OPENAI_ORG_ID}  # Optional
```

**Configuration:**
```powershell
# scripts/xray-api.ps1
$env:COPILOT_MODEL = "gpt-4o"
$env:OPENAI_TEMPERATURE = 0.2  # Lower = more deterministic
$env:OPENAI_MAX_TOKENS = 4096
```

**Cost Estimate:**
- Input: $0.005 per 1K tokens
- Output: $0.015 per 1K tokens
- Typical TC prep: ~3K tokens = $0.06

---

### Claude-3.5-Sonnet (Anthropic)

**Best for:**
- Step-by-step execution guidance
- Evidence quality assessment (nuanced judgment)
- Long-context analysis (evidence + test steps)

**Deployment:**
```yaml
# docker-compose.yml environment
COPILOT_MODEL_SECONDARY=claude-3-5-sonnet-20241022
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
```

**Configuration:**
```powershell
# scripts/xray-api.ps1
$env:COPILOT_MODEL_FALLBACK = "claude-3-5-sonnet-20241022"
$env:ANTHROPIC_TEMPERATURE = 0.3
$env:ANTHROPIC_MAX_TOKENS = 2048
```

**Cost Estimate:**
- Input: $0.003 per 1K tokens
- Output: $0.015 per 1K tokens
- Typical evidence review: ~2K tokens = $0.04

---

### Claude-3-Opus (Anthropic)

**Best for:**
- Complex multi-agent coordination
- Edge case handling
- Fallback reliability

**When to use:**
- If primary + secondary unavailable
- For complex defect analysis

---

## Environment Variables

### Docker Compose `.env` File

```bash
# ========== Model Selection ==========
# Primary model for most agents
COPILOT_MODEL_PRIMARY=gpt-4o

# Fallback models (in priority order)
COPILOT_MODEL_FALLBACK_1=claude-3-5-sonnet-20241022
COPILOT_MODEL_FALLBACK_2=claude-3-opus-20240229
COPILOT_MODEL_FALLBACK_3=gpt-4

# ========== OpenAI Configuration ==========
OPENAI_API_KEY=<your-api-key>
OPENAI_ORG_ID=<optional-org-id>
OPENAI_TEMPERATURE=0.2
OPENAI_MAX_TOKENS=4096

# ========== Anthropic Configuration ==========
ANTHROPIC_API_KEY=<your-api-key>
ANTHROPIC_TEMPERATURE=0.3
ANTHROPIC_MAX_TOKENS=2048

# ========== GitHub Copilot Configuration ==========
GITHUB_TOKEN=<your-github-pat>
COPILOT_AGENT_MODE=production  # or 'debug'

# ========== Model Timeout & Retry ==========
MODEL_REQUEST_TIMEOUT_SECONDS=60
MODEL_RETRY_COUNT=3
MODEL_RETRY_BACKOFF_SECONDS=5
```

### PowerShell Module Configuration

**In `scripts/xray-api.ps1`:**

```powershell
# Load model preferences
function Get-PreferredModel {
    param([string]$AgentName)
    
    $modelMap = @{
        'test_case_preparation'     = 'gpt-4o'
        'test_case_review'          = 'gpt-4o'
        'test_case_execution'       = 'claude-3-5-sonnet-20241022'
        'automation_code_preparation' = 'gpt-4o'
        'automation_code_review'    = 'gpt-4o'
        'automation_run_publish'    = 'claude-3-5-sonnet-20241022'
        'story_monitor'             = 'claude-3-5-sonnet-20241022'
        'sprint_story_qa_plan'      = 'gpt-4o'
    }
    
    return $modelMap[$AgentName]
}

# Usage
$model = Get-PreferredModel -AgentName "test_case_preparation"
# Returns: gpt-4o
```

---

## Model Selection Logic

### Decision Tree

```
Agent Request
    ↓
[Try Primary Model]
    ↓
    ├─ SUCCESS → Return result
    ├─ TIMEOUT (>60s) → Try Fallback-1
    ├─ RATE_LIMIT → Wait + Retry (3x)
    ├─ AUTH_ERROR → Alert DevOps + Stop
    └─ OTHER_ERROR → Log + Try Fallback-1
        ↓
[Try Fallback-1 (Claude-3.5-Sonnet)]
    ├─ SUCCESS → Log model switch + Return result
    ├─ TIMEOUT/ERROR → Try Fallback-2
    └─ ... (repeat for Fallback-2, 3)
        ↓
[All models exhausted]
    └─ Post Jira comment: "QA agents unavailable - all LLMs offline"
    └─ Alert: qa-framework@company.atlassian.net
    └─ Story remains in current status (no transition)
```

---

## Cost Optimization

### Estimated Monthly Costs (50 stories/sprint, 2-week sprints)

| Agent | Calls/Sprint | Avg Tokens | Cost/Call | Sprint Total |
|-------|------|------------|-----------|--------------|
| test_case_preparation | 50 | 3,000 | $0.06 | $3.00 |
| test_case_review | 50 | 2,000 | $0.04 | $2.00 |
| test_case_execution | 50 | 1,500 | $0.03 | $1.50 |
| evidence_review | 50 | 2,500 | $0.05 | $2.50 |
| automation_code_prep | 40 | 2,000 | $0.04 | $1.60 |
| automation_code_review | 40 | 1,500 | $0.03 | $1.20 |
| automation_run_publish | 40 | 1,000 | $0.02 | $0.80 |
| story_monitor | 1440 (daily) | 500 | $0.01 | $14.40 |
| sprint_story_qa_plan | 12 | 4,000 | $0.08 | $0.96 |
| **TOTAL** | | | | **~$28/sprint** |

**Annual budget**: ~$224 (for single sprint cycle; scale per org size)

### Cost Reduction Tips

1. **Lower temperature for deterministic tasks**
   - test_case_review: 0.1 (very consistent)
   - story_monitor: 0.0 (always same routing)

2. **Use smaller models where possible**
   - story_monitor routing: Use Claude-3-Haiku (cheapest)
   - Simple pass/fail decisions: Use GPT-4 (not 4o)

3. **Cache common prompts**
   - Agent instructions (static)
   - Skill documentation (static)
   - Can save 90% on repeat calls

4. **Batch requests**
   - sprint_story_qa_plan: Process 12 stories in single batch call
   - Save token overhead per call

---

## AI Safety & Compliance

### Model Guardrails

**Do NOT pass to LLMs:**
- Production database credentials
- Customer PII or sensitive data
- Live API tokens or secrets

**Safe to pass:**
- Jira issue keys (STORY-0000)
- Test step descriptions (anonymized)
- Generic error messages
- Public documentation

### Audit Trail

All LLM calls are logged with:
```json
{
  "timestamp": "2026-08-14T10:30:00Z",
  "agent": "test_case_preparation",
  "model": "gpt-4o",
  "prompt_tokens": 3124,
  "completion_tokens": 2456,
  "cost_usd": 0.062,
  "duration_seconds": 4.2,
  "result_status": "success",
  "story_key": "STORY-0000"
}
```

Stored in: `logs/llm-calls.jsonl`

---

## Troubleshooting

### Model Selection Issues

| Issue | Diagnosis | Solution |
|-------|-----------|----------|
| "GPT-4o not available" | API rate limit | Use fallback (Claude), add delay in retry logic |
| "All models failing" | API outage | Check status.openai.com, status.anthropic.com; wait 5 min |
| Slow responses (>60s) | Network latency or model overload | Use faster model (Sonnet < 4o) or reduce max_tokens |
| "Invalid API key" | Auth error | Verify `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` in `.env` |
| High costs | Excessive token usage | Reduce max_tokens; use cheaper model; cache prompts |

### Model Verification

```powershell
# Test primary model availability
$headers = @{Authorization="Bearer $env:OPENAI_API_KEY"}
$body = @{
    model = "gpt-4o"
    messages = @(@{role="user"; content="Say 'OK'"})
    max_tokens = 10
} | ConvertTo-Json

$r = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
  -Method POST -Headers $headers -Body $body
Write-Host "✅ GPT-4o: Available"

# Test fallback model
$headers = @{Authorization="x-api-key $env:ANTHROPIC_API_KEY"}
$body = @{
    model = "claude-3-5-sonnet-20241022"
    max_tokens = 10
    messages = @(@{role="user"; content="Say 'OK'"})
} | ConvertTo-Json

$r = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" `
  -Method POST -Headers $headers -Body $body
Write-Host "✅ Claude-3.5: Available"
```

---

## Next Steps

1. **Set API keys** in `.env` file
2. **Choose primary model** (recommend: GPT-4o for reasoning, Claude for guidance)
3. **Deploy with model config**: `docker-compose up -d`
4. **Verify models**: Run healthcheck script above
5. **Monitor costs**: Check `logs/llm-calls.jsonl` weekly

---

**Document Generated**: 2026-08-14  
**Last Updated**: 2026-08-14

