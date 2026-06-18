# Changelog

All notable changes to the BPA Analytics Cowork Plugin will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] — 2026-06-18

### Added

- **4 new ASKILL-validated skills** for advanced finance personas, inspired by
  [Natalia Salas' blog post on D365 ERP Analytics MCP prompts](https://natisalas.com/2026/06/17/dyn365-erp-analytics-mcp-4-financials-4-prompts/):
  - `bpa-intercompany` — GL summary by entity/account type, purchase activity, anomaly detection
    (negative expense balances, invoices w/o POs, open POs w/o invoices) — persona: Senior Analyst
  - `bpa-cash-flow-projection` — 30/60/90-day AR/AP projection, FX conversion, CRITICAL/MODERATE/LOW
    liquidity gap classification, pessimistic collection scenario — persona: Manager / Treasurer
  - `bpa-spending-behavior` — Month-by-month actual vs budget, causal factor analysis
    (internal/external), annual over-execution risk, corrective recommendations — persona: FP&A Director
  - `bpa-roi-capital` — Investment ROI by category vs prior period, revenue budget execution,
    free capital calculation, three-scenario viability analysis (conservative/base/optimistic) — persona: CFO
- **`manifest.json`** bumped to v1.1.0 with 4 additional `agentSkills` entries
- **`EXAMPLES.md`** — 4 new worked examples (17–20) covering each new skill

## [1.2.0] — 2026-06-18

### Added

- **4 new ASKILL-validated skills** covering management accounting, working capital, revenue analysis, and fixed assets:
  - `bpa-cost-center-profitability` — Cost center P&L, contribution margin, overhead allocation, budget variance per department — persona: Management Accountant / Controller
  - `bpa-working-capital` — Cash Conversion Cycle (CCC = DSO + DIO − DPO), net working capital, current/quick ratios, optimization levers with cash release estimates — persona: Treasurer / Finance Director
  - `bpa-revenue-analysis` — Revenue by customer/product/geography, TOPN ranking, Pareto/concentration risk, YoY growth, mix shift — persona: Revenue Manager / Sales Finance / CFO
  - `bpa-fixed-assets-capex` — Fixed asset register NBV, depreciation schedule, fully-depreciated-but-in-service flag, capex vs opex split, capex execution rate — persona: Asset Controller / Finance Controller
- **`manifest.json`** bumped to v1.2.0 with 14 total `agentSkills` entries
- **`EXAMPLES.md`** — 4 new worked examples (21–24) covering each new skill

## [Unreleased]

_Nothing yet._

---

## [1.0.0] — 2026-06-18

### Added

- **6 ASKILL-validated skills** for CFO, Finance Controller, FP&A, AR/AP, and Procurement personas:
  - `bpa-financial-performance` — P&L summary, gross margin by dimension, EBITDA trend (Record-to-Report)
  - `bpa-cash-flow-ar-ap` — AR aging, DSO trend, AP aging, DPO, working capital (O2C / P2P)
  - `bpa-budget-variance` — Budget vs actuals, variance waterfall, over-budget drill-down (Record-to-Report)
  - `bpa-vendor-performance` — Vendor spend ranking, OTIF, procurement category analysis (Procure-to-Pay)
  - `bpa-period-close` — Period-close checklist, subledger reconciliation gaps, intercompany status (R2R)
  - `bpa-executive-kpis` — CFO KPI dashboard, financial health scorecard, board-ready RAG summary (All domains)
- **`manifest.json`** — M365 App Manifest v1.28 with OAuthPluginVault connector for BPA MCP server
- **`bpa-mcp-tools.json`** — Plugin tools schema v2.1 describing `execute_dax_query` and `get_bpa_dataset_schema`
- **`package.ps1`** — ASKILL validation (P001-P008) + ZIP packager with `-SkillsOnly` mode (Option A)
- **`architecture.mmd`** + **`architecture.png`** — 5-layer architecture diagram
- **`README.md`**, **`EXAMPLES.md`**, **`CHANGELOG.md`**, **`CONTRIBUTING.md`**, **`PRIVACY.md`**, **`SECURITY.md`**, **`LICENSE`**
- **`.github/workflows/validate.yml`** — CI validation on push/PR to main
- **`.github/dependabot.yml`**, **`CODEOWNERS`**, issue templates, PR template

[Unreleased]: https://github.com/AurelienClere-365/bpa-cowork-plugin/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/AurelienClere-365/bpa-cowork-plugin/releases/tag/v1.0.0
