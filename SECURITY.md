# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 1.x (current) | Yes |

## Reporting a vulnerability

**Do not open a public GitHub Issue for security vulnerabilities.**

Please report security issues by emailing the maintainer directly:

- Aurelien Clere — via [LinkedIn](https://www.linkedin.com/in/aurelien-clere/)

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fix (optional)

We will acknowledge receipt within 72 hours and aim to release a fix within 14 days
for confirmed critical issues.

---

## Security design

This plugin does not handle credentials directly. Depending on the deployment mode:

### Option A — Skills only

No network connection. Skills are plain Markdown files copied to the VS Code prompts
folder. No credentials required, no data transmitted.

### Option B — VS Code Local MCP

- Authentication uses your **Azure AD session** managed by VS Code — no PAT or secret needed.
- The MCP connection URL (`mcp.json`) contains your Power Platform environment ID,
  which is not a secret (it is visible in the Power Platform Admin Center to all admins).
- Ensure your `mcp.json` is excluded from version control via `.gitignore`.

### Option C — M365 Copilot (OAuthPluginVault)

- **OAuthPluginVault** — M365 Copilot handles token acquisition via the standard plugin
  OAuth flow. The token is scoped to your Azure AD tenant; anonymous requests are rejected.
- **No secrets in source code** — `manifest.json` only contains the environment URL and
  the OAuthPluginVault reference ID assigned by M365 Copilot admin centre.
- The BPA MCP endpoint enforces Azure AD authentication at the platform level — no
  additional ingress rules or custom auth configuration needed.

---

## Required permissions (least-privilege)

Grant users only the minimum roles required for their use case:

| Role / Permission | Where assigned | Required by |
|---|---|---|
| **BPA User** | Power Platform environment | All skills (MCP connection) |
| **D365 Finance — Basic User** | D365 Finance environment | All skills (financial data read) |
| **Finance Reporting** (optional) | D365 Finance | Required for consolidated entity P&L |
| **Power BI Viewer** | Power BI workspace | If BPA dataset is in a Premium workspace |

For read-only use cases, **BPA User** + **D365 Finance Basic User** is sufficient.
Do not grant **System Administrator** or **Finance Manager** roles unless explicitly required.

---

## What data the plugin can access

The plugin can only access data that the signed-in user has permission to see in BPA.
Row-level security (RLS) configured in the BPA Power BI dataset is respected — the plugin
cannot bypass it.

If a user does not have access to a particular legal entity or company, DAX queries
against that entity's data will return empty results, not an error.
