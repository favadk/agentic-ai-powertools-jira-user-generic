---
description: Environment and compatibility matrix — determines which OS, browser, database, device, and ExampleOrg software product version environments a story requires. Covers multi-environment coverage scoping, per-environment test-management executions, evidence requirements, and defect tagging. Includes a Product Version Traceability Matrix for OpenLab Server, OpenLab CDS, instrument drivers, ExampleOrg add-ons, and third-party add-ons — supporting single or multi-environment software version testing driven by a user-defined configuration table.
---

# Test Environment Compatibility

Load this skill in any agent that prepares, executes, or reviews test cases to ensure cross-environment coverage is never missed.

---

## 1. Detection — Does This Story Need Cross-Environment Testing?

Before writing or reviewing any test case, scan the story **summary, description, acceptance criteria, labels, and components** for trigger keywords.

### Trigger keyword table

| Dimension | Keywords that trigger cross-env coverage |
|-----------|------------------------------------------|
| **Browser / Web** | browser, web browser, Chrome, Firefox, Edge, Safari, Internet Explorer, IE, web UI, frontend, front-end, HTML, responsive, viewport, web interface |
| **Operating System** | Windows, macOS, Mac OS, Linux, Ubuntu, operating system, OS, platform, cross-platform |
| **Mobile / Device** | mobile, tablet, iPad, iPhone, Android, responsive design, screen resolution, device |
| **Database** | database, SQL Server, Oracle, MySQL, PostgreSQL, Postgres, DB, data store, RDBMS |
| **General** | compatibility, cross-browser, multi-environment, supported environments, supported platforms |
| **ExampleOrg Software Products** | OpenLab, OpenLab Server, OpenLab CDS, OpenLab ECM, OpenLab ChemStation, ChemStation, instrument driver, ExampleOrg driver, add-on, add-ons, DDK, driver version, firmware version, software version, product version, software compatibility, version compatibility, driver compatibility, service pack, SP1, SP2, SR1, SR2, version matrix |

**Rule**: If ANY trigger keyword is found in ANY of the scanned fields, cross-environment testing is required. Log which dimension(s) were detected.

**If no trigger is found**: The story is single-environment. Use the project's primary environment from the matrix (Section 2) and proceed normally — no special handling needed.

---

## 2. Matrix Resolution — What Environments Apply?

Resolve the project's supported environment matrix in priority order:

### Priority 1 — Workspace config file (most authoritative)

Look for `docs/_TEMPLATES/EnvironmentMatrixTemplate.md` in the workspace. If it exists, read the **Project Environment Matrix** table from it. This is the single source of truth for the project.

### Priority 2 — Story labels / components

Check `fields.labels[]` and `fields.components[]` from the `issue-tracker_get_issue` response. Map known label patterns:

| Label pattern | Meaning |
|--------------|---------|
| `browser-*` | Specific browser required (e.g., `browser-chrome`) |
| `os-*` | Specific OS required (e.g., `os-windows-11`) |
| `db-*` | Specific DB required (e.g., `db-sqlserver`) |
| `cross-browser` | All browsers in project matrix |
| `cross-platform` | All OS in project matrix |
| `env-smoke-only` | P3 tier — primary environment only |

### Priority 3 — Explicit mentions in AC text

If the AC or description explicitly names environments (e.g., "This must work on Chrome and Firefox"), treat those as the required set, regardless of the full matrix.

### Priority 4 — Ask the user (fallback only)

If none of the above yielded a matrix and cross-env keywords were detected, ask the user once:
> "I detected cross-environment requirements in this story but could not find a project compatibility matrix. Please specify which browsers/OS/databases apply, OR fill in `docs/_TEMPLATES/EnvironmentMatrixTemplate.md` and I will read it automatically."

---

## 2B. Product Version Traceability Matrix (ExampleOrg Software)

This section applies when the story involves **ExampleOrg software product version compatibility** — OpenLab Server, OpenLab CDS, instrument drivers, ExampleOrg add-ons, or third-party integrated add-on software.

### When this section activates

Active when **any** of the following are true:
- Section 1 detection found ExampleOrg software trigger keywords in the story
- `docs/_TEMPLATES/EnvironmentMatrixTemplate.md` contains a populated **Software Version Traceability Matrix** table
- Story AC or description explicitly names a software version, service pack, or add-on product

### Matrix structure

Users define the matrix **once** in `docs/_TEMPLATES/EnvironmentMatrixTemplate.md` under the heading `## Software Version Traceability Matrix`. Agents read it automatically on every story.

Each row defines a **named software environment configuration** (Env ID) — a specific combination of product versions installed together. Rows are assigned a coverage tier (P1/P2/P3) that controls when they are included.

```
## Software Version Traceability Matrix

| Env ID  | OpenLab Server | OpenLab CDS       | Instr. Driver | ExampleOrg Add-on       | 3rd-Party Add-on          | Tier |
|---------|----------------|-------------------|---------------|----------------------|---------------------------|------|
| SWE-1   | v2.7 SP2       | v2.7 SP2          | v7.4.3        | GC Backflush v3.1    | None                      | P1   |
| SWE-2   | v2.7 SP1       | v2.7 SP1          | v7.4.2        | GC Backflush v3.1    | Waters MassLynx v2.0      | P2   |
| SWE-3   | v2.6 SR2       | ChemStation C.01.10 | v7.3.5      | None                 | None                      | P3   |
```

### Column definitions

| Column | Required | Description | Example values |
|--------|----------|-------------|----------------|
| **Env ID** | Yes | Short unique identifier — used as label on test-management executions and defects | `SWE-1`, `QA-v27`, `PROD-Baseline` |
| **OpenLab Server** | If applicable | Full version + service pack / service release | `v2.7 SP2`, `v2.6 SR2`, `N/A` |
| **OpenLab CDS** | If applicable | Full version + SP, or product name variant | `v2.7 SP2`, `ChemStation C.01.10`, `N/A` |
| **Instr. Driver** | If applicable | ExampleOrg instrument driver version | `v7.4.3`, `DDK v5.1`, `N/A` |
| **ExampleOrg Add-on** | If applicable | Name + version of each installed ExampleOrg add-on product | `GC Backflush v3.1`, `None` |
| **3rd-Party Add-on** | If applicable | Name + version of each third-party integrated add-on | `Waters MassLynx v2.0`, `None` |
| **Tier** | Yes | P1 / P2 / P3 — controls which story coverage tier includes this row | `P1`, `P2`, `P3` |

> Use `N/A` for a component not installed in that environment. Use `None` for add-on slots not populated.  
> A column not applicable to the project (e.g., 3rd-Party Add-on) may be omitted from the table entirely.

### Single vs. multiple environment support

| Mode | How to configure | Agent behaviour |
|------|-----------------|-----------------|
| **Single environment** | One row in the matrix (Tier = P1) | Agents create one test-management execution regardless of story coverage tier |
| **Multiple environments** | Multiple rows with different Env IDs and Tier values | Agents create one test-management execution per row that matches the story's coverage tier |
| **Story-level override** | Add issue-tracker label `sw-env:SWE-1,SWE-2` to the story | Only the listed Env IDs are tested, ignoring tier rules |

### Coverage tier rules for software environments

| Story coverage tier | Software environments to test |
|--------------------|-------------------------------|
| **P1** | ALL rows in the matrix |
| **P2** (default) | Rows with Tier = P1 or P2 |
| **P3** | Rows with Tier = P1 only |

### How agents use this matrix at each lifecycle stage

**`test_case_preparation`**
1. Read the Software Version Traceability Matrix from `EnvironmentMatrixTemplate.md`
2. Determine applicable Env IDs using the coverage tier rules above
3. Add a **Software** row to the Environment Coverage table in the TC document (see Section 4.1)
4. Annotate steps that behave differently per software version with `[SW-ENV: SWE-1, SWE-2]` (see Section 4.2)
5. For each applicable Env ID, add a version-specific expected result sub-row where outcomes differ (see Section 4.3)

**`test_case_execution`**
1. Create one test-management Test Execution per applicable Env ID
2. Name: `TE {KEY}: {Env ID} — OL CDS {version}` (see Section 5.4)
3. Set the test-management `Environment` field to the Env ID string (e.g., `SWE-1`)
4. Capture an About dialog screenshot as the first evidence item of each execution run (see Section 6)

**`test_case_review`**
1. Check TC includes a Software row in the Environment Coverage table — HIGH finding if missing
2. Verify all applicable Env IDs are listed with their full version strings
3. Check that version-sensitive steps carry `[SW-ENV: ...]` annotations — MEDIUM finding if absent
4. Verify coverage tier is stated and justified against the matrix

---

## 3. Priority Tiers — Scope the Coverage

Not every story needs full matrix testing. Determine the **coverage tier** from the matrix template's "Feature Area Overrides" section, or apply the default rules below.

| Tier | Coverage | Apply when |
|------|----------|-----------|
| **P1 — Full matrix** | All environments in the project matrix | Security, authentication, login/logout, data integrity, compliance features |
| **P2 — Primary + secondary** | Top 2 browsers + primary OS (default) | Most UI features, form interactions, navigation flows |
| **P3 — Smoke only** | Primary browser + primary OS only | Backend-heavy changes with minimal UI surface; admin-only features |

**Default tier is P2** unless the matrix template's "Feature Area Overrides" specifies otherwise or the story AC explicitly references specific environments.

When applying P2, the primary browser is the first entry in the matrix's Browser list. Secondary browser is the second entry.

---

## 4. TC Document Structure — How to Record Environment Coverage

### 4.1 Environment Coverage section (add to TC document header)

Every TC document for a cross-environment story must include an **Environment Coverage** table immediately after the story summary:

```
## Environment Coverage

| Dimension | Required Environments                                                                         | Coverage Tier |
|-----------|-----------------------------------------------------------------------------------------------|---------------|
| Browser   | Chrome Latest, Firefox Latest                                                                 | P2            |
| OS        | Windows 11, macOS 14 Sonoma                                                                   | P2            |
| Database  | N/A                                                                                           | -             |
| Device    | N/A                                                                                           | -             |
| Software  | SWE-1 (OL Server v2.7 SP2 / OL CDS v2.7 SP2), SWE-2 (OL Server v2.7 SP1 / OL CDS v2.7 SP1) | P2            |

> Source: docs/_TEMPLATES/EnvironmentMatrixTemplate.md — last updated {date}
> Omit the Software row when no Software Version Traceability Matrix is defined in the template.
```

If coverage is P3 (smoke only), state:
```
> Coverage Tier: P3 (Smoke) — primary environment only: Chrome Latest / Windows 11
```

### 4.2 Annotating test steps for environment-specific behaviour

If a test step behaves **differently** across environments, annotate it:

```
**Step N** `[ENV: Chrome, Firefox, Edge]`
Action: {action}
Expected: {expected result}

**Step N** `[ENV: Safari only]`
Action: {action}
Expected: {expected result — Safari-specific behaviour, e.g. different date picker UI}
```

If a step applies **equally** to all environments in the matrix, no annotation is needed — it implicitly covers all.

### 4.3 Environment-variant expected results

When expected results differ per environment, use a sub-table:

```
Expected Results:
| Environment          | Expected Outcome                      |
|----------------------|---------------------------------------|
| Chrome / Windows     | Upload completes, file listed in grid |
| Firefox / Windows    | Upload completes, file listed in grid |
| Edge / Windows       | Upload completes, file listed in grid |
| Chrome / macOS       | Upload completes, file listed in grid |
```

---

## 5. test-management Execution Strategy — Running Tests per Environment

### 5.1 Separate test-management Test Execution per environment (preferred)

Create **one test-management Test Execution per environment combination** that must be tested:

```powershell
# Example: P2 coverage with Chrome+Windows and Firefox+Windows
New-test-managementTestExecution `
    -StoryKey   "PROJ-1234" `
    -TestKeys   @("PROJ-1240") `
    -Summary    "TE PROJ-1234: Chrome / Windows 11" `
    -Environment "SIT-Chrome-Win11"

New-test-managementTestExecution `
    -StoryKey   "PROJ-1234" `
    -TestKeys   @("PROJ-1240") `
    -Summary    "TE PROJ-1234: Firefox / Windows 11" `
    -Environment "SIT-Firefox-Win11"
```

**Naming convention for environment executions**:
```
TE {STORY-KEY}: {Browser} / {OS}              ← browser+OS combinations
TE {STORY-KEY}: {DB} on {OS}                  ← database+OS combinations
TE {STORY-KEY}: {Device} / {OS}               ← device+OS combinations
TE {STORY-KEY}: {Env ID} — OL CDS {version}   ← software version environments (Section 2B)
```

### 5.2 Time-constrained fallback — single execution with environment notes

When sprint time is limited and separate executions are not practical, use one execution but:
- Set `Environment` field to the primary environment (e.g., `SIT-Chrome-Win11`)
- Record environment in each step's actual result: `"Tested on: Chrome 126.0.6478 / Windows 11 23H2"`
- Create a note in the TC execution report: `"Remaining environments (Firefox, macOS) deferred to Regression"`

### 5.3 Skipped environments — how to record

For any matrix environment that was NOT tested in this sprint:
1. Create the test-management Test Execution
2. Set its overall status to `TODO` (not started)
3. Add a comment: `"Deferred — not tested in sprint {N}. Schedule for regression."`
4. Note it in the local TE document under "Deferred Environments"

---

## 6. Evidence Requirements — What Screenshots Must Show

Standard evidence requirements (from `evidence-quality-standards.md`) apply. For cross-environment tests, add these **mandatory** requirements:

### Browser evidence
Every screenshot taken on a browser test must show at least **one** of:
- Browser name + version in the title bar or address bar chrome
- Browser developer tools open showing User-Agent string
- Windows taskbar showing browser icon (for OS + browser combination proof)

**Acceptable**: Full-page screenshot with Chrome's address bar visible
**NOT acceptable**: Screenshot cropped to hide browser UI

### OS evidence
For OS-specific tests:
- Windows: taskbar clock + system tray visible OR Windows start button visible
- macOS: Apple menu bar visible with OS indicator
- Linux: appropriate desktop environment indicator visible

### Database evidence
For DB-specific tests:
- Include a screenshot of the query result showing the DB version: `SELECT @@VERSION` (SQL Server), `SELECT version()` (MySQL/Postgres), `SELECT * FROM v$version` (Oracle)
- OR show the connection string / environment banner that identifies the DB

### Software version evidence
For software version compatibility tests, capture a version evidence screenshot **before any functional steps** in each test-management execution:

| Component | Evidence method | Screenshot naming |
|-----------|----------------|-------------------|
| OpenLab Server / CDS | `Help > About` dialog — shows product name, full version, build number, and service pack | `step0-about-openlab-{env-id}.png` |
| Instrument Driver | ExampleOrg Connection Expert or Device Manager — driver version visible | `step0-driver-version-{env-id}.png` |
| ExampleOrg Add-ons | OpenLab Administration > Add-ons list — name + installed version visible | `step0-addons-{env-id}.png` |
| 3rd-Party Add-on | Add-on's own About / Version dialog | `step0-thirdparty-{env-id}.png` |

**Rule**: The version evidence screenshot is treated as **Step 0** of every software-version test-management execution. It is the primary traceability link between the test result and the exact software configuration under test. If Step 0 evidence is absent, the execution evidence is incomplete.

### Combined environment label
Where practical, add a visible text overlay or caption to the screenshot naming:
```
screenshot-file-name: step3-chrome-126-windows11.png
```
File names are captured in test-management and serve as additional environment traceability.

---

## 7. Defect Reporting — Tagging Environment Context

When raising a defect for a failure found on a specific environment, the defect must carry full environment context.

### Required defect fields

| Field | Value |
|-------|-------|
| **Summary prefix** | `[{Browser}/{OS}]`, `[{DB}]`, or `[{Env ID}]` — e.g., `[Chrome/Win11] Upload fails on large files` or `[SWE-1] OL CDS import fails on v2.7 SP2` |
| **Environment** | Exact environment string — e.g., `SIT - Chrome 126 / Windows 11 23H2` or `SIT - SWE-1 (OL CDS v2.7 SP2)` |
| **Labels** | Add environment label(s): `browser-chrome`, `os-windows-11`, `db-sqlserver-2022`, `sw-env-SWE-1` |
| **Steps to Reproduce** | Step 1 MUST state the exact environment: `"On Chrome 126.0.6478 / Windows 11 23H2..."` or `"On OL CDS v2.7 SP2 / OL Server v2.7 SP2 (SWE-1)..."` |

### Environment-specific labels to add

| Dimension | Label format | Examples |
|-----------|-------------|---------|
| Browser | `browser-{name}` | `browser-chrome`, `browser-firefox`, `browser-edge`, `browser-safari` |
| OS | `os-{name}-{version}` | `os-windows-11`, `os-macos-14`, `os-ubuntu-22` |
| Database | `db-{name}` | `db-sqlserver`, `db-oracle`, `db-mysql`, `db-postgres` |
| Device | `device-{type}` | `device-mobile`, `device-tablet` || Software Env ID | `sw-env-{id}` | `sw-env-SWE-1`, `sw-env-SWE-2`, `sw-env-PROD-baseline` |
| OpenLab version | `ol-server-{ver}`, `ol-cds-{ver}` | `ol-server-v27sp2`, `ol-cds-v27sp1`, `ol-cds-chemstation-c0110` |
| Instrument Driver | `instr-driver-{ver}` | `instr-driver-v743`, `instr-driver-ddk51` |
| Add-on | `addon-{name}-{ver}` | `addon-gcbackflush-v31`, `addon-masslynx-v20` |
### Cross-environment defect — multiple environments affected

If the defect reproduces on multiple environments, list them all:
- Summary: `[Chrome+Firefox/Win11] Button misaligned on login page`
- Labels: `browser-chrome`, `browser-firefox`, `os-windows-11`
- Environment: `SIT - Chrome + Firefox / Windows 11`

---

## 8. Test Case Review — Checking Cross-Environment Coverage

When reviewing a TC document (used by `test_case_review` agent), check:

### Coverage completeness checks

| Check | Finding level if missing |
|-------|--------------------------|
| TC has an Environment Coverage section | HIGH — TC is incomplete |
| All required matrix dimensions are listed | HIGH — missing dimension |
| Steps annotated where env-specific behaviour exists | MEDIUM — risk of missed failures |
| Evidence requirements include browser/OS visibility | MEDIUM — evidence not auditable |
| Coverage tier stated and justified | LOW — traceability gap |

### Missing environment coverage finding template

```
**Finding [HIGH]: Missing environment coverage for {dimension}**
The story AC references {trigger keyword} but the TC has no coverage for {browser/OS/DB} environments.
Required by: EnvironmentMatrixTemplate.md — {dimension} tier P{N}
Recommended fix: Add Environment Coverage section; annotate steps with [ENV: ...] where behaviour differs.
```

---

## 9. Quick Reference — Agent Decision Tree

```
Story received
    │
    ├─ Scan for trigger keywords (Section 1)
    │       │
    │       ├─ No triggers found ──► Single-environment. Use primary env from matrix. Proceed normally.
    │       │
    │       └─ Triggers found ──► Cross-env required
    │               │
    │               ├─ Read EnvironmentMatrixTemplate.md (Section 2, Priority 1)
    │               ├─ Read Software Version Traceability Matrix (Section 2B) — if populated
    │               ├─ Determine tier (Section 3)
    │               │       P1 → all matrix combos
    │               │       P2 → top 2 browsers + primary OS  [DEFAULT]
    │               │       P3 → primary only
    │               │
    │               ├─ Add Environment Coverage section to TC (Section 4.1)
    │               ├─ Annotate env-specific steps (Section 4.2 / 4.3)
    │               ├─ Create separate test-management executions per env (Section 5.1)
    │               ├─ If software matrix defined: create test-management execs per Env ID (Section 2B / 5.1)
    │               ├─ Enforce env evidence in screenshots (Section 6)
    │               └─ Tag defects with env labels (Section 7)
```
