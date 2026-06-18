---
name: bpa-cash-flow-projection
description: >
  WHEN: "projected cash flow", "cash flow at 30 60 90 days", "liquidity gap",
  "expected collections next month", "committed payments forecast", "FX payment coverage",
  "liquidity risk", "pessimistic cash scenario", "cash flow forecast",
  "will we have enough to pay", "treasury projection", "collection realization rate",
  "opening balance plus collections minus payments", "cash deficit", "cash surplus"
license: MIT
metadata:
  version: 1.0.0
  author: Aurelien Clere
  tags: [bpa, finance, cash-flow, treasury, liquidity, o2c, p2p, manager]
---

# bpa-cash-flow-projection

Projects cash flow at 30, 60, and 90 days by combining expected AR collections and
committed AP payments. Applies the current exchange rate to foreign currency payments,
classifies liquidity gaps as CRITICAL / MODERATE / LOW, and builds a pessimistic
scenario based on the historical collection realization rate of the last 90 days.

Designed for Treasury and Finance Managers who need an actionable forward-looking view —
not just historical aging — to decide whether to trigger early collection actions.

## When to use this skill

Use when asked for:
- Cash flow projection at 30, 60, 90 days
- Liquidity gap analysis by period and currency
- FX-adjusted payment coverage (base currency conversion at today's rate)
- Pessimistic scenario with collection realization factor
- Whether current bank balance covers upcoming payments

## Workflow

### Step 1 — Retrieve schema
Call `get_bpa_dataset_schema` to confirm:
- `FactCustomerInvoice` — AR invoices (DueDate, Amount, Currency, PaymentDate)
- `FactVendorInvoice` — AP invoices (DueDate, Amount, Currency, VendorId, PaymentDate)
- `FactExchangeRate` or `DimCurrency` — daily exchange rates
- `FactBankBalance` or similar — current bank balance

### Step 2 — Expected collections (AR due in each window)
Call `execute_dax_query` for each period (replace TODAY and WINDOW with actual dates):

```dax
EVALUATE
SUMMARIZECOLUMNS(
    FactCustomerInvoice[Currency],
    "ExpectedCollections",
    CALCULATE(
        SUM(FactCustomerInvoice[Amount]),
        FactCustomerInvoice[PaymentDate] = BLANK(),
        FactCustomerInvoice[DueDate] >= TODAY(),
        FactCustomerInvoice[DueDate] <= TODAY() + 30
    )
)
```

Repeat for +31→60 and +61→90 windows.

### Step 3 — Committed payments (AP due in each window)
Call `execute_dax_query`:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    FactVendorInvoice[Currency],
    DimVendor[VendorName],
    "CommittedPayments",
    CALCULATE(
        SUM(FactVendorInvoice[Amount]),
        FactVendorInvoice[PaymentDate] = BLANK(),
        FactVendorInvoice[DueDate] >= TODAY(),
        FactVendorInvoice[DueDate] <= TODAY() + 30
    )
)
```

### Step 4 — FX conversion for non-base-currency payments
For each non-base-currency committed payment, retrieve the current exchange rate and
convert to base currency. Flag payments where converted amount exceeds projected
bank balance.

### Step 5 — Liquidity gap and criticality
For each period:
```
Gap = Opening Balance + Collections (base CCY) – Payments (base CCY)
```
Classify:
- **CRITICAL** if gap represents > 20% shortfall against opening balance
- **MODERATE** if 5–20% shortfall
- **LOW** if < 5% shortfall (or surplus)

### Step 6 — Pessimistic scenario
Query collection history for the last 90 days:
```dax
EVALUATE
VAR TotalDue = CALCULATE(SUM(FactCustomerInvoice[Amount]),
    FactCustomerInvoice[DueDate] >= TODAY() - 90,
    FactCustomerInvoice[DueDate] < TODAY())
VAR PaidOnTime = CALCULATE(SUM(FactCustomerInvoice[Amount]),
    FactCustomerInvoice[DueDate] >= TODAY() - 90,
    FactCustomerInvoice[DueDate] < TODAY(),
    FactCustomerInvoice[PaymentDate] <= FactCustomerInvoice[DueDate])
RETURN
    DIVIDE(PaidOnTime, TotalDue)
```

Apply the resulting realization rate (e.g. 82%) to expected collections to recalculate
the pessimistic gap.

### Step 7 — Present results
Return a summary table by period with base scenario and pessimistic scenario side by side,
plus a criticality conclusion and recommended action.

## Sample result

**Cash Flow Projection — as of 18 June 2026**

| Period | Opening Bal | Collections (base) | Payments (base) | Gap | Criticality |
|---|---|---|---|---|---|
| 0–30 days | $2,840,000 | $1,920,000 | $2,100,000 | +$660,000 | LOW ✅ |
| 31–60 days | $660,000 | $1,640,000 | $1,980,000 | +$320,000 | LOW ✅ |
| 61–90 days | $320,000 | $980,000 | $1,480,000 | **-$180,000** | **MODERATE ⚠** |

**Pessimistic scenario (82% collection rate):**

| Period | Adj. Collections | Gap | Criticality |
|---|---|---|---|
| 0–30 days | $1,574,400 | +$314,400 | LOW ✅ |
| 31–60 days | $1,344,800 | **-$291,200** | **MODERATE ⚠** |
| 61–90 days | $803,600 | **-$356,400** | **CRITICAL 🔴** |

> **Action:** In the pessimistic scenario, the 61–90 day window reaches CRITICAL.
> Recommend activating early collection calls for invoices due in that window.
> "Show me the invoices due 61–90 days with the largest outstanding amounts."
