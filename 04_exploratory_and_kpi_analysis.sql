-- ============================================================================
-- Project: RetailPulse — E-Commerce Sales & Customer RFM Data Analysis
-- File:    04_exploratory_and_kpi_analysis.sql
-- Target:  MySQL 8.0+
-- Purpose: Core business intelligence & exploratory KPI queries (Q1–Q12).
--          Every query avoids join fan-out by pre-aggregating line-level tables.
-- ============================================================================

USE retailpulse_dw;

-- ============================================================================
-- Q1. Executive Summary KPI Scorecard (Overall Business Health)
-- ============================================================================
WITH order_line_totals AS (
    SELECT
        oi.order_id,
        SUM(oi.quantity) AS total_units,
        SUM(oi.quantity * oi.unit_price) AS gross_item_revenue,
        SUM(oi.line_discount) AS total_line_discount,
        SUM(oi.quantity * oi.unit_cost) AS total_cogs
    FROM order_items oi
    GROUP BY oi.order_id
),
order_return_totals AS (
    SELECT
        r.order_id,
        SUM(r.refund_amount) AS total_refund_amount
    FROM returns r
    GROUP BY r.order_id
),
order_financials AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_status,
        olt.total_units,
        olt.gross_item_revenue,
        (olt.gross_item_revenue - olt.total_line_discount - o.order_discount) AS net_sales_before_refunds,
        COALESCE(ort.total_refund_amount, 0.00) AS refund_amount,
        (olt.gross_item_revenue - olt.total_line_discount - o.order_discount - COALESCE(ort.total_refund_amount, 0.00)) AS realized_net_revenue,
        olt.total_cogs
    FROM orders o
    JOIN order_line_totals olt       ON o.order_id = olt.order_id
    LEFT JOIN order_return_totals ort ON o.order_id = ort.order_id
)
SELECT
    COUNT(*)                                                                  AS total_orders,
    COUNT(DISTINCT customer_id)                                               AS active_customers,
    SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)               AS delivered_orders,
    SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)               AS cancelled_orders,
    SUM(CASE WHEN order_status = 'Returned'  THEN 1 ELSE 0 END)               AS fully_returned_orders,
    ROUND(100.0 * SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancellation_rate_pct,
    ROUND(SUM(CASE WHEN order_status <> 'Cancelled' THEN gross_item_revenue ELSE 0 END), 2) AS gross_merchandise_value,
    ROUND(SUM(CASE WHEN order_status <> 'Cancelled' THEN refund_amount ELSE 0 END), 2)      AS total_refunds,
    ROUND(SUM(CASE WHEN order_status <> 'Cancelled' THEN realized_net_revenue ELSE 0 END), 2) AS realized_net_revenue,
    ROUND(SUM(CASE WHEN order_status <> 'Cancelled' THEN total_cogs ELSE 0 END), 2)         AS total_cogs,
    ROUND(
        SUM(CASE WHEN order_status <> 'Cancelled' THEN realized_net_revenue - total_cogs ELSE 0 END),
        2
    ) AS gross_profit,
    ROUND(
        100.0 * SUM(CASE WHEN order_status <> 'Cancelled' THEN realized_net_revenue - total_cogs ELSE 0 END)
        / NULLIF(SUM(CASE WHEN order_status <> 'Cancelled' THEN realized_net_revenue ELSE 0 END), 0),
        2
    ) AS gross_margin_pct,
    ROUND(
        AVG(CASE WHEN order_status <> 'Cancelled' THEN net_sales_before_refunds END),
        2
    ) AS avg_order_value_aov
FROM order_financials;


-- ============================================================================
-- Q2. Monthly Revenue Trend, Profit & Month-over-Month (MoM) Growth %
-- ============================================================================
WITH order_net AS (
    SELECT
        o.order_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_revenue,
        SUM(oi.quantity * oi.unit_cost) AS cogs
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY o.order_id, DATE_FORMAT(o.order_date, '%Y-%m'), o.order_discount
),
monthly_agg AS (
    SELECT
        order_month,
        COUNT(*) AS order_count,
        ROUND(SUM(net_revenue), 2) AS monthly_revenue,
        ROUND(SUM(net_revenue - cogs), 2) AS monthly_profit
    FROM order_net
    GROUP BY order_month
)
SELECT
    order_month,
    order_count,
    monthly_revenue,
    monthly_profit,
    LAG(monthly_revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
    ROUND(
        100.0 * (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY order_month))
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY order_month), 0),
        2
    ) AS mom_growth_pct
FROM monthly_agg
ORDER BY order_month;


-- ============================================================================
-- Q3. Year-over-Year (YoY) Quarterly Revenue & Margin Comparison
-- ============================================================================
WITH order_net AS (
    SELECT
        o.order_id,
        YEAR(o.order_date) AS order_year,
        QUARTER(o.order_date) AS order_quarter,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_revenue,
        SUM(oi.quantity * oi.unit_cost) AS cogs
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY o.order_id, YEAR(o.order_date), QUARTER(o.order_date), o.order_discount
),
quarterly AS (
    SELECT
        order_year,
        order_quarter,
        COUNT(*) AS total_orders,
        ROUND(SUM(net_revenue), 2) AS quarterly_revenue,
        ROUND(SUM(net_revenue - cogs), 2) AS quarterly_profit
    FROM order_net
    GROUP BY order_year, order_quarter
)
SELECT
    order_year,
    CONCAT('Q', order_quarter) AS quarter_label,
    total_orders,
    quarterly_revenue,
    quarterly_profit,
    ROUND(100.0 * quarterly_profit / NULLIF(quarterly_revenue, 0), 2) AS margin_pct,
    LAG(quarterly_revenue) OVER (PARTITION BY order_quarter ORDER BY order_year) AS prior_year_q_revenue,
    ROUND(
        100.0 * (quarterly_revenue - LAG(quarterly_revenue) OVER (PARTITION BY order_quarter ORDER BY order_year))
        / NULLIF(LAG(quarterly_revenue) OVER (PARTITION BY order_quarter ORDER BY order_year), 0),
        2
    ) AS yoy_revenue_growth_pct
FROM quarterly
ORDER BY order_year, order_quarter;


-- ============================================================================
-- Q4. Category Performance: Revenue, Profit, Target Margin Variance & Share %
-- ============================================================================
WITH cat_sales AS (
    SELECT
        cat.category_id,
        cat.category_name,
        cat.target_margin_pct,
        SUM(oi.quantity) AS units_sold,
        COUNT(DISTINCT o.order_id) AS orders_with_category,
        ROUND(SUM(oi.quantity * oi.unit_price - oi.line_discount), 2) AS gross_revenue,
        ROUND(SUM(COALESCE(r.refund_amount, 0)), 2) AS refunds,
        ROUND(SUM(oi.quantity * oi.unit_cost), 2) AS cogs
    FROM categories cat
    JOIN products p     ON cat.category_id = p.category_id
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o       ON oi.order_id = o.order_id
    LEFT JOIN returns r ON oi.order_item_id = r.order_item_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY cat.category_id, cat.category_name, cat.target_margin_pct
)
SELECT
    category_name,
    units_sold,
    orders_with_category,
    gross_revenue,
    refunds,
    ROUND(gross_revenue - refunds, 2) AS net_revenue,
    ROUND((gross_revenue - refunds) - cogs, 2) AS gross_profit,
    ROUND(100.0 * ((gross_revenue - refunds) - cogs) / NULLIF(gross_revenue - refunds, 0), 2) AS actual_margin_pct,
    target_margin_pct,
    ROUND(
        (100.0 * ((gross_revenue - refunds) - cogs) / NULLIF(gross_revenue - refunds, 0)) - target_margin_pct,
        2
    ) AS margin_vs_target_pts,
    ROUND(100.0 * (gross_revenue - refunds) / NULLIF(SUM(gross_revenue - refunds) OVER (), 0), 2) AS revenue_share_pct
FROM cat_sales
ORDER BY net_revenue DESC;


-- ============================================================================
-- Q5. Regional Revenue & Delivery SLA Performance
-- ============================================================================
WITH order_rev AS (
    SELECT
        o.order_id,
        o.region_id,
        o.order_status,
        o.order_date,
        o.shipped_date,
        o.delivered_date,
        o.promised_days,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.region_id, o.order_status, o.order_date,
             o.shipped_date, o.delivered_date, o.promised_days, o.order_discount
)
SELECT
    reg.region_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN o.order_status <> 'Cancelled' THEN 1 ELSE 0 END) AS fulfilled_or_active_orders,
    ROUND(SUM(CASE WHEN o.order_status <> 'Cancelled' THEN o.net_revenue ELSE 0 END), 2) AS net_revenue,
    ROUND(AVG(CASE WHEN o.shipped_date IS NOT NULL THEN TIMESTAMPDIFF(HOUR, o.order_date, o.shipped_date) / 24.0 END), 2) AS avg_days_to_ship,
    ROUND(AVG(CASE WHEN o.delivered_date IS NOT NULL THEN TIMESTAMPDIFF(HOUR, o.order_date, o.delivered_date) / 24.0 END), 2) AS avg_days_to_deliver,
    SUM(CASE WHEN o.delivered_date IS NOT NULL AND DATEDIFF(o.delivered_date, o.order_date) > o.promised_days THEN 1 ELSE 0 END) AS late_deliveries,
    ROUND(
        100.0 * SUM(CASE WHEN o.delivered_date IS NOT NULL AND DATEDIFF(o.delivered_date, o.order_date) > o.promised_days THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN o.delivered_date IS NOT NULL THEN 1 ELSE 0 END), 0),
        2
    ) AS late_delivery_pct
FROM regions reg
JOIN order_rev o ON reg.region_id = o.region_id
GROUP BY reg.region_id, reg.region_name
ORDER BY net_revenue DESC;


-- ============================================================================
-- Q6. Payment Method Mix, Average Order Value & Cancellation / Return Rates
-- ============================================================================
WITH order_totals AS (
    SELECT
        o.order_id,
        o.payment_method,
        o.order_status,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.payment_method, o.order_status, o.order_discount
)
SELECT
    payment_method,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS order_share_pct,
    ROUND(SUM(CASE WHEN order_status <> 'Cancelled' THEN net_value ELSE 0 END), 2) AS net_revenue,
    ROUND(AVG(CASE WHEN order_status <> 'Cancelled' THEN net_value END), 2) AS avg_order_value,
    ROUND(100.0 * SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancellation_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN order_status = 'Returned'  THEN 1 ELSE 0 END) / COUNT(*), 2) AS full_return_rate_pct
FROM order_totals
GROUP BY payment_method
ORDER BY net_revenue DESC;


-- ============================================================================
-- Q7. Top 10 Products by Revenue vs. Profit Margin Ranking
-- ============================================================================
WITH prod_perf AS (
    SELECT
        p.product_id,
        p.sku,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) AS total_units_sold,
        ROUND(SUM(oi.quantity * oi.unit_price - oi.line_discount), 2) AS gross_revenue,
        ROUND(SUM(COALESCE(r.refund_amount, 0)), 2) AS refund_total,
        ROUND(SUM(oi.quantity * oi.unit_cost), 2) AS total_cogs
    FROM products p
    JOIN categories c   ON p.category_id = c.category_id
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o       ON oi.order_id = o.order_id
    LEFT JOIN returns r ON oi.order_item_id = r.order_item_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY p.product_id, p.sku, p.product_name, c.category_name
)
SELECT
    sku,
    product_name,
    category_name,
    total_units_sold,
    ROUND(gross_revenue - refund_total, 2) AS net_revenue,
    ROUND((gross_revenue - refund_total) - total_cogs, 2) AS gross_profit,
    ROUND(100.0 * ((gross_revenue - refund_total) - total_cogs) / NULLIF(gross_revenue - refund_total, 0), 2) AS profit_margin_pct,
    DENSE_RANK() OVER (ORDER BY (gross_revenue - refund_total) DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY ((gross_revenue - refund_total) - total_cogs) DESC) AS profit_rank
FROM prod_perf
ORDER BY net_revenue DESC
LIMIT 10;


-- ============================================================================
-- Q8. Supplier Scorecard: Revenue, Lead Time, Reliability & Product Return Rate
-- ============================================================================
SELECT
    s.supplier_name,
    s.country,
    s.lead_time_days,
    s.reliability_score,
    COUNT(DISTINCT p.product_id) AS active_skus,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price - oi.line_discount), 2) AS gross_sales,
    COUNT(r.return_id) AS returned_line_items,
    ROUND(100.0 * COUNT(r.return_id) / NULLIF(COUNT(oi.order_item_id), 0), 2) AS item_return_rate_pct
FROM suppliers s
JOIN products p     ON s.supplier_id = p.supplier_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o       ON oi.order_id = o.order_id
LEFT JOIN returns r ON oi.order_item_id = r.order_item_id
WHERE o.order_status <> 'Cancelled'
GROUP BY s.supplier_id, s.supplier_name, s.country, s.lead_time_days, s.reliability_score
ORDER BY gross_sales DESC;


-- ============================================================================
-- Q9. Discount Impact Analysis: Discounted vs. Full-Price Orders
-- ============================================================================
WITH order_economics AS (
    SELECT
        o.order_id,
        CASE
            WHEN o.order_discount > 0 OR SUM(oi.line_discount) > 0 THEN 'Discounted'
            ELSE 'Full Price'
        END AS pricing_type,
        SUM(oi.quantity * oi.unit_price) AS gross_amount,
        SUM(oi.line_discount) + o.order_discount AS total_discount,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_revenue,
        SUM(oi.quantity * oi.unit_cost) AS cogs
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY o.order_id, o.order_discount
)
SELECT
    pricing_type,
    COUNT(*) AS order_count,
    ROUND(AVG(gross_amount), 2) AS avg_gross_basket,
    ROUND(AVG(total_discount), 2) AS avg_discount_given,
    ROUND(AVG(net_revenue), 2) AS avg_net_order_value,
    ROUND(SUM(net_revenue), 2) AS total_net_revenue,
    ROUND(SUM(net_revenue - cogs), 2) AS total_gross_profit,
    ROUND(100.0 * SUM(net_revenue - cogs) / NULLIF(SUM(net_revenue), 0), 2) AS gross_margin_pct
FROM order_economics
GROUP BY pricing_type;


-- ============================================================================
-- Q10. Marketing Campaign ROI & ROAS (Return on Ad Spend)
-- ============================================================================
WITH order_fin AS (
    SELECT
        o.order_id,
        o.campaign_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_sales,
        SUM(oi.quantity * oi.unit_cost) AS cogs
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
      AND o.campaign_id IS NOT NULL
    GROUP BY o.order_id, o.campaign_id, o.customer_id, o.order_discount
),
ret_fin AS (
    SELECT
        order_id,
        SUM(refund_amount) AS refunds
    FROM returns
    GROUP BY order_id
)
SELECT
    c.campaign_name,
    c.channel,
    c.promo_code,
    c.budget AS campaign_spend,
    COUNT(DISTINCT ofin.order_id) AS attributed_orders,
    COUNT(DISTINCT ofin.customer_id) AS unique_buyers,
    ROUND(SUM(ofin.net_sales - COALESCE(rf.refunds, 0)), 2) AS attributed_net_revenue,
    ROUND(SUM((ofin.net_sales - COALESCE(rf.refunds, 0)) - ofin.cogs), 2) AS gross_profit_generated,
    ROUND(SUM(ofin.net_sales - COALESCE(rf.refunds, 0)) / NULLIF(c.budget, 0), 2) AS roas_x,
    ROUND(
        100.0 * (SUM((ofin.net_sales - COALESCE(rf.refunds, 0)) - ofin.cogs) - c.budget) / NULLIF(c.budget, 0),
        2
    ) AS net_marketing_roi_pct
FROM campaigns c
LEFT JOIN order_fin ofin ON c.campaign_id = ofin.campaign_id
LEFT JOIN ret_fin rf     ON ofin.order_id = rf.order_id
GROUP BY c.campaign_id, c.campaign_name, c.channel, c.promo_code, c.budget
ORDER BY roas_x DESC;


-- ============================================================================
-- Q11. Return Reason Breakdown & Financial Leakage Analysis
-- ============================================================================
SELECT
    r.return_reason,
    COUNT(*) AS return_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_of_returns_pct,
    ROUND(SUM(r.refund_amount), 2) AS total_refund_leakage,
    SUM(CASE WHEN r.restocked = TRUE  THEN 1 ELSE 0 END) AS restocked_items,
    SUM(CASE WHEN r.restocked = FALSE THEN 1 ELSE 0 END) AS damaged_writeoffs
FROM returns r
GROUP BY r.return_reason
ORDER BY total_refund_leakage DESC;


-- ============================================================================
-- Q12. Day-of-Week Ordering & Revenue Patterns
-- ============================================================================
WITH order_net AS (
    SELECT
        o.order_id,
        DAYOFWEEK(o.order_date) AS dow_num,
        DAYNAME(o.order_date) AS day_of_week,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY o.order_id, DAYOFWEEK(o.order_date), DAYNAME(o.order_date), o.order_discount
)
SELECT
    day_of_week,
    COUNT(*) AS total_orders,
    ROUND(SUM(net_revenue), 2) AS total_revenue,
    ROUND(AVG(net_revenue), 2) AS avg_order_value
FROM order_net
GROUP BY dow_num, day_of_week
ORDER BY dow_num;

