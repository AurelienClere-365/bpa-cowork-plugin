# Changelog

All notable changes to the BPA Analytics Cowork Plugin will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
