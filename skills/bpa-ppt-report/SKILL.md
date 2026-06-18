---
name: bpa-ppt-report
description: >
  WHEN: "create a presentation", "generate a PowerPoint", "make a slide deck",
  "build a board deck", "create slides from BPA data", "CFO PowerPoint report",
  "quarterly financial review slides", "executive presentation from data",
  "board presentation", "finance deck", "create a deck for the board",
  "generate a CFO report in PowerPoint", "create a financial summary presentation",
  "make slides for the QBR", "build the quarterly business review deck"
license: MIT
metadata:
  version: 1.0.0
  author: Aurelien Clere
  tags: [bpa, finance, powerpoint, presentation, report, m365, copilot, cowork]
---

# bpa-ppt-report

Orchestrates BPA data retrieval and structures it into a PowerPoint presentation
using M365 Copilot's native deck-creation capability. Designed for the Cowork (Option C)
deployment where M365 Copilot can write files to OneDrive/SharePoint directly.

> **Availability**: PowerPoint file creation (step 6 below) requires **Option C — M365 Copilot
> (Cowork)**. In Options A and B (VS Code), this skill produces a structured Markdown outline
> that the user can copy into PowerPoint manually or paste into Copilot to generate the deck.

## When to use this skill

Use when asked for:
- A PowerPoint board deck or executive presentation from BPA data
- A quarterly/monthly financial review slide set
- A CFO presentation for board or leadership meetings
- A QBR (Quarterly Business Review) deck with live financial data
- A management summary slide deck from BPA KPIs

## Default slide structure

Unless the user specifies otherwise, build a 6-slide deck:

| # | Slide | BPA data source |
|---|---|---|
| 1 | Cover slide — company name, period, date | User context |
| 2 | P&L summary — Revenue, Gross Profit, EBITDA, Net Income | bpa-financial-performance |
| 3 | Budget vs actuals — YTD variance waterfall | bpa-budget-variance |
| 4 | Cash flow projection — 30/60/90-day outlook | bpa-cash-flow-projection |
| 5 | CFO KPI scorecard — RAG status | bpa-executive-kpis |
| 6 | Recommendations and next steps | AI reasoning over slides 2–5 |

## Workflow

### Step 1 — Clarify scope with user (if not provided)
Ask for:
- **Period**: fiscal year, quarter, or specific months (e.g., "Q2 2026", "H1 2026")
- **Audience**: board, C-suite, department heads, external (affects detail level)
- **Legal entity / consolidation**: single entity or group consolidation
- **Custom slides**: any additional topics (e.g., vendor performance, revenue by customer)

### Step 2 — Retrieve P&L data (slide 2)
Invoke `bpa-financial-performance` skill workflow:
- Call `get_bpa_dataset_schema` to confirm revenue and income statement tables.
- Call `execute_dax_query` for P&L summary: Revenue, COGS, Gross Profit, OpEx, EBITDA, Net Income.
- Compute YoY growth percentages.

### Step 3 — Retrieve budget variance data (slide 3)
Invoke `bpa-budget-variance` skill workflow:
- Call `execute_dax_query` for budget vs actuals, YTD variance by major category.
- Identify top 3 over-budget and top 3 under-budget lines.

### Step 4 — Retrieve cash flow projection (slide 4)
Invoke `bpa-cash-flow-projection` skill workflow:
- Call `execute_dax_query` for 30/60/90-day AR collections and AP payments.
- Compute liquidity gap and criticality classification.

### Step 5 — Retrieve CFO KPIs (slide 5)
Invoke `bpa-executive-kpis` skill workflow:
- Call `execute_dax_query` for the top KPIs with RAG status.
- Identify items flagged Red that need board attention.

### Step 6 — Generate the presentation

**In Option C (M365 Copilot / Cowork):**

Instruct M365 Copilot to create the PowerPoint file using its native deck-creation capability:

```
Create a PowerPoint presentation in my OneDrive titled "[Company] CFO Board Deck — [Period]".
Use the following structure and data:

Slide 1 — Cover
  Title: [Company name] | CFO Board Presentation
  Subtitle: [Period] | Prepared [today's date]

Slide 2 — P&L Summary
  Headline: Revenue [X]M | Gross Margin [Y]% | EBITDA [Z]M
  Table: [P&L data from step 2]
  Callout: YoY growth [+/- %]

Slide 3 — Budget vs Actuals
  Headline: YTD variance [amount] ([%])
  Table: [top over/under-budget lines from step 3]
  Highlight: [3 lines most over budget in red]

Slide 4 — Cash Flow Outlook
  Headline: 90-day free cash position [amount]
  Table: 30/60/90-day collections, payments, gap
  Status: [CRITICAL/MODERATE/LOW classification]

Slide 5 — KPI Scorecard
  RAG table: [KPIs from step 5]
  Highlight: [Red-status KPIs]

Slide 6 — Recommendations
  [3–5 AI-generated recommendations based on the data above]
  Next steps with owners and target dates
```

**In Options A / B (VS Code):**

Output the same structure as a Markdown document. The user can:
1. Copy the Markdown into a new M365 Copilot chat and say *"Create a PowerPoint from this"*.
2. Paste into an existing presentation template in PowerPoint.

### Step 7 — Confirm and share

After the file is created, provide:
- The OneDrive link to the generated `.pptx` file.
- A summary of what data was included and the period covered.
- Offer to add custom slides: *"Would you like to add a revenue-by-customer slide or a vendor performance summary?"*

## Customisation examples

- Add a customer revenue slide: *"Include a top-10 customer revenue slide"*  
  → invoke `bpa-revenue-analysis` and add as Slide 7.

- Add a working capital slide: *"Include working capital and CCC metrics"*  
  → invoke `bpa-working-capital` and add as Slide 7.

- Board-only version (less detail): *"Make it a 4-slide board summary"*  
  → condense to Cover, P&L, KPI Scorecard, Recommendations.

- Monthly team version (more detail): *"Include cost center breakdown"*  
  → invoke `bpa-cost-center-profitability` and add between slides 3 and 4.
