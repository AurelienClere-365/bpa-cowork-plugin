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
| 17 | Intercompany report + anomaly detection | Senior Analyst | bpa-intercompany |
| 18 | Cash flow projection 30/60/90 days + liquidity gap | Manager / Treasurer | bpa-cash-flow-projection |
| 19 | Spending behaviour vs budget with causal analysis | FP&A Director | bpa-spending-behavior |
| 20 | ROI, budget execution, and capital scenarios | CFO | bpa-roi-capital |
| 21 | Cost center profitability ranking + over-budget alert | Management Accountant | bpa-cost-center-profitability |
| 22 | Cash Conversion Cycle (CCC) breakdown + optimization levers | Treasurer | bpa-working-capital |
| 23 | Revenue by customer — Pareto + concentration risk | Revenue Manager | bpa-revenue-analysis |
| 24 | Fixed asset NBV + fully depreciated assets + capex execution | Asset Controller | bpa-fixed-assets-capex |

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

---

## Example 17 — Intercompany report + anomaly detection

### Prompt

> Run an intercompany report for all active legal entities in BPA. Show the GL summary
> by entity and account type, including net balance, total debits, total credits, and
> entry count. Identify intercompany indicators and purchase activity by entity.
> Flag any anomalies such as negative expense balances, invoices without purchase orders,
> open POs without invoices, or missing intercompany reconciliation, and provide
> actionable recommendations for each.

### What happens

1. `bpa-intercompany` skill activates.
2. Calls `get_bpa_dataset_schema` to confirm `FactGeneralLedger`, `FactVendorInvoice`,
   `FactPurchaseOrder`, and `DimLegalEntity` columns.
3. Runs DAX query for GL summary grouped by entity and account type.
4. Runs DAX query for purchase activity per entity (PO count, invoice count, matching variances).
5. Runs targeted anomaly queries: negative expense balances, invoices without POs,
   open POs without invoices.
6. Assembles structured report with per-anomaly recommendations.

### Result

> **GL Summary — All active entities**
>
> | Entity | Account Type | Net Balance | Debits | Credits | Entries |
> |---|---|---|---|---|---|
> | USSI | Revenue | (4,820,100) | 0 | 4,820,100 | 412 |
> | USMF | Expense | 3,104,200 | 3,104,200 | 0 | 388 |
> | FRSI | Intercompany | 12,400 | 980,200 | 967,800 | 54 |
>
> **Purchase Activity by Entity**
>
> | Entity | POs | PO Amount | Invoices | Invoice Amount | Matching Var |
> |---|---|---|---|---|---|
> | USMF | 142 | $2,840,000 | 138 | $2,798,400 | $41,600 |
> | FRSI | 38 | $640,200 | 35 | $596,800 | $43,400 |
>
> **Anomalies detected (3):**
>
> | Type | Entity | Detail | Recommendation |
> |---|---|---|---|
> | Negative expense | USMF | Account 6200 – IT Costs: -$8,400 | Review reversing entry #JNL-2025-0341 |
> | Invoice w/o PO | USSI | 3 invoices, Fabrikam, $22,100 | Three-way match review required |
> | Open PO no invoice | FRSI | PO-FR-00482, $14,800, 45 days old | Contact vendor or cancel PO |

---

## Example 18 — Cash flow projection 30/60/90 days + liquidity gap

### Prompt

> Analyse the projected cash flow at 30, 60, and 90 days from today.
> Show expected collections and committed payments by period, convert foreign currency
> payments at today’s exchange rate, and calculate the liquidity gap for each window.
> Classify each gap as CRITICAL, MODERATE, or LOW, and give me a pessimistic scenario
> based on our collection history from the last 90 days.

### What happens

1. `bpa-cash-flow-projection` skill activates.
2. Calls `get_bpa_dataset_schema` to confirm `FactCustomerInvoice`, `FactVendorInvoice`,
   `FactExchangeRate`, and `FactBankBalance` columns.
3. Runs DAX queries for expected AR collections by currency for each 30-day window.
4. Runs DAX queries for committed AP payments by currency and vendor for each window.
5. Converts non-base-currency payments at today’s exchange rate.
6. Calculates gap = Opening Balance + Collections – Payments, applies criticality thresholds.
7. Queries last-90-days collection realization rate and recalculates pessimistic scenario.

### Result

> **Cash Flow Projection — as of 18 June 2026**
>
> | Period | Collections | Payments | Gap | Criticality |
> |---|---|---|---|---|
> | 0–30 days | $1,920,000 | $2,100,000 | +$660,000 | LOW ✅ |
> | 31–60 days | $1,640,000 | $1,980,000 | +$320,000 | LOW ✅ |
> | 61–90 days | $980,000 | $1,480,000 | **-$180,000** | **MODERATE ⚠** |
>
> **Pessimistic scenario (82% collection rate):**
>
> | Period | Adj. Collections | Gap | Criticality |
> |---|---|---|---|
> | 0–30 days | $1,574,400 | +$314,400 | LOW ✅ |
> | 31–60 days | $1,344,800 | -$291,200 | **MODERATE ⚠** |
> | 61–90 days | $803,600 | -$356,400 | **CRITICAL 🔴** |
>
> Recommend activating early collection calls for invoices due 61–90 days.
> "Show me the largest open invoices due in 61–90 days."

---

## Example 19 — Spending behaviour vs budget with causal analysis

### Prompt

> Analyse the distribution transportation spending behaviour during the current year
> (January–June 2026), comparing it month by month against the approved budget.
> For each month, show the actual vs budget, the variance in absolute value and percentage,
> the months with the greatest variance, possible causes (internal and external factors),
> and corrective recommendations if we risk over-executing the annual budget.

### What happens

1. `bpa-spending-behavior` skill activates.
2. Calls `get_bpa_dataset_schema` to confirm `FactGeneralLedger`, `FactBudget`,
   `DimAccount`, and `DimFiscalCalendar`.
3. Runs DAX query for monthly actuals filtered to transportation account category.
4. Runs DAX query for monthly budget on the same filter.
5. Computes month-by-month variance (USD and %) and ranks worst/best months.
6. Reasons over causal factors (internal: volume, routes, suppliers;
   external: fuel prices, seasonality, macro context).
7. Projects year-end spend; flags over-budget risk and surfaces corrective options.

### Result

> **Transportation Spend — Jan–Jun 2026 vs Budget**
>
> | Month | Actual | Budget | Var (USD) | Var % |
> |---|---|---|---|---|
> | January | 312,400 | 300,000 | +12,400 | +4.1% |
> | February | 298,100 | 300,000 | -1,900 | -0.6% ✅ |
> | March | 368,200 | 300,000 | +68,200 | **+22.7%** ⚠ |
> | April | 310,500 | 310,000 | +500 | +0.2% |
> | May | 290,400 | 310,000 | -19,600 | -6.3% ✅ |
> | June | 334,800 | 310,000 | +24,800 | +8.0% |
>
> **YTD: +$84,400 over budget (+4.6%)**
>
> **March spike — probable causes:** fuel price index +8% in March, Q1 close outbound
> shipment peak, possible unplanned carrier substitution. Validate with logistics team.
>
> **Annual risk:** Projected year-end over-execution: +$108,800 (+2.9%).
> **Recommendation:** Renegotiate fuel surcharge clauses with top 3 carriers before Q3.

---

## Example 20 — ROI, budget execution, and capital scenarios

### Prompt

> For the eCommerce business line (Business Unit 253), during H1 2026:
> What was the ROI of expenditures on software and employee training, compared to H1 2025?
> What percentage of budgeted revenue was actually achieved, and what were the main
> causes of deviation? How much free capital is available to finance a new Digital Marketing
> line, and under which scenarios (conservative, base, optimistic) would a $800K investment
> be viable?

### What happens

1. `bpa-roi-capital` skill activates.
2. Calls `get_bpa_dataset_schema` to confirm `FactGeneralLedger`, `FactBudget`,
   `DimBusinessUnit`, `DimAccount`, and `DimFiscalCalendar`.
3. Runs DAX query for investment spend by category (Software, Training) for BU 253, H1 2026 vs H1 2025.
4. Runs DAX query for H1 revenue actuals vs budget for BU 253.
5. Calculates free capital: Revenue − OpEx + Reserves.
6. Builds three viability scenarios for the $800K Digital Marketing initiative.

### Result

> **BU 253 — eCommerce | H1 2026 Investment Review**
>
> **Investment ROI**
>
> | Category | H1 2026 | H1 2025 | Revenue (BU) | ROI 2026 | ROI 2025 |
> |---|---|---|---|---|---|
> | Software | $420,000 | $380,000 | $3,840,000 | 814% | 826% |
> | Training | $95,000 | $72,000 | $3,840,000 | 3,942% | 5,233% |
>
> **Budget Execution — Revenue**
>
> | Actual | Budget | Execution | Variance | Main cause |
> |---|---|---|---|---|
> | $3,840,000 | $4,100,000 | 93.7% | -$260,000 | eCommerce launch delayed 3 weeks in Q1 |
>
> **Free Capital: $1,500,000** (Revenue $3.84M − OpEx $2.98M + Reserves $0.64M)
>
> **Digital Marketing Launch — $800K — Scenario Analysis**
>
> | Scenario | Yr 1 Revenue | Net Return | ROI | Viable? |
> |---|---|---|---|---|
> | Conservative | $760,000 | -$40,000 | -5% | ❌ No |
> | Base | $1,100,000 | +$300,000 | 38% | ✅ Yes |
> | Optimistic | $1,380,000 | +$580,000 | 73% | ✅ Yes |
>
> Base and optimistic scenarios are viable. Consider a phased $400K launch
> to de-risk the conservative scenario.

---

## Example 21 — Cost center profitability ranking + over-budget alert

### Prompt

> Run the cost center profitability analysis for Q1 2026.
> Show revenue, direct costs, contribution margin, allocated overhead, and net margin
> for each cost center. Rank them from most to least profitable and flag any cost centers
> where actual spending exceeds budget by more than 5%.

### What happens

1. `bpa-cost-center-profitability` skill activates.
2. Calls `get_bpa_dataset_schema` to identify `FactGeneralLedger`, `FactBudget`,
   `DimCostCenter`, `DimDepartment`, and `DimAccount`.
3. Runs DAX for cost center P&L: revenue, direct costs, contribution margin.
4. Runs DAX for allocated overhead per cost center, computes net margin.
5. Runs DAX for budget vs actual at cost center level; flags variance > 5%.
6. Produces ranked profitability table and over-budget alert list.

### Result

> **Cost Center Profitability — Q1 2026 (ranked by net margin)**
>
> | Cost Center | Dept | Revenue | Direct Costs | Contrib % | Overhead | Net Margin % | Budget Var |
> |---|---|---|---|---|---|---|---|
> | CC-012 Digital | Marketing | $1,240,000 | $480,000 | 61.3% | $92,000 | 54.1% | +1.2% |
> | CC-008 Logistics | Operations | $980,000 | $640,000 | 34.7% | $78,000 | 26.7% | +3.8% |
> | CC-021 Facilities | G&A | $0 | $312,000 | n/a | $0 | n/a | **+11.4%** ⚠ |
> | CC-003 IT | G&A | $0 | $284,000 | n/a | $0 | n/a | **+8.9%** ⚠ |
>
> **Over-budget alerts (2):**
>
> | Cost Center | Budget | Actual | Variance |
> |---|---|---|---|
> | CC-021 Facilities | $280,000 | $312,000 | +$32,000 (+11.4%) |
> | CC-003 IT | $261,000 | $284,000 | +$23,000 (+8.9%) |
>
> Facilities: likely driven by Q1 maintenance contract renewals. IT: validate if linked
> to Q1 software licence renewals (should be capitalised if multi-year).
>
> "Show me the IT cost center breakdown by account category."

---

## Example 22 — Cash Conversion Cycle (CCC) breakdown + optimization levers

### Prompt

> Calculate our Cash Conversion Cycle for the last 4 quarters and compare it
> to the same period last year. Break it down into DSO, DIO, and DPO.
> Tell me which component is driving the change and what we can do to reduce the cycle by 10 days.

### What happens

1. `bpa-working-capital` skill activates.
2. Calls `get_bpa_dataset_schema` to confirm `FactCustomerInvoice`, `FactVendorInvoice`,
   `FactInventory`, and `FactGeneralLedger` (balance sheet).
3. Runs DAX to compute DSO per quarter (AR balance / revenue × days).
4. Runs DAX to compute DIO per quarter (avg inventory / COGS × days).
5. Runs DAX to compute DPO per quarter (AP balance / purchases × days).
6. Computes CCC = DSO + DIO − DPO for each quarter; compares to prior year.
7. Identifies the primary driver and quantifies cash release for a 10-day CCC reduction.

### Result

> **Cash Conversion Cycle — Rolling 4 quarters**
>
> | Quarter | DSO | DIO | DPO | CCC | vs PY |
> |---|---|---|---|---|---|
> | Q2 2025 | 34.2 | 28.1 | 31.4 | **30.9** | baseline |
> | Q3 2025 | 36.8 | 29.4 | 30.1 | **36.1** | +5.2 days |
> | Q4 2025 | 38.4 | 31.2 | 29.8 | **39.8** | +8.9 days |
> | Q1 2026 | 41.2 | 32.8 | 28.6 | **45.4** | **+14.5 days** ⚠ |
>
> **Primary driver: DSO** (+7 days YoY) and DIO (+4.7 days). DPO has shortened slightly
> (paying faster, which worsens CCC).
>
> **To recover 10 days:**
>
> | Lever | Impact | Cash Release |
> |---|---|---|
> | Reduce DSO by 5 days (stricter collection SLA) | −5 CCC days | +$2.1M freed |
> | Reduce DIO by 3 days (safety stock review) | −3 CCC days | +$0.9M freed |
> | Extend DPO by 2 days (renegotiate payment terms) | −2 CCC days | +$0.6M freed |
>
> "Show me the customers with the highest overdue balance driving the DSO increase."

---

## Example 23 — Revenue by customer — Pareto + concentration risk

### Prompt

> Analyse our revenue for H1 2026. Show me the top 20 customers by revenue,
> their share of total revenue, and the cumulative share. Flag any concentration risk.
> Also show me the year-over-year growth rate by customer and highlight
> any customer with a revenue decline > 10%.

### What happens

1. `bpa-revenue-analysis` skill activates.
2. Calls `get_bpa_dataset_schema` to confirm `FactCustomerInvoice`, `DimCustomer`,
   and `DimFiscalCalendar`.
3. Runs TOPN DAX to get top 20 customers by invoiced revenue for H1 2026.
4. Computes revenue share and cumulative share to identify the Pareto threshold.
5. Computes YoY growth per customer using SAMEPERIODLASTYEAR.
6. Flags customers with >20% revenue share (concentration risk) and <-10% YoY.

### Result

> **Top 20 Customers — H1 2026**
>
> | # | Customer | Revenue | Share | Cumul. | YoY Growth |
> |---|---|---|---|---|---|
> | 1 | Contoso Ltd | $1,840,000 | 18.2% | 18.2% | **⚠ >20% threshold** |
> | 2 | Fabrikam Inc | $1,120,000 | 11.1% | 29.3% | +4.2% |
> | 3 | Northwind Corp | $820,000 | 8.1% | 37.4% | -12.3% 🔴 |
> | 4 | Adventure Works | $710,000 | 7.0% | 44.4% | +18.7% |
> | ... | ... | ... | ... | ... | ... |
> | Top 20 total | | $8,240,000 | 81.4% | | |
>
> **Concentration flags:**
> - Contoso Ltd at 18.2% is approaching the 20% concentration risk threshold.
>   Single-customer dependency risk is moderate.
> - Top 5 customers = 51.5% of revenue. Revenue diversification recommended.
>
> **Revenue decline alerts:**
> - Northwind Corp: -12.3% YoY ($820K vs $934K H1 2025). Investigate relationship status.
>
> "Show me the monthly revenue trend for Northwind Corp over the last 12 months."

---

## Example 24 — Fixed asset NBV + fully depreciated assets + capex execution

### Prompt

> Show the fixed asset register as of end of Q1 2026: net book value by asset group,
> accumulated depreciation, and average remaining useful life. List all assets that are
> fully depreciated but still in service. Then compare our capex actual vs budget
> for YTD 2026 and give me the execution rate.

### What happens

1. `bpa-fixed-assets-capex` skill activates.
2. Calls `get_bpa_dataset_schema` to confirm `FactFixedAsset`, `DimAsset`,
   `DimAssetGroup`, `FactGeneralLedger`, and `FactBudget`.
3. Runs DAX for NBV summary by asset group (acquisition cost, accumulated depreciation, NBV).
4. Runs FILTER DAX to identify fully depreciated assets (NBV ≤ 0) still in service.
5. Runs DAX for capex GL entries (account type = Capital) vs capex budget YTD.

### Result

> **Fixed Asset Register — Q1 2026**
>
> | Asset Group | Gross Value | Accum. Depr. | NBV | Count | Avg Remaining Life |
> |---|---|---|---|---|---|
> | Buildings | $12,400,000 | $3,840,000 | $8,560,000 | 8 | 22.4 yrs |
> | Machinery | $6,820,000 | $4,210,000 | $2,610,000 | 34 | 3.8 yrs |
> | IT Equipment | $2,140,000 | $1,980,000 | $160,000 | 142 | 0.4 yrs |
> | Vehicles | $1,280,000 | $890,000 | $390,000 | 18 | 2.1 yrs |
> | **Total** | **$22,640,000** | **$10,920,000** | **$11,720,000** | **202** | |
>
> **Fully depreciated assets still in service (12 items, $1.84M original cost):**
>
> | Asset | Group | Department | Gross Value | Years in Service |
> |---|---|---|---|---|
> | SERVER-DC-01 | IT Equipment | IT | $84,000 | 7 yrs |
> | SERVER-DC-02 | IT Equipment | IT | $84,000 | 7 yrs |
> | LATHE-MK-07 | Machinery | Production | $142,000 | 12 yrs |
> | ... (9 more) | | | $1,534,000 | |
>
> ⚠ 12 assets fully depreciated. Replacement budget review recommended for Machinery items.
>
> **Capex Execution — YTD Q1 2026**
>
> | Category | Budget | Actual | Execution | Variance |
> |---|---|---|---|---|
> | Capital | $2,400,000 | $1,120,000 | 46.7% | -$1,280,000 |
>
> Capex execution at 46.7% after 1 quarter is below the 25% prorated target.
> Validate if planned server refresh (Q2) and machinery replacements (Q3) are on track.
>
> "Show me the planned capex projects and their expected spend dates."
