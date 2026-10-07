---
description: Automation code quality standards, framework alignment criteria, and naming conventions — used by automation code preparation and review agents
---

# Automation Code Standards

## Framework Discovery — What to Identify

Before writing or reviewing any automation code, establish the following from the existing codebase:

| Aspect                  | What to look for                                                                              |
|-------------------------|-----------------------------------------------------------------------------------------------|
| **Framework**           | NUnit / xUnit / MSTest (C#) · JUnit / TestNG (Java) · pytest (Python) · Playwright / Cypress / Selenium (JS/TS) |
| **Base test class**     | Does every test class extend a shared base? What does it provide (driver init, login, config)? |
| **Lifecycle hooks**     | How is setup/teardown done — `[SetUp]`/`[TearDown]`, `BeforeEach`/`AfterEach`, fixtures?     |
| **Assertion library**   | FluentAssertions, Shouldly, NUnit Assert, Jest `expect`, pytest `assert`, etc.               |
| **Page Object pattern** | Does the project use Page Objects, Screen Objects, or Helper classes? Naming pattern?        |
| **Test data supply**    | Inline values, JSON/CSV data files, fixtures, test data builders, or parameterised tests?    |
| **Folder structure**    | Where do test files, page objects, helpers, and test data files live?                        |
| **Config/environment**  | How are environment URLs, credentials, and feature flags injected (env vars, config files)?  |

If the repository is not accessible, ask the user to describe the framework and share 1–2 representative test files before proceeding.

---

## Code Quality Rules

Every generated or reviewed test must satisfy all of the following:

### High Priority — Must meet before merge

- [ ] Each test method covers **one logical scenario** — single responsibility, one Arrange/Act/Assert cycle
- [ ] All **assertions verify the stated expected result** — "no exception thrown" is not a valid assertion
- [ ] **No hardcoded credentials, real emails, PII, or production URLs** in test code — use config/environment variables
- [ ] Tests are **independent and repeatable** — no shared mutable state, no order dependency between methods
- [ ] **Page Object or helper methods** are used — raw locators are not inlined in test method bodies
- [ ] Every test method **references the TC ID and AC item** it covers (comment block at the top)

### Medium Priority — Should fix before merge

- [ ] Method naming follows the project convention (default: `Should_{Action}_When_{Condition}`)
- [ ] Assertion failure messages are descriptive enough to diagnose a failure without reading the code
- [ ] Setup/teardown uses the same lifecycle hooks as existing tests in the project
- [ ] The test class extends the correct base class (if the project uses one)

### Low Priority — Recommended improvements

- [ ] Test data is externalised to a data file or fixture rather than inlined in the test method
- [ ] Unused imports, variables, and helper calls are removed
- [ ] No test method is empty, commented-out, or marked `[Ignore]`/`skip` without an explanation comment

---

## Framework Alignment Checklist

Use this when reviewing whether new test code is consistent with the rest of the project:

| Check                                     | How to verify                                                              |
|-------------------------------------------|----------------------------------------------------------------------------|
| Extends correct base test class           | Compare class declaration against existing test classes                    |
| Uses same lifecycle hooks                 | Compare `[SetUp]`/`BeforeEach` usage against existing tests                |
| Uses same assertion library               | Check import statements — mixed assertion libraries are a code smell       |
| Follows folder structure                  | New files placed in the same directories as equivalent existing test files |
| Page object methods used for UI actions   | No `driver.FindElement(By.Id(...))` directly in test methods               |
| No framework mixing                       | One test runner per project (e.g., not mixing NUnit and xUnit)             |

---

## Test Method Naming Convention

Default pattern (use project's own convention if one exists):

```
Should_{ExpectedOutcome}_When_{Condition}
```

**Examples:**
- `Should_ShowValidationError_When_RequiredFieldIsEmpty`
- `Should_RedirectToDashboard_When_LoginSucceeds`
- `Should_ReturnHttp400_When_PayloadIsMissing`

**Rules:**
- Name describes the *behaviour*, not the implementation
- Name is readable as a sentence without knowing the code
- Avoid `Test1`, `TC01`, or any name that requires reading the body to understand intent

---

## What NOT to Automate

Flag as **Manual Only** and exclude from automation scripts:

| Scenario type                          | Reason                                             |
|----------------------------------------|----------------------------------------------------|
| Exploratory / usability testing        | Requires human judgement                           |
| One-off data migration verification    | Not repeatable by definition                       |
| Tests requiring physical hardware      | Cannot be emulated reliably in CI                  |
| Tests with no deterministic assertions | Flaky tests add noise, not confidence              |
| Steps blocked by missing API endpoints | Automate once the endpoint exists                  |

If a TC is marked `Automation = Partial`, automate only the deterministic assertions and note what remains manual.
