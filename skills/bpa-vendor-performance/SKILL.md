---
name: bpa-vendor-performance
description: |
  Analyzes vendor and procurement performance from Dynamics 365 Business Performance Analytics.
  Covers vendor spend analysis, purchase order trends, on-time delivery, invoice accuracy,
  top/bottom vendor ranking, procurement category spend, and payment terms compliance.
  Use when asked: "vendor spend analysis", "top vendors by spend", "procurement analysis",
  "which vendors are we spending the most with", "purchase order volume by vendor",
  "vendor performance ranking", "on-time delivery rate", "invoice accuracy", 
  "procurement category breakdown", "tail spend analysis", "vendor consolidation",
  "payment terms by vendor", "how many vendors do we use", "single-source suppliers".
license: MIT
metadata:
  author: Dynagile Consulting
  version: "1.0"
  domain: Finance / Procurement / CFO
  bpa-coverage: Procure-to-Pay
---

# BPA Vendor & Procurement Performance Analysis

## What This Skill Does

Queries BPA Procure-to-Pay data to analyze procurement efficiency and vendor relationships:
- **Vendor spend ranking**: Top N vendors by total spend, with trend
- **Procurement category analysis**: Spend distribution by category/commodity
- **Purchase order metrics**: PO count, average PO value, PO cycle time
- **On-time delivery rate (OTIF)**: Percentage of deliveries on time and in full
- **Invoice accuracy**: Match rate between PO, receipt, and invoice (3-way match)
- **Payment terms compliance**: Are we paying within agreed terms?
- **Tail spend**: Number of vendors with low spend (consolidation opportunities)
- **Vendor diversification**: Single-source risk assessment

## Prerequisites

- BPA connector active (uses `get_bpa_dataset_schema` and `execute_dax_query` tools)
- Requires Procure-to-Pay data coverage in BPA
- BPA User role in Power Platform environment

## Workflow

### Step 1 — Discover schema
Call `get_bpa_dataset_schema` to identify:
- Vendor and purchase order tables/measures
- Procurement category dimensions
- Date dimensions for trend analysis
- On-time delivery and OTIF measures

### Step 2 — Clarify scope
Ask for:
- **Time period**: Fiscal quarter, fiscal year, or rolling 12 months
- **Focus**: Spend analysis, OTIF performance, invoice compliance, or full view
- **Top N**: How many vendors to show (default: top 10)
- **Legal entity**: All entities or specific company

### Step 3 — Execute DAX queries

**Top 10 vendors by spend:**
```dax
EVALUATE
TOPN(
    10,
    SUMMARIZECOLUMNS(
        'Vendor'[VendorName],
        'Vendor'[VendorGroup],
        FILTER('Date', 'Date'[FiscalYear] = 2024),
        "Total Spend", [Total Purchase Amount],
        "PO Count", [Purchase Order Count],
        "Avg PO Value", DIVIDE([Total Purchase Amount], [Purchase Order Count]),
        "Invoice Count", [Vendor Invoice Count]
    ),
    [Total Spend],
    DESC
)
```

**Procurement category breakdown:**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'ProcurementCategory'[CategoryName],
    FILTER('Date', 'Date'[FiscalYear] = 2024),
    "Total Spend", [Total Purchase Amount],
    "Spend %", DIVIDE([Total Purchase Amount], CALCULATE([Total Purchase Amount], ALL('ProcurementCategory'))),
    "Vendor Count", DISTINCTCOUNT('Vendor'[VendorID]),
    "PO Count", [Purchase Order Count]
)
ORDER BY [Total Spend] DESC
```

**Vendor performance (OTIF + invoice accuracy):**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Vendor'[VendorName],
    FILTER('Date', 'Date'[FiscalYear] = 2024 && 'Date'[FiscalPeriodNumber] <= 9),
    "Total Spend", [Total Purchase Amount],
    "On-Time Delivery %", [OTIF Rate],
    "Invoice Match Rate %", [3-Way Match Rate],
    "Avg Invoice Amount", [Avg Vendor Invoice Amount],
    "Invoice Count", [Vendor Invoice Count]
)
ORDER BY [Total Spend] DESC
```

**Tail spend analysis (vendors with low spend):**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Vendor'[VendorName],
    FILTER('Date', 'Date'[FiscalYear] = 2024),
    "Total Spend", [Total Purchase Amount],
    "PO Count", [Purchase Order Count]
)
-- After retrieving results, identify vendors where Total Spend < [threshold, e.g., €10,000]
-- These are tail spend consolidation candidates
ORDER BY [Total Spend] ASC
```

**Quarter-over-quarter vendor spend trend (top 5 vendors):**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Vendor'[VendorName],
    'Date'[FiscalYear],
    'Date'[FiscalQuarter],
    "Spend", [Total Purchase Amount]
)
-- Filter to top 5 vendors by prior year spend, then show quarterly trend
ORDER BY 'Vendor'[VendorName], 'Date'[FiscalYear], 'Date'[FiscalQuarter]
```

> Adapt measure and dimension names using `get_bpa_dataset_schema` output if needed.

### Step 4 — Present results

**Top vendor spend table:**

| Rank | Vendor | Category | Total Spend | PO Count | OTIF % | Invoice Match % |
|------|--------|---------|------------|---------|--------|----------------|
| 1 | Acme Supplies | Raw Materials | 2,450,000 | 48 | 94.2% | 98.1% |
| 2 | TechParts Ltd | IT Hardware | 1,830,000 | 22 | 87.5% | 95.4% |

Include procurement KPI summary:
> Total spend: **€12.4M** across **143 active vendors** | Avg OTIF: **91.3%** | Tail spend vendors (<€10K): **67 (47%)**

Flag:
- Vendors with OTIF < 85% (delivery risk)
- Vendors with invoice match rate < 90% (AP processing inefficiency)
- Top 5 vendors represent > 60% of spend (concentration risk)

## Key Procurement KPIs

| KPI | Description | Benchmark |
|-----|------------|-----------|
| OTIF Rate | On-Time In-Full delivery % | > 95% |
| 3-Way Match Rate | PO–Receipt–Invoice match | > 95% |
| Tail Spend % | % spend with low-value vendors | < 20% |
| Vendor Concentration | Top 10 vendors as % of total spend | < 70% |
| PO Cycle Time | Days from PO creation to goods receipt | < 14 days |

## Example Prompts That Trigger This Skill

- "Who are our top 10 vendors by spend this year?"
- "Show me procurement spend by category for Q3 2024"
- "Which vendors have the worst on-time delivery rate?"
- "Analyze vendor invoice accuracy — who has the most mismatches?"
- "How much tail spend do we have and which vendors can we consolidate?"
- "Show me vendor spend trends over the last 4 quarters"
- "Are we at risk of vendor concentration?"
- "What is our total procurement spend YTD?"
