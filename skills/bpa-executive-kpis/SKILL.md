---
name: bpa-executive-kpis
description: |
  Delivers CFO-level executive KPI dashboards and financial health summaries from
  Dynamics 365 Business Performance Analytics. Covers top financial KPIs, business
  health scorecard, rolling 12-month trends, exception alerts, and board-ready summaries.
  Use when asked: "CFO dashboard", "executive summary", "financial health scorecard",
  "key financial KPIs", "board report data", "monthly management report",
  "top line metrics", "financial overview", "how is the business doing",
  "give me a snapshot of financial performance", "quick financial summary",
  "critical financial metrics", "ROE ROA ROCE", "liquidity ratios",
  "financial ratios", "anomaly detection in financials", "flag unusual transactions".
license: MIT
metadata:
  author: Dynagile Consulting
  version: "1.0"
  domain: CFO / Executive / Board
  bpa-coverage: Record-to-Report, Order-to-Cash, Procure-to-Pay
---

# BPA Executive KPI Dashboard

## What This Skill Does

Orchestrates multiple BPA queries to produce a unified CFO-level financial snapshot:
- **Revenue KPIs**: Revenue, revenue growth, revenue per headcount
- **Profitability KPIs**: Gross margin, EBITDA margin, net profit margin, ROE, ROA
- **Liquidity KPIs**: Current ratio, quick ratio, working capital, cash and equivalents
- **Efficiency KPIs**: DSO, DPO, inventory turnover, asset turnover
- **Exception alerts**: Anomalies, deviations from budget >10%, unusual transaction patterns
- **Trend sparklines**: Rolling 12-month directional trend for key metrics
- **Board narrative**: Auto-generated 5-sentence executive summary

## Prerequisites

- BPA connector active (uses `get_bpa_dataset_schema` and `execute_dax_query` tools)
- Requires multi-domain BPA coverage (Record-to-Report + Order-to-Cash + P2P)
- BPA User role in Power Platform environment
- Claude Sonnet 4+ recommended for narrative generation

## Workflow

This skill orchestrates sequential DAX queries — each building on the previous result.

### Step 1 — Discover schema
Call `get_bpa_dataset_schema` once to map all available measures across all BPA domains.
Identify which KPIs are directly available as measures vs. need to be computed.

### Step 2 — Clarify scope
Ask for:
- **Period**: Current month/quarter, fiscal YTD, or full fiscal year
- **Comparison baseline**: vs. prior period, vs. prior year, vs. budget, or all three
- **Output format**: Full dashboard, quick 5-KPI snapshot, or board slide data

### Step 3 — Execute DAX queries (multi-call orchestration)

**Query 1 — Top-line P&L KPIs:**
```dax
EVALUATE
ROW(
    "Revenue", CALCULATE([Total Revenue], DATESYTD('Date'[Date])),
    "Gross Profit", CALCULATE([Gross Profit], DATESYTD('Date'[Date])),
    "Gross Margin %", DIVIDE(CALCULATE([Gross Profit], DATESYTD('Date'[Date])), CALCULATE([Total Revenue], DATESYTD('Date'[Date]))),
    "EBITDA", CALCULATE([EBITDA], DATESYTD('Date'[Date])),
    "EBITDA Margin %", DIVIDE(CALCULATE([EBITDA], DATESYTD('Date'[Date])), CALCULATE([Total Revenue], DATESYTD('Date'[Date]))),
    "Net Income", CALCULATE([Net Income], DATESYTD('Date'[Date])),
    "Net Profit Margin %", DIVIDE(CALCULATE([Net Income], DATESYTD('Date'[Date])), CALCULATE([Total Revenue], DATESYTD('Date'[Date]))),
    "Revenue YoY %", DIVIDE(
        CALCULATE([Total Revenue], DATESYTD('Date'[Date])) -
        CALCULATE([Total Revenue], DATESYTD(DATEADD('Date'[Date], -1, YEAR))),
        ABS(CALCULATE([Total Revenue], DATESYTD(DATEADD('Date'[Date], -1, YEAR))))
    )
)
```

**Query 2 — Liquidity & Working Capital:**
```dax
EVALUATE
ROW(
    "Total AR", [Open AR Amount],
    "Total AP", [Open AP Amount],
    "Working Capital", [Open AR Amount] - [Open AP Amount],
    "DSO", [Days Sales Outstanding],
    "DPO", [Days Payable Outstanding],
    "Cash Conversion Cycle", [Days Sales Outstanding] + [Days Inventory Outstanding] - [Days Payable Outstanding]
)
```

**Query 3 — Budget adherence:**
```dax
EVALUATE
ROW(
    "YTD Actuals", CALCULATE([Total Actuals], DATESYTD('Date'[Date])),
    "YTD Budget", CALCULATE([Total Budget], DATESYTD('Date'[Date])),
    "YTD Variance %", DIVIDE(
        CALCULATE([Total Actuals], DATESYTD('Date'[Date])) -
        CALCULATE([Total Budget], DATESYTD('Date'[Date])),
        ABS(CALCULATE([Total Budget], DATESYTD('Date'[Date])))
    ),
    "Budget Utilization %", DIVIDE(CALCULATE([Total Actuals], DATESYTD('Date'[Date])), CALCULATE([Total Budget], DATESYTD('Date'[Date])))
)
```

**Query 4 — Rolling 12-month revenue trend:**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Date'[FiscalYear],
    'Date'[FiscalPeriodName],
    "Revenue", [Total Revenue],
    "Gross Margin %", DIVIDE([Gross Profit], [Total Revenue]),
    "EBITDA Margin %", DIVIDE([EBITDA], [Total Revenue])
)
ORDER BY 'Date'[FiscalYear], 'Date'[FiscalPeriodName]
```

**Query 5 — Exception/anomaly detection (top deviations):**
```dax
EVALUATE
TOPN(
    10,
    SUMMARIZECOLUMNS(
        'MainAccount'[AccountName],
        'Department'[DepartmentName],
        FILTER('Date', 'Date'[FiscalPeriodNumber] = 9 && 'Date'[FiscalYear] = 2024),
        "Actual", [Total Actuals],
        "Budget", [Total Budget],
        "Variance %", DIVIDE([Total Actuals] - [Total Budget], ABS([Total Budget]))
    ),
    ABS(DIVIDE([Total Actuals] - [Total Budget], ABS([Total Budget]))),
    DESC
)
WHERE ABS(DIVIDE([Total Actuals] - [Total Budget], ABS([Total Budget]))) > 0.1
```

> BPA has a 10 MB per query limit and 120-second timeout. Break into 5 separate calls as shown above.

### Step 4 — Compose executive summary

After all queries return, synthesize into this output structure:

---

## Executive Financial Dashboard — [Period]

### KPI Scorecard

| KPI | Current | Prior Period | Budget | vs Budget | Trend |
|-----|---------|------------|--------|-----------|-------|
| Revenue | €8.4M | €7.9M | €8.0M | +5.0% ↑ | ↗ |
| Gross Margin | 41.2% | 40.8% | 42.0% | -0.8pp | → |
| EBITDA Margin | 18.5% | 17.9% | 19.0% | -0.5pp | ↗ |
| DSO | 38 days | 42 days | 40 days | +5.0% ↑ | ↗ |
| Budget Utilization | 79% | 81% | 100% | On track | → |

### Trend Chart Data (Rolling 12 months)
[Revenue, Gross Margin %, EBITDA Margin % by month — provide as table for visualization]

### Exception Alerts
> ⚠ **IT Department** overspent by **23.4%** vs budget (€47K unfavorable)
> ⚠ **Customer: Acme Corp** has **€68K** overdue >90 days — escalation required
> ✓ **Revenue**: 5% above budget — favorable

### Executive Narrative
> Revenue reached €8.4M for the period, up 6.3% year-over-year and 5% ahead of budget,
> driven primarily by [top entity/segment]. Gross margin held at 41.2%, slightly below the
> 42% budget target due to increased raw material costs in [category]. DSO improved from
> 42 to 38 days reflecting stronger collections discipline. EBITDA margin at 18.5% remains
> healthy, though IT overspend requires review. Overall financial health: **ON TRACK**.

---

## Financial KPI Reference

| KPI | Formula | Healthy Range |
|-----|---------|--------------|
| Gross Margin % | Gross Profit / Revenue | Industry-specific; target > 35% |
| EBITDA Margin % | EBITDA / Revenue | > 15% for manufacturing |
| Net Profit Margin % | Net Income / Revenue | > 8% |
| DSO | (AR / Revenue) × Days | < 45 days |
| DPO | (AP / COGS) × Days | 30–60 days |
| Current Ratio | Current Assets / Current Liabilities | > 1.5 |
| Budget Utilization | Actuals / Budget | 85–105% = healthy |

## Example Prompts That Trigger This Skill

- "Give me the CFO dashboard for September 2024"
- "What are our key financial KPIs this quarter?"
- "Show me a financial health scorecard"
- "Prepare the data for the board meeting — high-level financial overview"
- "How is the business performing? Quick financial snapshot"
- "What are the top financial exceptions I should know about?"
- "Show rolling 12-month revenue and margin trends"
- "Compare this month's KPIs vs budget and prior year"
- "Are there any anomalies in this period's financials?"
