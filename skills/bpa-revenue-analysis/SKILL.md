---
name: bpa-revenue-analysis
description: >
  WHEN: "revenue analysis", "revenue by customer", "revenue by product", "revenue breakdown",
  "revenue by channel", "revenue by region", "revenue by geography", "top customers",
  "customer concentration", "revenue concentration risk", "Pareto analysis revenue",
  "top 10 customers", "revenue growth rate", "MoM revenue", "YoY revenue",
  "revenue trend", "revenue mix", "customer revenue ranking", "product revenue ranking",
  "revenue diversification", "key account analysis", "80/20 revenue",
  "which customers drive most revenue", "revenue by business unit", "revenue split"
license: MIT
metadata:
  version: 1.0.0
  author: Aurelien Clere
  tags: [bpa, finance, revenue, customers, growth, pareto, o2c, sales-finance, cfo]
---

# bpa-revenue-analysis

Deep-dives into revenue data from BPA across customers, products, channels, and geographies.
Designed for Revenue Managers, Sales Finance, and CFOs who need to understand revenue
composition, growth drivers, and concentration risk — not just the total top line.

## When to use this skill

Use when asked for:
- Revenue breakdown by customer, product, channel, or geography
- Top-N customer or product revenue ranking
- Pareto/80-20 concentration analysis (which 20% of customers drive 80% of revenue)
- Revenue growth rate: MoM, QoQ, YoY
- Revenue mix shift analysis (how the split changed over periods)
- Revenue concentration risk (single customer or product > X% of total)
- New vs recurring revenue split (first-time vs repeat customers)
- Revenue per legal entity or business unit comparison

## Workflow

### Step 1 — Retrieve schema
Call `get_bpa_dataset_schema` to identify:
- `FactCustomerInvoice` — invoiced revenue (CustomerId, ProductId, Amount, InvoiceDate, CompanyId, Channel)
- `DimCustomer` — customer master (CustomerName, CustomerGroup, Country, Region)
- `DimProduct` — product master (ProductName, ProductCategory, ProductLine)
- `DimLegalEntity` — entity filter
- `DimFiscalCalendar` — fiscal period, quarter, year

### Step 2 — Revenue by customer (top-N)
Call `execute_dax_query` for customer revenue ranking:

```dax
EVALUATE
TOPN(
    20,
    SUMMARIZECOLUMNS(
        DimCustomer[CustomerName],
        DimCustomer[CustomerGroup],
        DimCustomer[Country],
        "Revenue",     [Total Invoiced Revenue],
        "RevenueShare", DIVIDE([Total Invoiced Revenue], [Grand Total Revenue], 0)
    ),
    [Revenue], DESC
)
ORDER BY [Revenue] DESC
```

### Step 3 — Pareto / concentration risk
Call `execute_dax_query` to compute cumulative revenue share and flag
customers that collectively represent ≥80% of total revenue:

```dax
EVALUATE
VAR _Total = [Grand Total Revenue]
RETURN
ADDCOLUMNS(
    SUMMARIZECOLUMNS(
        DimCustomer[CustomerName],
        "Revenue", [Total Invoiced Revenue]
    ),
    "CumulativeShare", DIVIDE(
        SUMX(
            FILTER(ALL(DimCustomer), [Total Invoiced Revenue] >= EARLIER([Revenue])),
            [Total Invoiced Revenue]
        ),
        _Total, 0
    )
)
```

### Step 4 — Revenue growth rate (YoY and MoM)
Compare current period to same period prior year:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimFiscalCalendar[FiscalYear],
    DimFiscalCalendar[FiscalPeriodName],
    "Revenue",       [Total Invoiced Revenue],
    "RevenuePY",     CALCULATE([Total Invoiced Revenue], SAMEPERIODLASTYEAR('Date'[Date])),
    "GrowthUSD",     [Revenue] - [RevenuePY],
    "GrowthPct",     DIVIDE([Revenue] - [RevenuePY], [RevenuePY], 0)
)
ORDER BY DimFiscalCalendar[FiscalYear], DimFiscalCalendar[FiscalPeriodNumber]
```

### Step 5 — Revenue by product/category
Identify revenue contribution by product category and flag mix shifts:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimProduct[ProductCategory],
    DimProduct[ProductLine],
    DimFiscalCalendar[FiscalYear],
    "Revenue",     [Total Invoiced Revenue],
    "MixPct",      DIVIDE([Total Invoiced Revenue], [Grand Total Revenue], 0),
    "GrowthPct",   DIVIDE([Revenue] - [Revenue PY], [Revenue PY], 0)
)
ORDER BY [Revenue] DESC
```

### Step 6 — Format and interpret the output
Produce a structured analysis:
1. **Top customers table** — ranked, with revenue share and cumulative share
2. **Concentration risk flag** — how many customers = 80% of revenue; single-customer risk if >20%
3. **Growth analysis** — MoM and YoY growth, fastest/slowest growing segments
4. **Mix shift narrative** — identify if revenue composition has changed materially
5. **Recommendations** — diversification actions if concentration is high;
   flag declining customer relationships (revenue down >10% YoY)

## Output format

- **Revenue ranking table**: Customer / Product | Revenue | Share % | Cumulative Share % | YoY Growth %
- **Concentration summary**: "Top 5 customers represent X% of revenue. Highest single customer: Y at Z%"
- **Growth table**: Period | Revenue | vs PY | Growth %
- **Risk flags**: customers or products with >20% concentration or >15% revenue decline YoY

## Key concepts

- **Concentration risk**: one customer or product > 20% of total revenue = elevated risk
- **Pareto rule**: aim for top 20% of customers to represent <80% of revenue
- **Revenue mix shift**: change in category % from one period to another
- **New vs recurring**: first-invoice customers vs repeat customers in the same period
