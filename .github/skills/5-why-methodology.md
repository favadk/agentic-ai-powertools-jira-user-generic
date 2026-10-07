---
description: 5-Why root cause analysis methodology, process steps, classifications, and best practices
---

# 5-Why Methodology

## What RCA Is — and Isn't

**RCA Is:**
- A mechanism for analysing and problem-solving to identify root causes of defects
- A team activity focused on future-proofing and process improvement
- An investment that rewards teams with better quality products and processes

**RCA Is Not:**
- Not a "blame game" or shortcoming determination
- Not about eliminating symptoms alone — problems must be addressed at the source
- Not a postmortem, but a future-proofing technique

## When to Apply

- **Mandatory**: For each defect that is part of a Hotfix (Software Update)
- **Timing**: After investigation is complete, but before the fix is implemented
- **Team Activity**: Involves Scrum Master, Architect, Engineer, Tester, and Product Owner

## The 5-Why Process

1. **Write down the specific problem.** Be precise and complete — this helps the team focus on the same issue.
2. **Ask "Why did this problem happen?"** Write the answer below the problem statement.
3. **If the answer doesn't identify the root cause**, ask "Why?" again and document the answer.
4. **Repeat until the team agrees** the root cause is identified. This may take fewer or more than five iterations.
5. **Note**: There can be more than one root cause, and more than one solution.

## Root Cause Classifications

### Requirements-Related
- Missing or Inadequate Requirements
- Incorrect Requirements
- Ambiguous Requirements

### Development-Related
- Coding — incorrect logic
- Coding — code quality
- Handling of boundary conditions
- Error Handling
- Security Infrastructure
- Compliance not considered

### Testing-Related
- Impact analysis not sufficient (QA did not test the correct area of code)
- Test case coverage gaps
- Language/localization testing gaps

### External Factors
- Issue with third party
- ExampleOrg Driver/Add-on Issue

### Other
- Not designed for specific workflow or action (enhancement request, not a defect)

## Best Practices

- Encourage every team member to share their thoughts.
- Avoid "finger pointing" at individuals or functions.
- Focus on identifying ways to prevent issues in the future.
- Remember: QA is the final line of defence, not a catch-all for coding errors.
- Use concrete facts only — base statements on verifiable data from Jira, Bitbucket, or code.
- Avoid speculation — if information is missing, state what is missing rather than guessing.
- Avoid stopping at surface-level causes ("the test didn't catch it") — continue asking "Why?".
