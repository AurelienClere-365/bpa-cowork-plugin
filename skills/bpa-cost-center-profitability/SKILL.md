---
name: bpa-cost-center-profitability
description: >
  WHEN: "cost center profitability", "department P&L", "cost center margin",
  "profitability by department", "cost allocation analysis", "direct vs indirect costs",
  "overhead allocation", "cost center variance", "department over budget",
  "cost center performance", "G&A cost breakdown", "department cost ranking",
  "management accounting", "profit center analysis", "cost center report",
  "which department is most profitable", "allocated costs by cost center"
license: MIT
metadata:
  version: 1.0.0
  author: Aurelien Clere
  tags: [bpa, finance, cost-center, profitability, management-accounting, r2r]
---

# bpa-cost-center-profitability

Generates a full cost center and department profitability report from BPA data.
Designed for Management Accountants and Finance Controllers who need to understand
where value is created and destroyed across the organization — beyond aggregate totals.

## When to use this skill

Use when asked for:
- Cost center or department P&L (revenue, direct costs, allocated overhead, contribution margin)
- Ranking of most/least profitable cost centers or departments
- Direct vs indirect cost split per cost center
- Budget vs actual comparison at cost center level
- Over-budget or under-recovered departments
- Overhead allocation rates and recovery analysis

## Workflow

### Step 1 — Retrieve schema
Call `get_bpa_dataset_schema` to identify:
- `FactGeneralLedger` — GL entries by account, cost center, and period
- `FactBudget` — budget amounts by cost center and account
- `DimCostCenter` / `DimDepartment` — cost center and department hierarchy
- `DimAccount` — account type (Revenue, COGS, Direct Expense, Indirect/Overhead)
- `DimFiscalCalendar` — fiscal period and year dimensions

### Step 2 — Cost center P&L: revenue and direct costs
Call `execute_dax_query`:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimCostCenter[CostCenterCode],
    DimCostCenter[CostCenterName],
    DimDepartment[DepartmentName],
    DimFiscalCalendar[FiscalYear],
    DimFiscalCalendar[FiscalPeriodName],
    "Revenue",        CALCULATE([Total Amount], DimAccount[AccountType] = "Revenue"),
    "DirectCosts",    CALCULATE([Total Amount], DimAccount[AccountType] = "Expense",
                                DimAccount[CostNature] = "Direct"),
    "ContribMargin",  [Revenue] - [DirectCosts],
    "ContribMarginPct", DIVIDE([Revenue] - [DirectCosts], [Revenue], 0)
)
ORDER BY [ContribMargin] DESC
```

### Step 3 — Overhead allocation and net margin
Call `execute_dax_query` to retrieve allocated indirect costs per cost center,
then compute net contribution margin = Revenue − Direct Costs − Allocated Overhead.

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimCostCenter[CostCenterCode],
    DimCostCenter[CostCenterName],
    "AllocatedOverhead", CALCULATE([Total Amount], DimAccount[CostNature] = "Indirect"),
    "NetMargin",         [ContribMargin] - [AllocatedOverhead],
    "NetMarginPct",      DIVIDE([NetMargin], [Revenue], 0)
)
ORDER BY [NetMargin] ASC
```

### Step 4 — Budget vs actual at cost center level
Call `execute_dax_query` comparing `FactGeneralLedger` actuals to `FactBudget`:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimCostCenter[CostCenterName],
    DimFiscalCalendar[FiscalPeriodName],
    "Actual",   [Total Amount],
    "Budget",   [Budget Amount],
    "Variance", [Total Amount] - [Budget Amount],
    "VariancePct", DIVIDE([Total Amount] - [Budget Amount], [Budget Amount], 0)
)
ORDER BY [VariancePct] DESC
```

### Step 5 — Format and interpret the output
Produce a structured report:
1. **Profitability ranking table** — all cost centers sorted by net margin (best to worst)
2. **Over-budget alert list** — cost centers where actual > budget by more than 5%
3. **Overhead recovery rate** — allocated overhead vs total overhead pool per center
4. **Actionable flags**: identify underperforming or structurally loss-making centers
   and recommend corrective action (cost reduction, reallocation review, or revenue lever)

## Output format

- Summary table: Cost Center | Revenue | Direct Costs | Contrib Margin % | Net Margin % | Budget Var %
- Ranked list: Top 5 most profitable and bottom 5 most costly cost centers
- Alert section: Over-budget cost centers with variance > threshold
- Narrative paragraph for management commentary

## Key concepts

- **Contribution margin** = Revenue − Direct Costs (before overhead allocation)
- **Net margin** = Revenue − Direct Costs − Allocated Overhead
- **Overhead recovery rate** = Allocated Overhead / Total Overhead Pool × 100
- **Cost center** maps to `DimCostCenter`; **department** maps to `DimDepartment`
