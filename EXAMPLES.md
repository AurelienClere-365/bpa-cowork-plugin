# Usage Examples — BPA Analytics Cowork Plugin

The BPA Analytics Cowork Plugin translates plain-English finance questions into live DAX queries
against your Dynamics 365 Business Performance Analytics dataset.

```
Finance question  ──►  BPA skill       ──►  BPA MCP tools    ──►  Structured result
(plain English)        (routes intent)      (DAX queries)         (in chat window)
```

---

## Quick navigation

| # | Example | Persona | Skill |
|---|---|---|---|
| 0 | Schema discovery — understand what data is available | All | Any |
| 1 | P&L summary for the current period | Controller / FP&A | bpa-financial-performance |
| 2 | Gross margin by business unit | Finance Director | bpa-financial-performance |
| 3 | EBITDA trend — last 6 months | CFO / FP&A | bpa-financial-performance |
| 4 | AR aging by customer bucket | AR Manager | bpa-cash-flow-ar-ap |
| 5 | DSO trend — rolling 12 months | Treasurer | bpa-cash-flow-ar-ap |
| 6 | AP aging and DPO | AP Manager | bpa-cash-flow-ar-ap |
| 7 | Budget vs actuals — current month | FP&A Analyst | bpa-budget-variance |
| 8 | Over-budget departments | Finance Controller | bpa-budget-variance |
| 9 | Variance waterfall — YTD | Finance Director | bpa-budget-variance |
| 10 | Top 10 vendors by spend | Procurement | bpa-vendor-performance |
| 11 | OTIF rate by vendor | Supply Chain | bpa-vendor-performance |
| 12 | Procurement category analysis | CPO | bpa-vendor-performance |
| 13 | Period-close checklist status | Controller | bpa-period-close |
| 14 | Subledger reconciliation gaps | Shared Services | bpa-period-close |
| 15 | CFO KPI dashboard | CFO | bpa-executive-kpis |
| 16 | Financial health scorecard | Board / Audit | bpa-executive-kpis |

---

## Example 0 — Schema discovery

### Prompt

> What financial data is available in BPA? Show me the main tables and key columns.

### What happens

1. `bpa-financial-performance` (or any BPA skill) activates.
2. Calls `get_bpa_dataset_schema` to retrieve the full dataset schema.
3. Parses and summarises the table names and their column count by domain.

### Result

> **BPA Dataset — Available tables by domain:**
>
> **Record-to-Report (R2R)**
> | Table | Key columns |
> |---|---|
> | FactGeneralLedger | CompanyId, LedgerDimension, Amount, FiscalYear, FiscalPeriod |
> | FactTrialBalance | AccountId, Debit, Credit, NetBalance, PeriodDate |
> | DimAccount | AccountId, AccountName, MainAccountCategory |
> | DimFiscalCalendar | FiscalYear, FiscalPeriod, PeriodStartDate, PeriodEndDate |
>
> **Procure-to-Pay (P2P)**
> | Table | Key columns |
> |---|---|
> | FactVendorInvoice | VendorId, InvoiceDate, DueDate, Amount, PaymentDate |
> | FactPurchaseOrder | PurchaseOrderId, OrderDate, VendorId, LineAmount |
> | DimVendor | VendorId, VendorName, Category, Country |
>
> **Order-to-Cash (O2C)**
> | Table | Key columns |
> |---|---|
> | FactCustomerInvoice | CustomerId, InvoiceDate, DueDate, Amount, PaymentDate |
> | DimCustomer | CustomerId, CustomerName, CreditLimit, RiskGroup |

---

## Example 1 — P&L summary for the current period

### Prompt

> Show me the P&L summary for March 2025 for all legal entities.

### What happens

1. `bpa-financial-performance` skill activates.
2. Calls `get_bpa_dataset_schema` to confirm column names.
3. Calls `execute_dax_query` with an EVALUATE query summing revenue, COGS, and operating expenses by MainAccountCategory filtered to FiscalYear=2025, FiscalPeriod=3.

### Result

> **P&L Summary — March 2025 (all entities)**
>
> | Category | Amount (USD) |
> |---|---|
> | Revenue | 8,420,150 |
> | Cost of Goods Sold | (5,104,320) |
> | **Gross Profit** | **3,315,830** |
> | Gross Margin % | 39.4% |
> | Operating Expenses | (2,180,640) |
> | **EBITDA** | **1,135,190** |
> | EBITDA Margin % | 13.5% |
>
> Drill down? "Break down revenue by business unit for March 2025."

---

## Example 2 — Gross margin by business unit

### Prompt

> What is the gross margin by business unit for Q1 2025? Highlight units below 30%.

### What happens

1. `bpa-financial-performance` skill activates.
2. Retrieves schema — confirms `DimBusinessUnit` dimension and its join to `FactGeneralLedger`.
3. Executes DAX query grouping Revenue and COGS by `BusinessUnitName`, filtered to FiscalYear=2025, FiscalPeriod IN {1,2,3}.
4. Calculates gross margin %, flags rows below 30%.

### Result

> **Gross Margin by Business Unit — Q1 2025**
>
> | Business Unit | Revenue | COGS | Gross Margin % | Status |
> |---|---|---|---|---|
> | Digital Services | 5,210,000 | 2,800,000 | 46.3% | OK |
> | Manufacturing | 3,100,000 | 2,480,000 | 20.0% | ⚠ Below 30% |
> | Professional Services | 2,980,000 | 1,640,000 | 44.9% | OK |
> | Logistics | 890,000 | 710,000 | 20.2% | ⚠ Below 30% |
>
> 2 business units below the 30% threshold. Investigate? "Show me the cost breakdown for Manufacturing in Q1 2025."

---

## Example 3 — EBITDA trend — last 6 months

### Prompt

> Show me EBITDA and EBITDA margin for the last 6 months. Are we trending up or down?

### What happens

1. `bpa-financial-performance` skill activates.
2. Queries `execute_dax_query` for monthly EBITDA over the last 6 fiscal periods.
3. Calculates month-over-month change and linear trend direction.

### Result

> **EBITDA Trend — Oct 2024 to Mar 2025**
>
> | Month | Revenue | EBITDA | Margin % | MoM change |
> |---|---|---|---|---|
> | Oct 2024 | 7,810K | 920K | 11.8% | — |
> | Nov 2024 | 8,050K | 990K | 12.3% | +7.6% |
> | Dec 2024 | 9,200K | 1,380K | 15.0% | +39.4% |
> | Jan 2025 | 7,600K | 880K | 11.6% | -36.2% |
> | Feb 2025 | 8,100K | 1,050K | 13.0% | +19.3% |
> | Mar 2025 | 8,420K | 1,135K | 13.5% | +8.1% |
>
> **Trend: improving (+16% EBITDA over 6 months).** December spike likely seasonal. January dip typical post-holiday.

---

## Example 4 — AR aging by customer bucket

### Prompt

> Show me AR aging for all customers as of today. I want buckets: current, 1-30, 31-60, 61-90, over 90 days.

### What happens

1. `bpa-cash-flow-ar-ap` skill activates.
2. Calls `get_bpa_dataset_schema` to confirm `FactCustomerInvoice` columns (DueDate, Amount, PaymentDate).
3. Executes DAX computing days overdue from today and grouping into aging buckets.

### Result

> **AR Aging Report — as of 14 June 2025**
>
> | Bucket | Count | Amount (USD) | % of Total |
> |---|---|---|---|
> | Current (not due) | 145 | 3,210,440 | 48.2% |
> | 1–30 days | 38 | 980,220 | 14.7% |
> | 31–60 days | 22 | 640,880 | 9.6% |
> | 61–90 days | 14 | 420,500 | 6.3% |
> | Over 90 days | 19 | 1,408,760 | 21.2% |
> | **Total** | **238** | **6,660,800** | |
>
> **Action:** 19 invoices over 90 days ($1.4M). Show them? "List the over-90-day invoices with customer names."

---

## Example 5 — DSO trend — rolling 12 months

### Prompt

> What is our DSO trend for the last 12 months?

### What happens

1. `bpa-cash-flow-ar-ap` skill activates.
2. Calculates Days Sales Outstanding (DSO = AR balance / Revenue × days in period) for each of the last 12 fiscal periods.

### Result

> **DSO Trend — July 2024 to June 2025**
>
> | Month | AR Balance | Revenue | Days | DSO |
> |---|---|---|---|---|
> | Jul 2024 | 5,820K | 7,310K | 31 | 24.7 |
> | Aug 2024 | 6,100K | 7,640K | 31 | 24.7 |
> | ... | ... | ... | ... | ... |
> | Jun 2025 | 6,660K | 8,420K | 30 | 23.7 |
>
> **Average DSO: 25.1 days.** Trend is stable. Industry benchmark (B2B SaaS): 30–45 days — your DSO is healthy.

---

## Example 6 — AP aging and DPO

### Prompt

> Show me AP aging and our current DPO. Flag vendors where we are past their payment terms.

### What happens

1. `bpa-cash-flow-ar-ap` skill activates.
2. Queries `FactVendorInvoice` for unpaid invoices, calculates days from DueDate.
3. Joins to `DimVendor` for payment terms. Calculates DPO from total AP / COGS × period days.

### Result

> **AP Aging — as of 14 June 2025**
>
> | Bucket | Amount (USD) |
> |---|---|
> | Not yet due | 2,140,300 |
> | 1–30 days overdue | 380,200 |
> | 31–60 days overdue | 145,600 |
> | Over 60 days | 88,400 |
>
> **DPO: 32 days** (target: 30–45 days — within range)
>
> **Vendors past payment terms (3 flagged):**
> | Vendor | Amount | Days overdue | Terms |
> |---|---|---|---|
> | Contoso Supplies | 88,400 | 71 | Net 30 |
> | Fabrikam Parts | 62,100 | 38 | Net 30 |
> | Northwind Logistics | 45,600 | 34 | Net 30 |

---

## Example 7 — Budget vs actuals — current month

### Prompt

> Compare actual vs budget for May 2025. Show me the variance by cost centre.

### What happens

1. `bpa-budget-variance` skill activates.
2. Calls `get_bpa_dataset_schema` — confirms budget and actuals are in the same fact table (or separate budget fact table with DimCostCentre join).
3. Executes DAX EVALUATE joining actuals and budget for FiscalYear=2025, FiscalPeriod=5.

### Result

> **Budget vs Actuals — May 2025 (by Cost Centre)**
>
> | Cost Centre | Actual | Budget | Variance (USD) | Variance % |
> |---|---|---|---|---|
> | Sales & Marketing | 820,400 | 750,000 | +70,400 | +9.4% ⚠ |
> | Operations | 1,240,300 | 1,300,000 | -59,700 | -4.6% ✅ |
> | IT & Infrastructure | 310,200 | 280,000 | +30,200 | +10.8% ⚠ |
> | Finance & Admin | 195,400 | 200,000 | -4,600 | -2.3% ✅ |
>
> 2 cost centres over budget. Drill down? "Show me the line items driving the Sales variance in May."

---

## Example 8 — Over-budget departments

### Prompt

> Which departments are over budget YTD in 2025? Sort by variance amount descending.

### What happens

1. `bpa-budget-variance` skill activates.
2. Runs a DAX EVALUATE summing actuals and budget YTD (FiscalPeriods 1 to current) grouped by department.
3. Filters where Actual > Budget, orders by variance descending.

### Result

> **Over-Budget Departments — YTD 2025 (Jan–May)**
>
> | Department | YTD Actual | YTD Budget | Variance | Variance % |
> |---|---|---|---|---|
> | Sales & Marketing | 4,210,000 | 3,750,000 | +460,000 | +12.3% |
> | IT & Infrastructure | 1,580,000 | 1,400,000 | +180,000 | +12.9% |
> | R&D | 890,000 | 800,000 | +90,000 | +11.3% |
>
> 3 departments over budget totalling $730K variance YTD.

---

## Example 9 — Variance waterfall — YTD

### Prompt

> Build a budget variance waterfall for YTD 2025. What are the top 5 drivers?

### What happens

1. `bpa-budget-variance` skill activates — Workflow C (variance decomposition).
2. Runs DAX query for variance by MainAccountCategory YTD.
3. Ranks top positive (over-budget) and negative (under-budget) drivers.

### Result

> **YTD 2025 Variance Waterfall — Top 5 drivers:**
>
> | # | Driver | Variance |
> |---|---|---|
> | 1 | Personnel costs (Sales) | +310,000 |
> | 2 | Cloud infrastructure | +180,000 |
> | 3 | Travel & entertainment | +95,000 |
> | 4 | Marketing spend — delayed | -220,000 |
> | 5 | Contracted services | -145,000 |
>
> **Net YTD variance: +220,000 (3.1% over budget)**

---

## Example 10 — Top 10 vendors by spend

### Prompt

> Who are our top 10 vendors by total spend in 2025? Include category and country.

### What happens

1. `bpa-vendor-performance` skill activates.
2. Calls `get_bpa_dataset_schema` to confirm `DimVendor` columns.
3. Executes DAX query summing `FactVendorInvoice.Amount` by VendorId, joined to `DimVendor` for name, category, and country. Top 10 ordered by spend.

### Result

> **Top 10 Vendors by Spend — YTD 2025**
>
> | Rank | Vendor | Category | Country | Spend (USD) |
> |---|---|---|---|---|
> | 1 | Contoso Supplies | Raw Materials | US | 2,840,200 |
> | 2 | Fabrikam Parts | Manufacturing | DE | 1,920,400 |
> | 3 | Azure (Microsoft) | Cloud Services | US | 1,580,100 |
> | 4 | Northwind Logistics | Freight | NL | 940,300 |
> | 5 | Tailspin Travels | Travel | UK | 620,100 |
> | ... | ... | ... | ... | ... |

---

## Example 11 — OTIF rate by vendor

### Prompt

> Show me the OTIF (on-time in-full) rate for our top 20 vendors. Flag any below 90%.

### What happens

1. `bpa-vendor-performance` skill activates — Workflow B (OTIF analysis).
2. Queries `FactPurchaseOrder` for received vs scheduled delivery dates and quantities.
3. Calculates OTIF rate per vendor, flags below 90%.

### Result

> **OTIF Rate — Top 20 Vendors (YTD 2025)**
>
> | Vendor | PO Count | On-Time | In-Full | OTIF Rate | Status |
> |---|---|---|---|---|---|
> | Contoso Supplies | 184 | 179 | 181 | 97.3% | OK |
> | Fabrikam Parts | 98 | 82 | 94 | 83.7% | ⚠ Below 90% |
> | Northwind Logistics | 210 | 196 | 210 | 93.3% | OK |
> | ... | ... | ... | ... | ... | ... |
>
> 3 vendors below 90% OTIF. Create a performance review task? "Draft a vendor review note for Fabrikam Parts."

---

## Example 12 — Procurement category analysis

### Prompt

> Give me a spend analysis by procurement category for 2025. I want to know our concentration risk.

### What happens

1. `bpa-vendor-performance` skill activates — Workflow C (category analysis).
2. Groups `FactVendorInvoice` spend by `DimVendor.Category`.
3. Calculates spend share % and top vendor count per category.

### Result

> **Procurement Category Analysis — YTD 2025**
>
> | Category | Total Spend | % of Total | Top Vendor | Concentration |
> |---|---|---|---|---|
> | Raw Materials | 6,840,000 | 38.4% | Contoso Supplies (42%) | High |
> | Cloud Services | 3,200,000 | 18.0% | Microsoft (98%) | Very High |
> | Freight & Logistics | 2,100,000 | 11.8% | Northwind (45%) | Medium |
> | Professional Services | 1,900,000 | 10.7% | 8 vendors | Low |
>
> **Concentration risk alert:** Cloud Services — 98% with a single vendor.

---

## Example 13 — Period-close checklist status

### Prompt

> What is the status of our March 2025 period close? Which steps are still open?

### What happens

1. `bpa-period-close` skill activates.
2. Queries the period-close status indicators from BPA — pending journals, unposted transactions, reconciliation gaps.
3. Returns close checklist with status per step.

### Result

> **Period Close — March 2025 Status**
>
> | Step | Status | Detail |
> |---|---|---|
> | All sub-ledger journals posted | ✅ Done | — |
> | AR sub-ledger reconciled | ✅ Done | — |
> | AP sub-ledger reconciled | ⚠ Pending | 3 unmatched invoices |
> | Intercompany eliminations | ✅ Done | — |
> | Fixed assets depreciation posted | ✅ Done | — |
> | Trial balance reviewed | ⚠ Pending | Awaiting CFO sign-off |
>
> 2 items pending. To investigate: "Show me the 3 unmatched AP invoices in March 2025."

---

## Example 14 — Subledger reconciliation gaps

### Prompt

> Are there any reconciliation gaps between the AP subledger and general ledger for Q1 2025?

### What happens

1. `bpa-period-close` skill activates — Workflow B (subledger reconciliation).
2. Runs DAX comparing FactVendorInvoice totals to the AP control account in FactGeneralLedger for each period in Q1.
3. Flags any periods where the difference exceeds the tolerance threshold (default $0).

### Result

> **AP Subledger vs General Ledger — Q1 2025**
>
> | Period | Subledger Total | GL Control Account | Difference | Status |
> |---|---|---|---|---|
> | Jan 2025 | 2,841,200 | 2,841,200 | 0 | ✅ Reconciled |
> | Feb 2025 | 3,104,800 | 3,104,800 | 0 | ✅ Reconciled |
> | Mar 2025 | 2,980,300 | 2,983,100 | 2,800 | ⚠ Gap |
>
> **March gap: $2,800.** Likely timing difference — 3 invoices posted to GL after subledger cut-off.

---

## Example 15 — CFO KPI dashboard

### Prompt

> Give me the CFO dashboard for May 2025. I need the key financial health indicators at a glance.

### What happens

1. `bpa-executive-kpis` skill activates.
2. Runs 5 parallel DAX queries: P&L metrics, liquidity ratios, AR/AP metrics, budget variance, and revenue trend.
3. Assembles a structured dashboard.

### Result

> **CFO Dashboard — May 2025**
>
> **Profitability**
> | KPI | Value | vs Prior Month | vs Budget |
> |---|---|---|---|
> | Revenue | $8.4M | +3.9% ↑ | -1.2% |
> | Gross Margin % | 39.4% | +0.8pp | +1.4pp |
> | EBITDA Margin % | 13.5% | +0.5pp | -0.5pp |
>
> **Liquidity & Working Capital**
> | KPI | Value | Target |
> |---|---|---|
> | DSO | 23.7 days | < 35 days ✅ |
> | DPO | 32 days | 30–45 days ✅ |
> | AR > 90 days | $1.4M (21%) | < 15% ⚠ |
>
> **Budget**
> | KPI | Value |
> |---|---|
> | YTD variance | +$730K (3.1% over) |
> | Depts over budget | 3 |
>
> Drill in? "Show me the top 3 items driving the EBITDA miss vs budget."

---

## Example 16 — Financial health scorecard

### Prompt

> Prepare a financial health scorecard for the board. Rate each dimension green / amber / red.

### What happens

1. `bpa-executive-kpis` skill activates — Workflow B (scorecard).
2. Runs DAX queries for each scorecard dimension (profitability, liquidity, collections, payables, cost control, revenue growth).
3. Applies RAG (Red/Amber/Green) thresholds and returns the structured scorecard.

### Result

> **Financial Health Scorecard — Q1 2025**
>
> | Dimension | Metric | Value | Status |
> |---|---|---|---|
> | Revenue Growth | QoQ change | +4.2% | 🟢 Green |
> | Gross Margin | vs prior year | 39.4% (+1.1pp) | 🟢 Green |
> | EBITDA Margin | vs target | 13.5% (-0.5pp) | 🟡 Amber |
> | Collections (DSO) | vs target (<35 days) | 23.7 days | 🟢 Green |
> | Overdue AR (>90d) | % of AR | 21.2% | 🔴 Red |
> | Cost Control | YTD budget variance | +3.1% over | 🟡 Amber |
> | Payables (DPO) | vs target (30–45d) | 32 days | 🟢 Green |
>
> **Overall: 🟡 Amber** — 1 red item (AR overdue) requires action before next board meeting.
>
> Board summary ready? "Write an executive summary for the board based on this scorecard."
