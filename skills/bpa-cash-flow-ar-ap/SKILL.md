---
name: bpa-cash-flow-ar-ap
description: |
  Analyzes cash flow, accounts receivable (AR), and accounts payable (AP) data from
  Dynamics 365 Business Performance Analytics.
  Covers AR aging buckets, Days Sales Outstanding (DSO), customer payment behavior,
  AP aging, Days Payable Outstanding (DPO), vendor payment terms, and working capital analysis.
  Use when asked: "show AR aging", "what is our DSO", "overdue invoices", "cash collection",
  "AP aging report", "DPO trend", "who are our slowest paying customers",
  "working capital analysis", "outstanding receivables", "payment terms compliance",
  "how much do we owe vendors", "customer credit exposure", "liquidity analysis".
license: MIT
metadata:
  author: Dynagile Consulting
  version: "1.0"
  domain: Finance / Treasury / CFO
  bpa-coverage: Order-to-Cash, Procure-to-Pay
---

# BPA Cash Flow, AR & AP Analysis

## What This Skill Does

Queries BPA to analyze liquidity, working capital, and payment behavior:
- **AR Aging**: Outstanding receivables by aging bucket (0–30, 31–60, 61–90, 90+ days)
- **DSO** (Days Sales Outstanding): Average days to collect payment
- **Customer payment analysis**: Late payers, credit exposure, collection efficiency
- **AP Aging**: Outstanding payables by due date bucket
- **DPO** (Days Payable Outstanding): How long the company takes to pay vendors
- **Working capital**: Net AR minus AP, current ratio components
- **Cash flow from operations**: Collections received vs payments made

## Prerequisites

- BPA connector active (uses `get_bpa_dataset_schema` and `execute_dax_query` tools)
- Requires Order-to-Cash and Procure-to-Pay data coverage in BPA
- BPA User role in Power Platform environment

## Workflow

### Step 1 — Discover schema
Call `get_bpa_dataset_schema` to identify:
- AR and customer invoice tables/measures
- AP and vendor invoice tables/measures
- Date/aging dimension structures
- Available legal entity filters

### Step 2 — Clarify scope
Ask for:
- **Focus area**: AR only, AP only, or combined working capital view
- **As-of date**: Current date (default) or a specific period-end date
- **Dimension**: All entities, specific legal entity, or specific customer/vendor segment
- **Aging buckets**: Standard (0–30–60–90–90+) or custom

### Step 3 — Execute DAX queries

**AR Aging Buckets:**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Customer'[CustomerName],
    "Current (0-30 days)", CALCULATE([Open AR Amount], [Days Overdue] <= 30),
    "31-60 days", CALCULATE([Open AR Amount], [Days Overdue] > 30 && [Days Overdue] <= 60),
    "61-90 days", CALCULATE([Open AR Amount], [Days Overdue] > 60 && [Days Overdue] <= 90),
    "Over 90 days", CALCULATE([Open AR Amount], [Days Overdue] > 90),
    "Total Open AR", [Open AR Amount]
)
ORDER BY [Total Open AR] DESC
```

**DSO Calculation (Days Sales Outstanding):**
```dax
EVALUATE
ROW(
    "DSO", DIVIDE(
        [Open AR Amount],
        CALCULATE([Total Revenue], DATESINPERIOD('Date'[Date], TODAY(), -90, DAY))
    ) * 90,
    "Total Open AR", [Open AR Amount],
    "Revenue Last 90 Days", CALCULATE([Total Revenue], DATESINPERIOD('Date'[Date], TODAY(), -90, DAY))
)
```

**AP Aging (outstanding vendor payables):**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Vendor'[VendorName],
    "Not Yet Due", CALCULATE([Open AP Amount], [Days Until Due] >= 0),
    "1-30 days overdue", CALCULATE([Open AP Amount], [Days Overdue] >= 1 && [Days Overdue] <= 30),
    "31-60 days overdue", CALCULATE([Open AP Amount], [Days Overdue] > 30 && [Days Overdue] <= 60),
    "Over 60 days overdue", CALCULATE([Open AP Amount], [Days Overdue] > 60),
    "Total Open AP", [Open AP Amount]
)
ORDER BY [Total Open AP] DESC
```

**DPO Calculation:**
```dax
EVALUATE
ROW(
    "DPO", DIVIDE(
        [Open AP Amount],
        CALCULATE([Total Purchases], DATESINPERIOD('Date'[Date], TODAY(), -90, DAY))
    ) * 90,
    "Total Open AP", [Open AP Amount]
)
```

**Working Capital Summary:**
```dax
EVALUATE
ROW(
    "Total AR", [Open AR Amount],
    "Total AP", [Open AP Amount],
    "Net Working Capital (AR-AP)", [Open AR Amount] - [Open AP Amount],
    "DSO", [Days Sales Outstanding],
    "DPO", [Days Payable Outstanding],
    "Cash Conversion Cycle", [Days Sales Outstanding] + [Days Inventory Outstanding] - [Days Payable Outstanding]
)
```

> Adapt measure names to actual BPA schema — call `get_bpa_dataset_schema` first if needed.

### Step 4 — Present results

**AR Aging Summary table:**

| Customer | Current | 31-60d | 61-90d | >90d | Total | Risk |
|----------|---------|--------|--------|------|-------|------|
| Acme Corp | 50,000 | 0 | 0 | 0 | 50,000 | Low |
| Beta Ltd | 20,000 | 15,000 | 8,000 | 25,000 | 68,000 | High |

Include KPI summary row:
> DSO: **42 days** | DPO: **35 days** | Working Capital: **€1.2M** | Over-90 AR: **€125K (8.5%)**

Flag customers with >90 days overdue as requiring immediate follow-up.

## Key Finance Metrics Explained

| Metric | Formula | Healthy Benchmark |
|--------|---------|-----------------|
| DSO | (Open AR / Revenue) × Days | < 45 days (industry varies) |
| DPO | (Open AP / Purchases) × Days | 30–60 days |
| Cash Conversion Cycle | DSO + DIO − DPO | As low as possible |
| AR >90 days % | >90d AR / Total AR | < 5% |

## Example Prompts That Trigger This Skill

- "Show me AR aging as of today"
- "What is our current DSO?"
- "Which customers have invoices overdue more than 60 days?"
- "Show AP aging — how much do we owe and when is it due?"
- "What is our working capital position?"
- "Compare DSO this quarter vs last quarter"
- "Which vendors are we paying late?"
- "What is our cash conversion cycle?"
