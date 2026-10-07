---
description: Code review criteria, scope boundaries, and behavioral rules for all code review agents
---

# Code Review Criteria

## What to Review

### Code Quality Issues
- Typos and inconsistencies that cause incorrect behaviour
- Possible crashes or bugs (null dereferences, unhandled exceptions, off-by-one errors)
- Anti-patterns for the language/framework in use
- Framework-specific gotchas

### Documentation
- Interfaces and public methods have meaningful comments
- Error log messages match the actual problem being logged

### Style Compliance
- Violations of the project's ESLint, Prettier, or `.editorconfig` rules
- Naming conventions that clearly deviate from the project standard

## What NOT to Review

Do **not** comment on:
- Missing ARIA labels
- Missing JSDoc comments on private/internal methods
- Good changes or explanations of what changed
- Issues that existed **before** the current PR or branch (pre-existing issues)
- Cosmetic whitespace or minor naming variations that don't violate a documented convention

## Behavioral Rules

- ❌ NEVER ask for confirmation before proceeding with the review
- ❌ NEVER comment on good changes or explain what a change does
- ❌ NEVER modify files — review is always read-only
- ✅ Always base findings on actual code — read the files, never assume their content
- ✅ Always reference specific file path, line number, and method name for each finding
- ✅ Keep suggestions crisp and actionable — include exact fix or replacement text
- ✅ Persist until all changed files are reviewed

## Finding Format

For each finding, provide:

```
File: <filename>
Line(s): <line number(s)>
Issue: <clear, concise description of the problem>
Suggestion: <actionable recommendation or exact replacement code>
```

**Example:**
```
File: src/utils/validator.ts
Line(s): 42-45
Issue: Potential null pointer exception when user.email is undefined
Suggestion: Add null check before calling .toLowerCase() — use: user.email?.toLowerCase()
```
