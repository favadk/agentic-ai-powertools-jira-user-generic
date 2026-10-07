---
description: Evidence quality standards and per-result-type review rules for test execution and evidence review
---

# Evidence Quality Standards

## Evidence Granularity — Steps vs Actions

A test case step may contain **multiple sequential actions** that must be performed before an observable result is produced. Evidence must reflect this:

| Level       | What it is                                               | Evidence required                                              |
|-------------|----------------------------------------------------------|----------------------------------------------------------------|
| **Action**  | A single UI interaction or operation within a step (e.g., fill a field, click a button, submit a form) | Screenshot or log entry after any action that changes system state |
| **Step**    | A logical group of related actions that together produce a verifiable outcome | Screenshot of the final UI/system state confirming the expected result |

**Rule:** When a step contains more than one action, capture evidence at **each action that changes observable state**, not just the final step outcome. If an action produces no visible change (e.g., hover, keyboard shortcut), a single combined screenshot at the end of that action group is acceptable.

**Examples:**
- Step: "Log in and navigate to Reports" has 3 actions: (1) Enter username → screenshot, (2) Enter password → optional, (3) Click Login → screenshot of logged-in landing page
- Step: "Configure filter and run report" has 2 actions: (1) Set filter values → screenshot, (2) Click Run → screenshot of report output
- Step: "Verify error on empty submit" has 1 action: Click Submit → screenshot showing error message

---

## Quality Criteria

Good evidence must satisfy all four of the following:

| Criterion        | Definition                                                                                              |
|------------------|---------------------------------------------------------------------------------------------------------|
| **Specificity**  | Shows the exact UI state, data values, or output matching the TC expected result at that action/step   |
| **Traceability** | Filename references the TC ID, step, and action index (e.g., `TC01_Step3_Act2_PASS.png`)               |
| **Freshness**    | Dated or versioned to match the execution cycle — not reused from a prior cycle                        |
| **Completeness** | All state-changing actions within a step are evidenced, plus the final step outcome                    |

## Per-Result-Type Review Rules

### For PASS results
- [ ] Evidence is referenced for the **final action/outcome** of each step (screenshot, log, or screen recording)
- [ ] For steps with multiple state-changing actions: each action has its own evidence item
- [ ] Evidence matches the actual expected result stated in the TC
- [ ] Evidence is specific to this execution — not a generic or reused screenshot
- [ ] For High Priority TCs: per-action evidence is **mandatory** — flag missing evidence as a Blocking gap

### For FAIL results
- [ ] Evidence shows the **exact action** where the failure occurred (not just the end state)
- [ ] Failure screenshot includes: the step number, the action attempted, and the resulting error or unexpected state
- [ ] Actual result is recorded **verbatim** — not paraphrased
- [ ] A issue-tracker Defect key is linked to the failure
- [ ] Defect summary accurately describes the failing action and observed behaviour

### For BLOCKED / SKIPPED results
- [ ] A clear reason is documented for the block or skip
- [ ] The specific action that caused the block is identified (if applicable)
- [ ] A re-test plan or action owner is noted

## Screenshot Naming Convention

```
TC{nn}_Step{i}_Act{j}_{status}.png
```

| Token     | Meaning                                         |
|-----------|-------------------------------------------------|
| `TC{nn}`  | Test case number (e.g., `TC01`)                 |
| `Step{i}` | Step number within the TC (e.g., `Step3`)       |
| `Act{j}`  | Action index within the step (e.g., `Act2`). Omit (`Act1` implied) when a step has only one action. |
| `{status}`| `PASS`, `FAIL`, or `BLOCK`                      |

**Examples:**
- `TC01_Step3_PASS.png` — step has one action, passed
- `TC02_Step5_Act1_PASS.png`, `TC02_Step5_Act2_FAIL.png` — step has two actions; failed at action 2
- `TC03_Step2_Act3_BLOCK.png` — step blocked at action 3

Store in: `docs/TestExecution/{sprint-slug}/evidence/{STORY-KEY}/`

## Evidence Gap Severity

| Severity     | Criteria                                                                                          |
|--------------|---------------------------------------------------------------------------------------------------|
| **Blocking** | Missing evidence for a state-changing action in a High Priority or Failed step; Defect not logged |
| **Major**    | Evidence present but does not pinpoint the failing action; actual result vague                    |
| **Minor**    | Missing evidence for a non-state-changing action in a Low/Medium Priority Pass step              |
