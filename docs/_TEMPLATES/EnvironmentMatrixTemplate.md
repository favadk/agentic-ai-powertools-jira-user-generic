---
description: Project-specific compatibility matrix — defines the supported OS, browser, database, device, and ExampleOrg software product version environments for this project, coverage tiers per feature area, and the primary environment for smoke testing. Configure this file once per project. All QA agents read it automatically.
---

# Project Environment Matrix

> **How to use**: Fill in the tables below for your project. Agents read this file automatically to determine which environments apply to each story. Update it whenever the project's supported environments change.
>
> **File location**: `docs/_TEMPLATES/EnvironmentMatrixTemplate.md`
> **Last updated**: 2026-07-21
> **Updated by**: KHAN,FAVAD

---

## Deployment Environments

The CID Hub project has four named environments. All QA agents use this table to resolve environment labels and base URLs.

| Env Label | URL | Purpose | Use for Xray `Environment` field |
|-----------|-----|---------|----------------------------------|
| **TEST** | https://app.example.com | Active QA/testing — **default for story execution** | `SIT` |
| **DEV** | https://app.example.com | Developer integration | `DEV` |
| **STAGING** | https://app.example.com | Pre-production / UAT | `STAGING` |
| **PRODUCTION** | https://app.example.com | Live production | `PROD` |

> **Default for test execution**: TEST (`https://app.example.com) unless the story explicitly requires a different environment.

---

## Supported Browsers

List all browsers the application officially supports. The **first entry is the primary browser** (used for P3 smoke testing).

| Priority | Browser | Minimum Version | Notes |
|----------|---------|----------------|-------|
| 1 (Primary) | Chrome | Latest stable | Default for smoke testing |
| 2 (Secondary) | Firefox | Latest stable | |
| 3 | Edge | Latest stable | Chromium-based |
| 4 | Safari | 17+ | macOS only; test separately |
| — | Internet Explorer | Not supported | Do NOT test on IE |

---

## Supported Operating Systems

List all OS versions the application officially supports. The **first entry is the primary OS**.

| Priority | OS | Version | Notes |
|----------|----|---------|-------|
| 1 (Primary) | Windows | 11 (23H2) | Default for smoke testing |
| 2 (Secondary) | Windows | 10 (22H2) | |
| 3 | macOS | 14 Sonoma | Required for Safari testing |
| — | Linux | — | Not supported for this product |

---

## Supported Databases

List all database versions the application officially supports. Set to "N/A" if the application does not have a user-facing database dependency.

| Priority | Database | Version | Notes |
|----------|---------|---------|-------|
| 1 (Primary) | SQL Server | 2022 | Default for smoke testing |
| 2 (Secondary) | SQL Server | 2019 | |
| — | Oracle | — | Not supported |
| — | MySQL | — | Not supported |

> Set all entries to `N/A` and Priority to `—` if database compatibility testing does not apply to this project.

---

## Supported Devices / Viewports

List device types or screen resolution tiers if the application has responsive design requirements. Set to "N/A" if no responsive requirements exist.

| Priority | Device Type | Resolution / Viewport | Notes |
|----------|------------|----------------------|-------|
| 1 (Primary) | Desktop | 1920×1080 | Default |
| 2 (Secondary) | Desktop | 1366×768 | Common laptop resolution |
| 3 | Tablet | 768×1024 (iPad portrait) | |
| — | Mobile | — | Not in scope for this sprint |

---

## Default Coverage Tier

Set the default tier applied to stories where no feature-area override matches.

| Setting | Value |
|---------|-------|
| **Default tier** | P2 |
| **Primary environment** | Chrome Latest / Windows 11 |
| **P2 secondary browser** | Firefox Latest |
| **P2 secondary OS** | macOS 14 (when Safari testing applies) |

> Change `Default tier` to `P1`, `P2`, or `P3` as appropriate for your project.

---

## Feature Area Overrides

Define per-area tiers when specific areas need different coverage rules than the default. Delete rows that do not apply.

| Feature Area | Keywords to match in story summary/AC | Coverage Tier | Notes |
|-------------|--------------------------------------|---------------|-------|
| Authentication / Login | login, logout, SSO, authentication, sign in, sign out, password, MFA | P1 | Security-critical — full matrix always |
| Authorization / Permissions | permission, role, access control, restrict, authorise, authorize, CID | P1 | Security-critical — full matrix always |
| File Upload / Download | upload, download, file, attachment, export, import | P2 | Test primary + secondary browser |
| Data Entry / Forms | form, input, field, validation, submit, save | P2 | |
| Reporting / Dashboard | report, dashboard, chart, graph, analytics, export | P2 | |
| Navigation / UI Layout | navigation, menu, layout, responsive, display, render | P2 | |
| Background Services / API | service, API, backend, scheduled, job, batch | P3 | Minimal UI — primary env only |
| Configuration / Admin | admin, configuration, settings, system | P3 | |

**Matching rule**: When a story summary or AC contains a keyword in the "Keywords" column, apply that row's tier instead of the default. If multiple rows match, use the **highest tier (P1 > P2 > P3)**.

---

## Software Version Traceability Matrix

Define the ExampleOrg software product configurations that apply to this project. Each row is a **named environment** (Env ID) representing a specific combination of installed product versions. Agents read this table to determine which software configurations must be tested, and create one Xray Test Execution per applicable row.

> **How to use**:
> - Add one row per software version configuration you need to test.
> - Assign each row a **Tier** (P1 / P2 / P3) to control when it is included based on the story's coverage tier.
> - Set a column to `N/A` if that component is not installed in the environment.
> - Set add-on columns to `None` if no add-on is present.
> - A column not applicable to this project may be removed from the table.
> - Set all rows to a single Env ID (P1 only) for single-environment projects.

| Env ID | OpenLab Server | OpenLab CDS | Instr. Driver | ExampleOrg Add-on | 3rd-Party Add-on | Tier |
|--------|----------------|-------------|---------------|----------------|-----------------|------|
| SWE-1  | {e.g. v2.7 SP2} | {e.g. v2.7 SP2} | {e.g. v7.4.3} | {e.g. GC Backflush v3.1 or None} | {e.g. None} | P1 |
| SWE-2  | {e.g. v2.7 SP1} | {e.g. v2.7 SP1} | {e.g. v7.4.2} | {e.g. GC Backflush v3.1 or None} | {e.g. Waters MassLynx v2.0 or None} | P2 |
| SWE-3  | {e.g. v2.6 SR2} | {e.g. ChemStation C.01.10} | {e.g. v7.3.5} | {e.g. None} | {e.g. None} | P3 |

> **Delete the template rows above and replace with your actual product versions.**  
> **To disable software version testing entirely:** remove all rows from this table (leave the header only).

### Software Coverage Tier Rules

| Story tier | Software environments tested |
|-----------|------------------------------|
| **P1** | ALL rows in this table |
| **P2** (default) | Rows with Tier = P1 or P2 |
| **P3** | Rows with Tier = P1 only |

### Story-Level Override

To test specific Env IDs for a particular story (overriding the tier rules), add a Jira label:
- `sw-env:SWE-1` — test only SWE-1 for that story
- `sw-env:SWE-1,SWE-2` — test SWE-1 and SWE-2 only
- `sw-env:all` — test all rows regardless of tier

### Column Definitions Reference

| Column | Description |
|--------|-------------|
| **Env ID** | Short unique identifier used on Xray executions and defect labels (e.g., `SWE-1`, `PROD-Baseline`, `QA-v27`) |
| **OpenLab Server** | Full version + service pack, e.g., `v2.7 SP2`, `v2.6 SR2` |
| **OpenLab CDS** | Full version + SP or product name variant, e.g., `v2.7 SP2`, `ChemStation C.01.10` |
| **Instr. Driver** | ExampleOrg instrument driver version, e.g., `v7.4.3`, `DDK v5.1` |
| **ExampleOrg Add-on** | Name + version of each installed ExampleOrg add-on, e.g., `GC Backflush v3.1`; use `None` if absent |
| **3rd-Party Add-on** | Name + version of each third-party integrated add-on, e.g., `Waters MassLynx v2.0`; use `None` if absent |
| **Tier** | P1 = always tested, P2 = tested when story tier is P1 or P2, P3 = tested only when story tier is P1 |

---

## Exclusions

List any environments that should NEVER be used for testing, even if mentioned in a story.

| Environment | Reason |
|------------|--------|
| Internet Explorer (any version) | End of support — do not test |
| Windows 7 / Windows 8 | End of support — do not test |
| {Add more as needed} | |

---

## Changelog

| Date | Changed by | Change |
|------|-----------|--------|
| {DATE} | {NAME} | Initial version created by setup-qa-framework.ps1 |
