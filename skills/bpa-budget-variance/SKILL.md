---
name: bpa-budget-variance
description: |
  Analyzes budget vs actuals variance from Dynamics 365 Business Performance Analytics.
  Covers favorable/unfavorable variances, budget utilization, forecast vs budget,
  re-forecasting analysis, and spend-to-budget ratios by cost center, department, or GL account.
  Use when asked: "budget vs actuals", "how are we tracking against budget",
  "show me the variance report", "which departments are over budget",
  "budget utilization", "favorable and unfavorable variances", "are we on track with forecast",
  "spend vs budget by cost center", "budget adherence", "forecast accuracy",
  "remaining budget", "encumbrance analysis", "how much budget is left".
license: MIT
metadata:
  author: Dynagile Consulting
  version: "1.0"
  domain: Finance / FP&A / CFO
  bpa-coverage: Record-to-Report
---

# BPA Budget vs Actuals Variance Analysis

## What This Skill Does

Queries BPA to deliver FP&A-grade budget and forecast analysis:
- **Budget vs Actuals**: Side-by-side with variance (amount and %)
- **Favorable/Unfavorable classification**: Revenue over-budget = favorable; expense over-budget = unfavorable
- **Budget utilization**: % of budget consumed year-to-date
- **Remaining budget**: Budget minus actuals, projected vs remaining
- **Forecast accuracy**: Forecast vs actuals for closed periods
- **Dimension drill-down**: By cost center, department, GL account, or legal entity
- **Encumbrance/commitment**: Committed spend not yet invoiced vs remaining budget

## Prerequisites

- BPA connector active (uses `get_bpa_dataset_schema` and `execute_dax_query` tools)
- Budget data must be loaded in D365FO Budget module and synced to BPA
- BPA User role in Power Platform environment

## Workflow

### Step 1 — Discover schema
Call `get_bpa_dataset_schema` to identify:
- Budget and actuals measure names
- Available forecast versions (original budget, revised budget, latest forecast)
- Dimension hierarchies (cost center, department, main account)
- Fiscal calendar structure

### Step 2 — Clarify scope
Ask for:
- **Period**: YTD, specific quarter, full fiscal year, or specific month
- **Dimension**: All, by department, by cost center, or by GL account
- **Budget version**: Original budget or latest forecast
- **Focus**: Revenue side, expense side, or full P&L variance

### Step 3 — Execute DAX queries

**Full P&L Budget vs Actuals (YTD):**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'MainAccount'[AccountCategory],
    'MainAccount'[AccountName],
    FILTER('Date', 'Date'[FiscalYear] = 2024 && 'Date'[FiscalPeriodNumber] <= 9),
    "Actual", [Total Actuals],
    "Budget", [Total Budget],
    "Variance Amount", [Total Actuals] - [Total Budget],
    "Variance %", DIVIDE([Total Actuals] - [Total Budget], ABS([Total Budget])),
    "Budget Utilization %", DIVIDE([Total Actuals], [Total Budget])
)
ORDER BY ABS([Total Actuals] - [Total Budget]) DESC
```

**Department spend vs budget:**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Department'[DepartmentName],
    FILTER('Date', 'Date'[FiscalYear] = 2024),
    "YTD Actual", [Total Actuals],
    "YTD Budget", [Total Budget],
    "Variance", [Total Actuals] - [Total Budget],
    "Variance %", DIVIDE([Total Actuals] - [Total Budget], ABS([Total Budget])),
    "Remaining Budget", [Total Budget] - [Total Actuals],
    "Budget Used %", DIVIDE([Total Actuals], [Total Budget])
)
ORDER BY [Variance] DESC
```

**Monthly actuals vs budget trend (rolling 12 months):**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Date'[FiscalYear],
    'Date'[FiscalPeriodName],
    "Actual", [Total Actuals],
    "Budget", [Total Budget],
    "Variance", [Total Actuals] - [Total Budget],
    "Cumulative Actual", CALCULATE([Total Actuals], DATESYTD('Date'[Date])),
    "Cumulative Budget", CALCULATE([Total Budget], DATESYTD('Date'[Date]))
)
ORDER BY 'Date'[FiscalYear], 'Date'[FiscalPeriodName]
```

**Top over-budget cost centers:**
```dax
EVALUATE
TOPN(
    10,
    SUMMARIZECOLUMNS(
        'CostCenter'[CostCenterName],
        FILTER('Date', 'Date'[FiscalYear] = 2024),
        "Actual", [Total Actuals],
        "Budget", [Total Budget],
        "Over Budget Amount", [Total Actuals] - [Total Budget]
    ),
    [Over Budget Amount],
    DESC
)
```

> If measure names differ, call `get_bpa_dataset_schema` and adapt accordingly.

### Step 4 — Present results

**Variance summary table:**

| Department | Actual | Budget | Variance | Var% | Status |
|-----------|--------|--------|---------|------|--------|
| Sales | 850,000 | 900,000 | -50,000 | -5.6% | Under budget (favorable) |
| IT | 420,000 | 380,000 | +40,000 | +10.5% | Over budget (unfavorable) |

**Variance classification rules:**
- Revenue: Actual > Budget = Favorable (+), Actual < Budget = Unfavorable (-)
- Expense: Actual < Budget = Favorable (+), Actual > Budget = Unfavorable (-)

Include summary KPIs:
> Total variance: **-€35K (unfavorable)** | Budget utilization: **78%** | Departments over budget: **3 of 12**

## Key FP&A Metrics

| Metric | Description |
|--------|------------|
| Budget Utilization % | Actual / Budget — above 100% = over budget |
| Variance % | (Actual - Budget) / |Budget| |
| Run Rate | Annualized actual based on YTD spend |
| Budget at Risk | Remaining budget × expected spend rate |

## Example Prompts That Trigger This Skill

- "Show me budget vs actuals for FY2024 YTD"
- "Which departments are over budget?"
- "What is our budget utilization by cost center?"
- "Show me the variance report for Q3 2024"
- "How much budget is left for IT this year?"
- "Are we on track to hit our revenue budget?"
- "Show me favorable and unfavorable variances for this month"
- "What is the forecast vs original budget for Q4?"
