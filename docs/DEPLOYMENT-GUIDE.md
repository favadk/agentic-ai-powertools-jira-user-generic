# Agentic AI QA Framework — Deployment Guide

**Version**: 1.0  
**Date**: 2026-08-14  
**Target Audience**: DevOps, QA Leadership, Teams across organization  

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start (Single Machine)](#quick-start-single-machine)
4. [Docker Deployment (Recommended)](#docker-deployment-recommended)
5. [Cloud Deployment (Azure/AWS)](#cloud-deployment-azureaws)
6. [Configuration & Customization](#configuration--customization)
7. [Monitoring & Troubleshooting](#monitoring--troubleshooting)
8. [Support & Rollback](#support--rollback)

---

## Overview

The **Agentic AI QA Framework** is a fully automated, trigger-driven QA lifecycle system that:

- ✅ Automatically detects story status/AC changes via continuous monitoring
- ✅ Invokes 9 specialized GitHub Copilot agents in sequence (test case prep → review → execution → evidence → automation)
- ✅ Executes manual + automated tests with full screenshot evidence per step
- ✅ Manages sub-task lifecycle and team coordination via Jira @mentions
- ✅ Builds regression suite incrementally with every passing story
- ✅ Requires **zero manual invocation** after setup

**Deployable as:**
- Standalone Windows service (Task Scheduler)
- Docker container (containerized backend + UI)
- Cloud-native (Azure Container Instances, AWS ECS/Fargate)
- Hybrid (on-premises monitoring + cloud agents)

---

## Prerequisites

### 1. Documentation Reference

**Before starting deployment, review the centralized documentation:**

- **[DOCUMENTATION-INDEX.md](DOCUMENTATION-INDEX.md)** — Complete reference guide for all project docs
  - Quick navigation by role (PM, Developer, DevOps, QA)
  - File reference for all agents, skills, and templates
  - Support contacts by issue type

- **[MODEL-LLM-CONFIGURATION.md](MODEL-LLM-CONFIGURATION.md)** — LLM model selection and setup
  - Recommended models per agent (GPT-4o, Claude-3.5-Sonnet)
  - API key configuration for OpenAI & Anthropic
  - Cost optimization tips
  - Model fallback logic

**Action**: Read DOCUMENTATION-INDEX.md to understand your role and find relevant docs.

### 2. Jira & Xray Setup

**Required:**
- Jira Cloud or Server (API v3 access)
- Xray Cloud (test management plugin)
- Project key assigned (e.g., `STORY`, `CID`)
- Active sprint with board configured

**Service Account:**
- Jira API token (user with QA permissions)
- Xray Cloud API credentials
- Jira GraphQL endpoint access

**Create a service account:**
```bash
# In Jira Administration → Users
Email:        qa-automation@company.atlassian.net
Display Name: QA Automation Service
Permissions:  Browse Projects, Create Issues, Comment on Issues, Transition Issues, Link Issues
               (Add to your QA project group)
```

**Generate API token:**
1. Log in as the service account
2. Go to **Settings → Security → API Tokens**
3. Click **Create API Token**
4. Copy and store securely in a password manager

### 2. GitHub Copilot Integration

**Required:**
- GitHub Copilot subscription (enterprise or individual)
- VS Code with Copilot extension
- Access to custom agents & skills (`.github/agents/`, `.github/skills/`)

**Verify Copilot is enabled:**
```powershell
# In VS Code: Ctrl+Shift+P → "Copilot: Show Logs"
# Confirm agent list and skill files load without errors
```

### 3. System Requirements

| Component | Requirement |
|-----------|-------------|
| OS | Windows 10+ or Linux (Ubuntu 20.04+) with WSL2 |
| PowerShell | 5.1+ (Windows) or 7.0+ (cross-platform) |
| Node.js | 16.0+ (for Protractor automation) |
| Docker | 20.10+ (for containerized deployment) |
| Git | 2.30+ |
| Disk Space | ~2 GB (framework + docs + evidence) |

### 4. Network Access

**Required outbound:**
- `issue-tracker.example.com` (Jira Cloud)
- `api.github.com` (GitHub Copilot)
- Your CID/product test environment (for network tests)

**Optional inbound:**
- Port 8080 (registration UI)
- Port 9000 (monitoring dashboard — if deployed)

---

## Quick Start (Single Machine)

### Wizard-First Setup (Fastest Path)

If you want guided setup after cloning, run:

```powershell
cd C:\Projects\agentic-ai-powertools-jira-user-generic
.\setup-wizard\Start-SetupWizard.ps1
```

This opens `http://localhost:7420` and provides a UI for:
1. Target project path and Jira board/project values
2. Jira/Xray credentials
3. Bitbucket repo settings (server, project, repo, branch targets)
4. Documentation/integration links
5. LLM provider and model setup (Ollama/OpenAI/Anthropic)
6. Optional scheduler registration

Use the step-by-step CLI flow below if you prefer manual setup.

### Step 1: Clone Repository

```powershell
cd C:\Projects  # or your workspace location
git clone https://github.com/your-org/agentic-ai-powertools-jira-user-generic.git
cd agentic-ai-powertools-jira-user-generic
```

### Step 2: Configure Credentials

**Create `.env` file in repository root:**

```bash
# .env (do NOT commit to git)

# ========== Jira Configuration ==========
JIRA_URL=https://app.example.com
JIRA_USER=qa-automation@company.atlassian.net
JIRA_API_TOKEN=<paste-your-api-token-here>
JIRA_PROJECT_KEY=STORY

# ========== Xray Cloud Configuration ==========
XRAY_CLOUD_CLIENT_ID=<from-xray-admin>
XRAY_CLOUD_CLIENT_SECRET=<from-xray-admin>

# ========== GitHub Integration ==========
GITHUB_TOKEN=<your-github-personal-access-token>

# ========== LLM / Copilot Model Configuration ==========
# See docs/MODEL-LLM-CONFIGURATION.md for complete guide
COPILOT_MODEL_PRIMARY=gpt-4o           # Primary model (GPT-4o recommended)
COPILOT_MODEL_FALLBACK_1=claude-3-5-sonnet-20241022  # Fallback model

# OpenAI API (for GPT-4o)
OPENAI_API_KEY=<your-openai-api-key>
OPENAI_ORG_ID=<optional-org-id>
OPENAI_TEMPERATURE=0.2
OPENAI_MAX_TOKENS=4096

# Anthropic API (for Claude fallback)
ANTHROPIC_API_KEY=<your-anthropic-api-key>
ANTHROPIC_TEMPERATURE=0.3
ANTHROPIC_MAX_TOKENS=2048

# ========== QA Framework Configuration ==========
SPRINT_SLUG=sample-sprint
ACTIVE_BOARD_ID=440
PRODUCT_NAME=CID
ENVIRONMENT=DEV
```

**Important Model Selection:**

Refer to [docs/MODEL-LLM-CONFIGURATION.md](MODEL-LLM-CONFIGURATION.md) for:
- Which model to use per agent
- API key setup for OpenAI & Anthropic
- Cost estimates per sprint
- Model fallback behavior

**Store in secure location:**
```powershell
# Windows Credential Manager
cmdkey /add:Jira /user:qa-automation@company.atlassian.net /pass:<token>
cmdkey /add:XrayCloud /user:<client-id> /pass:<client-secret>
```

### Step 3: Install Dependencies

```powershell
# PowerShell modules
Install-Module -Name Az.Automation -Repository PSGallery -Force
Install-Module -Name PSScheduledJob -Force

# Node.js packages (for automation)
npm install -g protractor
cd tests
npm install
cd ..
```

### Step 4: Setup Scheduled Monitors

**Run with Admin privileges:**

```powershell
# Right-click PowerShell → "Run as Administrator"
cd C:\Projects\agentic-ai-powertools-jira-user-generic
.\scripts\setup-story-monitor-scheduler.ps1
```

**Custom frequency (example: every 60 minutes):**

```powershell
.\scripts\setup-story-monitor-scheduler.ps1 -IntervalMinutes 60
```

`-IntervalMinutes` applies to the story monitor, PO response monitor, comment review processor, and agent trigger dispatcher tasks.

**Verify tasks were created:**

```powershell
Get-ScheduledTask -TaskName "QA-Monitor-*" | Select-Object TaskName, State, NextRunTime
```

**Expected output:**
```
TaskName                 State   NextRunTime
--------                 -----   -----------
QA-Monitor-Story-Changes Enabled 2026-08-14 13:00:00
QA-Monitor-PO-Responses  Enabled 2026-08-14 13:15:00
```

### Step 5: Verify Setup

**Test Jira API connectivity:**

```powershell
. .\scripts\xray-api.ps1
$creds = Get-XrayCreds
$r = Invoke-RestMethod -Uri "$env:JIRA_URL/rest/api/3/projects/$env:JIRA_PROJECT_KEY" -Headers $creds.Headers
Write-Host "✅ Connected to Jira project: $($r.name)"
```

**Test monitor execution (manual trigger):**

```powershell
. .\scripts\xray-api.ps1
.\scripts\monitor-story-changes.ps1 -PostAck
# Check scripts/triggers/ for generated JSON files
```

### Step 6: Register with UI (Optional)

**Start registration wizard:**

```powershell
.\setup-wizard\Start-SetupWizard.ps1
# Opens http://localhost:7420 in default browser
```

**Complete the setup wizard screens:**
1. Project path and Jira board/project
2. Jira and Xray credentials
3. Bitbucket repository settings
4. Documentation and integration references
5. LLM provider/model configuration
6. Review and generate setup

---

## Docker Deployment (Recommended)

### Build & Run Container

**Create `Dockerfile`:**

```dockerfile
FROM mcr.microsoft.com/powershell:latest

# Install dependencies
RUN pwsh -Command \
    Install-Module -Name Az.Automation -Force; \
    apt-get update && apt-get install -y \
    git curl nodejs npm && \
    npm install -g protractor && \
    rm -rf /var/lib/apt/lists/*

# Copy framework
COPY . /app
WORKDIR /app

# Install Node dependencies
RUN cd /app && npm install

# Expose ports
EXPOSE 8080 9000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD pwsh -Command "Test-Path /app/scripts/monitor-state.json"

# Start monitors
CMD ["pwsh", "-Command", "& {. ./scripts/xray-api.ps1; ./scripts/monitor-story-changes.ps1 -PostAck; ./scripts/monitor-po-responses.ps1 -PostAck; while($true) { Start-Sleep -Seconds 1800; & ./scripts/monitor-story-changes.ps1 -PostAck; & ./scripts/monitor-po-responses.ps1 -PostAck }}"]
```

**Create `docker-compose.yml`:**

```yaml
version: '3.9'

services:
  qa-framework:
    build: .
    container_name: agentic-qa-framework
    restart: unless-stopped
    environment:
      JIRA_URL: ${JIRA_URL}
      JIRA_USER: ${JIRA_USER}
      JIRA_API_TOKEN: ${JIRA_API_TOKEN}
      JIRA_PROJECT_KEY: ${JIRA_PROJECT_KEY}
      XRAY_CLOUD_CLIENT_ID: ${XRAY_CLOUD_CLIENT_ID}
      XRAY_CLOUD_CLIENT_SECRET: ${XRAY_CLOUD_CLIENT_SECRET}
      GITHUB_TOKEN: ${GITHUB_TOKEN}
      SPRINT_SLUG: ${SPRINT_SLUG}
    ports:
      - "8080:8080"  # Registration UI
      - "9000:9000"  # Monitoring dashboard
    volumes:
      - ./docs:/app/docs
      - ./scripts:/app/scripts
      - ./.github:/app/.github
    healthcheck:
      test: ["CMD", "pwsh", "-Command", "Test-Path /app/scripts/monitor-state.json"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s

  ui-server:
    image: node:16-alpine
    container_name: qa-ui-server
    working_dir: /app
    command: npx http-server ./setup-wizard -p 8080 -c-1
    ports:
      - "8080:8080"
    volumes:
      - ./setup-wizard:/app
    restart: unless-stopped
```

**Deploy:**

```bash
# Set environment variables
export JIRA_URL=https://app.example.com
export JIRA_USER=qa-automation@company.atlassian.net
export JIRA_API_TOKEN=<token>
export JIRA_PROJECT_KEY=STORY
export XRAY_CLOUD_CLIENT_ID=<id>
export XRAY_CLOUD_CLIENT_SECRET=<secret>
export GITHUB_TOKEN=<token>
export SPRINT_SLUG=sample-sprint

# Build and start
docker-compose up -d

# Verify
docker-compose ps
docker-compose logs -f qa-framework
```

**Access services:**
- Registration UI: `http://localhost:8080`
- Monitoring Dashboard: `http://localhost:9000`

### Multi-Container Architecture

For production deployments, use separate containers:

```yaml
services:
  monitor-service:
    build: .
    environment: # (all vars)
    command: ["pwsh", "-Command", "./scripts/monitor-story-changes.ps1 -Daemon"]
    restart: always

  agent-service:
    build: .
    environment: # (all vars)
    ports:
      - "9001:9001"  # Agent RPC
    command: ["pwsh", "-Command", "Start-GithubCopilotServer -Port 9001"]
    restart: always

  ui-service:
    image: node:16-alpine
    ports:
      - "8080:8080"
    command: npx http-server ./setup-wizard -p 8080
    restart: always

  dashboard-service:
    build: ./dashboard  # New service (see next section)
    ports:
      - "9000:9000"
    environment:
      JIRA_URL: ${JIRA_URL}
      DB_HOST: postgres
    depends_on:
      - postgres
    restart: always

  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: qa_metrics
      POSTGRES_USER: qa_admin
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - qa_db:/var/lib/postgresql/data
    restart: always

volumes:
  qa_db:
```

---

## Cloud Deployment (Azure/AWS)

### Azure Container Instances (ACI)

```bash
# Create resource group
az group create --name agentic-qa-rg --location eastus

# Create container registry
az acr create --resource-group agentic-qa-rg --name aqiregistry --sku Basic

# Build and push image
az acr build --registry aqiregistry --image agentic-qa:latest .

# Deploy to ACI
az container create \
  --resource-group agentic-qa-rg \
  --name agentic-qa-container \
  --image aqiregistry.azurecr.io/agentic-qa:latest \
  --cpu 2 --memory 4 \
  --registry-login-server aqiregistry.azurecr.io \
  --registry-username <username> \
  --registry-password <password> \
  --environment-variables \
    JIRA_URL=https://app.example.com \
    JIRA_PROJECT_KEY=STORY \
  --secure-environment-variables \
    JIRA_API_TOKEN=$JIRA_API_TOKEN \
    XRAY_CLOUD_CLIENT_SECRET=$XRAY_CLOUD_CLIENT_SECRET \
  --ports 8080 9000 \
  --ip-address public
```

### AWS ECS Fargate

```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name agentic-qa-cluster

# Register task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# Create service
aws ecs create-service \
  --cluster agentic-qa-cluster \
  --service-name agentic-qa-service \
  --task-definition agentic-qa:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration \
    "awsvpcConfiguration={subnets=[subnet-xxxxx],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}"
```

---

## Configuration & Customization

### Customize for Your Project

**Edit `scripts/monitor-state.json`:**

```json
{
  "sprintWatch": {
    "enabled": true,
    "boardId": 440,           // Your board ID
    "sprintName": "sample-sprint",
    "projectKey": "STORY"      // Your project key
  },
  "qaTeamGroupEmail": "qa-team@company.atlassian.net",
  "slackWebhookUrl": "https://hooks.slack.com/services/...",  // Optional
  "automationRepositoryUrl": "https://github.com/your-org/ui-tests.git",
  "regressionSuitePath": "test.conf.js",
  "issues": []
}
```

### Customize Agent Behavior

**Edit agent YAML frontmatter** (`.github/agents/*.agent.md`):

```yaml
---
description: "..."
tools: [...]
instructions:
  - ".github/skills/qa-artifact-naming.md"
  - ".github/skills/story-execution-readiness.md"
---
```

**Add skill references** (`.github/skills/*.md`):
- `qa-artifact-naming.md` — document naming conventions
- `story-execution-readiness.md` — gates and prerequisites
- `xray-integration.md` — Xray-specific logic
- `evidence-quality-standards.md` — screenshot/log standards

### Customize Monitor Triggers

**Edit `scripts/monitor-story-changes.ps1`:**

```powershell
# Around line 120: Add custom trigger types
if ($issueType -eq "Defect") {
    $trigger = @{
        changeType = "REGRESSION_TEST"  # New trigger type
        issueKey = $key
        # ...
    }
    # Write trigger JSON
}

# Route in story_monitor.agent.md:
# REGRESSION_TEST → automation_code_review (skip prep/review, go straight to automation)
```

---

## Monitoring & Troubleshooting

### Health Checks

**Monitor task status:**

```powershell
# Check if monitors are running
Get-ScheduledTask -TaskName "QA-Monitor-*" | ForEach-Object {
    $lastRun = $_.LastRunTime
    $nextRun = $_.NextRunTime
    Write-Host "$($_.TaskName): Last=$lastRun, Next=$nextRun"
}

# Review logs
Get-EventLog -LogName "Windows PowerShell" -Source PowerShell -Newest 20
```

**Check trigger backlog:**

```powershell
Get-ChildItem .\scripts\triggers\*.json | Measure-Object
# If count > 50, monitors may be falling behind
```

**Validate Jira connectivity:**

```powershell
. .\scripts\xray-api.ps1
$creds = Get-XrayCreds
$r = Invoke-RestMethod -Uri "$env:JIRA_URL/rest/api/3/projects/$env:JIRA_PROJECT_KEY/recent" -Headers $creds.Headers
Write-Host "Recent issues: $($r.Length)"
```

### Common Issues

| Issue | Symptom | Fix |
|-------|---------|-----|
| **Monitors not running** | No triggers written to `scripts/triggers/` | Run `setup-story-monitor-scheduler.ps1` again; check Task Scheduler |
| **Jira API 401** | "Unauthorized" error in logs | Regenerate JIRA_API_TOKEN; verify service account has QA permissions |
| **Agents not auto-chaining** | story_monitor agent not invoked | Verify `.github/agents/story_monitor.agent.md` exists; check GitHub Copilot logs |
| **Evidence upload fails** | Screenshots not attaching to Xray | Verify Xray Cloud API credentials; check file path permissions |
| **Docker build fails** | Node packages missing | Add `npm install` to Dockerfile post-copy |

### Logging & Debugging

**Enable verbose logging:**

```powershell
$PSDefaultParameterValues['*:Verbose'] = $true
.\scripts\monitor-story-changes.ps1 -Verbose
```

**Docker container logs:**

```bash
docker-compose logs -f qa-framework
docker-compose logs -f --tail=100 qa-framework | grep -i error
```

**Review trigger processing:**

```powershell
# Check which triggers were processed
Get-ChildItem .\scripts\triggers\*.processed
# Re-process a failed trigger
Copy-Item .\scripts\triggers\STORY-0000-create-tc.json.processed .\scripts\triggers\STORY-0000-create-tc.json
```

---

## Support & Rollback

### Rollback Procedure

**If deployment causes issues:**

```powershell
# 1. Disable monitors immediately
Disable-ScheduledTask -TaskName "QA-Monitor-Story-Changes"
Disable-ScheduledTask -TaskName "QA-Monitor-PO-Responses"

# 2. Restore previous version
git checkout HEAD~1

# 3. Run tests
.\scripts\test-framework.ps1

# 4. Re-enable if tests pass
Enable-ScheduledTask -TaskName "QA-Monitor-Story-Changes"
Enable-ScheduledTask -TaskName "QA-Monitor-PO-Responses"
```

### Support Contacts

| Role | Contact | Timezone |
|------|---------|----------|
| QA Framework Owner | qa-framework@company.atlassian.net | PST |
| GitHub Copilot Admin | copilot-admin@company.atlassian.net | PST |
| Jira Admin | jira-admin@company.atlassian.net | PST |
| DevOps | devops@company.atlassian.net | PST |

### Documentation & Training

- **Framework Overview**: `docs/FRAMEWORK-ARCHITECTURE.md`
- **Workflow Diagram**: `docs/QA-WORKFLOW-COMPLETE.md` (this file)
- **Agent Skills**: `.github/skills/`
- **PowerShell Modules**: `scripts/xray-api.ps1`

**Training sessions:**
- Weekly: "QA Framework Q&A" (1 hour)
- Monthly: "Advanced Agent Customization" (2 hours)
- On-demand: Agent/skill troubleshooting

---

## Deployment Checklist

**Documentation & Reference Setup:**
- [ ] Read [DOCUMENTATION-INDEX.md](DOCUMENTATION-INDEX.md) to find relevant docs for your role
- [ ] Review [MODEL-LLM-CONFIGURATION.md](MODEL-LLM-CONFIGURATION.md) for model selection
- [ ] Bookmark agent files in `.github/agents/` for workflow reference

**Infrastructure & Credentials:**
- [ ] Prerequisites met (Jira, Xray, Copilot, PowerShell)
- [ ] `.env` file created with all credentials (Jira, Xray, OpenAI/Anthropic)
- [ ] Jira API credentials tested
- [ ] LLM API keys verified (OpenAI and/or Anthropic)

**Deployment Execution:**
- [ ] Monitors scheduled (or Docker deployed)
- [ ] Registration UI accessible
- [ ] First monitor run completed (check `scripts/triggers/`)

**Verification & Testing:**
- [ ] Story created in sprint and assigned
- [ ] Verify agent auto-invoked via story status change
- [ ] Manual test execution completed (Step 6)
- [ ] Automation suite generated (Step 8)
- [ ] Story transitioned to "Done"

**Team & Documentation:**
- [ ] Team trained on system (use [QA-WORKFLOW-COMPLETE.md](QA-WORKFLOW-COMPLETE.md) for training)
- [ ] Support contacts identified
- [ ] Monitoring dashboard (monitoring-dashboard.html) bookmarked

---

## Deployment Checklist

- [ ] Prerequisites met (Jira, Xray, Copilot, PowerShell)
- [ ] `.env` file created and secured
- [ ] Jira API credentials tested
- [ ] Monitors scheduled (or Docker deployed)
- [ ] Registration UI accessible
- [ ] First monitor run completed (check `scripts/triggers/`)
- [ ] Story created in sprint and assigned
- [ ] Verify agent auto-invoked via story status change
- [ ] Manual test execution completed (Step 6)
- [ ] Automation suite generated (Step 8)
- [ ] Story transitioned to "Done"
- [ ] Team trained on system

---

**Next Steps**: Deploy to your organization and scale QA automation!

