# Slide 1

**Root Cause Analysis of Customer Defects**
**1**

# Slide 2

**Background**

- In order to better serve customer needs, we would like to perform root cause analysis for Serious customer reported defects.
- Initial focus is on customer defects fixed as part of an Update (aka Hotfix).
  **Key data points we are looking for are**
  **What caused this defect and**
  **how can we avoid such defects.**
  **2**
- RCA (Root cause analysis) is a mechanism of analyzing and problem solving techniques, to identify its root cause. We brainstorm, read and dig the defect to identify whether the defect was due to “testing miss”, “development miss” or was a “requirement or design miss”.

# Slide 3

**Why perform Root cause analysis (RCA)?**

- The primary benefit of root cause analysis is that it identifies fundamental problems in the development process, allowing teams to enact corrective measures that fix those problems and prevent them from recurring in the future. As a result, there is less rework and fewer defects in the released product
- It is not for “Blame game” or to determine shortcomings of a team.
- RCA also provides basis for process improvements / training needs
  **Improves product quality over time**
- Elimination of the symptoms of the problems is not alone sufficient to address the problem, it has to be addressed at the source. If you solve a problem at this root level, it is highly probable that you can prevent its recurrence.
  **3**

# Slide 4

**Root Cause Analysis 5-Why Example (video)**
**https://www.youtube.com/watch?v=Ps9hoDeY1Cw**
**4**

# Slide 5

**Process**

- RCA is not Postmortem but a Future Proofing technique.
  **RCA is a team activity.**
- This is a component team exercise. (Scrum Master, Architect, Engineer, Tester and PO)
- Ideal time for RCA is after investigation is complete, but before fix is implemented as enough information is available to provide an accurate solution.
- Team takes it up during a team meeting like sprint planning etc. (prior to this, it is expected that both engineer and test team member assigned to specific defect have done their investigation)
- Root cause of the defect and mitigation plan (if any) are discussed
- Shared reference page updated by Scrum Master. (until issue-tracker fields are added)
  **Plan is to add RCA fields to issue-tracker.**
  **5**

# Slide 6

**Detailed process – 5 Whys**

- Write down the specific problem. Writing the issue helps you formalize the problem and describe it completely. It also helps a team focus on the same problem.
- Ask Why the problem happens and write the answer down below the problem.
- If the answer you just provided doesn’t identify the root cause of the problem that you wrote down in Step 1, ask Why again and write that answer down.
- Loop back to step 3 until the team is in agreement that the problem’s root cause is identified. Again, this may take fewer or more times than five Whys.
- There could be more than 1 root cause and more than 1 solution.
  **6**

# Slide 7

**Proposed Classifications**
**Missing/ Inadequate Requirements**
**Incorrect Requirements**
**Ambiguous Requirements**
**Issue with third party**
**Vendor Driver/Add-on Issue**
**Coding – incorrect logic**
**Coding – code quality**
**Handling of boundary conditions**
**Error Handling**
**Security Infrastructure**
**Compliance not considered**

- impact analysis not sufficient (QA not test correct area of code)
- Not designed or specific workflow or action (not a defect)
  **enhancement request**
  **7**

# Slide 8

**Example (Requirements)**
**Software Update X was recalled**
**Q – Why was it recalled**

- Answer: It was recalled as customer did not agree to the way we addressed an issue
- Q – Why did we build something that customer could not use?
- Answer: We built as per the acceptance criteria which did not meet customer expectation
- Q – Why did requirements not match customer expectations?
- Answer: This was a new feature and we did not validate our design / implementation with customer
- Q – Why was design not confirmed with customer
- Answer: We did not have time as the defect was added to the update at last minute
  **Potential Improvements**
  **Avoid changing scope of an update after I/D**
  **Always validate requirement with customer expectations**
  **Avoid adding “design defects” to an Update**
  **8**

# Slide 9

**Example (Coding)**

- Customer reported that when printing sequence report with a specific instrument causes crash
  **Q – Why did software crash**
  **Answer: Software crashed because of a unhandled exception**
  **Q – Why was exception thrown**
- Answer: Exception was thrown because of Common Language Specification (CLS) compliance check failed
  **Q – Why did CLS compliance check fail**
- Answer: Code was expecting ID to start with a alphabetic character as required by CLS, But this driver was providing a ID starting with a number.
- Q – Why did driver provide ID which is not CLS compliant?
- Answer: Driver team was not aware of specific requirements for ID parameter.
  **Potential Improvements**
- Validate that the ID is valid before passing to APIs
- Prepend IDs sent by driver with a alphabet character such as ID\_
- If there are specific requirements for a parameter, it should be clearly documented
  **9**

# Slide 10

**Example (Testing)**

- Some calculations when added to report causes crash at a Chinese customer. Support reported that crash is not reproducible in English language or when using other calculations in Chinese.
- Q – Why did it fail at customer site
- Answer: Customer is using Chinese O/S and adding reportable item x to the report. Crash is seen only with specific combination of Chinese language and reportable item x.
- Q – Why does it fail only on specific combination?
- Answer: String used by item x was not supposed to be translated but did get translated in Chinese
- Q – Why did we not catch it during our testing?
- Answer: Although we tested this item in English and most other items in multiple languages, this specific combination was not tested.
  **Q – Why was this combination not tested**
- Answer: It was a new item added in this revision and test case for localized language was not updated to include this new item in localized languages
- Q – Why was string that was not supposed to be translated got translated
- Answer: This string was not marked ‘Read-Only” in Passolo and localization team always translates all untranslated string that is not “Read-only”
  **Potential Improvements**
- During story development, update existing test cases for all languages as applicable
- Mark all strings that are not to be translated as read-only during development
  **10**

# Slide 11

- Example (Other)Teams were not able to achieve expected velocity during Sprint X
- Q – Why were teams not able to close story points
  **Answer: Daily builds not available to verify stories**
  **Q – Why did daily builds fail?**
  **Answer: Builds were timing out**
  **Q – Why did builds timeout?**
  **Answer: due to network clogging**
  **Potential solution: Invest in additional network infrastructure**
- If you stopped here and assumed network clogging is root cause, you would invest in bigger network bandwidth to solve this problem, which is not best solution. If you dig deeper to determine accurate root cause you may uncover much simpler solution.
  **Q – Why did network clog frequently?**
- Answer: Because DGG servers were using most of available network bandwidth
- Q – Why did DGG servers use so much bandwidth?
- Answer: Because Servers were running daily archives of large amount of data which was taking almost whole day
- Potential solution: IT to work with DGG and determine why it was being backed up daily and if it was required, find better archiving method.
  **11**

# Slide 12

**FAQ**

- Q – Is RCA optional? I feel it is not best use of my time.
- Answer: RCA for “Software Update” defects is not optional. Several studies have shown that RCA results in improved product quality.
- Q – I love RCA, can we do it for other defects too.
- Answer: Feel free to use team’s spare time to perform RCA for other defects. Remember to strike a good balance between product development and team improvement.
- Q – Where can I learn more about RCA process
- Answer: Google, YouTube, etc. There are also books available on this topic.
  **12**

# Slide 13

**Final Thoughts**

- Root Cause analysis is an investment that will reward us with better quality product and processes. More we put in, more we will get out of it.
- During RCA process encourage every member to share their thoughts.
- During RCA avoid “finger pointing” a member or a function. Goal is not to determine why we went wrong, but to identify ways to prevent it in future.
- Consider QA as final line of defense and not a catch-all for coding errors. Test teams may not be able to test every item in all possible combinations and scenarios.
  **13**

# Slide 14

**Questions / Suggestions**
**14**

# Slide 15

**Root cause analysis**

- Root Cause Analysis (RCA) MUST be performed for each defect that is part of a Hotfix (aka Update)
- RCA information needs to be entered in issue-tracker (and not on an external reference page). There are fields available in issue-tracker to record RCA.
- Go to the defect in issue-tracker for which RCA information is to be entered
- Switch to “Root Cause Analysis” Tab in edit mode
  **Choose Appropriate classification**
  **Enter Root cause information in The RCA field**
  **Enter mitigation plan**
  **Add any additional comments**
  **Take a picture of RCA board and attach**
  **it to the defect**
  **November 24, 2022**
  **Title Confidentiality label Regulatory statement (if applicable)**
  **15**
