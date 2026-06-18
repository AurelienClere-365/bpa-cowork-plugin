---
name: bpa-period-close
description: |
  Analyzes period-end close status and financial close metrics from Dynamics 365 Business
  Performance Analytics. Covers close progress tracking, journal entry completeness,
  reconciliation status, intercompany eliminations, accruals, and close timeline analysis.
  Use when asked: "period close status", "how is the month-end close going",
  "what is still open for close", "reconciliation status", "close checklist progress",
  "accrual review", "intercompany transactions", "which journals are not posted",
  "close timeline", "days to close", "financial close efficiency", "open items for close",
  "subledger reconciliation", "GL account reconciliation", "unposted transactions".
license: MIT
metadata:
  author: Dynagile Consulting
  version: "1.0"
  domain: Finance / Controller / CFO
  bpa-coverage: Record-to-Report
---

# BPA Period-End Close Analysis

## What This Skill Does

Queries BPA to support and monitor the financial period-close process:
- **Close progress**: Open vs. posted journals by type (accruals, allocations, corrections)
- **Subledger reconciliation**: AR, AP, inventory, fixed asset subledger vs. GL balance
- **Transaction completeness**: Unposted or unreconciled items blocking close
- **Intercompany**: Intercompany balances that need elimination
- **Accruals**: Recurring accrual status and reversal tracking
- **Close timeline**: Days-to-close trend over fiscal periods
- **Period comparison**: Current period vs. prior periods at same close stage

## Prerequisites

- BPA connector active (uses `get_bpa_dataset_schema` and `execute_dax_query` tools)
- BPA User role in Power Platform environment
- Requires Record-to-Report data coverage in BPA

## Workflow

### Step 1 — Discover schema
Call `get_bpa_dataset_schema` to identify:
- Journal entry and posting status measures
- Subledger reconciliation tables
- Period and close date dimensions
- Intercompany and elimination structures

### Step 2 — Clarify scope
Ask for:
- **Period**: Current open period or specific historical period
- **Entity**: Single legal entity or all entities
- **Focus**: Full close checklist, specific reconciliation, or trend analysis

### Step 3 — Execute DAX queries

**Close status overview — posted vs. unposted transactions:**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'JournalType'[JournalTypeName],
    FILTER('Date', 'Date'[FiscalYear] = 2024 && 'Date'[FiscalPeriodNumber] = 9),
    "Posted Count", CALCULATE([Journal Line Count], 'Journal'[PostingStatus] = "Posted"),
    "Unposted Count", CALCULATE([Journal Line Count], 'Journal'[PostingStatus] <> "Posted"),
    "Posted Amount", CALCULATE([Journal Amount], 'Journal'[PostingStatus] = "Posted"),
    "Unposted Amount", CALCULATE([Journal Amount], 'Journal'[PostingStatus] <> "Posted")
)
```

**Subledger vs GL reconciliation:**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Subledger'[SubledgerName],
    FILTER('Date', 'Date'[FiscalPeriodNumber] = 9 && 'Date'[FiscalYear] = 2024),
    "Subledger Balance", [Subledger Balance],
    "GL Balance", [GL Control Account Balance],
    "Reconciliation Difference", [Subledger Balance] - [GL Control Account Balance],
    "Reconciled", IF(ABS([Subledger Balance] - [GL Control Account Balance]) < 0.01, "Yes", "No")
)
```

**Intercompany imbalances:**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'LegalEntity'[EntityName],
    'IntercompanyEntity'[CounterpartyName],
    FILTER('Date', 'Date'[FiscalPeriodNumber] = 9 && 'Date'[FiscalYear] = 2024),
    "IC Receivable", [Intercompany Receivable Balance],
    "IC Payable", [Intercompany Payable Balance],
    "Net IC Imbalance", [Intercompany Receivable Balance] + [Intercompany Payable Balance]
)
WHERE [Net IC Imbalance] <> 0
```

**Days-to-close trend (last 6 periods):**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'Date'[FiscalYear],
    'Date'[FiscalPeriodName],
    "Days to Close", [Days to Close],
    "Close Date", [Period Close Date],
    "Period End Date", [Period End Date]
)
ORDER BY 'Date'[FiscalYear] DESC, 'Date'[FiscalPeriodName] DESC
```

**Accrual completeness:**
```dax
EVALUATE
SUMMARIZECOLUMNS(
    'AccrualType'[AccrualTypeName],
    FILTER('Date', 'Date'[FiscalPeriodNumber] = 9 && 'Date'[FiscalYear] = 2024),
    "Expected Accruals", [Expected Accrual Count],
    "Posted Accruals", [Posted Accrual Count],
    "Missing Accruals", [Expected Accrual Count] - [Posted Accrual Count],
    "Total Accrual Amount", [Posted Accrual Amount]
)
```

> Adapt measure names to actual BPA schema using `get_bpa_dataset_schema` output.

### Step 4 — Present results

**Close status dashboard:**

| Category | Status | Open Items | Amount | Owner |
|----------|--------|-----------|--------|-------|
| AR Subledger Recon | Reconciled | 0 | — | AR Team |
| AP Subledger Recon | Open | 1 | €2,340 | AP Team |
| Accruals | Partial | 3 of 8 posted | €45,000 | Controller |
| Intercompany | Open | 2 imbalances | €12,500 | Group Finance |
| Fixed Assets | Reconciled | 0 | — | Asset Team |

Close KPI summary:
> Period: **September 2024** | Days elapsed since period end: **3** | Items blocking close: **6** | Close target: **Day 5**

**Days-to-close trend:**
| Period | Days to Close | vs Prior Period |
|--------|-------------|----------------|
| Aug 2024 | 4 | — |
| Jul 2024 | 5 | +1 |
| Jun 2024 | 6 | +1 |

## Close Best Practices Reference

| Close Activity | Timing | Risk if Delayed |
|--------------|--------|----------------|
| Subledger reconciliation | Day 1–2 | Incorrect GL balances |
| Accruals posting | Day 2–3 | Understated expenses |
| Intercompany elimination | Day 3–4 | Consolidated P&L errors |
| Management reporting | Day 4–5 | Delayed decisions |

## Example Prompts That Trigger This Skill

- "What is the status of the September close?"
- "Show me all unposted journals for period 9 2024"
- "Are there any subledger reconciliation differences?"
- "How many intercompany imbalances need to be resolved before we can close?"
- "Show me the days-to-close trend for the last 6 months"
- "Which accruals are missing for this period?"
- "What is blocking us from closing the books?"
- "Show me the financial close timeline comparison vs prior periods"
