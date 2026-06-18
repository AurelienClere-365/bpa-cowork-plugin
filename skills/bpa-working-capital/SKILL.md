---
name: bpa-working-capital
description: >
  WHEN: "working capital", "cash conversion cycle", "CCC", "DSO DIO DPO",
  "days inventory outstanding", "DIO", "net working capital", "working capital ratio",
  "current ratio", "quick ratio", "working capital trend", "working capital optimization",
  "cash tied up in inventory", "liquidity ratios", "working capital by entity",
  "how long does it take to convert inventory to cash", "working capital efficiency",
  "cash cycle", "operating cycle", "net working capital improvement",
  "working capital benchmark", "working capital management"
license: MIT
metadata:
  version: 1.0.0
  author: Aurelien Clere
  tags: [bpa, finance, working-capital, ccc, liquidity, treasurer, finance-director, o2c, p2p, r2r]
---

# bpa-working-capital

Computes working capital metrics and the Cash Conversion Cycle (CCC) from BPA data.
Designed for Treasurers and Finance Directors who need to understand how efficiently
the business converts resources into cash — and where working capital can be freed up.

## When to use this skill

Use when asked for:
- Cash Conversion Cycle: CCC = DSO + DIO − DPO
- Days Sales Outstanding (DSO) trend and entity breakdown
- Days Inventory Outstanding (DIO) and inventory cash lock-up
- Days Payables Outstanding (DPO) and payment timing
- Net Working Capital (NWC) = Current Assets − Current Liabilities
- Working capital ratios: Current Ratio, Quick Ratio
- Period-over-period working capital trend (quarterly, annual)
- Entity-level working capital comparison
- Working capital optimization levers (accelerate collections, extend payables, reduce inventory)

## Workflow

### Step 1 — Retrieve schema
Call `get_bpa_dataset_schema` to identify:
- `FactCustomerInvoice` — open and closed AR invoices (Amount, DueDate, PaidDate, CompanyId)
- `FactVendorInvoice` — AP invoices (Amount, DueDate, PaidDate, CompanyId)
- `FactInventory` — inventory balance and valuation (OnHandQty, UnitCost, CompanyId)
- `FactGeneralLedger` — balance sheet items: current assets, current liabilities
- `DimLegalEntity` — entity filter

### Step 2 — Compute DSO (Days Sales Outstanding)
Formula: DSO = (Ending AR Balance / Total Revenue) × Number of Days in Period

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimLegalEntity[CompanyName],
    DimFiscalCalendar[FiscalYear],
    DimFiscalCalendar[FiscalQuarter],
    "ARBalance",    [Ending AR Balance],
    "Revenue",      [Total Revenue],
    "DaysInPeriod", [Days In Period],
    "DSO",          DIVIDE([ARBalance], [Revenue], 0) * [DaysInPeriod]
)
ORDER BY [DSO] DESC
```

### Step 3 — Compute DIO (Days Inventory Outstanding)
Formula: DIO = (Average Inventory / COGS) × Number of Days in Period

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimLegalEntity[CompanyName],
    DimFiscalCalendar[FiscalYear],
    DimFiscalCalendar[FiscalQuarter],
    "AvgInventory", [Average Inventory Value],
    "COGS",         [Cost of Goods Sold],
    "DaysInPeriod", [Days In Period],
    "DIO",          DIVIDE([AvgInventory], [COGS], 0) * [DaysInPeriod]
)
ORDER BY [DIO] DESC
```

### Step 4 — Compute DPO (Days Payables Outstanding)
Formula: DPO = (Ending AP Balance / Total Purchases) × Number of Days in Period

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimLegalEntity[CompanyName],
    DimFiscalCalendar[FiscalYear],
    DimFiscalCalendar[FiscalQuarter],
    "APBalance",    [Ending AP Balance],
    "Purchases",    [Total Purchases],
    "DaysInPeriod", [Days In Period],
    "DPO",          DIVIDE([APBalance], [Purchases], 0) * [DaysInPeriod]
)
ORDER BY [DPO] ASC
```

### Step 5 — CCC and working capital ratios
Combine the three metrics and compute net working capital:

```dax
EVALUATE
ROW(
    "CCC",              [DSO] + [DIO] - [DPO],
    "NetWorkingCapital", [Current Assets] - [Current Liabilities],
    "CurrentRatio",      DIVIDE([Current Assets], [Current Liabilities], 0),
    "QuickRatio",        DIVIDE([Current Assets] - [Inventory], [Current Liabilities], 0)
)
```

### Step 6 — Trend analysis and optimization levers
- Run the same metrics for the previous 4 quarters to show CCC trend
- Identify which component (DSO, DIO, or DPO) is the primary CCC driver
- Quantify cash release potential: e.g. "Reducing DSO by 5 days frees up $Xm at current revenue run rate"
- Rank entities by CCC and highlight outliers

## Output format

- **CCC summary table**: Entity | DSO | DIO | DPO | CCC | NWC | Current Ratio | vs Prior Period
- **CCC trend chart data**: 4-quarter rolling table for each component
- **Optimization levers**: 3 ranked actions with estimated cash release in $
- **Benchmark flags**: Industry benchmark comparison if available (DSO target <35d, DPO target 30–45d)

## Key concepts

- **CCC** (Cash Conversion Cycle) = DSO + DIO − DPO; lower is better
- **DSO** = how many days to collect cash from customers after invoicing
- **DIO** = how many days inventory sits before being sold
- **DPO** = how many days before the company pays its suppliers
- **NWC** = Current Assets − Current Liabilities; positive = solvent short-term
