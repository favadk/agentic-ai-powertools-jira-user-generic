# Test Cases — STORY-7579: Create, validate, and release a CID ghost image for Lenovo ThinkEdge SE10n Gen 2

## Document Information

| **Filename**      | TC_STORY-7579.md |
|-------------------|-----------------|
| **Story Key**     | `STORY-7579` |
| **Story Summary** | `Create, validate, and release a CID ghost image for Lenovo ThinkEdge SE10n Gen 2` |
| **Sprint**        | `CID Sprint 114` (board 440, sprintId 78783 — from `scripts/monitor-state.json`; **not re-verified against Jira this run**, see Blockers) |
| **Prepared By**   | `test_case_preparation` agent |
| **Date Prepared** | 2026-09-10 |
| **Status**        | Draft — BLOCKED on Q/N-01 … Q/N-08 |
| **Xray Test Key** | *(not yet created — see `## Xray Publication Status`)* |
| **Smoke Gate**    | ✅ Applied (triggers: `linux update`, `openlab cds`, `kvm`) |

---

## Story Reference Gate

### Loaded References

| Source Type | Reference | Access Status | Relevant Sections Extracted | Used In |
| --- | --- | --- | --- | --- |
| Story | `STORY-7579` — https://jira.exampleqa.local/browse/STORY-7579 | Provided in prompt (Jira MCP + REST unavailable this run) | A/C 1–9, D/N (hardware config, image metadata, restore instructions, `ac_install.sh` production registration server, validation scope), known comments (MIKE KICINSKI, SUNIL REHMAN) | AC list, test data placeholders, scope limits |
| Product Help | https://hub.stg-51.aws.GenericQA.com/docs/ | **Not fetched** — no network/tool access in this run | — | Q/N-05, Q/N-08 raised instead of assuming behaviour |
| CID Hub Home | https://hub.stg-51.aws.GenericQA.com/home | **Not fetched** | — | Q/N-05 |
| API Spec | *(not configured in `.github/skills/project-reference-sources.md`)* | Not configured | — | — |
| Development evidence | `jira_get_development_information STORY-7579` | **Not retrieved** — Jira MCP erroring | — | Q/N items request impacted artefacts explicitly |
| Merged story | `STORY-7573` (merged into STORY-7579 and obsoleted — per SUNIL REHMAN comment) | Referenced only | A/C 4 wording "must be possible" | TC-05 scope note |

### Gate Checklist

- [x] All configured references from `.github/skills/project-reference-sources.md` were attempted.
- [x] Each inaccessible reference is explicitly marked (see table — all remote fetches unavailable this run).
- [x] Test scope is bounded to Story AC + D/N + Q/N supplied in the request. No speculative steps added.
- [x] Missing evidence captured as Q/N-01 … Q/N-08 below.

> **[Ref] ⚠️ No development links retrieved for STORY-7579 (branches/commits/PR).** Clarification questions explicitly request the image build artefact, baseline versions, and checksum in place of code evidence — this is an image build/release story, not a code-change story.

---

## Story Acceptance Criteria

- **AC-01**: Manufacturing receives a released CID ghost image for Lenovo ThinkEdge SE10n Gen 2 configuration.
- **AC-02**: The image contains the latest approved production Linux Update and CID Agent baseline. It does **NOT** contain pre-cached AIC KVM images.
- **AC-03**: Gen 2 performance is compared with a Gen 1 CID using the same representative workflow, and the results are recorded in the ticket before release.
- **AC-04**: The image can be restored (by manufacturing) to other SE10n Gen 2 units with the exact same configuration.
- **AC-05**: A restored unit functions successfully: (a) boots without manual intervention; (b) after boot the CID automatically contacts CID Hub without manual intervention and last-connected time updates on the Devices page; (c) both network interfaces operate in their assigned Corporate and Instrument roles.
- **AC-06**: A CID created from the image can be activated against the production CID Hub and becomes available for use.
- **AC-07**: The latest approved OpenLab CDS 2.8 and 3.0 images can each be provisioned successfully on a CID created from the ghost image.
- **AC-08**: A supported physical GC/MS or LC/MS instrument can be configured through the Instrument NIC; a representative multi-sample sequence completes successfully with results available in OpenLab CDS, with no instrument communication failures, interrupted runs, or CID instability.
- **AC-09**: Reset to Factory completes successfully from CID Hub, after which the CID can be activated again.

### Design Notes (D/N) — recorded as release artefact requirements

The release record must capture, verbatim: processor, memory, storage, BIOS version, network controllers, image name/version, release train, software baseline, creation date, checksum, minimum destination disk size, and restoration instructions. `ac_install.sh` must point at the **production** registration server. Validation is scoped to **one CID controlling one instrument**.

---

## Test Data — Placeholders Pending Q/N

> ⚠️ Every value below is **UNCONFIRMED** until the corresponding Q/N is answered. Do not execute against assumed values.

| Field | Value | Source Q/N |
|---|---|---|
| Hardware — Processor / Memory / Storage / BIOS / NICs | `{PENDING}` | Q/N-01 |
| Ghost image name + version | `{PENDING}` | Q/N-02 |
| Release train | `{PENDING}` | Q/N-02 |
| Linux Update baseline version | `{PENDING}` | Q/N-02 |
| CID Agent baseline version | `{PENDING}` | Q/N-02 |
| Image creation date | `{PENDING}` | Q/N-02 |
| Image checksum (algorithm + value) | `{PENDING}` | Q/N-02 |
| Minimum destination disk size | `{PENDING}` | Q/N-02 |
| Gen 1 comparison unit + representative workflow + metric thresholds | `{PENDING}` | Q/N-04 |
| Production CID Hub URL | `{PENDING}` | Q/N-05 |
| Production registration server endpoint (in `ac_install.sh`) | `{PENDING}` | Q/N-05 |
| Activation code source | `{PENDING}` | Q/N-05 |
| OpenLab CDS 2.8 approved image identifier | `{PENDING}` | Q/N-06 |
| OpenLab CDS 3.0 approved image identifier | `{PENDING}` | Q/N-06 |
| Instrument model (GC/MS or LC/MS) + sequence definition | `{PENDING}` | Q/N-07 |
| KVM-image absence verification method | `{PENDING}` | Q/N-08 |
| `BASE_URL` for smoke suites | `{PENDING}` | Q/N-05 |

---

## Test Case Details

---

### TC-STORY-7579-01 — Smoke prerequisite gate (smoke + smoke-install)

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-01 |
| **AC Reference** | Prerequisite (mandated by `.github/skills/smoke-prerequisite-gate.md`) |
| **Title** | Environment smoke and smoke-install suites pass before story-specific validation |
| **Type** | Regression |
| **Priority** | High |
| **Automation** | Yes |

#### Prerequisites

- Automation repo present at `C:\automation\06102026\UI_Protractor_Tests`.
- `BASE_URL` set to the target CID Hub environment (Q/N-05).

#### Steps

| Step | Action | Expected Result |
|---|---|---|
| 1 | From `C:\automation\06102026\UI_Protractor_Tests` with `BASE_URL` set, run `npx protractor smoke.conf.js`. | All smoke tests pass. `BASE_URL`, command, run time, and result recorded in the execution evidence. |
| 2 | From the same directory, run `npx protractor smokeInstallation.conf.js`. | All smoke-install tests pass. `BASE_URL`, command, run time, and result recorded in the execution evidence. |

> **Gate rule**: if either suite fails, stop all story-specific steps, record the failure, and raise/link a Jira **Defect** if reproducible.

---

### TC-STORY-7579-02 — Released ghost image is delivered to manufacturing with complete release record

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-02 |
| **AC Reference** | AC-01 (+ D/N) |
| **Type** | Happy Path |
| **Priority** | High |
| **Automation** | No |

#### Prerequisites (TC-02)

- Ghost image build completed for the SE10n Gen 2 configuration.

#### Steps (TC-02)

| Step | Action | Expected Result |
|---|---|---|
| 1 | Open the release record / ticket attachment for the SE10n Gen 2 ghost image and confirm the image artefact is published to the manufacturing delivery location. | The image artefact is present at the manufacturing delivery location and is marked **Released**. |
| 2 | Verify the release record lists: processor, memory, storage, BIOS version, and network controllers. ⚠️ UNCONFIRMED — values per Q/N-01. | All five hardware attributes are recorded and match the physical SE10n Gen 2 unit under test. |
| 3 | Verify the release record lists: image name/version, release train, software baseline, creation date, checksum, and minimum destination disk size. ⚠️ UNCONFIRMED — values per Q/N-02. | All six metadata attributes are recorded and non-empty. |
| 4 | Compute the checksum of the delivered image artefact and compare it to the checksum in the release record. | Computed checksum matches the recorded checksum exactly. |
| 5 | Verify restoration instructions are attached/linked in the release record. | Restoration instructions are present and reference the minimum destination disk size from step 3. |

---

### TC-STORY-7579-03 — Image contains latest approved Linux Update and CID Agent baseline

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-03 |
| **AC Reference** | AC-02 |
| **Type** | Happy Path |
| **Priority** | High |
| **Automation** | Partial |

#### Steps (TC-03)

| Step | Action | Expected Result |
|---|---|---|
| 1 | On a unit provisioned from the ghost image, query the installed Linux Update version. | Version equals the latest **approved production** Linux Update baseline (Q/N-02). |
| 2 | Query the installed CID Agent version. | Version equals the latest **approved production** CID Agent baseline (Q/N-02). |
| 3 | Compare both versions against the software baseline recorded in the release record (TC-02 step 3). | Both versions match the recorded software baseline — no drift. |

---

### TC-STORY-7579-04 — Image does NOT contain pre-cached AIC KVM images

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-04 |
| **AC Reference** | AC-02 |
| **Type** | Negative |
| **Priority** | High |
| **Automation** | Partial |

#### Steps (TC-04)

| Step | Action | Expected Result |
|---|---|---|
| 1 | On a unit provisioned from the ghost image, enumerate the local AIC/KVM image cache using the verification method confirmed in Q/N-08. ⚠️ UNCONFIRMED — method pending. | The AIC KVM image cache is empty — no pre-cached AIC KVM images are present. |
| 2 | Record the reported free disk space on the unit. | Free disk space is consistent with an image that carries no pre-cached KVM payload (baseline recorded for comparison). |

---

### TC-STORY-7579-05 — Gen 2 vs Gen 1 performance comparison recorded before release

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-05 |
| **AC Reference** | AC-03 |
| **Type** | Happy Path |
| **Priority** | High |
| **Automation** | No |
| **Status** | ⚠️ UNCONFIRMED — blocked on Q/N-04 (workflow definition + thresholds) |

#### Steps (TC-05)

| Step | Action | Expected Result |
|---|---|---|
| 1 | Execute the agreed representative workflow (Q/N-04) on the SE10n **Gen 2** CID and capture the defined metrics. | Metrics captured for all defined measurement points. |
| 2 | Execute the identical workflow on a **Gen 1** CID and capture the same metrics. | Metrics captured using the identical workflow and data set. |
| 3 | Compare Gen 2 results against Gen 1 results using the agreed acceptance threshold (Q/N-04). | Gen 2 meets or exceeds the agreed threshold relative to Gen 1. |
| 4 | Record the comparison results in STORY-7579 **before** the image is marked Released. | Comparison results are present on the ticket and dated prior to the release action. |

---

### TC-STORY-7579-06 — Image restores to another SE10n Gen 2 unit with identical configuration

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-06 |
| **AC Reference** | AC-04 |
| **Type** | Happy Path |
| **Priority** | High |
| **Automation** | No |
| **Status** | ⚠️ **CONSTRAINED** — blocked on Q/N-03 |

> **Hardware constraint (from story comments)**: only ONE Gen 2 SE10n unit is available, so restoring to a **second physical unit** may not be possible. A/C 4 was retained but reworded to "must be possible"; the decision on whether a second physical unit must actually be exercised is delegated to Dev/QA. Q/N-03 requests that decision before execution.

#### Steps (TC-06)

| Step | Action | Expected Result |
|---|---|---|
| 1 | Follow the documented restoration instructions (TC-02 step 5) to restore the ghost image to an SE10n Gen 2 destination unit. | Restore completes without error and reports success. |
| 2 | After restore, capture the destination unit's processor, memory, storage, BIOS version, and network controller configuration. | Configuration matches the source configuration recorded in the release record exactly (Q/N-01). |
| 3 | Verify the restored unit's Linux Update and CID Agent versions. | Versions match the baseline verified in TC-03 — the restore is byte-equivalent in software baseline. |

---

### TC-STORY-7579-07 — Restore is rejected on a destination disk below the documented minimum size

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-07 |
| **AC Reference** | AC-04 (D/N — minimum destination disk size) |
| **Type** | Boundary / Negative |
| **Priority** | Medium |
| **Automation** | No |
| **Status** | ⚠️ UNCONFIRMED — minimum disk size pending Q/N-02 |

#### Steps (TC-07)

| Step | Action | Expected Result |
|---|---|---|
| 1 | Attempt the documented restore procedure onto a destination disk smaller than the documented minimum destination disk size. | Restore does not complete; the tool reports an insufficient-disk-size condition. No partially restored, bootable-but-invalid unit is produced. |
| 2 | Repeat the restore onto a destination disk exactly equal to the documented minimum destination disk size. | Restore completes successfully. |

---

### TC-STORY-7579-08 — Restored unit boots without manual intervention

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-08 |
| **AC Reference** | AC-05 (a) |
| **Type** | Happy Path |
| **Priority** | High |
| **Automation** | No |

#### Steps (TC-08)

| Step | Action | Expected Result |
|---|---|---|
| 1 | Power on the restored SE10n Gen 2 unit and observe the full boot sequence without touching the console. | The unit reaches a fully booted, operational state with no prompts, no manual key presses, and no recovery/BIOS intervention required. |
| 2 | Confirm no boot-time errors are recorded in the system log. | No boot-blocking errors are present. |

---

### TC-STORY-7579-09 — Restored CID automatically contacts CID Hub and last-connected time updates

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-09 |
| **AC Reference** | AC-05 (b) |
| **Type** | Happy Path |
| **Priority** | High |
| **Automation** | Partial |

#### Steps (TC-09)

| Step | Action | Expected Result |
|---|---|---|
| 1 | After the unit boots (TC-08), do not perform any manual registration action. Open the CID Hub **Devices** page and locate the restored CID. | The restored CID appears on the Devices page without any manual registration step being performed. |
| 2 | Note the CID's last-connected time, wait for the next check-in interval, and refresh the Devices page. | The last-connected time advances to the newer check-in timestamp. |

---

### TC-STORY-7579-10 — Both NICs operate in their assigned Corporate and Instrument roles

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-10 |
| **AC Reference** | AC-05 (c) |
| **Type** | Happy Path |
| **Priority** | High |
| **Automation** | Partial |

#### Steps (TC-10)

| Step | Action | Expected Result |
|---|---|---|
| 1 | On the restored unit, list both network interfaces and their assigned roles. | Exactly two interfaces are present; one is assigned the **Corporate** role and the other the **Instrument** role, matching the network controllers recorded in the release record (Q/N-01). |
| 2 | Verify outbound connectivity to CID Hub over the Corporate interface. | Corporate interface reaches CID Hub successfully. |
| 3 | Verify connectivity to the instrument subnet over the Instrument interface. | Instrument interface reaches the instrument subnet successfully; the Corporate interface is not used for instrument traffic. |

---

### TC-STORY-7579-11 — CID from the ghost image activates against the production CID Hub

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-11 |
| **AC Reference** | AC-06 (+ D/N — `ac_install.sh` production registration server) |
| **Type** | Happy Path |
| **Priority** | High |
| **Automation** | Partial |
| **Status** | ⚠️ UNCONFIRMED — production endpoints pending Q/N-05 |

#### Steps (TC-11)

| Step | Action | Expected Result |
|---|---|---|
| 1 | On a CID created from the ghost image, inspect `ac_install.sh` and read the configured registration server endpoint. | The endpoint is the **production** registration server (Q/N-05) — not a staging/test endpoint. |
| 2 | Run the activation flow against the production CID Hub using the approved activation code source (Q/N-05). | Activation completes successfully with no error. |
| 3 | On the production CID Hub Devices page, locate the activated CID. | The CID is listed and its state is **available for use**. |

---

### TC-STORY-7579-12 — Activation is rejected when the image is not pointed at the production registration server

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-12 |
| **AC Reference** | AC-06 (D/N guard) |
| **Type** | Negative |
| **Priority** | Medium |
| **Automation** | No |

#### Steps (TC-12)

| Step | Action | Expected Result |
|---|---|---|
| 1 | On a scratch copy of the image, set `ac_install.sh` to a non-production registration server endpoint and attempt activation against the production CID Hub. | Activation does not succeed against the production CID Hub; the failure is reported to the operator rather than silently registering the device elsewhere. |
| 2 | Restore `ac_install.sh` to the production endpoint and re-run activation. | Activation succeeds — confirming the released image configuration is the one required by AC-06. |

---

### TC-STORY-7579-13 — OpenLab CDS 2.8 image provisions successfully on the CID

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-13 |
| **AC Reference** | AC-07 |
| **Type** | Happy Path |
| **Priority** | High |
| **Automation** | Partial |
| **Status** | ⚠️ UNCONFIRMED — approved image identifier pending Q/N-06 |

#### Steps (TC-13)

| Step | Action | Expected Result |
|---|---|---|
| 1 | From CID Hub, provision the latest approved **OpenLab CDS 2.8** image onto the CID created from the ghost image. | Provisioning starts and progresses without error. |
| 2 | Wait for provisioning to complete and check the resulting instance state. | Provisioning completes successfully; the CDS 2.8 instance reports a running/ready state on the CID. |
| 3 | Verify the provisioned CDS version. | Version matches the approved CDS 2.8 image identifier (Q/N-06). |

---

### TC-STORY-7579-14 — OpenLab CDS 3.0 image provisions successfully on the CID

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-14 |
| **AC Reference** | AC-07 |
| **Type** | Happy Path |
| **Priority** | High |
| **Automation** | Partial |
| **Status** | ⚠️ UNCONFIRMED — approved image identifier pending Q/N-06 |

#### Steps (TC-14)

| Step | Action | Expected Result |
|---|---|---|
| 1 | From CID Hub, provision the latest approved **OpenLab CDS 3.0** image onto a CID created from the ghost image. | Provisioning starts and progresses without error. |
| 2 | Wait for provisioning to complete and check the resulting instance state. | Provisioning completes successfully; the CDS 3.0 instance reports a running/ready state on the CID. |
| 3 | Verify the provisioned CDS version. | Version matches the approved CDS 3.0 image identifier (Q/N-06). |

---

### TC-STORY-7579-15 — Physical instrument configured via Instrument NIC; multi-sample sequence completes

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-15 |
| **AC Reference** | AC-08 |
| **Type** | Happy Path — **Workflow Test — must run in sequence** |
| **Priority** | High |
| **Automation** | No |
| **Status** | ⚠️ UNCONFIRMED — instrument model and sequence definition pending Q/N-07 |

> **Scope (D/N)**: validation is scoped to **one CID controlling one instrument**.

#### Steps (TC-15)

| Step | Action | Expected Result |
|---|---|---|
| 1 | Connect the supported physical GC/MS or LC/MS instrument (Q/N-07) to the CID's **Instrument NIC** and configure it in OpenLab CDS. | The instrument is discovered and configured through the Instrument NIC; instrument status is online in CDS. |
| 2 | Define and start the agreed representative multi-sample sequence (Q/N-07). | The sequence starts and each sample acquires in turn without operator intervention. |
| 3 | Monitor the run through completion. | The sequence completes fully — no instrument communication failures, no interrupted runs, and no CID instability (no reboot, hang, or agent restart). |
| 4 | Open the acquired results in OpenLab CDS. | Results for every sample in the sequence are present and openable in OpenLab CDS. |
| 5 | Review the CID system log and CID Hub device status for the duration of the run. | No communication errors or device-offline events are recorded for the run window. |

---

### TC-STORY-7579-16 — Reset to Factory from CID Hub succeeds and the CID can be re-activated

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-16 |
| **AC Reference** | AC-09 |
| **Type** | Happy Path — **Workflow Test — must run in sequence** |
| **Priority** | High |
| **Automation** | Partial |

#### Steps (TC-16)

| Step | Action | Expected Result |
|---|---|---|
| 1 | From CID Hub, trigger **Reset to Factory** on the CID created from the ghost image. | The reset is accepted and progresses to completion without error. |
| 2 | Observe the CID after reset completes. | The CID returns to its factory/unactivated state and boots without manual intervention. |
| 3 | Re-run the activation flow against the production CID Hub (as in TC-11). | Activation succeeds; the CID is listed on the Devices page and is available for use again. |

---

### TC-STORY-7579-17 — Regression: existing Gen 1 CID operation is unaffected

| Field | Value |
|---|---|
| **TC ID** | TC-STORY-7579-17 |
| **AC Reference** | Regression (adjacent to AC-03 / AC-05) |
| **Type** | Regression |
| **Priority** | Medium |
| **Automation** | Partial |

#### Steps (TC-17)

| Step | Action | Expected Result |
|---|---|---|
| 1 | On the CID Hub Devices page, confirm the existing Gen 1 CID used for the AC-03 comparison is still listed and reporting check-ins. | The Gen 1 CID remains listed with an advancing last-connected time — unchanged by the Gen 2 image work. |
| 2 | Confirm the Gen 1 CID's provisioned OpenLab CDS instance is still reachable and operational. | Gen 1 CDS instance is unchanged and operational — no side effects from the Gen 2 ghost image release. |

---

## AC Coverage Matrix

| AC Item | Description (brief) | TC IDs Covering It | Coverage Status |
|---|---|---|---|
| Prereq | Smoke + smoke-install gate (Linux Update / OpenLab CDS / KVM triggers) | TC-01 | ✅ Covered |
| AC-01 | Manufacturing receives released ghost image for SE10n Gen 2 | TC-02 | ✅ Covered |
| AC-02 | Latest approved Linux Update + CID Agent baseline; no pre-cached AIC KVM images | TC-03, TC-04 | ✅ Covered |
| AC-03 | Gen 2 vs Gen 1 performance comparison recorded before release | TC-05 | ⚠️ Covered — blocked on Q/N-04 |
| AC-04 | Image restores to other SE10n Gen 2 units with same configuration | TC-06, TC-07 | ⚠️ Covered — constrained by single-unit availability (Q/N-03) |
| AC-05a | Restored unit boots without manual intervention | TC-08 | ✅ Covered |
| AC-05b | CID auto-contacts CID Hub; last-connected updates on Devices page | TC-09 | ✅ Covered |
| AC-05c | Both NICs operate in Corporate and Instrument roles | TC-10 | ✅ Covered |
| AC-06 | CID activates against production CID Hub and is available for use | TC-11, TC-12 | ⚠️ Covered — blocked on Q/N-05 |
| AC-07 | OpenLab CDS 2.8 and 3.0 provision successfully | TC-13, TC-14 | ⚠️ Covered — blocked on Q/N-06 |
| AC-08 | Instrument via Instrument NIC; multi-sample sequence completes with results | TC-15 | ⚠️ Covered — blocked on Q/N-07 |
| AC-09 | Reset to Factory succeeds; CID can be activated again | TC-16 | ✅ Covered |
| D/N | Release record metadata + restore instructions + production `ac_install.sh` | TC-02, TC-07, TC-11, TC-12 | ✅ Covered |

---

## Open Questions (Q/N) — post ONLY on the Xray Test issue

> **Constraint honoured**: no comment has been or will be posted on the User Story **STORY-7579**. All Q/N items must be posted on the Xray Test issue, addressed to the QA Engineer (@tester), who decides whether to escalate to PO or Dev.

| Q/N | Blocked TC(s) | Question | Ask |
|---|---|---|---|
| Q/N-01 | TC-02, TC-06, TC-10 | Please confirm the authoritative source and exact values for the SE10n Gen 2 hardware configuration (processor, memory, storage, BIOS version, network controllers). A wiki page was proposed in the story comments as the single source of truth — is that page available, and what is its URL? | Dev |
| Q/N-02 | TC-02, TC-03, TC-07 | Please provide the released image metadata to use as test data: image name/version, release train, software baseline (exact Linux Update version and CID Agent version), creation date, checksum (algorithm + value), and minimum destination disk size. | Dev |
| Q/N-03 | TC-06 | Only one Gen 2 SE10n unit is available. For AC-04 ("must be possible"), is a restore to a **second physical unit** in scope for this sprint, or is a documented restore-procedure verification on the same unit / an equivalent destination acceptable evidence? | PO |
| Q/N-04 | TC-05 | For AC-03, please define the "representative workflow" used for the Gen 2 vs Gen 1 comparison, the exact metrics to capture, and the acceptance threshold that decides pass/fail. | PO |
| Q/N-05 | TC-11, TC-12, TC-01 | Please confirm the production CID Hub URL, the production registration server endpoint that `ac_install.sh` must target, the activation code source to use, and the `BASE_URL` value for the smoke suites. | Dev |
| Q/N-06 | TC-13, TC-14 | Please confirm the exact "latest approved" OpenLab CDS 2.8 and CDS 3.0 image identifiers/versions in the production catalogue at the time of validation. | Dev |
| Q/N-07 | TC-15 | For AC-08, please confirm the specific supported instrument model (GC/MS or LC/MS) to be used and the definition of the "representative multi-sample sequence" (sample count, method, expected runtime). | PO |
| Q/N-08 | TC-04 | For AC-02, please confirm the accepted verification method to prove the absence of pre-cached AIC KVM images on the CID (exact command / path / CID Hub view that constitutes evidence). | Dev |

---

## Notes and Assumptions

- **Smoke Gate applied**: the story references `linux update`, `openlab cds`, and `kvm`, so `smoke.conf.js` and `smokeInstallation.conf.js` are the first two steps (TC-01) per `.github/skills/smoke-prerequisite-gate.md`.
- **Scope limit (D/N)**: validation is scoped to one CID controlling one instrument — TC-15 does not attempt multi-instrument coverage.
- **STORY-7573** was merged into this story and obsoleted; AC-04 was retained but reworded. No separate test artefacts are produced for STORY-7573.
- **Hardware availability risk**: a single Gen 2 SE10n unit constrains TC-06. If Q/N-03 confirms a second unit is out of scope, TC-06 step 1 will execute as a documented-procedure verification and must be marked as such in the execution evidence.
- **All test data is `{PENDING}`** — this TC document must not be executed until Q/N-01 … Q/N-08 are answered and the test data table is populated. TCs marked ⚠️ UNCONFIRMED are execute-with-caution only if the user explicitly accepts the risk.
- **No Jira comment was posted on STORY-7579** (explicit user constraint).

---

## Xray Publication Status

| Item | Status |
|---|---|
| Xray Test issue created | ❌ Not created — no terminal execution capability in this session (`scripts/xray-api.ps1` could not be dot-sourced; Jira MCP tools returned invocation errors) |
| Steps pushed to Xray | ❌ Not pushed |
| Q/N comment posted on Xray Test | ❌ Not posted — the Xray Test issue does not exist yet |
| Sprint TE linkage (`.github/skills/test-execution-sprint-linking.md`) | ❌ Not performed |
| Ready-to-run publisher script | ✅ `scripts/create-xray-STORY-7579.ps1` — run it to create the Xray Test, push all steps, and post the Q/N comment on the Test issue only |

---

*Generated by: `test_case_preparation` agent | Template: `docs/_TEMPLATES/TestCasePlanTemplate.md`*
