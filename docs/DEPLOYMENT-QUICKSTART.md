# STLC Framework Deployment Quickstart (Non-Technical Friendly)

This guide helps QA teams start using this framework with minimal setup.

## Goal

By the end of this guide, you will be able to:

1. Open the project in VS Code.
2. Use safe demo settings with no real credentials.
3. Run a simple validation check.
4. Know what to update when moving to a real environment.

## What You Need

1. Windows, macOS, or Linux machine.
2. Visual Studio Code installed.
3. GitHub Copilot extension enabled in VS Code.
4. This repository on your machine.

## Option A: Demo Mode (Recommended First)

Use this mode for learning, workshops, and internal demos.

1. Open the repository folder in VS Code.
2. Confirm the file `.vscode/mcp.json` exists.
3. Confirm it contains `exampleqa.local` URLs and `DUMMY_...` tokens.
4. Open Copilot Chat in VS Code.
5. Ask a safe test prompt, such as:

```text
List available issue-tracker tools
```

Expected result:

- The workspace starts with placeholder settings.
- No production credentials are required.
- No real issue-tracker/source-control/knowledge-base changes are made.

## Option B: Real Environment Mode

Use this mode only when your admin approves real connectivity.

1. Keep `.vscode/mcp.json` in source control with dummy values.
2. Create local-only overrides for real URLs and tokens.
3. Never commit real tokens, passwords, or secrets.
4. Validate access with read-only checks first.
5. After validation, enable write operations if needed.

## 10-Minute Validation Checklist

1. Project opens in VS Code without errors.
2. Copilot Chat can see configured MCP servers.
3. Demo URLs still point to `exampleqa.local` in tracked files.
4. Tracked files contain no real credentials.
5. Team can run one sample read-only prompt.

## Common Questions

### Is this setup safe for sharing with other teams?

Yes, if tracked files keep dummy values only.

### Do we need deep DevOps knowledge to start?

No for demo mode. Basic VS Code usage is enough.

### When do we need technical help?

You may need engineering support when:

1. Connecting to real enterprise systems.
2. Managing secrets and network rules.
3. Setting advanced permissions and governance.

## Recommended Rollout Path

1. Start with demo mode for all QA users.
2. Train with read-only prompts.
3. Pilot real environment with a small admin group.
4. Expand to full STLC usage after governance checks.

## Security Reminder

Never store real tokens or passwords in tracked files. Keep credentials in local-only or approved secret stores.
