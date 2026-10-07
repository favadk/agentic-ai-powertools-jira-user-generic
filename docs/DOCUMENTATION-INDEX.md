# Project Documentation Index & Reference Guide

**Version**: 1.0  
**Date**: 2026-08-14  
**Updated**: 2026-08-14

---

## 📚 Centralized Documentation Directory

This guide provides a single reference point for all project documentation, organized by audience and use case.

---

## Quick Navigation by Role

### 👨‍💼 Project Managers / QA Leadership

**Start here:**
1. [QA-WORKFLOW-COMPLETE.md](#qa-workflow-completemdar) — 9-step lifecycle overview with diagram
2. [README.md](#readmemd) — Feature summary and quick-start
3. [docs/Agentic-AI-QA-Framework-Presentation.pptx](#pptx) — Executive presentation

**Key metrics:**
- docs/QA-WORKFLOW-COMPLETE.md → "Key Metrics" section
- monitoring-dashboard.html → Real-time sprint metrics

---

### 👨‍💻 Developers / QA Engineers

**Start here:**
1. [FRAMEWORK-ARCHITECTURE.md](#framework-architecturemd) — Design decisions and architecture
2. [docs/MODEL-LLM-CONFIGURATION.md](#model-llm-configurationmd) — Agent model specifications
3. Agent files (.github/agents/*.agent.md) → Agent responsibilities

**For test execution:**
1. [TEST CASE EXECUTION](#test-case-executionagent-md) → Manual testing workflow
2. [docs/TestCases/](#testcases-directory) → Prepared test cases for your story

**For automation:**
1. [AUTOMATION CODE PREP](#automation-code-preparationagent-md) → Generate test specs
2. [AUTOMATION CODE REVIEW](#automation-code-reviewagent-md) → Code quality gates

---

### 🚀 DevOps / Platform Teams

**Start here:**
1. [DEPLOYMENT-GUIDE.md](#deployment-guidemd) — Complete setup instructions
2. [Dockerfile](#dockerfile) & [docker-compose.yml](#docker-composeyml) — Containerization
3. [docs/MODEL-LLM-CONFIGURATION.md](#model-llm-configurationmd) → LLM credentials & setup

**For cloud deployment:**
- DEPLOYMENT-GUIDE.md → "Cloud Deployment (Azure/AWS)" section
- docker-compose.yml → Multi-container architecture

**For monitoring:**
- monitoring-dashboard.html → Live metrics UI
- DEPLOYMENT-GUIDE.md → "Monitoring & Troubleshooting" section

---

### 📊 QA Analysts / Test Coordinators

**Start here:**
1. [QA-WORKFLOW-COMPLETE.md](#qa-workflow-completemdar) — Test lifecycle gates
2. monitoring-dashboard.html → Sprint cycles & pass rates
3. [docs/TestExecution/](#testexecution-directory) → Execution reports

**For test planning:**
- docs/QAPlan/ → Generated sprint QA plans
- docs/TestCases/ → Prepared test cases
- .github/agents/test_case_review.agent.md → Standard, impact, post-update, and Xray test-comment reviews
- .github/skills/smoke-prerequisite-gate.md → Mandatory smoke and smoke-install gate for installation-related stories
- docs/TestExecution/ → Execution cycles & evidence

---

## 📋 Complete File Reference

### Core Documentation

#### `README.md`
**Purpose**: Project overview, features, and getting started  
**Audience**: Everyone  
**Contains**:
- Feature list (9-step workflow, automation, monitoring)
- One-command setup
- File structure overview
- Quick troubleshooting

**When to use**: Initial project overview, sharing with stakeholders

---

#### `docs/FRAMEWORK-ARCHITECTURE.md`
**Purpose**: Design decisions, algorithms, API endpoints, and data flows  
**Audience**: Developers, QA engineers, architects  
**Contains**:
- Trigger system architecture (7 trigger types)
- Agent responsibility matrix
- Sub-task lifecycle definition
- Jira/Xray API integration patterns
- Data model (monitor-state.json schema)
- Design decisions & trade-offs

**When to use**: Understanding how system works, troubleshooting complex issues, extending functionality

---

#### `docs/DEPLOYMENT-GUIDE.md`
**Purpose**: Complete deployment guide for single machine, Docker, and cloud  
**Audience**: DevOps, platform teams, QA leadership  
**Contains**:
- Prerequisites checklist
- Quick start (6 steps)
- Docker deployment with docker-compose
- Azure ACI & AWS ECS/Fargate deployment
- Configuration & customization
- Monitoring & troubleshooting
- Rollback procedures
- Support contacts

**When to use**: Setting up framework for your team, troubleshooting deployment issues, scaling to production

---

#### `docs/QA-WORKFLOW-COMPLETE.md`
**Purpose**: Complete workflow diagram with all gates and sequences  
**Audience**: Everyone (visual reference)  
**Contains**:
- 9-step QA lifecycle with Mermaid flowchart
- Gate summary table (Gates 0–0E with blocking criteria)
- Sub-task lifecycle tracking
- Agent chain sequence
- Monitor-driven automation overview
- Key design principles

**When to use**: Understanding workflow flow, presentations, onboarding new team members

---

#### `docs/MODEL-LLM-CONFIGURATION.md` (NEW)
**Purpose**: Model selection, API keys, cost optimization, and safety guidelines  
**Audience**: DevOps, QA engineers, product managers  
**Contains**:
- Recommended model matrix per agent
- GPT-4o vs Claude-3.5 specifications
- Environment variable configuration
- Cost estimates per sprint
- Model fallback logic & decision tree
- AI safety & compliance audit trail
- Troubleshooting model selection issues

**When to use**: Configuring LLM setup, optimizing costs, debugging model availability issues

---

### Agent Specification Files

**Location**: `.github/agents/`  
**Format**: Markdown with YAML frontmatter

#### `.github/agents/sprint_story_qa_plan.agent.md`
**Role**: Generate QA plans for all sprint stories  
**Triggers**: Manual invocation (beginning of sprint)  
**Output**: docs/QAPlan/QAP_{STORY-KEY}.md  
**When to use**: Sprint planning, creating QA checklist for all stories

---

#### `.github/agents/test_case_preparation.agent.md`
**Role**: Create test cases from acceptance criteria  
**Triggers**: CREATE_TEST_CASE (story In Dev + no Xray Test)  
**Output**: 
- docs/TestCases/{sprint}/TC_{STORY-KEY}.md (local)
- Xray Test issue in Jira
**Handles**:
- AC parsing
- Context-first Q&N gate (impacted APIs + design references + code/PR evidence)
- Test step generation (40+ steps typical)
- Xray Test creation with all steps

**When to use**: Starting test case creation workflow

---

#### `.github/agents/test_case_review.agent.md`
**Role**: Review test cases against acceptance criteria  
**Triggers**: Auto-trigger on Xray Test status = "Ready for Test Review"  
**Output**: docs/TestCaseReview/TCR_{TC-KEY}.md  
**Handles**:
- AC vs test step gap analysis (High/Med/Low priority)
- Impact mapping from changed files/APIs to TC coverage
- Feedback comments on Xray Test
- Status transitions (sub-task to Closed if approved)

**When to use**: After test case creation, verifying quality

---

#### `.github/agents/test_case_execution.agent.md`
**Role**: Execute test steps one by one, attach evidence  
**Triggers**: Auto-trigger on sub-task "Review Test Case" = Closed  
**Pre-requisites**:
- Story status = "Waiting for Verification"
- PR merged
- Xray Test = "Active"
**Output**: docs/TestExecution/{sprint}/TE_{STORY-KEY}_Cycle{N}.md  
**Handles**:
- Step-by-step execution guidance
- Screenshot evidence per step
- Defect logging on failures
- Sub-task transitions (Execute → In Dev, Results Review → Ready for Verification)

**When to use**: Manual testing phase

---

#### `.github/agents/test_case_evidence_review.agent.md`
**Role**: Review execution evidence quality (screenshots, logs)  
**Triggers**: Auto-trigger after all test steps PASS  
**Output**: docs/EvidenceReview/ER_{STORY-KEY}_Cycle{N}.md  
**Handles**:
- Screenshot quality assessment
- Defect evidence validation
- Gap identification (High/Med/Low)
- Sub-task closure (Test Results Review → Closed)

**When to use**: After execution, before automation begins

---

#### `.github/agents/automation_code_preparation.agent.md`
**Role**: Generate automation test specifications  
**Triggers**: Auto-trigger after evidence review APPROVED  
**Output**:
- docs/Automation/AUT_{STORY-KEY}.md (local)
- Automation spec file (e.g., STORY-0000.spec.js)
**Handles**:
- Protractor spec generation from test steps
- Page object mapping
- Data-driven test parameters

**When to use**: Converting manual tests to automation

---

#### `.github/agents/automation_code_review.agent.md`
**Role**: Review automation code for quality and coverage  
**Triggers**: Auto-trigger after automation spec created  
**Output**: docs/Automation/AUTR_{STORY-KEY}.md  
**Handles**:
- Code style review (Protractor conventions)
- Coverage analysis
- Maintainability assessment
- Approval gates

**When to use**: Quality gate before automation execution

---

#### `.github/agents/automation_run_publish.agent.md`
**Role**: Execute automation suite, publish results, add to regression  
**Triggers**: Auto-trigger after code review APPROVED  
**Output**:
- docs/Automation/AUTRPT_{STORY-KEY}_Run{N}.md (results)
- Git commit (add to regression suite)
**Handles**:
- Test execution via Protractor
- Result parsing & status transitions
- Regression suite integration
- Jira defect creation for failures

**When to use**: Running automated tests

---

#### `.github/agents/story_monitor.agent.md`
**Role**: Monitor story changes and route triggers to appropriate agents  
**Triggers**: Detects JSON files in scripts/triggers/  
**Routing**:
- CREATE_TEST_CASE → test_case_preparation
- DESCRIPTION_CHANGE → test_case_preparation (AC update loop)
- STATUS_CHANGE → evaluate & route appropriately
- SPRINT_CHANGE → create a fresh sprint TE and relink story, Xray Test, and TE
- EXECUTE_TEST_CASE → verify TE/test-run readiness and hand off to test_case_execution
- PO_RESPONSE → resume test_case_preparation
- READY_TO_RUN → test_case_execution
- WINDOWS_UPDATE → special handling (CI/CD trigger)

**When to use**: Internal routing (no manual invocation)

---

### Skill Library

**Location**: `.github/skills/`  
**Format**: Markdown reference documents

#### `.github/skills/qa-artifact-naming.md`
**Purpose**: Document naming conventions across QA artifacts  
**References**:
- Test case documents: `TC_{STORY-KEY}.md`
- Execution reports: `TE_{STORY-KEY}_Cycle{N}.md`
- Evidence folders: `evidence/{STORY-KEY}-Cycle{N}/`
- Automation specs: `AUT_{STORY-KEY}.md`

**When to use**: Creating new artifacts, finding existing documents

---

#### `.github/skills/story-execution-readiness.md`
**Purpose**: Gates and prerequisites for test execution  
**Defines**:
- Gate 0: Story status = "Waiting for Verification"
- Gate 0B: Sprint TE presence
- Gate 0-Dev: PR merged
- Gate 0D: Xray Test = Active
- Sprint carry-over: never reuse a previous-sprint TE; verify story, Xray Test, and new TE in the active sprint
- Pre-requisites per agent

**When to use**: Verifying execution can begin

---

#### `.github/skills/xray-integration.md`
**Purpose**: Xray Cloud API patterns and conventions  
**Covers**:
- Test creation (New-XrayTest)
- Step addition (Import-XrayCloudTestSteps)
- Test Execution creation (New-XrayTestExecution)
- Step result updates (Set-XrayStepResult)
- Evidence attachment (Add-XrayStepEvidence)
- Status transitions (Set-XrayTestRunStatus)

**When to use**: Understanding Xray workflows, debugging Xray API calls

---

#### `.github/skills/evidence-quality-standards.md`
**Purpose**: Standards for screenshot and log evidence  
**Defines**:
- Screenshot quality (resolution, visibility, focus)
- Log excerpt length (first 20 lines)
- File naming (Step{N}_{Status}.png)
- Defect evidence requirements

**When to use**: Recording evidence during execution

---

#### `.github/skills/defect-creation-pattern.md`
**Purpose**: Standard pattern for creating Sub-task defects  
**Covers**:
- Issue type: Sub-task (never standalone)
- Parent: {STORY-KEY}
- Description format (ADF JSON)
- Required fields: Summary, Priority, Steps to Reproduce, Expected, Actual
- @Dev mention pattern

**When to use**: Logging failures as defects

---

### PowerShell Scripts

**Location**: `scripts/`

#### `scripts/xray-api.ps1`
**Purpose**: Xray Cloud API helper functions  
**Key Functions**:
- New-XrayTest
- Import-XrayCloudTestSteps
- New-XrayTestExecution
- Set-XrayStepResult
- Add-XrayStepEvidence
- Set-XrayTestRunStatus

**When to use**: Any Xray API interaction

---

#### `scripts/monitor-story-changes.ps1`
**Purpose**: Continuous monitor detecting story status/AC changes  
**Writes**: JSON trigger files to scripts/triggers/  
**Runs**: Every 30 min (via Task Scheduler)

**When to use**: Understanding trigger generation

---

#### `scripts/monitor-po-responses.ps1`
**Purpose**: Continuous monitor for PO responses to Q&N comments  
**Writes**: PO_RESPONSE trigger files  
**Runs**: Every 30 min (via Task Scheduler)

**When to use**: Understanding Q&N loop

---

#### `scripts/build-agent-activity-log.ps1`
**Purpose**: Builds `scripts/agent-activity-log.json` for dashboard sections **Agent Change Log Updates** and **Pending User Actions**  
**Reads**: QA plans, test-case review comment docs, automation reports, and trigger files  
**Runs**: Manually or via VS Code task `QA: Build Agent Activity Log`

**When to use**: Refreshing dashboard activity data after agent updates

---

### Template Files

**Location**: `docs/_TEMPLATES/`

#### `QASprintPlanTemplate.md`
Template for sprint QA plans with checklist per story

#### `TestCasePlanTemplate.md`
Template for test case documents with structure

#### `TestCaseExecutionTemplate.md`
Template for test execution reports with step-by-step details

#### `ImpactAnalysisTemplate.md`
Template for change impact analysis

#### `EnvironmentMatrixTemplate.md`
Template for project compatibility matrix (browsers, OS, devices)

**When to use**: Creating new artifacts from scratch

---

### Directory Structure

#### `docs/QAPlan/`
**Contents**: Generated sprint QA plans  
**Format**: `QAP_{SPRINT}.md`  
**Created by**: sprint_story_qa_plan agent

#### `docs/TestCases/{sprint-slug}/`
**Contents**: Prepared test case documents  
**Format**: `TC_{STORY-KEY}.md`  
**Created by**: test_case_preparation agent

#### `docs/TestCaseReview/`
**Contents**: Test case review findings  
**Format**: `TCR_{TC-KEY}.md`  
**Created by**: test_case_review agent

#### `docs/TestExecution/{sprint-slug}/`
**Contents**: Test execution reports  
**Format**: `TE_{STORY-KEY}_Cycle{N}.md`  
**Sub-directory**: `evidence/{STORY-KEY}-Cycle{N}/` (screenshots)  
**Created by**: test_case_execution agent

#### `docs/EvidenceReview/`
**Contents**: Evidence review approval documents  
**Format**: `ER_{STORY-KEY}_Cycle{N}.md`  
**Created by**: test_case_evidence_review agent

#### `docs/Automation/`
**Contents**: Automation code and results  
**Formats**:
- `AUT_{STORY-KEY}.md` (plan)
- `AUTR_{STORY-KEY}.md` (review)
- `AUTRPT_{STORY-KEY}_Run{N}.md` (results)
- `{STORY-KEY}.spec.js` (Protractor spec)  
**Created by**: automation agents

#### `docs/_REFERENCES/`
**Contents**: External documentation links and references

---

## 🔍 How to Find What You Need

### By Task

**I need to create test cases for my story**
→ Agent: test_case_preparation  
→ Doc: [TEST CASE PREPARATION](#test-case-preparationagent-md)  
→ Template: docs/_TEMPLATES/TestCasePlanTemplate.md

**I need to execute tests manually**
→ Agent: test_case_execution  
→ Doc: [TEST CASE EXECUTION](#test-case-executionagent-md)  
→ Output: docs/TestExecution/{sprint}/TE_{KEY}_Cycle{N}.md

**I need to generate automation code**
→ Agent: automation_code_preparation  
→ Doc: [AUTOMATION CODE PREP](#automation-code-preparationagent-md)  
→ Output: docs/Automation/AUT_{KEY}.md + {KEY}.spec.js

**I need to deploy this framework**
→ Doc: [DEPLOYMENT-GUIDE.md](#deployment-guidemd)  
→ Files: Dockerfile, docker-compose.yml

**I need to understand the workflow**
→ Doc: [QA-WORKFLOW-COMPLETE.md](#qa-workflow-completemdar)  
→ Visual: Mermaid diagram in markdown

**I need to select an LLM model**
→ Doc: [MODEL-LLM-CONFIGURATION.md](#model-llm-configurationmd)  
→ Config: .env file + docker-compose.yml

**I need to troubleshoot an agent**
→ Doc: [FRAMEWORK-ARCHITECTURE.md](#framework-architecturemd) → Debug section  
→ File: .github/agents/{agent-name}.agent.md

---

## 📞 Support & Escalation

### By Issue Type

| Issue | Document | Contact |
|-------|----------|---------|
| "How do I set up the framework?" | DEPLOYMENT-GUIDE.md | DevOps: devops@company.atlassian.net |
| "Which model should I use?" | MODEL-LLM-CONFIGURATION.md | QA: qa-framework@company.atlassian.net |
| "How does the workflow work?" | QA-WORKFLOW-COMPLETE.md | QA Lead: qa-lead@company.atlassian.net |
| "Agent is failing" | .github/agents/{agent}.agent.md | Dev: dev-team@company.atlassian.net |
| "Tests aren't auto-triggering" | FRAMEWORK-ARCHITECTURE.md | DevOps: devops@company.atlassian.net |
| "I need to add a custom agent" | agent-customization.md | Copilot: copilot-admin@company.atlassian.net |

---

## 📊 Documentation Maintenance

### Last Updated

| Document | Updated | By | Change |
|----------|---------|-----|--------|
| DEPLOYMENT-GUIDE.md | 2026-08-14 | QA Team | Initial v1.0 |
| QA-WORKFLOW-COMPLETE.md | 2026-08-14 | QA Team | Added gates & sub-task tracking |
| MODEL-LLM-CONFIGURATION.md | 2026-08-14 | QA Team | New: Model selection guide |
| FRAMEWORK-ARCHITECTURE.md | 2026-08-14 | Dev Team | Updated agent matrix |

**Next Review**: 2026-09-14 (monthly)

---

## 🚀 Quick Links

| Resource | Link |
|----------|------|
| Project Repo | https://github.com/your-org/agentic-ai-powertools-jira-user-generic |
| README | [README.md](../README.md) |
| Architecture | [FRAMEWORK-ARCHITECTURE.md](FRAMEWORK-ARCHITECTURE.md) |
| Deployment | [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) |
| Workflow Diagram | [QA-WORKFLOW-COMPLETE.md](QA-WORKFLOW-COMPLETE.md) |
| Model Config | [MODEL-LLM-CONFIGURATION.md](MODEL-LLM-CONFIGURATION.md) |
| Monitoring UI | [monitoring-dashboard.html](../monitoring-dashboard.html) |
| Agents | [.github/agents/](.github/agents/) |
| Skills | [.github/skills/](.github/skills/) |

---

**Document Version**: 1.0  
**Created**: 2026-08-14  
**Last Updated**: 2026-08-14  
**Next Review**: 2026-09-14

