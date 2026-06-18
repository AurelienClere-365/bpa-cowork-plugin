# Privacy Policy — BPA Analytics Cowork Plugin

**Last updated: 2026**

## What data this plugin processes

The BPA Analytics Cowork Plugin provides AI assistant skills that call the
Microsoft-hosted Business Performance Analytics MCP server on your behalf.
Queries and responses travel between your AI assistant and your own
Dynamics 365 / Power Platform environment.

- **No personal data is collected, stored, or transmitted by the plugin authors.**
- When using VS Code Local MCP mode (Option B), all traffic stays between your
  machine and your Power Platform environment — the plugin authors have zero visibility.
- When using the Azure Connector (Option C), the MCP server is Microsoft-hosted inside
  your own tenant. The authors have no access to your deployment, logs, or queries.

---

## What the plugin does NOT do

- It does not transmit data to any third-party service other than the AI assistant
  you are already using (GitHub Copilot, Claude, etc.) and your Power Platform / D365 environment.
- It does not log queries, responses, or financial data.
- It does not share data outside your organisation's Azure AD tenant.
- It does not store BPA dataset schema or query results anywhere beyond your chat session.

---

## Authentication and credentials

### Option B — VS Code Local MCP

Authentication uses your **Azure AD session** managed by VS Code — no credentials are
stored by the plugin. VS Code handles MSAL device-flow authentication transparently.
Tokens are cached by VS Code's credential store and are never written to disk in plain text.

### Option C — M365 Copilot (OAuthPluginVault)

Credentials are managed by the Microsoft 365 OAuthPluginVault mechanism.
Tokens are acquired and managed by the M365 Copilot platform and are never
written to source code, disk files, or the plugin package.

---

## Third-party AI assistants

When you use this plugin with an AI assistant (GitHub Copilot, Claude Code, Cursor,
Microsoft 365 Copilot, etc.), your queries and financial data are subject to that
assistant's own privacy policy. The plugin authors have no control over, or access to,
those services.

Please review your AI assistant's privacy policy before sending sensitive financial data.

---

## Contact

Questions? Open a [GitHub Issue](https://github.com/AurelienClere-365/bpa-cowork-plugin/issues)
or contact the maintainer via [LinkedIn](https://www.linkedin.com/in/aurelien-clere/).
