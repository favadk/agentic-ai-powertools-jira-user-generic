# GitHub Copilot Instructions for MCP Servers

## Project Context

This repository provides MCP (Model Context Protocol) servers for Jira, Bitbucket, and Confluence integration with GitHub Copilot.

## General Guidelines

When working with this project:

- **Use concrete facts only** - Base all statements on verifiable data from Jira, Bitbucket, Confluence, or code. Never make assumptions about missing information.
- **Avoid speculation** - If information is incomplete or unavailable, explicitly state what is missing rather than guessing or inferring.
- **Be concise** - Provide focused, relevant information without excessive elaboration. Keep responses direct and to the point.
- **Focus on effective solutions** - Prioritize optimal approaches and best practices. Don't spend time analyzing or documenting inefficient processes unless specifically requested.
- **Support claims with evidence** - Reference specific issue keys, commit hashes, file paths, or API responses when making technical statements.

- **For markdown files requiring diagrams, use Mermaid syntax** - When generating markdown files and a diagram is needed, use [Mermaid](https://mermaid-js.github.io/) syntax to embed diagrams directly in the document. This ensures diagrams are both human-readable and renderable in supported markdown viewers.

- **PDF Export Guidance** - Agents should inform users that if they need to export markdown files to PDF, they should use the recommended VS Code extension (`Markdown PDF`) for PDF export.

## MCP Servers

### Jira MCP Server

#### Issue Types

- Use "Defect" for defects (not "Bug").

#### How to Get Sprint Information

1. **Identify the project key** (e.g., `CDS2REP`).
2. **List Agile boards** for the project using the MCP API (`jira_jira_get_agile_boards`).
3. **Find the relevant board** (e.g., "CDS2 Reporting Board").
4. **Get active sprints** for the board (`jira_jira_get_sprints_from_board`).
5. **Retrieve issues in the sprint** using the sprint ID (`jira_jira_get_sprint_issues`).
6. **Reference issue keys and summaries** for reporting or documentation.
