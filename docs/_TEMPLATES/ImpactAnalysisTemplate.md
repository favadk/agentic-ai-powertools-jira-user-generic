# Impact Analysis

**Life Sciences and Chemical Analysis Lifecycle**  
Impact Analysis

## Impact Analysis for `#<IssueID>`

## Document Information

| **Filename**         | Impact Analysis.dotx                     |
| -------------------- | ---------------------------------------- |
| **Current Owner**    | `<Owner>`                                |
| **Product/Release:** | `<ProductName>-<ToBeResolvedInRevision>` |
| **History**          |                                          |

---

## Related issue-tracker Defect(s)

| _Defect #_    | _Title_   |
| ------------- | --------- |
| **<IssueId>** | `<title>` |

---

## Problem description

`<Describe the issue(s) fixed in terms understandable by an end-user. No computer gibberish!>`

## Investigation / Fix

`<Describe the root cause and the fix provided.>`

---

## Affected Component(s)

Component: `<Component name>`

| Source Code Pool Management System | `<Pool location in Source Code Management System>` |
| ---------------------------------- | -------------------------------------------------- |
| Release Label                      | `<Label>`                                          |

---

## Impact / Test recommendation

### Impact and Amount of Required Test

`<Describe the impact to the user/system. Identify affected functions and workflows in the software. Identify any impact on localized versions of the software. Identify any impact on documentation (e.g., Online Help, manuals) as well. Identify the amount of software code requiring change and amount of dependencies on the code being changed:>`

#### Amount of software code requiring change

| Level  | Description                                                              | Mark |
| ------ | ------------------------------------------------------------------------ | ---- |
| Low    | small change such as a specific logic or formula change                  | ☐    |
| Medium | multiple low risk changes in different areas of the code                 | ☐    |
| High   | large change such as introduction of new functions or code restructuring | ☐    |

#### Amount of dependencies on the code being changed

| Level | Description                                                                        | Mark |
| ----- | ---------------------------------------------------------------------------------- | ---- |
| Low   | code being changed is only used for the specific software function with the defect | ☐    |
| High  | code being changed is part of a function called by multiple other functions        | ☐    |

#### Required Tests

| **Amount of software code requiring changes** | **Amount of dependencies** | **Required Test**                                                                                                         | Mark |
| --------------------------------------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------- | ---- |
| Low                                           | Low                        | Test whether the issue is fixed                                                                                           | ☐    |
| Low                                           | High                       | Test whether the issue is fixed and execute regression tests for the dependent functionality                              | ☐    |
| Medium                                        | Low                        | Test whether the issue is fixed and execute updated regression test for the changed functionality                         | ☐    |
| Medium                                        | High                       | Test whether the issue is fixed and execute updated regression tests and regression test for the dependent functionality  | ☐    |
| High                                          | Low                        | Test whether the issue is fixed and execute regression tests for the dependent functionality                              | ☐    |
| High                                          | High                       | Test whether the issue is fixed and execute updated regression tests and regression tests for the dependent functionality | ☐    |

#### Additional Checks

| Question                                                                                | Yes | No  |
| --------------------------------------------------------------------------------------- | --- | --- |
| Test in localized version required (specify language if not all languages are affected) | ☐   | ☐   |
| Is there an impact on documentation (specify affected documentation if appropriate)     | ☐   | ☐   |

---

### Test Recommendation

`<Based on the identified impact for each affected function/workflow, describe the minimal tests to be executed in order to make sure that the change fixed the issue and did not break the functionality. Please put yourself into the position of a tester and ask yourself whether you would understand what needs to be done in order to test the change.>`

---
