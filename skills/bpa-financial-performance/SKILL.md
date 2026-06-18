---
name: bpa-financial-performance
description: |
  Analyzes financial performance data from Dynamics 365 Business Performance Analytics.
  Covers income statement (P&L), revenue breakdown, gross margin, EBITDA, operating expenses,
  cost of goods sold, and profitability by dimension (legal entity, department, cost center).
  Use when asked: "show me the P&L", "what is our gross margin", "revenue by department",
  "how is profitability trending", "compare revenue this year vs last year",
  "show income statement", "what is our EBITDA", "operating expenses breakdown",
  "net income analysis", "financial performance by legal entity", "profit margin by product".
license: MIT
metadata:
  author: Dynagile Consulting
  version: "1.0"
  domain: Finance / CFO
  bpa-coverage: Record-to-Report
---

# BPA Financial Performance Analysis

## What This Skill Does

Queries the Business Performance Analytics dataset to analyze income statement data including:
- Revenue recognition and breakdown (by period, dimension, entity)
- Gross profit and margin calculation
- Operating expense analysis (by category, department, cost center)
- EBITDA and net income computation
- Year-over-year and period-over-period comparisons
- Profitability trending across multiple fiscal periods

## Prerequisites

- BPA connector active (uses `get_bpa_dataset_schema` and `execute_dax_query` tools)
- User must have **BPA User** role in the Power Platform environment
- Data refreshes twice daily; queries reflect data as of last refresh

## Workflow

### Step 1 — Discover the schema
Call `get_bpa_dataset_schema` to identify:
- Revenue and income statement tables/measures
- Available date dimensions (fiscal period, fiscal year, quarter)
- Legal entity and dimension filters available

### Step 2 — Clarify scope with user (if not provided)
Ask for:
- **Time period**: fiscal year, quarter, or specific months (e.g., "FY2024", "Q4 2024", "Jan–Mar 2025")
- **Granularity**: summary total, monthly trend, or by dimension
- **Dimensions**: legal entity, department, cost center, or all consolidated
- **Comparison**: single period, YoY, or period-over-period

### Step 3 — Execute DAX query
Build and run a DAX query using `execute_dax_query`. Follow these patterns:

**P&L Summary (total revenue, gross profit, net income):**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Date'[FiscalYear],
    'Date'[FiscalPeriodName],
    "Total Revenue", [Total Revenue],
    "Cost of Goods Sold", [COGS],
    "Gross Profit", [Gross Profit],
    "Gross Margin %", DIVIDE([Gross Profit], [Total Revenue]),
    "Operating Expenses", [Total Operating Expenses],
    "EBITDA", [EBITDA],
    "Net Income", [Net Income]
)
ORDER BY 'Date'[FiscalYear], 'Date'[FiscalPeriodName]
```

**Revenue breakdown by department:**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Department'[DepartmentName],
    FILTER('Date', 'Date'[FiscalYear] = 2024),
    "Revenue", [Total Revenue],
    "Revenue %", DIVIDE([Total Revenue], CALCULATE([Total Revenue], ALL('Department')))
)
ORDER BY [Revenue] DESC
```

**Year-over-year comparison:**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Date'[FiscalPeriodName],
    "Revenue CY", CALCULATE([Total Revenue], 'Date'[FiscalYear] = 2024),
    "Revenue PY", CALCULATE([Total Revenue], 'Date'[FiscalYear] = 2023),
    "YoY Change %", DIVIDE(
        CALCULATE([Total Revenue], 'Date'[FiscalYear] = 2024) -
        CALCULATE([Total Revenue], 'Date'[FiscalYear] = 2023),
        CALCULATE([Total Revenue], 'Date'[FiscalYear] = 2023)
    )
)
ORDER BY 'Date'[FiscalPeriodName]
```

> If exact measure names are unknown, call `get_bpa_dataset_schema` first and adapt the query to match actual schema names.

### Step 4 — Present results
Format the output as a structured table. Add a brief narrative summary highlighting:
- Key trends (growth/decline, notable period)
- Top/bottom performers by dimension
- Margin trend direction

## Output Format

| Period | Revenue | COGS | Gross Profit | GM% | Op. Expenses | EBITDA | Net Income |
|--------|---------|------|-------------|-----|-------------|--------|-----------|
| Jan 2024 | 1,250,000 | 750,000 | 500,000 | 40.0% | 320,000 | 215,000 | 180,000 |
| ... | ... | ... | ... | ... | ... | ... | ... |

Followed by a 3–5 sentence narrative:
> "Revenue grew 12% YoY driven by [entity/dept]. Gross margin declined slightly from 42% to 40% due to [cost pressure]. EBITDA remains healthy at [X%]."

## DAX Best Practices for BPA

- Always use `SUMMARIZECOLUMNS` for grouped queries (more performant than `SUMMARIZE`)
- Use `DIVIDE([numerator], [denominator])` instead of `/` to avoid division-by-zero errors
- Limit result sets: add `TOPN(100, ...)` for large dimensions
- Use `FILTER` inside `CALCULATE` for period scoping rather than slicers
- Query timeout is 120 seconds — break complex multi-step analysis into separate calls
- Data return limit is ~10 MB per query — use aggregations, not row-level detail

## Example Prompts That Trigger This Skill

- "Show me the P&L for Q3 2024"
- "What is our gross margin trend over the last 12 months?"
- "Compare revenue by legal entity for FY2024 vs FY2023"
- "Break down operating expenses by department for this fiscal year"
- "What is our EBITDA margin this quarter?"
- "Which cost center is driving the most expenses?"
