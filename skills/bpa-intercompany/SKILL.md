---
name: bpa-intercompany
description: >
  WHEN: "intercompany report", "intercompany reconciliation", "GL summary by entity",
  "cross-entity transactions", "intercompany packing slips", "intercompany sales orders",
  "reversing journal entries", "invoice matching variances", "open POs without invoices",
  "invoices without purchase orders", "negative expense balances",
  "intercompany anomalies", "intercompany elimination", "multi-entity GL"
license: MIT
metadata:
  version: 1.0.0
  author: Aurelien Clere
  tags: [bpa, finance, intercompany, r2r, p2p, anomaly-detection, senior-analyst]
---

# bpa-intercompany

Runs a consolidated intercompany report across all active legal entities in BPA with
anomaly detection. Designed for Senior Analysts who need exhaustive data coverage,
D365FO-specific terminology, and actionable recommendations — not just raw numbers.

## When to use this skill

Use when asked for:
- Intercompany reconciliation across entities
- GL summary by entity and account type (net balance, debits, credits, entry count)
- Intercompany indicators: packing slips, linked intercompany ledgers, sales orders,
  reversing journal entries
- Purchase activity per entity: PO count/amount, invoice count/amount, vendor count,
  invoice matching variances
- Anomaly flags: negative expense balances, invoices without POs, open POs without
  invoices, missing intercompany reconciliation activity

## Workflow

### Step 1 — Retrieve schema
Call `get_bpa_dataset_schema` to identify:
- `FactGeneralLedger` — GL entries (LedgerDimension, CompanyId, AccountType, Amount,
  Debit, Credit, EntryCount, IsReversing)
- `FactVendorInvoice` — purchase invoices (VendorId, PurchaseOrderId, Amount, CompanyId)
- `FactPurchaseOrder` — POs (PurchaseOrderId, CompanyId, VendorId, LineAmount, Status)
- `DimCompany` / `DimLegalEntity` — legal entity names and active status
- `DimAccount` — account type classification

### Step 2 — GL summary by entity and account type
Call `execute_dax_query`:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimLegalEntity[CompanyName],
    DimAccount[AccountType],
    "NetBalance",    [Net Balance],
    "TotalDebits",   [Total Debits],
    "TotalCredits",  [Total Credits],
    "EntryCount",    [Entry Count]
)
ORDER BY DimLegalEntity[CompanyName], DimAccount[AccountType]
```

### Step 3 — Purchase activity per entity
Call `execute_dax_query`:

```dax
EVALUATE
SUMMARIZECOLUMNS(
    DimLegalEntity[CompanyName],
    "POCount",        DISTINCTCOUNT(FactPurchaseOrder[PurchaseOrderId]),
    "POAmount",       SUM(FactPurchaseOrder[LineAmount]),
    "InvoiceCount",   DISTINCTCOUNT(FactVendorInvoice[InvoiceId]),
    "InvoiceAmount",  SUM(FactVendorInvoice[Amount]),
    "VendorCount",    DISTINCTCOUNT(FactVendorInvoice[VendorId]),
    "MatchingVar",    [Invoice Matching Variance]
)
```

### Step 4 — Anomaly detection
Run targeted DAX queries for each anomaly type:

**Negative expense balances:**
```dax
EVALUATE
FILTER(
    SUMMARIZECOLUMNS(
        DimLegalEntity[CompanyName],
        DimAccount[AccountName],
        "NetBalance", [Net Balance]
    ),
    [NetBalance] < 0 && RELATED(DimAccount[AccountType]) = "Expense"
)
```

**Invoices without POs:**
```dax
EVALUATE
FILTER(
    FactVendorInvoice,
    ISBLANK(FactVendorInvoice[PurchaseOrderId])
)
```

**Open POs without invoices:**
```dax
EVALUATE
FILTER(
    FactPurchaseOrder,
    FactPurchaseOrder[Status] = "Open"
    && ISBLANK(RELATED(FactVendorInvoice[InvoiceId]))
)
```

### Step 5 — Assemble and present
Return a structured report:
1. **GL Summary table** — by entity and account type
2. **Purchase Activity table** — by entity
3. **Anomaly flags table** — with description and recommended action per finding

For each anomaly, provide a concrete recommendation:
- Negative expense balance → suggest reviewing the offsetting entry or incorrect posting
- Invoice without PO → flag for three-way match review
- Open PO without invoice → check with vendor or close if goods not received
- Missing intercompany reconciliation → escalate to Controller for elimination entry

## Sample result

**GL Summary — All entities**

| Entity | Account Type | Net Balance | Debits | Credits | Entries |
|---|---|---|---|---|---|
| USSI | Revenue | (4,820,100) | 0 | 4,820,100 | 412 |
| USMF | Expense | 3,104,200 | 3,104,200 | 0 | 388 |
| FRSI | Intercompany | 12,400 | 980,200 | 967,800 | 54 |

**Anomalies detected (3)**

| Type | Entity | Detail | Recommendation |
|---|---|---|---|
| Negative expense | USMF | Account 6200 – IT Costs: -$8,400 | Review reversing entry #JNL-2025-0341 |
| Invoice w/o PO | USSI | 3 invoices, Vendor Fabrikam, $22,100 | Three-way match review required |
| Open PO no invoice | FRSI | PO-FR-00482, $14,800, 45 days old | Contact vendor or cancel PO |
