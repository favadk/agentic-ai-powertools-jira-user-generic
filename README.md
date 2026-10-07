# MCP Servers Installation Guide

This guide covers the installation and configuration of MCP (Model Context Protocol) servers for Jira, Bitbucket, and Confluence integration with GitHub Copilot.

The repository already includes a ready-to-use sample configuration at `.vscode/mcp.json` and local MCP binaries under `.tools/`.

## Prerequisites

- GitHub Copilot extension in Visual Studio Code
- The MCP server binaries for your platform (already included in `.tools` directory)

## GitHub Copilot Configuration

The default `mcp.json` included in this repository uses simulated URLs and dummy secret placeholders for local dry-run testing.

### Simulated Credentials for Local Testing

The checked-in `.vscode/mcp.json` uses:

- Dummy domains (`*.exampleqa.local`)
- Non-functional placeholder secrets (for example `DUMMY_JIRA_TOKEN_FOR_LOCAL_TESTING_ONLY`)

This keeps the branch fully portable for STLC framework demonstrations and prevents accidental use of real organization credentials.

### Configuration File Location

The sample file is already present at: `.vscode/mcp.json`

If you need a user-specific setup, copy it to your local workspace and replace placeholder values without committing secrets.

### Configuration Parameters

- **JIRA_URL**: Your Jira instance URL (dummy by default)
- **JIRA_PERSONAL_TOKEN**: Placeholder value for local simulation
- **JIRA_SSL_VERIFY**: Set to `"false"` if using self-signed certificates

- **BITBUCKET_URL**: Your Bitbucket instance URL (dummy by default)
- **BITBUCKET_TOKEN**: Placeholder value for local simulation
- **BITBUCKET_DEFAULT_PROJECT**: Default project key (optional)

- **CONFLUENCE_URL**: Your Confluence instance URL (dummy by default)
- **CONFLUENCE_PERSONAL_TOKEN**: Placeholder value for local simulation
- **CONFLUENCE_SSL_VERIFY**: Set to `"false"` if using self-signed certificates

- **lc-asssisthub.url**: Optional HTTPS MCP endpoint placeholder used for local/demo routing
- **lc-asssisthub.type**: Set to `"https"`

## Agent Modes (VS Code / GitHub Copilot)

This project integrates with GitHub Copilot and supports different "agent modes" you can select in the VS Code Copilot UI or the GitHub Copilot chat window. Agent modes allow switching between pre-configured behaviors or specialized assistants (for example, a Jira agent, a Bitbucket agent, or a Confluence agent). They are conceptually similar to chat modes and let you tailor Copilot to a particular system context.

How to use agent modes:

- Open the GitHub Copilot chat panel in VS Code (Copilot Chat view) or the in-editor Copilot chat widget.
- In the chat UI, look for the mode/agent selector near the top of the chat input (it may be a dropdown or a label). Click it to see available agents.
- Select an agent like "Jira", "Bitbucket", or "Confluence" to scope the assistant to that system. The selected agent will route queries to the corresponding MCP server defined in `.vscode/mcp.json`.

Tips for prompts and examples:

- To fetch issue details: `Get details for Jira issue PROJ-12345`
- To summarize a pull request: `Summarize PR #123 (include files changed and risk)`
- To find documentation: `Search Confluence for MCP server setup guide`

Note: If your VS Code installation doesn't show agent options, ensure you have the latest GitHub Copilot extension and that `mcp.json` is correctly configured. Administrators can add custom agents by extending the workspace MCP configuration.

## Usage

Once configured, the MCP servers will be available to Copilot via the agents you selected. You can use them to:

- Query Jira issues and create RCA documents
- Access Bitbucket repositories and pull requests
- Search and retrieve Confluence documentation

### Example Copilot Prompts

```text
Get details for Jira issue PROJ-12345
Show me the diff for PR #1303 in the SID project
Search Confluence for documentation about MCP servers
Create an RCA for issue PROJ-12345
```

## Troubleshooting

### Server Not Starting

1. Verify the MCP server executable exists at the path referenced in `.vscode/mcp.json` (or that the executable name is on your PATH)
2. Check the `.vscode/mcp.json` configuration
3. Ensure environment variables are correctly set
4. Check Visual Studio Code output panel (Copilot) for errors and the extension logs

### Authentication Issues

- If you switch from simulation to a real environment, inject credentials through local-only files or your secret manager.
- Keep dummy values in the repository and never commit real credentials.
- Check the URL endpoints are accessible from your network.

## Development Mode

For local development, run the MCP server binary directly and point the Copilot configuration to the local binary path. Example (PowerShell):

```powershell
# run the Jira server in the foreground for local development
& C:\path\to\jira-mcp.exe --dev
```

Refer to each server's `--help` output for supported flags.

## Additional Resources

- [Model Context Protocol Documentation](https://github.com/modelcontextprotocol)
- [GitHub Copilot Instructions](.github/copilot-instructions.md)
- [C# MCP SDK](https://github.com/modelcontextprotocol/csharp-sdk)
- [STLC Deployment Quickstart (Non-Technical Friendly)](docs/DEPLOYMENT-QUICKSTART.md)

## Documentation Workflow (MD to PDF)

Use this process for deployment documentation:

1. Edit the source Markdown file first (single source of truth), for example: `docs/DEPLOYMENT-QUICKSTART.md`.
2. Export a PDF for sharing with business and QA stakeholders.
3. Keep both artifacts aligned after every documentation update.

Recommended tool:

- VS Code extension: **Markdown PDF**

Suggested team rule:

- Markdown is authoritative for version control and reviews.
- PDF is the distribution format for sign-off and offline sharing.

## Security Notes

⚠️ **Important**: Keep only dummy placeholder secrets in version control.
