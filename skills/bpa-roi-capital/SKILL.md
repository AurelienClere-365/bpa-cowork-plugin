---
name: bpa-roi-capital
description: >
  WHEN: "ROI analysis", "return on investment", "available capital for new initiatives",
  "capital allocation", "investment viability scenarios", "conservative base optimistic scenario",
  "budget execution percentage", "free capital", "investment by business unit",
  "software and training ROI", "new business line financing", "CFO investment decision",
  "how much can we invest", "H1 investment review", "strategic capital review"
license: MIT
metadata:
  version: 1.0.0
  author: Aurelien Clere
  tags: [bpa, finance, roi, capital, cfo, strategy, scenarios, investment]
---

# bpa-roi-capital

Delivers the three-question CFO investment review for a business unit or cost centre:
1. **ROI** — What return did we get on what we invested? (by category, vs prior period)
2. **Budget execution** — Did we deliver the revenue we committed to?
3. **Available capital** — How much free capital exists for the next initiative,
   under conservative, base, and optimistic scenarios?

Designed for CFOs and Finance Directors who need a forward-looking, capital-allocation
view — not just historical reporting.

## When to use this skill

Use when asked for:
- ROI on a specific investment category (software, training, marketing, capex)
- Comparison of ROI vs prior semester or prior year
- Revenue budget execution % with causes of deviation
- Free capital calculation for a new initiative
- Financial viability scenarios (conservative / base / optimistic)
- Business-unit-level investment analysis

## Workflow

### Step 1 — Retrieve schema
Call `get_bpa_dataset_schema` to identify:
- `FactGeneralLedger` — actuals (Amount, AccountId, DimensionBusinessUnit, FiscalPeriod)
- `FactBudget` — budget amounts
- `DimAccount` — investment categories (Software, Training, Marketing, Capex)
- `DimBusinessUnit` — business unit dimension for filtering
- `DimFiscalCalendar` — period filtering (H1 = periods 1–6)

### Step 2 — Investment ROI by category
For each investment category, calculate:
- **Investment amount** = actual spend in target period
- **Revenue generated** = revenue attributed to the same BU in same period
- **ROI** = (Revenue − Investment) / Investment × 100

```dax
EVALUATE
VAR BU = "253"   -- replace with requested business unit
VAR PeriodStart = 1
VAR PeriodEnd   = 6
VAR FY          = 2026
RETURN
SUMMARIZECOLUMNS(
    DimAccount[AccountCategory],
    FILTER(DimBusinessUnit, DimBusinessUnit[BusinessUnitId] = BU),
    FILTER(DimFiscalCalendar,
        DimFiscalCalendar[FiscalYear] = FY &&
        DimFiscalCalendar[FiscalPeriod] >= PeriodStart &&
        DimFiscalCalendar[FiscalPeriod] <= PeriodEnd),
    "InvestmentAmount", CALCULATE(SUM(FactGeneralLedger[Amount]),
        DimAccount[AccountType] = "Expense"),
    "Revenue", CALCULATE(SUM(FactGeneralLedger[Amount]),
        DimAccount[AccountType] = "Revenue")
)
```

Compare the same query for the prior period (H2 previous year or H1 prior year).

### Step 3 — Budget execution
```dax
EVALUATE
VAR ActualRevenue = CALCULATE(SUM(FactGeneralLedger[Amount]),
    DimAccount[AccountType] = "Revenue",
    DimBusinessUnit[BusinessUnitId] = "253",
    DimFiscalCalendar[FiscalYear] = 2026,
    DimFiscalCalendar[FiscalPeriod] IN {1,2,3,4,5,6})
VAR BudgetRevenue = CALCULATE(SUM(FactBudget[BudgetAmount]),
    DimAccount[AccountType] = "Revenue",
    DimBusinessUnit[BusinessUnitId] = "253",
    DimFiscalCalendar[FiscalYear] = 2026,
    DimFiscalCalendar[FiscalPeriod] IN {1,2,3,4,5,6})
RETURN ROW(
    "ActualRevenue",   ActualRevenue,
    "BudgetRevenue",   BudgetRevenue,
    "ExecutionPct",    DIVIDE(ActualRevenue, BudgetRevenue) * 100,
    "Variance",        ActualRevenue - BudgetRevenue
)
```

Identify main causes of deviation (positive or negative) by drilling into
account-level variances.

### Step 4 — Available capital calculation
```dax
EVALUATE
VAR Revenue    = [Actual Revenue H1]
VAR OpEx       = [Actual Operating Expenses H1]
VAR Reserves   = [Current Reserve Balance]
VAR FreeCap    = Revenue - OpEx + Reserves
RETURN ROW("FreeCapital", FreeCap)
```

### Step 5 — Three scenarios for new initiative viability
Given the free capital amount and a requested investment size, build:

| Scenario | Revenue assumption | Cost assumption | Viable? |
|---|---|---|---|
| **Conservative** | -20% vs base | +10% vs estimate | Yes / No |
| **Base** | As projected | As estimated | Yes / No |
| **Optimistic** | +20% vs base | -5% vs estimate | Yes / No |

For each scenario, calculate projected ROI and payback period.

### Step 6 — Present results
Return:
1. **Investment ROI table** — by category, current vs prior period
2. **Budget execution summary** — revenue %, variance, top deviation drivers
3. **Free capital statement** — Revenue − OpEx + Reserves
4. **Scenario table** — conservative / base / optimistic viability for the proposed initiative

## Sample result

**Business Unit 253 — eCommerce | H1 2026 Investment Review**

**Investment ROI by category**

| Category | H1 2026 Investment | H1 2025 Investment | Revenue (BU) | ROI H1 2026 | ROI H1 2025 |
|---|---|---|---|---|---|
| Software | $420,000 | $380,000 | $3,840,000 | 814% | 826% |
| Employee Training | $95,000 | $72,000 | $3,840,000 | 3942% | 5233% |

**Budget Execution — Revenue**

| Metric | Value |
|---|---|
| Actual Revenue H1 | $3,840,000 |
| Budget Revenue H1 | $4,100,000 |
| Execution | 93.7% |
| Variance | -$260,000 |
| Main cause | eCommerce launch delayed by 3 weeks in Q1 |

**Available Capital for New Initiatives**

| | Amount |
|---|---|
| H1 Revenue | $3,840,000 |
| H1 Operating Expenses | ($2,980,000) |
| Current Reserves | $640,000 |
| **Free Capital** | **$1,500,000** |

**Digital Marketing Line Launch — Scenario Analysis ($800K investment)**

| Scenario | Revenue (Yr 1) | Net Return | ROI | Viable? |
|---|---|---|---|---|
| Conservative | $760,000 | -$40,000 | -5% | ❌ No |
| Base | $1,100,000 | +$300,000 | 38% | ✅ Yes |
| Optimistic | $1,380,000 | +$580,000 | 73% | ✅ Yes |

> **Recommendation:** Base and optimistic scenarios are viable with available free capital.
> Conservative scenario requires either a reduced initial investment or a phased launch.
