---
description: Bitbucket repository coordinates for the automation codebase — project key, repo slug, default branch, and test folder paths used by automation agents
---

# Automation Repository Configuration

This skill defines **where the automation code lives** in Bitbucket. All automation agents must load this skill before browsing, reading, or writing any automation code.

> **Bitbucket Server** (self-hosted) — base URL: `https://app.example.com

---

## Repository Coordinates

| Setting                | Value                                                                                         |
|------------------------|-----------------------------------------------------------------------------------------------|
| **Bitbucket Server**   | `source-control.example.com`                                                       |
| **Project Key**        | `SIDDEV`                                                                                      |
| **Repository Slug**    | `ac_portal_e2e`                                                                               |
| **Browse URL**         | `https://app.example.com   |
| **Default Branch**     | `windows-STORY-0000-new-release-fix-latest`                          |
| **PR Target Branch**   | `release-fr1.4`                                                     |

> These values are confirmed — no user input required. Automation branches always follow the pattern `automation/{STORY-KEY}` and PRs always target `release-fr1.4`.

---

## Test Folder Structure

| Folder path (relative to repo root)          | Contents                                            |
|----------------------------------------------|-----------------------------------------------------|
| `Tests/Feature tests/`                       | **Feature test specs** — `STORY-{KEY}.spec.js`       |
| `Tests/Epic tests/`                          | Epic-level test specs                               |
| `Tests/Installation Tests/`                  | Installation test specs                             |
| `Pages/`                                     | Page Object classes (`*Page.js`)                    |
| `Pages/CID Pages/`                           | NODE-0000 page objects                           |
| `Pages/Customer Pages/`                      | Customer page objects                               |
| `Pages/OpenLab Servers Pages/`               | OpenLab Server page objects                         |
| `TestData/constantData.json`                 | Shared test constants (users, env vars, URLs)       |
| `Intergration/API_Integration/`              | API helper classes (`apiIntegration.js`, etc.)      |
| `Intergration/CID_Integration/`              | CID SSH/shell integration helpers                   |
| `commonUtils.js`                             | Shared utilities (auth token, random string, etc.)  |
| `test.conf.js`                               | Main Protractor config; `feature` suite = `Tests/Feature tests/*` |

---

## How to Browse the Repository

Use these Bitbucket tools with the coordinates above (Bitbucket Server uses `projectKey` not `workspace`):

```
bitbucket_browse_repository(projectKey: "SIDDEV", repoSlug: "ac_portal_e2e", path: "Tests/Feature tests")
bitbucket_get_file_content(projectKey: "SIDDEV", repoSlug: "ac_portal_e2e", path: "{file_path}", branch: "windows-STORY-0000-new-release-fix-latest")
bitbucket_search(projectKey: "SIDDEV", repoSlug: "ac_portal_e2e", query: "{search_term}")
```

---

## Local Repository Path

The automation agent needs to know where the user has `ac_portal_e2e` checked out locally in order to run git commands and test the automation code.

| Setting                  | Value                                                               |
|--------------------------|---------------------------------------------------------------------|
| **Local clone path**     | `C:\automation\06102026\UI_Protractor_Tests`                       |

> The local clone path has been confirmed. Use this for all git and test runner commands.

---

## Branching Workflow

All automation agents that write or modify code in `ac_portal_e2e` **must** follow this branching workflow. This mirrors the standard developer workflow for the project.

### Step 1 — Sync with Default Branch

Before creating any automation code, pull the latest from the default branch:

```powershell
cd "C:\automation\06102026\UI_Protractor_Tests"
git checkout windows-STORY-0000-new-release-fix-latest
git pull origin windows-STORY-0000-new-release-fix-latest
```

### Step 2 — Create an Automation Branch

Create a dedicated branch for this story's automation work:

```powershell
git checkout -b automation/{STORY-KEY}
```

**Branch naming convention:** `automation/{STORY-KEY}` (e.g., `automation/STORY-0000`)

### Step 3 — Write Automation Code

- Generate and save automation scripts following the framework conventions in `automation-code-standards.md`
- Read existing test files from the default branch via Bitbucket tools to match patterns
- Write generated files directly to `C:\automation\06102026\UI_Protractor_Tests\Tests\Feature tests\` using `run_in_terminal` or `edit/createFile`

### Step 4 — Run and Verify Locally

Run the automation suite scoped to the new test(s) only. Do NOT run the full suite:

```powershell
cd "C:\automation\06102026\UI_Protractor_Tests"
# Protractor — run by spec file:
npx protractor test.conf.js --specs "{path/to/new-spec-file}"
# OR using an include filter if configured:
npx protractor test.conf.js --grep "{STORY-KEY}"
```

> This project uses **Protractor** (Angular E2E). Confirmed config files in repo root: `smoke.conf.js`, `smokeInstallation.conf.js`, `test.conf.js`. Use **`test.conf.js`** for feature test runs.

**Gate:** All new tests must pass locally before proceeding. If any fail — fix and re-run. Do not raise a PR with failing tests.

### Step 5 — Commit

```powershell
cd "C:\automation\06102026\UI_Protractor_Tests"
git add "Tests/Feature tests/"
git commit -m "automation({STORY-KEY}): add E2E tests for {Story Summary}"
```

**Commit message format:** `automation({STORY-KEY}): {brief description}`

### Step 6 — Raise a Pull Request

> **Explicit user confirmation required before raising a PR.** Present the PR details first and ask: "Shall I raise this PR in Bitbucket?"

PR details to confirm with user:

| Field          | Value                                                                        |
|----------------|------------------------------------------------------------------------------|
| **From branch**| `automation/{STORY-KEY}`                                                     |
| **To branch**  | `release-fr1.4`                                                              |
| **Title**      | `automation({STORY-KEY}): E2E tests for {Story Summary}`                     |
| **Description**| See template below                                                           |

**PR Description Template:**
```
## Automation — {STORY-KEY}: {Story Summary}

### Coverage
| TC ID | Test Method | Result |
|-------|-------------|--------|
| TC-{STORY-KEY}-01 | `{MethodName}` | ✅ Pass |

### Test Run Summary
- Tests added: {n}
- All passed locally: Yes
- Framework: {framework}
- Branch: automation/{STORY-KEY} → release-fr1.4

### Related
- Story: {STORY-KEY}
- Automation Plan: docs/Automation/AUT_{STORY-KEY}.md
```

Push the branch and raise the PR via git:

```powershell
cd "C:\automation\06102026\UI_Protractor_Tests"
git push origin automation/{STORY-KEY}
```

Then use Bitbucket tools (`bitbucket_create_pull_request` if available) or provide the PR URL for the user to raise manually.

---

## Execution Status Gate (Automation Code Preparation Only)

Before writing any new automation scripts, the `automation_code_preparation` agent **must** verify that the test execution has passed:

1. Locate the latest execution report: `docs/TestExecution/{sprint-slug}/TE_{STORY-KEY}_Cycle{N}.md`
2. Read the **Step Results Summary** table.
3. Check that:
   - Every step result is `PASS` — no `FAIL`, `BLOCKED`, or blank results exist
   - The overall Xray test run status is `PASS`
4. If **any step is not PASS**:
   - Report: "Test execution for `{STORY-KEY}` has incomplete or failing results. Automation code preparation requires all manual test steps to pass. Resolve the following before proceeding: `{list of non-PASS steps}`"
   - **Stop. Do not write any automation code.**
5. If all steps pass, confirm: "All {n} steps PASSED in Cycle {N}. Proceeding with automation code preparation."
