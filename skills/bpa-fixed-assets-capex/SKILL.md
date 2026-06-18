---
name: bpa-fixed-assets-capex
description: >
  WHEN: "fixed assets", "capex", "capital expenditure", "net book value", "NBV",
  "depreciation schedule", "asset register", "fixed asset report", "capex vs opex",
  "capital vs operating expenditure", "asset utilization", "accumulated depreciation",
  "asset group analysis", "capex budget", "capex execution", "capex tracking",
  "fully depreciated assets", "capex approval", "asset disposal", "asset additions",
  "property plant equipment", "PP&E", "tangible assets", "capex forecast",
  "which assets are fully depreciated", "how much capex did we spend this year",
  "capex budget vs actual", "return on assets"
license: MIT
metadata:
  version: 1.0.0
  author: Aurelien Clere
  tags: [bpa, finance, fixed-assets, capex, depreciation, nbv, r2r, controller, asset-manager]
---

# bpa-fixed-assets-capex

Provides a comprehensive fixed asset and capital expenditure analysis from BPA data.
Designed for Asset Controllers, Finance Controllers, and CFOs who need visibility into
PP&E net book value, depreciation run, capex budget execution, and return on assets.

## When to use this skill

Use when asked for:
- Fixed asset register: net book value (NBV) by asset group, department, or legal entity
- Depreciation schedule: current period and YTD depreciation by asset group
- Accumulated depreciation and remaining useful life analysis
- Capex vs opex split from the GL
- Capex budget vs actual tracking (capital spending execution rate)
- Fully depreciated assets still in service (hidden risk / replacement candidates)
- Asset additions and disposals in a given period
- Return on Assets (ROA) = Net Income / Total Assets

## Workflow

### Step 1 — Retrieve schema
Call `get_bpa_dataset_schema` to identify:
- `FactFixedAsset` — asset transactions (AssetId, AcquisitionCost, AccumulatedDepreciation,
  CurrentDepreciation, DisposalAmount, BookValue, AcquisitionDate, CompanyId)
- `DimAsset` — asset master (AssetName, AssetGroup, ServiceLife, AcquisitionDate)
- `DimAssetGroup` — asset group (Machinery, IT Equipment, Buildings, Vehicles, etc.)
- `DimCostCenter` / `DimDepartment` — responsible cost center for the asset
- `FactGeneralLedger` — GL entries classified as capex vs opex (account type = Capital)
- `FactBudget` — capex budget entries

### Step 2 — Net book value by asset group
Call `execute_dax_query`:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimAssetGroup[AssetGroupName],
    DimLegalEntity[CompanyName],
    "AcquisitionCost",         [Total Acquisition Cost],
    "AccumulatedDepreciation", [Total Accumulated Depreciation],
    "NetBookValue",            [Total Acquisition Cost] - [Total Accumulated Depreciation],
    "AssetCount",              COUNTROWS(FactFixedAsset),
    "AvgRemainingLife",        AVERAGEX(FactFixedAsset, [Remaining Useful Life])
)
ORDER BY [NetBookValue] DESC
```

### Step 3 — Current period depreciation run
Call `execute_dax_query` for depreciation posted in the selected period:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimAssetGroup[AssetGroupName],
    DimFiscalCalendar[FiscalYear],
    DimFiscalCalendar[FiscalPeriodName],
    "CurrentDepreciation", [Period Depreciation Amount],
    "YTDDepreciation",     [YTD Depreciation Amount],
    "AssetCount",          COUNTROWS(FactFixedAsset)
)
ORDER BY [YTDDepreciation] DESC
```

### Step 4 — Fully depreciated assets still in service
Flag assets where NBV = 0 or < threshold but acquisition date > disposal date (still active):

```dax
EVALUATE
FILTER(
    SUMMARIZECOLUMNS(
        DimAsset[AssetName],
        DimAssetGroup[AssetGroupName],
        DimCostCenter[CostCenterName],
        "AcquisitionCost",  [Total Acquisition Cost],
        "NBV",              [Total Acquisition Cost] - [Total Accumulated Depreciation],
        "AcquisitionDate",  MIN(FactFixedAsset[AcquisitionDate]),
        "ServiceLifeYears", MAX(DimAsset[ServiceLife])
    ),
    [NBV] <= 0
)
```

### Step 5 — Capex vs opex from GL
Classify GL entries by account nature (capital vs operating) and compare to budget:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimAccount[ExpenditureType],
    DimFiscalCalendar[FiscalYear],
    DimFiscalCalendar[FiscalQuarter],
    "Actual",        [Total Amount],
    "Budget",        [Budget Amount],
    "Execution",     DIVIDE([Total Amount], [Budget Amount], 0),
    "Variance",      [Total Amount] - [Budget Amount]
)
WHERE DimAccount[ExpenditureType] IN {"Capital", "Operating"}
ORDER BY DimFiscalCalendar[FiscalYear], DimAccount[ExpenditureType]
```

### Step 6 — Return on Assets (ROA)
```dax
EVALUATE
ROW(
    "TotalAssets",    [Total Asset Book Value],
    "NetIncome",      [Net Income],
    "ROA",            DIVIDE([Net Income], [Total Asset Book Value], 0),
    "ROAPct",         DIVIDE([Net Income], [Total Asset Book Value], 0) * 100
)
```

### Step 7 — Format and interpret the output
Produce a structured report:
1. **NBV summary table** — by asset group: acquisition cost, accumulated depreciation, NBV, asset count
2. **Depreciation run** — current period and YTD depreciation by group
3. **Fully deprecated assets list** — name, group, cost center, acquisition cost, years in service
4. **Capex execution table** — capex actual vs budget, execution %, quarterly trend
5. **ROA KPI** — current vs prior year
6. **Recommendations**: assets approaching end of life (remaining life <1 year),
   capex underspend risk (low execution rate), capex overrun groups

## Output format

- **NBV table**: Asset Group | Acquisition Cost | Accum. Depreciation | NBV | Count | Avg Remaining Life
- **Capex execution**: Period | Capex Budget | Capex Actual | Execution % | Variance
- **Fully depreciated list**: Asset | Group | Department | Cost | Years in Service
- **ROA**: Net Income / Total Assets = X% (vs prior year Y%)

## Key concepts

- **Net Book Value (NBV)** = Acquisition Cost − Accumulated Depreciation
- **Capex** = capital expenditure (increases PP&E asset value)
- **Opex** = operating expenditure (charged to P&L in the period)
- **ROA** = Net Income / Total Assets; measures how efficiently assets generate profit
- **Fully depreciated but in service** = potential hidden replacement risk or understated asset base
