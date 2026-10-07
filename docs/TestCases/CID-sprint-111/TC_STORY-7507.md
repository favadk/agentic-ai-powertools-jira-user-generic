# Test Cases

**Quality Assurance - Defect Regression Test Document**

## Test Cases for `STORY-7507`

## Document Information

| **Filename**      | TC_STORY-7507.md                                                                              |
|-------------------|----------------------------------------------------------------------------------------------|
| **Defect Key**    | `STORY-7507`                                                                                  |
| **Summary**       | 1451251 - CID never comes online at Aktis Oncology, where DHCP responds slowly (~9 seconds) |
| **Sprint**        | CID sprint 111                                                                               |
| **Prepared By**   | test_case_preparation agent (Mode D - Defect Regression)                                     |
| **Date Prepared** | 2026-07-29                                                                                   |
| **Status**        | Draft                                                                                        |
| **Xray Test Key** | *(pending - create via `New-XrayTest` in xray-api.ps1)*                                     |

---

## Defect Summary

| Field | Value |
|---|---|
| **Defect Key** | `STORY-7507` |
| **Steps to Reproduce** | See TC-STORY-7507-01 |
| **Actual Result (bug)** | CID loops forever on hostname resolution with an empty IP address, restarting network services every ~5.5 minutes indefinitely. Never comes online. |
| **Expected Result (fix)** | A DHCP response that takes a few seconds is a normal network condition. The CID should tolerate it and come online, at worst a minute or two later than usual. |
| **Root Cause** | The CID's hostname-resolution agent reads the assigned IP too early â€” before NetworkManager finishes processing the DHCP lease â€” and caches a blank string. Fix: add a retry/wait after DHCP assignment before reading the IP. |
| **Environment** | CID GC-A940, Oracle Linux 8.10 (NetworkManager 1.40.16-19.0.1.el8_10) |
| **Fix Version** | CID sprint 111 (FR 1.4) |

> **[2026-08-17] Description-change review**: The updated defect description (slow DHCP around 5-10 seconds, repeated empty-IP resolution loop, and manual workaround context) was reviewed against existing regression coverage. No TC step or expected-result rewrite was required because TC-01 through TC-10 already cover the delayed-DHCP boot and no-loop expectations.

---

## Test Cases

---

### TC-STORY-7507-01  -  Bug Reproduction: CID with slow DHCP (~9s) never comes online

| Field           | Value                                                            |
|-----------------|------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7507-01                                                  |

| **Title**       | Bug Reproduction: CID with ~9-second DHCP delay never comes online          |
| **Type**        | Bug Reproduction                                                 |
| **Priority**    | High                                                             |
| **Automation**  | Yes                                                              |

**Prerequisites**

- CID hardware: GC-A940 running Oracle Linux 8.10 (NetworkManager 1.40.16) with the fix applied.
- DHCP server on test network configured to respond in < 1 second (baseline / control condition).
- CID Hub accessible and able to display device status.
- NetworkManager journal and CID Recent Activities log accessible for inspection.

**Test Data**

| Field                  | Value                        |
|------------------------|------------------------------|
| DHCP response time     | < 1 second                   |
| Expected assigned IP   | Any valid non-empty address  |
| Observation window     | 5 minutes after boot         |

**Steps**

| Step | Action                                                                                              | Expected Result                                                                                          |
|------|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| 1    | Connect CID to the test network (DHCP < 1 s). Power on the CID.                                    | CID begins booting; NetworkManager starts DHCP negotiation.                                              |
| 2    | Monitor NetworkManager journal: `journalctl -u NetworkManager -f`                                   | DHCP lease is obtained within 1 second. Assigned IP address is non-empty and appears in journal.         |
| 3    | Monitor CID Recent Activities log for the first 5 minutes after boot.                              | No "Resolved IPs did not match assigned IP ''" entries appear. No network-service restart events logged. |
| 4    | Open CID Hub and check device status for the CID.                                                  | CID shows as **Connected / Online** within 2 minutes of boot completion.                                 |
| 5    | Verify the resolved hostname IP in the agent matches the DHCP-assigned IP.                         | Hostname resolves to the same IP address assigned by DHCP. No empty-IP cache entries in logs.            |

---

### TC-STORY-7507-02 â€” Slow DHCP (9 s, bug scenario): CID comes online after delay

| Field           | Value                                                             |
|-----------------|-------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7507-02                                                   |

| **Title**       | Slow DHCP (9 s, bug scenario): CID comes online after delay      |
| **Type**        | Regression                                                        |
| **Priority**    | High                                                              |
| **Automation**  | Yes                                                              |

**Prerequisites**

- CID hardware with fix applied.
- DHCP server (or traffic-shaping tool) configured to introduce a 9-second response delay.
- Access to NetworkManager journal, CID Recent Activities, and CID Hub.

**Test Data**

| Field                  | Value                        |
|------------------------|------------------------------|
| DHCP response time     | ~9 seconds                   |
| Expected assigned IP   | 10.1.30.77 (or equivalent)   |
| Observation window     | 10 minutes after boot        |

**Steps**

| Step | Action                                                                                              | Expected Result                                                                                          |
|------|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| 1    | Configure test DHCP to delay response by 9 seconds. Power on the CID.                              | CID boots. DHCP negotiation begins; lease is not immediately received.                                   |
| 2    | Monitor NetworkManager journal during boot.                                                         | After ~9 seconds, DHCP lease is obtained. Assigned IP (e.g., 10.1.30.77) appears in the journal.        |
| 3    | Monitor CID Recent Activities log for the first 10 minutes.                                        | At most one or two "Resolving hostname to IP" entries logged while waiting for DHCP. No empty-IP loop.  |
| 4    | Verify no indefinite restart cycle in Recent Activities.                                           | No repeated "Resolved IPs ... did not match assigned IP ''" sequence. No network-restart events cycling every ~5.5 minutes. |
| 5    | Check CID Hub device status.                                                                       | CID shows as **Connected / Online** within a reasonable time (<= 3 minutes after DHCP lease obtained).  |
| 6    | Inspect agent logs to confirm cached IP is non-empty after DHCP completes.                        | Log shows valid IP (e.g., 10.1.30.77) cached by the hostname-resolution agent. No blank-string cache entry. |

---

### TC-STORY-7507-03 â€” Boundary: DHCP responds at exactly 5 seconds

| Field           | Value                                                             |
|-----------------|-------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7507-03                                                   |

| **Title**       | Boundary: DHCP responds at exactly 5 seconds                     |
| **Type**        | Boundary                                                          |
| **Priority**    | High                                                              |
| **Automation**  | Yes                                                              |

**Prerequisites**

- CID with fix applied; DHCP delay configurable to exactly 5 seconds.

**Test Data**

| Field              | Value       |
|--------------------|-------------|
| DHCP response time | 5 seconds   |

**Steps**

| Step | Action                                                                                    | Expected Result                                                                                |
|------|-------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| 1    | Set DHCP delay to exactly 5 seconds. Boot the CID.                                       | DHCP lease is obtained at the 5-second mark.                                                   |
| 2    | Monitor NetworkManager journal and Recent Activities for 10 minutes.                     | No empty-IP caching, no indefinite restart loop. CID comes online successfully.               |
| 3    | Verify CID Hub shows device as Connected.                                                | CID is online within â‰¤ 3 minutes of boot completion.                                           |

---

### TC-STORY-7507-04 â€” Boundary: DHCP responds at 8 seconds

| Field           | Value                                                             |
|-----------------|-------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7507-04                                                   |

| **Title**       | Boundary: DHCP responds at 8 seconds                             |
| **Type**        | Boundary                                                          |
| **Priority**    | High                                                              |
| **Automation**  | Yes                                                              |

**Prerequisites**

- CID with fix applied; DHCP delay configurable to 8 seconds.

**Test Data**

| Field              | Value      |
|--------------------|------------|
| DHCP response time | 8 seconds  |

**Steps**

| Step | Action                                                                                    | Expected Result                                                                                |
|------|-------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| 1    | Set DHCP delay to 8 seconds. Boot the CID.                                               | DHCP lease obtained at ~8 seconds.                                                             |
| 2    | Monitor NetworkManager journal and Recent Activities for 10 minutes.                     | No empty-IP caching, no restart loop. CID comes online.                                       |
| 3    | Confirm CID Hub shows device as Connected.                                               | CID online within â‰¤ 3 minutes of DHCP lease.                                                  |

---

### TC-STORY-7507-05 â€” Boundary: DHCP responds at 10 seconds

| Field           | Value                                                             |
|-----------------|-------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7507-05                                                   |

| **Title**       | Boundary: DHCP responds at 10 seconds                            |
| **Type**        | Boundary                                                          |
| **Priority**    | High                                                              |
| **Automation**  | Yes                                                              |

**Prerequisites**

- CID with fix applied; DHCP delay configurable to 10 seconds.

**Test Data**

| Field              | Value       |
|--------------------|-------------|
| DHCP response time | 10 seconds  |

**Steps**

| Step | Action                                                                                    | Expected Result                                                                                   |
|------|-------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| 1    | Set DHCP delay to 10 seconds. Boot the CID.                                              | DHCP lease obtained at ~10 seconds.                                                               |
| 2    | Monitor NetworkManager journal and Recent Activities for 10 minutes.                     | No empty-IP caching, no restart loop. CID comes online.                                          |
| 3    | Confirm CID Hub shows device as Connected.                                               | CID online within â‰¤ 3 minutes of DHCP lease.                                                     |
| 4    | Confirm no regression vs TC-STORY-7507-02 at 9 seconds.                                  | Behaviour at 10 s is consistent with behaviour at 9 s â€” device still comes online without looping.|

---

### TC-STORY-7507-06 â€” Boundary: DHCP responds at 15 seconds

| Field           | Value                                                             |
|-----------------|-------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7507-06                                                   |

| **Title**       | Boundary: DHCP responds at 15 seconds                            |
| **Type**        | Boundary                                                          |
| **Priority**    | Medium                                                            |
| **Automation**  | Yes                                                              |

**Prerequisites**

- CID with fix applied; DHCP delay configurable to 15 seconds.

**Test Data**

| Field              | Value       |
|--------------------|-------------|
| DHCP response time | 15 seconds  |

**Steps**

| Step | Action                                                                                    | Expected Result                                                                                |
|------|-------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| 1    | Set DHCP delay to 15 seconds. Boot the CID.                                              | DHCP lease obtained at ~15 seconds.                                                            |
| 2    | Monitor NetworkManager journal and Recent Activities for 15 minutes.                     | No indefinite restart loop. CID tolerates the extended wait and comes online.                 |
| 3    | Confirm CID Hub shows device as Connected.                                               | CID is online. Delay from boot to online is longer than the < 1 s case, but CID does not loop.|

---

### TC-STORY-7507-07 â€” Boundary: DHCP responds at 30 seconds

| Field           | Value                                                             |
|-----------------|-------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7507-07                                                   |

| **Title**       | Boundary: DHCP responds at 30 seconds                            |
| **Type**        | Boundary                                                          |
| **Priority**    | Medium                                                            |
| **Automation**  | Yes                                                              |

**Prerequisites**

- CID with fix applied; DHCP delay configurable to 30 seconds.

**Test Data**

| Field              | Value       |
|--------------------|-------------|
| DHCP response time | 30 seconds  |

**Steps**

| Step | Action                                                                                    | Expected Result                                                                                |
|------|-------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| 1    | Set DHCP delay to 30 seconds. Boot the CID.                                              | CID waits; DHCP lease obtained at ~30 seconds.                                                 |
| 2    | Monitor NetworkManager journal and Recent Activities for 20 minutes.                     | No indefinite restart loop. CID eventually comes online once DHCP lease is granted.           |
| 3    | Verify Recent Activities do not show endless empty-IP resolution messages.               | At most a brief waiting period logged, not the repeated-failure cycle from the bug.            |
| 4    | Confirm CID Hub shows device as Connected.                                               | CID is online. Boot-to-online time is extended but the device is functional.                  |

---

### TC-STORY-7507-08 â€” Negative: DHCP server completely unreachable

| Field           | Value                                                                   |
|-----------------|-------------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7507-08                                                         |

| **Title**       | Negative: DHCP server completely unreachable â€” CID fails gracefully    |
| **Type**        | Negative                                                                |
| **Priority**    | High                                                                    |
| **Automation**  | No                                                                      |

**Prerequisites**

- CID with fix applied.
- DHCP server blocked entirely (firewall rule or disconnected network path) so no lease can ever be obtained.
- Access to NetworkManager journal and CID Recent Activities.

**Test Data**

| Field              | Value                       |
|--------------------|-----------------------------|
| DHCP response      | No response (server blocked)|
| Observation window | 30 minutes                  |

**Steps**

| Step | Action                                                                                              | Expected Result                                                                                            |
|------|-----------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| 1    | Block DHCP server. Boot the CID.                                                                   | CID attempts DHCP negotiation; no lease is received.                                                       |
| 2    | Monitor NetworkManager journal for 30 minutes.                                                     | DHCP timeout/failure is logged. The CID does NOT enter an indefinite silent restart loop.                 |
| 3    | Check Recent Activities log.                                                                       | Clear error is logged indicating no network connectivity / DHCP failure. Not a blank-IP resolution loop.  |
| 4    | Check CID Hub device status.                                                                       | CID shows as **Offline / Not Connected** with an informative status message. It does not appear as hanging silently. |
| 5    | Restore DHCP connectivity and verify CID recovers.                                                 | After DHCP becomes available, CID obtains a lease and comes online without requiring a manual reboot.      |

---

### TC-STORY-7507-09 â€” Regression: No indefinite loop in Recent Activities after fix (9 s DHCP)

| Field           | Value                                                                          |
|-----------------|--------------------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7507-09                                                                |

| **Title**       | Regression: No indefinite loop in Recent Activities after fix (9 s DHCP)     |
| **Type**        | Regression                                                                     |
| **Priority**    | High                                                                           |
| **Automation**  | Yes                                                              |

**Prerequisites**

- CID with fix applied; DHCP delay = 9 seconds.
- CID Recent Activities log and NetworkManager journal accessible.
- Observation window: 30 minutes minimum to confirm no recurring ~5.5-minute restart cycle.

**Test Data**

| Field                          | Value                                          |
|--------------------------------|------------------------------------------------|
| DHCP response time             | 9 seconds                                      |
| Bug cycle interval (pre-fix)   | ~5.5 minutes (restarts at ~19:20, 19:25, ...)   |
| Observation window             | 30 minutes                                     |

**Steps**

| Step | Action                                                                                                    | Expected Result                                                                                                      |
|------|-----------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| 1    | Configure DHCP delay to 9 seconds. Boot the CID. Start a 30-minute observation timer.                   | CID boots. DHCP lease obtained at ~9 seconds.                                                                        |
| 2    | Continuously monitor Recent Activities log for entries matching "Resolving '<hostname>' to its IP address: ''" (empty IP). | Zero or at most one such entry during initial boot. No repeated empty-IP entries every minute.                      |
| 3    | Monitor for network-service restart events (`network services and agent restarted`) in Recent Activities.| No restart events occur after the initial boot completes. The ~5.5-minute restart cycle from the bug is absent.     |
| 4    | At the 10-minute mark, confirm CID is online in CID Hub.                                                 | CID shows **Connected / Online**. Not stuck in "never comes online" state.                                          |
| 5    | Continue monitoring to the 30-minute mark. Check Recent Activities for any restart cycles.               | No restart cycles observed. Device remains online and stable throughout the 30-minute window.                        |
| 6    | Verify NetworkManager journal does not show repeated DHCP renegotiations triggered by the agent restart. | DHCP lease held continuously; no unexpected lease renewals caused by agent restarts.                                |

---

### TC-STORY-7507-10 â€” Regression: Activity log shows successful boot after slow DHCP

| Field           | Value                                                                       |
|-----------------|-----------------------------------------------------------------------------|
| **TC ID**       | TC-STORY-7507-10                                                             |

| **Title**       | Regression: Activity log shows successful boot after slow DHCP (9 s)       |
| **Type**        | Regression                                                                  |
| **Priority**    | Medium                                                                      |
| **Automation**  | Yes                                                              |

**Prerequisites**

- CID with fix applied; DHCP delay = 9 seconds.
- Access to CID Recent Activities log (full boot sequence).

**Test Data**

| Field              | Value      |
|--------------------|------------|
| DHCP response time | 9 seconds  |

**Steps**

| Step | Action                                                                                             | Expected Result                                                                                      |
|------|----------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| 1    | Configure DHCP delay to 9 seconds. Boot the CID. Capture the full Recent Activities log.          | Boot sequence is recorded in Recent Activities.                                                      |
| 2    | Inspect Recent Activities for the hostname-resolution entry after DHCP assignment.                 | Entry shows a valid, non-empty IP address (e.g., "Resolving '<hostname>' to its IP address: '10.1.30.77'"). |
| 3    | Verify the "Resolved IPs matched assigned IP" (or equivalent success) entry is present.           | Log contains a positive confirmation that IP resolution succeeded â€” no mismatch or empty-IP failure entry. |
| 4    | Confirm the activity log ends with a successful online / connected status event.                   | Final activity log entry reflects CID coming online successfully. No error or loop-restart entries at the end of the sequence. |

---
## Open Questions (Q&N Gate  -  Pending Responses)

> These questions were identified retroactively. TC authoring proceeded under accepted-risk. Post Q&N Jira comments on STORY-7507 before scheduling execution.

| Q/N # | Question | Ask | Blocks |
|---|---|---|---|
| Q/N-01 | Is sprint 111 delivering a **code fix** (agent retry/wait logic) or a **workaround** (config/network change)? TOPRAK,EMRE's question (2026-07-22) was not definitively answered. | PO (REHMAN,SUNIL) | TC-02 Fix Verification  -  steps differ for code fix vs config change |
| Q/N-02 | What is the exact DHCP delay threshold at which the fix applies? Is there a configurable timeout value in the agent? | Dev | TC-03, TC-04 boundary values |
| Q/N-03 | Is the DHCP simulation reproducible in the lab using `tc`/`netem` or a configurable DHCP server? Which approach is approved for lab use? | Dev / Lab | All boundary TCs (TC-03 through TC-05) |

**Status**: ⚠️ UNCONFIRMED  -  Jira Q&N comments not yet posted. Post manually on STORY-7507 @mentioning REHMAN,SUNIL (Q/N-01) and the Dev assignee (Q/N-02, Q/N-03).

---

## Test Coverage

> Defect regression tests (Mode D)  -  coverage mapped to bug scenario, not ACs. See Defect Summary for traceability.


