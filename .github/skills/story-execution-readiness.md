---
description: Gate checks that must pass before starting test case execution — verifies story status and development section (branch, commits, PR merged)
---

# Story Execution Readiness

Before beginning any test execution activity, verify **both** gates below. If either gate fails, **do not proceed** — report the blocking condition to the user and stop.

---

## Gate 1 — issue-tracker Story Status

The story must be in **"Waiting for Verification"** status (or an equivalent status in the project workflow that signals development is complete and the story is ready for QA sign-off).

**How to check:**
1. Use `issue-tracker_get_issue` to retrieve the story.
2. Read `fields.status.name`.
3. Accepted statuses: `Waiting for Verification`, `Ready for Testing`, `In QA` — confirm the exact name used in the project.

**If the status is NOT one of the above:**
- Report: "Story `{STORY-KEY}` is currently in status **{status}**. Test execution cannot begin until the story moves to **Waiting for Verification**."
- Stop. Do not proceed.

---

## Gate 2 — Development Section (Branch, Commits, PR Merged)

The story's development section must show that a feature branch has been created, code has been committed, and the pull request has been **merged** to the target branch.

**How to check:**
1. Use `issue-tracker_get_development_information` with the story key.
2. Verify all three conditions:

| Condition                 | Field to check                              | Required value          |
|---------------------------|---------------------------------------------|-------------------------|
| Branch exists             | `devSummary.branch.count` > 0               | At least 1 branch       |
| Commits present           | `devSummary.commit.count` > 0               | At least 1 commit       |
| Pull Request merged       | `devSummary.pullrequest.overall.state`      | `MERGED`                |

**If any condition fails:**
- Report the specific failing condition, for example:
  - "No pull request found for `{STORY-KEY}` — development may not be complete."
  - "Pull request exists but status is **OPEN** (not MERGED) — wait for PR to be merged before executing."
- Stop. Do not proceed.

---

## Both Gates Pass — Proceed

Only when Gate 1 and Gate 2 both pass, continue to the test execution workflow. Confirm to the user:

> "Story `{STORY-KEY}` is in **{status}** and the PR is **MERGED**. Execution readiness confirmed — proceeding."
