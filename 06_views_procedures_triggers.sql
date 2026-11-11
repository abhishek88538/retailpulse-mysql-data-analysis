-- ============================================================================
-- Project: RetailPulse — E-Commerce Sales & Customer RFM Data Analysis
-- File:    06_views_procedures_triggers.sql
-- Target:  MySQL 8.0+
-- Purpose: Production-grade analytical Views, Stored Function, Stored
--          Procedures, and Inventory Audit Trigger for BI tools & reporting.
-- Note:    Run AFTER 01_schema.sql and 02_seed_data.sql.
-- ============================================================================

USE retailpulse_dw;

-- ----------------------------------------------------------------------------
-- 1. Stored Function: Safe Profit Margin % Calculator
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_profit_margin_pct;

DELIMITER //
CREATE FUNCTION fn_profit_margin_pct(
    p_revenue DECIMAL(12,2),
    p_cost    DECIMAL(12,2)
)
RETURNS DECIMAL(6,2)
DETERMINISTIC
NO SQL
BEGIN
    IF p_revenue IS NULL OR p_revenue <= 0 THEN
        RETURN 0.00;
    END IF;
    RETURN ROUND(100.0 * (p_revenue - COALESCE(p_cost, 0.00)) / p_revenue, 2);
END //
DELIMITER ;


-- ----------------------------------------------------------------------------
-- 2. Analytical View: vw_order_financials
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_order_financials AS
WITH item_agg AS (
    SELECT
        oi.order_id,
        SUM(oi.quantity) AS total_units,
        SUM(oi.quantity * oi.unit_price) AS gross_merchandise_value,
        SUM(oi.line_discount) AS line_discounts,
        SUM(oi.quantity * oi.unit_cost) AS total_cogs
    FROM order_items oi
    GROUP BY oi.order_id
),
ret_agg AS (
    SELECT
        r.order_id,
        COUNT(*) AS returned_items_count,
        SUM(r.refund_amount) AS total_refunds
    FROM returns r
    GROUP BY r.order_id
)
SELECT
    o.order_id,
    o.customer_id,
    c.full_name AS customer_name,
    reg.region_name,
    camp.campaign_name,
    DATE(o.order_date) AS order_day,
    DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    o.order_status,
    o.payment_method,
    ia.total_units,
    ROUND(ia.gross_merchandise_value, 2) AS gross_merchandise_value,
    ROUND(ia.line_discounts + o.order_discount, 2) AS total_discount,
    ROUND(COALESCE(ra.total_refunds, 0.00), 2) AS total_refunds,
    ROUND(
        (ia.gross_merchandise_value - ia.line_discounts - o.order_discount) - COALESCE(ra.total_refunds, 0.00),
        2
    ) AS realized_net_revenue,
    ROUND(ia.total_cogs, 2) AS total_cogs,
    ROUND(
        ((ia.gross_merchandise_value - ia.line_discounts - o.order_discount) - COALESCE(ra.total_refunds, 0.00)) - ia.total_cogs,
        2
    ) AS gross_profit,
    fn_profit_margin_pct(
        (ia.gross_merchandise_value - ia.line_discounts - o.order_discount) - COALESCE(ra.total_refunds, 0.00),
        ia.total_cogs
    ) AS gross_margin_pct,
    o.promised_days,
    CASE
        WHEN o.delivered_date IS NOT NULL THEN DATEDIFF(o.delivered_date, o.order_date)
        ELSE NULL
    END AS actual_delivery_days,
    CASE
        WHEN o.order_status = 'Cancelled' THEN 'Cancelled'
        WHEN o.delivered_date IS NULL THEN 'In Transit / Processing'
        WHEN DATEDIFF(o.delivered_date, o.order_date) <= o.promised_days THEN 'On Time'
        ELSE 'Late'
    END AS delivery_sla_status
FROM orders o
JOIN customers c     ON o.customer_id = c.customer_id
JOIN regions reg     ON o.region_id = reg.region_id
JOIN item_agg ia     ON o.order_id = ia.order_id
LEFT JOIN campaigns camp ON o.campaign_id = camp.campaign_id
LEFT JOIN ret_agg ra ON o.order_id = ra.order_id;


-- ----------------------------------------------------------------------------
-- 3. Analytical View: vw_customer_360 (Complete Profile + RFM Segmentation)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_360 AS
WITH ref_date AS (
    SELECT COALESCE(MAX(order_day), CURDATE()) AS as_of_date
    FROM vw_order_financials
    WHERE order_status <> 'Cancelled'
),
cust_metrics AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.email,
        c.signup_date,
        c.acquisition_channel,
        c.loyalty_tier,
        reg.region_name,
        c.city,
        COUNT(DISTINCT CASE WHEN v.order_status <> 'Cancelled' THEN v.order_id END) AS completed_orders,
        COUNT(DISTINCT CASE WHEN v.order_status = 'Cancelled' THEN v.order_id END)  AS cancelled_orders,
        MIN(CASE WHEN v.order_status <> 'Cancelled' THEN v.order_day END)           AS first_order_date,
        MAX(CASE WHEN v.order_status <> 'Cancelled' THEN v.order_day END)           AS last_order_date,
        DATEDIFF(
            rd.as_of_date,
            MAX(CASE WHEN v.order_status <> 'Cancelled' THEN v.order_day END)
        ) AS recency_days,
        ROUND(COALESCE(SUM(CASE WHEN v.order_status <> 'Cancelled' THEN v.realized_net_revenue ELSE 0 END), 0), 2) AS lifetime_net_revenue,
        ROUND(COALESCE(SUM(CASE WHEN v.order_status <> 'Cancelled' THEN v.gross_profit ELSE 0 END), 0), 2)         AS lifetime_gross_profit,
        ROUND(COALESCE(SUM(CASE WHEN v.order_status <> 'Cancelled' THEN v.total_refunds ELSE 0 END), 0), 2)        AS total_refunds
    FROM customers c
    CROSS JOIN ref_date rd
    JOIN regions reg ON c.region_id = reg.region_id
    LEFT JOIN vw_order_financials v ON c.customer_id = v.customer_id
    GROUP BY c.customer_id, c.full_name, c.email, c.signup_date, c.acquisition_channel,
             c.loyalty_tier, reg.region_name, c.city, rd.as_of_date
),
scored AS (
    SELECT
        *,
        CASE
            WHEN completed_orders = 0 THEN 1
            ELSE NTILE(5) OVER (PARTITION BY (completed_orders > 0) ORDER BY COALESCE(recency_days, 9999) DESC)
        END AS r_score,
        CASE
            WHEN completed_orders = 0 THEN 1
            ELSE NTILE(5) OVER (PARTITION BY (completed_orders > 0) ORDER BY completed_orders ASC)
        END AS f_score,
        CASE
            WHEN completed_orders = 0 THEN 1
            ELSE NTILE(5) OVER (PARTITION BY (completed_orders > 0) ORDER BY lifetime_net_revenue ASC)
        END AS m_score
    FROM cust_metrics
)
SELECT
    customer_id,
    full_name,
    email,
    signup_date,
    acquisition_channel,
    loyalty_tier,
    region_name,
    city,
    completed_orders,
    cancelled_orders,
    first_order_date,
    last_order_date,
    recency_days,
    lifetime_net_revenue,
    lifetime_gross_profit,
    total_refunds,
    ROUND(lifetime_net_revenue / NULLIF(completed_orders, 0), 2) AS avg_order_value,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_code,
    CASE
        WHEN completed_orders = 0                         THEN 'No Completed Purchases'
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2                  THEN 'Recent / Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
        WHEN r_score = 2  AND f_score <= 2                  THEN 'About to Sleep'
        WHEN r_score = 1  AND f_score <= 2                  THEN 'Hibernating / Lost'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM scored;


-- ----------------------------------------------------------------------------
-- 4. Analytical View: vw_product_performance
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    cat.category_name,
    sup.supplier_name,
    p.unit_cost,
    p.unit_price,
    p.stock_qty,
    p.reorder_level,
    COALESCE(SUM(CASE WHEN o.order_status <> 'Cancelled' THEN oi.quantity ELSE 0 END), 0) AS total_units_sold,
    ROUND(COALESCE(SUM(CASE WHEN o.order_status <> 'Cancelled' THEN (oi.quantity * oi.unit_price - oi.line_discount) ELSE 0 END), 0), 2) AS gross_revenue,
    ROUND(COALESCE(SUM(CASE WHEN o.order_status <> 'Cancelled' THEN r.refund_amount ELSE 0 END), 0), 2) AS total_refunds,
    ROUND(
        COALESCE(SUM(CASE WHEN o.order_status <> 'Cancelled' THEN (oi.quantity * oi.unit_price - oi.line_discount) - COALESCE(r.refund_amount, 0) ELSE 0 END), 0),
        2
    ) AS net_revenue,
    ROUND(COALESCE(SUM(CASE WHEN o.order_status <> 'Cancelled' THEN oi.quantity * oi.unit_cost ELSE 0 END), 0), 2) AS total_cogs,
    COUNT(r.return_id) AS returned_line_count,
    ROUND(
        100.0 * COUNT(r.return_id) / NULLIF(COUNT(CASE WHEN o.order_status <> 'Cancelled' THEN oi.order_item_id END), 0),
        2
    ) AS item_return_rate_pct
FROM products p
JOIN categories cat  ON p.category_id = cat.category_id
JOIN suppliers sup   ON p.supplier_id = sup.supplier_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o       ON oi.order_id = o.order_id
LEFT JOIN returns r      ON oi.order_item_id = r.order_item_id
GROUP BY p.product_id, p.sku, p.product_name, cat.category_name, sup.supplier_name,
         p.unit_cost, p.unit_price, p.stock_qty, p.reorder_level;


-- ----------------------------------------------------------------------------
-- 5. Stored Procedure: Executive KPIs for Custom Date Range
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_get_executive_kpis;

DELIMITER //
CREATE PROCEDURE sp_get_executive_kpis(
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    SELECT
        p_start_date AS period_start,
        p_end_date   AS period_end,
        COUNT(*) AS total_orders,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(CASE WHEN order_status <> 'Cancelled' THEN 1 ELSE 0 END) AS active_or_delivered_orders,
        SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)  AS cancelled_orders,
        ROUND(SUM(CASE WHEN order_status <> 'Cancelled' THEN gross_merchandise_value ELSE 0 END), 2) AS gmv,
        ROUND(SUM(CASE WHEN order_status <> 'Cancelled' THEN total_refunds ELSE 0 END), 2)           AS refunds,
        ROUND(SUM(CASE WHEN order_status <> 'Cancelled' THEN realized_net_revenue ELSE 0 END), 2)    AS realized_net_revenue,
        ROUND(SUM(CASE WHEN order_status <> 'Cancelled' THEN gross_profit ELSE 0 END), 2)            AS gross_profit,
        fn_profit_margin_pct(
            SUM(CASE WHEN order_status <> 'Cancelled' THEN realized_net_revenue ELSE 0 END),
            SUM(CASE WHEN order_status <> 'Cancelled' THEN total_cogs ELSE 0 END)
        ) AS gross_margin_pct,
        ROUND(AVG(CASE WHEN order_status <> 'Cancelled' THEN realized_net_revenue END), 2)           AS avg_realized_order_value
    FROM vw_order_financials
    WHERE order_day BETWEEN p_start_date AND p_end_date;
END //
DELIMITER ;


-- ----------------------------------------------------------------------------
-- 6. Stored Procedure: Category Drill-Down (Optional Year Filter)
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_get_category_drilldown;

DELIMITER //
CREATE PROCEDURE sp_get_category_drilldown(
    IN p_category_name VARCHAR(80),
    IN p_year          INT
)
BEGIN
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        p.sku,
        p.product_name,
        SUM(oi.quantity) AS units_sold,
        ROUND(SUM(oi.quantity * oi.unit_price - oi.line_discount - COALESCE(r.refund_amount, 0)), 2) AS net_revenue,
        ROUND(SUM((oi.quantity * oi.unit_price - oi.line_discount - COALESCE(r.refund_amount, 0)) - (oi.quantity * oi.unit_cost)), 2) AS gross_profit
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    JOIN categories c   ON p.category_id = c.category_id
    LEFT JOIN returns r ON oi.order_item_id = r.order_item_id
    WHERE o.order_status <> 'Cancelled'
      AND c.category_name = p_category_name
      AND (p_year IS NULL OR YEAR(o.order_date) = p_year)
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), p.sku, p.product_name
    ORDER BY order_month, net_revenue DESC;
END //
DELIMITER ;


-- ----------------------------------------------------------------------------
-- 7. Stored Procedure: Filter Customers by RFM Segment
-- ----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_get_customers_by_rfm_segment;

DELIMITER //
CREATE PROCEDURE sp_get_customers_by_rfm_segment(
    IN p_segment_name VARCHAR(50)
)
BEGIN
    SELECT
        customer_id,
        full_name,
        email,
        region_name,
        loyalty_tier,
        completed_orders,
        last_order_date,
        recency_days,
        lifetime_net_revenue,
        rfm_code,
        rfm_segment
    FROM vw_customer_360
    WHERE rfm_segment = p_segment_name
    ORDER BY lifetime_net_revenue DESC;
END //
DELIMITER ;


-- ----------------------------------------------------------------------------
-- 8. Trigger: Automatic Stock Decrement & Audit Log on New Order Items
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_after_order_item_insert;

DELIMITER //
CREATE TRIGGER trg_after_order_item_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT order_status INTO v_status
    FROM orders
    WHERE order_id = NEW.order_id;

    IF v_status <> 'Cancelled' THEN
        UPDATE products
        SET stock_qty = GREATEST(0, CAST(stock_qty AS SIGNED) - CAST(NEW.quantity AS SIGNED))
        WHERE product_id = NEW.product_id;

        INSERT INTO inventory_audit_log (product_id, order_id, qty_change, reason)
        VALUES (NEW.product_id, NEW.order_id, -CAST(NEW.quantity AS SIGNED), 'Order Item Fulfilled');
    END IF;
END //
DELIMITER ;


-- ============================================================================
-- Example Usage (Uncomment to test after executing the script):
-- ============================================================================
-- SELECT * FROM vw_order_financials LIMIT 10;
-- SELECT * FROM vw_customer_360 ORDER BY lifetime_net_revenue DESC LIMIT 10;
-- SELECT * FROM vw_product_performance ORDER BY net_revenue DESC;
-- CALL sp_get_executive_kpis('2025-01-01', '2025-12-31');
-- CALL sp_get_category_drilldown('Electronics', 2026);
-- CALL sp_get_customers_by_rfm_segment('Champions');

