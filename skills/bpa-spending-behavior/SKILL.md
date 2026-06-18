---
name: bpa-spending-behavior
description: >
  WHEN: "spending behavior vs budget", "why are we over budget", "month by month spend analysis",
  "causal budget variance", "transportation spend analysis", "external factors variance",
  "what caused the variance", "corrective recommendations over budget",
  "over-executing annual budget", "spending trend risk", "department spend trend",
  "budget deviation with causes", "operational spend analysis", "cost line analysis"
license: MIT
metadata:
  version: 1.0.0
  author: Aurelien Clere
  tags: [bpa, finance, spending, budget, fpa, variance, director, causal-analysis]
---

# bpa-spending-behavior

Analyses spending behaviour for a cost line or department over a defined period,
comparing it month by month against the approved budget. Goes beyond the numbers:
explains probable causes of deviations (internal and external factors) and provides
corrective recommendations if the trend risks over-executing the annual budget.

Designed for FP&A Directors and operational unit directors who need to argue variance
causes in front of the management committee — not just report the numbers.

## When to use this skill

Use when asked for:
- Month-by-month actual spend vs approved budget for a cost category or department
- Which months had the greatest favourable or unfavourable variance
- Why variances occurred (delivery volume, routes, suppliers, fuel prices, seasonality,
  macroeconomic context)
- Corrective recommendations if the annual budget is at risk of over-execution
- Spending trend analysis with risk assessment

## Workflow

### Step 1 — Retrieve schema
Call `get_bpa_dataset_schema` to identify:
- `FactGeneralLedger` — actual posted amounts (Amount, AccountId, FiscalPeriod, CompanyId)
- `FactBudget` — approved budget amounts (BudgetAmount, AccountId, FiscalPeriod)
- `DimAccount` — account names and categories (use to filter the cost line requested)
- `DimDepartment` / `DimCostCentre` — department dimension
- `DimFiscalCalendar` — period-to-month mapping

### Step 2 — Monthly actuals for the cost line
Replace ACCOUNT_FILTER and YEAR with the values from the user's request:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimFiscalCalendar[FiscalPeriod],
    DimFiscalCalendar[MonthName],
    FILTER(DimAccount, DimAccount[AccountCategory] = "Transportation"),
    "ActualSpend", CALCULATE(SUM(FactGeneralLedger[Amount]))
)
ORDER BY DimFiscalCalendar[FiscalPeriod]
```

### Step 3 — Monthly budget for the same cost line
```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimFiscalCalendar[FiscalPeriod],
    DimFiscalCalendar[MonthName],
    FILTER(DimAccount, DimAccount[AccountCategory] = "Transportation"),
    "BudgetAmount", CALCULATE(SUM(FactBudget[BudgetAmount]))
)
ORDER BY DimFiscalCalendar[FiscalPeriod]
```

### Step 4 — Compute variance and rank months
For each month, calculate:
- **Variance (USD)** = Actual − Budget
- **Variance (%)** = (Actual − Budget) / Budget × 100
- **Direction** = Over budget (positive) or Under budget (negative)

Identify the top 3 months with the greatest unfavourable variance and the top 3 with
the greatest favourable variance.

### Step 5 — Causal interpretation
For each high-variance month, reason over likely causes:
- **Internal factors**: delivery volume spike/drop, route changes, supplier substitution,
  contract renegotiation, one-off extraordinary costs
- **External factors**: fuel price movements, seasonal demand patterns, macroeconomic
  events (inflation, supply chain disruptions), regulatory changes

Note: the AI assistant combines BPA transactional data with general knowledge of market
context. The Director should validate with their operational team before presenting
to the management committee.

### Step 6 — Risk assessment and corrective recommendations
Calculate the YTD spend rate vs budget:
```dax
EVALUATE
VAR YTDActual = CALCULATE(SUM(FactGeneralLedger[Amount]),
    DimFiscalCalendar[FiscalYear] = 2026,
    DimAccount[AccountCategory] = "Transportation")
VAR YTDBudget = CALCULATE(SUM(FactBudget[BudgetAmount]),
    DimFiscalCalendar[FiscalYear] = 2026,
    DimAccount[AccountCategory] = "Transportation")
VAR AnnualBudget = CALCULATE(SUM(FactBudget[BudgetAmount]),
    DimFiscalCalendar[FiscalYear] = 2026,
    DimAccount[AccountCategory] = "Transportation")
RETURN ROW(
    "YTDActual", YTDActual,
    "YTDBudget", YTDBudget,
    "Variance", YTDActual - YTDBudget,
    "RemainingBudget", AnnualBudget - YTDActual,
    "ProjectedAnnual", YTDActual / DIVIDE(MONTH(TODAY()), 12)
)
```

If the projected annual spend exceeds the annual budget, surface corrective options:
- Renegotiate rates with top freight carriers
- Review route optimisation opportunities
- Defer discretionary shipments to Q4
- Request a budget revision for the impacted line

### Step 7 — Present results
Return:
1. Month-by-month variance table (actual, budget, variance USD, variance %)
2. Top variance months (best and worst) with causal commentary
3. Annual risk summary: projected year-end spend vs budget
4. Corrective recommendations (if over-budget risk detected)

## Sample result

**Transportation Spend — Jan to Jun 2026 vs Budget**

| Month | Actual | Budget | Var (USD) | Var % |
|---|---|---|---|---|
| January | 312,400 | 300,000 | +12,400 | +4.1% |
| February | 298,100 | 300,000 | -1,900 | -0.6% ✅ |
| March | 368,200 | 300,000 | +68,200 | **+22.7%** ⚠ |
| April | 310,500 | 310,000 | +500 | +0.2% |
| May | 290,400 | 310,000 | -19,600 | -6.3% ✅ |
| June | 334,800 | 310,000 | +24,800 | +8.0% |

**YTD: $1,914,400 actual vs $1,830,000 budget — +$84,400 (+4.6% over)**

**March spike analysis (+22.7%):**
> Likely causes: (1) fuel price spike (+8% in March per market data), (2) seasonal
> peak in outbound shipments consistent with Q1 close rush, (3) possible unplanned
> carrier substitution — validate with logistics team.

**Annual risk:** Projected year-end spend: $3,828,800 vs annual budget $3,720,000.
Risk of over-execution: **+$108,800 (+2.9%)** — manageable but requires monitoring.

**Recommendation:** Renegotiate fuel surcharge clauses with top 3 carriers before Q3.
