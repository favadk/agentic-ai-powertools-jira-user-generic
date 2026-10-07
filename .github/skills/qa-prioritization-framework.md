---
description: Three-tier priority/severity classification used consistently across all QA review activities
---

# QA Prioritization Framework

This framework applies consistently across Test Case Reviews, Automation Code Reviews, and Evidence Reviews.

## Priority Levels

### High Priority — Must Fix / Blocking

Issues in this tier **must be resolved before any sign-off or merge** can occur.

Examples:
- AC item with no corresponding test case or test step
- Missing evidence for a Failed or High Priority TC
- Defect not raised for a failed test step
- Test method covers the wrong AC item
- Assertions missing or always-passing (e.g., "no exception thrown")
- Hardcoded credentials, PII, or production data in test code
- Tests with shared mutable state or order dependency between methods
- Environment URLs hardcoded inline instead of read from config

### Medium Priority — Should Fix

Issues in this tier **should be resolved before sign-off or merge**, but may be conditionally approved with documented exceptions.

Examples:
- Evidence present but does not clearly match the expected result
- Test method naming doesn't follow project convention
- Raw locators inlined in test methods (should be in Page Objects / helpers)
- Expected result text is vague or paraphrased rather than verbatim
- Internal inconsistency between TC steps or expected results
- Each test method does not have a single logical responsibility

### Low Priority — Recommended Improvement

Issues in this tier are **optional improvements** at the reviewer's or tester's discretion.

Examples:
- Missing evidence for a Low-priority passing TC
- Test data not externalised to a data file or fixture
- Unused imports, variables, or helper calls
- Comment block missing TC ID / AC reference per test method
- Minor wording issues — only raise when explicitly requested

## Verdict Thresholds

| Verdict                      | Condition                                                         |
|------------------------------|-------------------------------------------------------------------|
| ✅ Approved                  | Zero High-priority issues; all Medium issues documented          |
| ⚠️ Approved with Comments    | Zero High-priority issues; Medium/Low issues noted for follow-up |
| ❌ Rejected                  | One or more High-priority issues remain unresolved               |

## Classification Rule of Thumb

- **Blocking** when the issue would mask a real defect, misrepresent coverage, or leave the system in an untested state.
- **Major** when it reduces quality or traceability but does not mask a defect.
- **Minor** when it is a style, clarity, or convenience improvement only.
- When in doubt, promote to the higher tier.
