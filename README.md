# BPA Analytics Cowork Plugin

> AI skills for CFO & Finance teams — connects GitHub Copilot and M365 Copilot to Dynamics 365 Business Performance Analytics via live DAX queries.

> **AI-assisted financial analytics for CFO, Controllers, FP&A, and Finance teams**  
> Connect Microsoft 365 Copilot or VS Code to Dynamics 365 Business Performance Analytics — live DAX queries, no manual exports.

---

## Who is this for?

| Persona | What they get |
|---|---|
| **CFO / Finance Director** | Executive KPI dashboard, financial health scorecard, board-ready summaries |
| **Finance Controller** | P&L by entity/dimension, trial balance, period-end close status |
| **FP&A Analyst** | Budget vs actuals variance, trend analysis, forecast vs actual |
| **AP / Procurement** | Vendor spend ranking, OTIF, AP aging, DPO monitoring |
| **AR / Revenue** | AR aging by bucket, DSO trend, overdue invoice alerts |

---

## What this plugin does

The BPA Analytics Cowork Plugin provides **6 AI skills** that translate plain-English finance questions into DAX queries executed directly against your **Dynamics 365 Business Performance Analytics** Power BI dataset.

```
Finance question  ──►  BPA skill       ──►  BPA MCP tools    ──►  Structured result
(plain English)        (routes intent)      (DAX queries)         (in chat window)
```

No dashboards to navigate. No exports. Just ask your AI assistant.

---

## Architecture

```mermaid
flowchart LR

    subgraph USERS["👥  Users"]
        direction TB
        CFO(["💼  CFO / Finance Director\nKPI dashboard · scorecard\nboard report · EBITDA"])
        CTRL(["📊  Finance Controller\nP&L · trial balance\nperiod close · recon"])
        FPA(["📈  FP&A Analyst\nBudget vs actuals\nvariance · forecast"])
        ARAP(["🧾  AR / AP Manager\nAging · DSO · DPO\noverdue invoices"])
        PROC(["🛒  Procurement\nVendor spend · OTIF\ncategory analysis"])
    end

    subgraph PLUGIN["🔌  BPA Analytics Cowork Plugin  —  6 SKILL.md files"]
        direction TB
        subgraph R2R["Record-to-Report  ★"]
            S1["bpa-financial-performance\nP&L · gross margin · EBITDA"]
            S2["bpa-budget-variance\nBudget vs actuals · variance"]
            S3["bpa-period-close\nClose checklist · subledger recon"]
            S6["bpa-executive-kpis\nCFO dashboard · scorecard"]
        end
        subgraph P2P["Procure-to-Pay"]
            S4["bpa-vendor-performance\nVendor spend · OTIF · categories"]
        end
        subgraph O2C["Order-to-Cash"]
            S5["bpa-cash-flow-ar-ap\nAR/AP aging · DSO · DPO"]
        end
    end

    subgraph DEPLOY["⚙️  Deployment options"]
        direction TB
        OA["A — Skills-only\nPrompts folder copy\nNo server needed"]
        OB["B — VS Code mcp.json\ntype: http · Azure AD\nLocal MCP connection"]
        OC["C — M365 Copilot\nmanifest.json upload\nOAuthPluginVault"]
    end

    subgraph MCPSVR["☁️  BPA MCP Server  (Microsoft-hosted · Power Platform)"]
        direction TB
        EP["agent365.svc.cloud.microsoft\nmsdyn_ERPAnalyticsMCPServer\nAzure AD · BPA User role"]
        subgraph TOOLS["2 MCP tools"]
            direction LR
            T1["get_bpa_dataset_schema\nDiscover tables & columns"]
            T2["execute_dax_query\nRun DAX EVALUATE queries"]
        end
        EP --> T1 & T2
    end

    subgraph BPA["🗄️  Dynamics 365 Business Performance Analytics"]
        direction TB
        D1["📋 Record-to-Report\nGeneral Ledger · P&L · Budget"]
        D2["🛒 Procure-to-Pay\nVendor Invoices · AP Aging"]
        D3["💰 Order-to-Cash\nCustomer Invoices · AR Aging"]
    end

    CFO & CTRL & FPA & ARAP & PROC -->|"plain-English prompt"| PLUGIN
    PLUGIN --> OA & OB & OC
    OB -->|"HTTP · Azure AD"| EP
    OC -->|"HTTP · OAuthPluginVault"| EP
    T1 & T2 -->|"DAX / Power BI REST"| D1 & D2 & D3
    D1 & D2 & D3 -->|"query results"| T1 & T2

    classDef user   fill:#1e3a5f,stroke:#4fa3e0,color:#cce5ff
    classDef r2r    fill:#0d3068,stroke:#4fa3e0,color:#fff
    classDef p2p    fill:#1a2a3a,stroke:#4fa3e0,color:#cce5ff
    classDef o2c    fill:#0a2040,stroke:#4fa3e0,color:#cce5ff
    classDef deploy fill:#1e3a1e,stroke:#6abf69,color:#cfffce
    classDef ep     fill:#003366,stroke:#4fa3e0,color:#fff
    classDef tool   fill:#001a33,stroke:#4fa3e0,color:#99ccff
    classDef bpa    fill:#005a9e,stroke:#4fa3e0,color:#fff
    class CFO,CTRL,FPA,ARAP,PROC user
    class S1,S2,S3,S6 r2r
    class S4 p2p
    class S5 o2c
    class OA,OB,OC deploy
    class EP ep
    class T1,T2 tool
    class D1,D2,D3 bpa
```

> Mermaid source: [architecture.mmd](architecture.mmd)

---

## Repository structure

```
bpa-cowork-plugin/
├── manifest.json               M365 App Manifest v1.28
├── bpa-mcp-tools.json          BPA MCP tools schema (v2.1)
├── package.ps1                 ASKILL validation + ZIP packager
├── architecture.mmd            Mermaid architecture diagram (rendered in README)
├── color.png                   192x192 colour icon
├── outline.png                 32x32 outline icon
├── README.md                   This file
├── EXAMPLES.md                 Usage examples for all personas
├── CHANGELOG.md
├── CONTRIBUTING.md
├── PRIVACY.md
├── SECURITY.md
├── LICENSE
└── skills/
    ├── bpa-financial-performance/SKILL.md   P&L, gross margin, EBITDA, R2R
    ├── bpa-cash-flow-ar-ap/SKILL.md         Cash flow, AR/AP aging, DSO, DPO
    ├── bpa-budget-variance/SKILL.md         Budget vs actuals, FP&A variance
    ├── bpa-vendor-performance/SKILL.md      Vendor spend, OTIF, procurement
    ├── bpa-period-close/SKILL.md            Period-close status, subledger recon
    └── bpa-executive-kpis/SKILL.md          CFO dashboard, board KPIs, scorecard
```

---

## Skills

| Skill | BPA coverage | Key personas |
|---|---|---|
| `bpa-financial-performance` | Record-to-Report | Controller, FP&A |
| `bpa-cash-flow-ar-ap` | Order-to-Cash, Procure-to-Pay | Treasurer, AR/AP |
| `bpa-budget-variance` | Record-to-Report | FP&A, Finance Director |
| `bpa-vendor-performance` | Procure-to-Pay | Procurement, AP |
| `bpa-period-close` | Record-to-Report | Controller, Shared Services |
| `bpa-executive-kpis` | All three domains | CFO, Board |

---

## Deployment options

| Option | Where it runs | Skill access | Auth |
|---|---|---|---|
| **A — Skills only** | VS Code prompts folder | Copilot answers from skill instructions (no live data) | None |
| **B — VS Code mcp.json** | Local HTTP connection | Live DAX queries in VS Code | Azure AD (MSAL device flow) |
| **C — M365 Copilot** | manifest.json upload to M365 Admin | Full plugin experience | OAuthPluginVault (Entra ID) |

---

## Licence requirements

- **BPA User** role assigned in the Power Platform environment where BPA is deployed.
- **D365 Finance — Basic User** (minimum) or **Finance Reporting** security role.
- Active **Power BI Pro** or **Premium Per User** licence for the BPA environment.
- For Option C: M365 Copilot licence with Cowork plugin admin upload rights.

---

## Option C — Step-by-step setup

### 1. Prepare the manifest

Edit `manifest.json`:
- Replace `YOUR_ENVIRONMENT_ID` in `mcpServerUrl` with your Power Platform environment ID (find it in https://admin.powerplatform.microsoft.com → your environment → Settings → Session details → Environment ID).
- Replace `YOUR_OAUTH_REGISTRATION_ID` with the reference ID from Teams Developer Portal after registering the OAuth connection.

### 2. Register the OAuth connection (Teams Developer Portal)

1. Go to https://dev.teams.microsoft.com → **Connectors** → **OAuth registrations**.
2. Create a new registration:
   - **Token endpoint**: `https://login.microsoftonline.com/{your-tenant-id}/oauth2/v2.0/token`
   - **Scopes**: `https://service.powerapps.com/.default`
3. Copy the generated **Reference ID** into `manifest.json → referenceId`.

### 3. Build the ZIP

```powershell
.\package.ps1
```

Produces `bpa-analytics-cowork.zip` (all ASKILL checks must pass).

### 4. Upload to M365 Admin Center

1. Go to https://admin.microsoft.com → **Settings** → **Integrated apps** → **Upload custom app**.
2. Select `bpa-analytics-cowork.zip`.
3. Assign to pilot users or your Finance security group.

### 5. Validate in Microsoft 365 Copilot

Ask: *"Show me the BPA plugin tools available."*  
Expected: the assistant lists `get_bpa_dataset_schema` and `execute_dax_query`.

### 6. First use — authentication

When the plugin first calls the BPA MCP server, M365 Copilot will prompt for consent. Users sign in with their Azure AD account. The token is cached — no re-authentication on subsequent sessions.

### 7. Updating the plugin

Bump `version` in `manifest.json`, run `.\package.ps1`, re-upload the ZIP in M365 Admin Center. Assigned users receive the update automatically.

---

## Option B — Quick start (VS Code)

Add to `%APPDATA%\Code\User\mcp.json`:

```jsonc
{
  "servers": {
    "BPA-Analytics": {
      "url": "https://agent365.svc.cloud.microsoft/mcp/environments/YOUR_ENVIRONMENT_ID/servers/msdyn_ERPAnalyticsMCPServer",
      "type": "http"
    }
  }
}
```

Then run `.\package.ps1 -SkillsOnly` to copy the skills to your VS Code prompts folder.  
Reload VS Code — the BPA skills appear in Copilot Chat automatically.

---

## Option A — Skills only (no live data)

```powershell
.\package.ps1 -SkillsOnly
```

Copies `skills/` to `%APPDATA%\Code\User\prompts\bpa-analytics`.  
Skills guide the AI assistant using DAX examples but cannot query live BPA data without an MCP connection.

---

## Security

See [SECURITY.md](SECURITY.md). In brief:
- No credentials are stored in any file in this repository.
- Option B: Azure AD session managed by VS Code — no PAT required.
- Option C: OAuthPluginVault — tokens never written to disk or source code.
- Minimum required role: **BPA User** in the target Power Platform environment.

## Privacy

See [PRIVACY.md](PRIVACY.md). No data is collected by the plugin authors. All queries travel between your AI assistant and your own Power Platform environment.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). New skills for additional BPA domains (e.g. Supply Chain, Inventory) are very welcome.

## License

[MIT](LICENSE) — Copyright (c) 2026 Aurelien Clere