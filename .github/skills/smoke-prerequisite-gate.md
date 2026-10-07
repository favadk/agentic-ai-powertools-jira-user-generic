---
description: Mandatory smoke-suite prerequisite for stories involving updates, software, drivers, add-ons, or lab-platform components
---

# Smoke Prerequisite Gate

Apply this gate before preparing, reviewing, or executing a story when its summary, description, acceptance criteria, labels, components, or comments contain any case-insensitive trigger:

- `driver`
- `linux update`
- `addon` or `add-on`
- `windows update`
- `openlab cds`
- `kvm`

## Required Test Steps

For a triggered story, the first two Xray and local TC steps are always:

| Order | Action | Command | Expected Result |
| --- | --- | --- | --- |
| 1 | Run automated smoke suite against the selected environment. | `npx protractor smoke.conf.js` | All smoke tests pass. |
| 2 | Run automated smoke-install suite against the selected environment. | `npx protractor smokeInstallation.conf.js` | All smoke-install tests pass. |

Run both commands from `C:\automation\06102026\UI_Protractor_Tests` with `BASE_URL` set to the target environment. The smoke suite uses `Tests/Smoke tests/*`; the smoke-install suite uses `Tests/Installation Tests/OLAC-3957.spec.js`.

## Gate Behavior

- Record `BASE_URL`, command, run time, and pass/fail result in the TC or execution evidence.
- If either suite fails, stop the story-specific test steps, record the failure, and raise or link a Jira **Defect** when the failure is reproducible.
- Reviewers must reject a triggered TC if the first two steps are not the smoke and smoke-install prerequisites.
- Do not apply this gate to stories with no trigger keyword.
