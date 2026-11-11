-- ============================================================================
-- Project: RetailPulse — E-Commerce Sales & Customer RFM Data Analysis
-- File:    03_data_cleaning_and_validation.sql
-- Target:  MySQL 8.0+
-- Purpose: Pre-analysis data quality, integrity, and business-rule audit
--          before running downstream KPI and RFM analytics.
-- ============================================================================

USE retailpulse_dw;

-- ----------------------------------------------------------------------------
-- 1. Table Row Count Inventory
-- ----------------------------------------------------------------------------
SELECT 'regions'             AS table_name, COUNT(*) AS row_count FROM regions
UNION ALL
SELECT 'customers',                         COUNT(*) FROM customers
UNION ALL
SELECT 'categories',                        COUNT(*) FROM categories
UNION ALL
SELECT 'suppliers',                         COUNT(*) FROM suppliers
UNION ALL
SELECT 'products',                          COUNT(*) FROM products
UNION ALL
SELECT 'campaigns',                         COUNT(*) FROM campaigns
UNION ALL
SELECT 'orders',                            COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',                       COUNT(*) FROM order_items
UNION ALL
SELECT 'returns',                           COUNT(*) FROM returns;

-- ----------------------------------------------------------------------------
-- 2. Null & Missing Critical Field Audit
-- ----------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN full_name IS NULL OR TRIM(full_name) = '' THEN 1 ELSE 0 END) AS missing_customer_names,
    SUM(CASE WHEN email IS NULL OR email NOT LIKE '%@%.%' THEN 1 ELSE 0 END)   AS invalid_emails,
    SUM(CASE WHEN birth_date IS NULL THEN 1 ELSE 0 END)                        AS missing_birth_dates,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END)                       AS missing_signup_dates
FROM customers;

SELECT
    SUM(CASE WHEN order_status = 'Delivered' AND delivered_date IS NULL THEN 1 ELSE 0 END) AS delivered_without_date,
    SUM(CASE WHEN order_status = 'Cancelled' AND shipped_date IS NOT NULL THEN 1 ELSE 0 END) AS cancelled_but_shipped,
    SUM(CASE WHEN order_discount < 0 OR shipping_fee < 0 THEN 1 ELSE 0 END)                AS negative_order_amounts
FROM orders;

-- ----------------------------------------------------------------------------
-- 3. Duplicate Detection Checks
-- ----------------------------------------------------------------------------
SELECT email, COUNT(*) AS duplicate_count
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;

SELECT sku, COUNT(*) AS duplicate_count
FROM products
GROUP BY sku
HAVING COUNT(*) > 1;

-- Check if any single order contains the same product on two separate lines
SELECT order_id, product_id, COUNT(*) AS duplicate_lines
FROM order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- ----------------------------------------------------------------------------
-- 4. Chronological & Business-Rule Sanity Checks
-- ----------------------------------------------------------------------------
-- Orders placed BEFORE customer's signup_date (should return 0 rows)
SELECT
    o.order_id,
    c.customer_id,
    c.signup_date,
    o.order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE DATE(o.order_date) < c.signup_date;

-- Orders without any line items (should return 0 rows)
SELECT o.order_id, o.order_date, o.order_status
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_item_id IS NULL;

-- Returns where return_date precedes delivered_date or refund > item net value
SELECT
    r.return_id,
    r.order_id,
    r.order_item_id,
    o.delivered_date,
    r.return_date,
    r.refund_amount,
    (oi.quantity * oi.unit_price - oi.line_discount) AS line_net_amount
FROM returns r
JOIN orders o       ON r.order_id = o.order_id
JOIN order_items oi ON r.order_item_id = oi.order_item_id
WHERE (o.delivered_date IS NOT NULL AND r.return_date < DATE(o.delivered_date))
   OR r.refund_amount > (oi.quantity * oi.unit_price - oi.line_discount)
   OR oi.order_id <> r.order_id;

-- ----------------------------------------------------------------------------
-- 5. Pricing & Margin Anomaly Check (Catalog vs Line Item Price Drift)
-- ----------------------------------------------------------------------------
SELECT
    oi.order_item_id,
    oi.order_id,
    p.sku,
    p.product_name,
    p.unit_price AS catalog_price,
    oi.unit_price AS billed_price,
    (oi.unit_price - oi.unit_cost) AS unit_margin
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE oi.unit_price <> p.unit_price
   OR oi.unit_price < oi.unit_cost;

-- ----------------------------------------------------------------------------
-- 6. Consolidated Data Health Summary (Pass / Review Status)
-- ----------------------------------------------------------------------------
SELECT 'Orders Before Customer Signup' AS audit_check,
       COUNT(*) AS issue_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END AS status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE DATE(o.order_date) < c.signup_date
UNION ALL
SELECT 'Orphan Orders (No Line Items)',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_item_id IS NULL
UNION ALL
SELECT 'Invalid Return Dates or Over-Refunds',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM returns r
JOIN orders o ON r.order_id = o.order_id
JOIN order_items oi ON r.order_item_id = oi.order_item_id
WHERE r.return_date < DATE(o.delivered_date)
   OR r.refund_amount > (oi.quantity * oi.unit_price - oi.line_discount)
   OR oi.order_id <> r.order_id
UNION ALL
SELECT 'Negative Margin Line Items',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM order_items
WHERE unit_price < unit_cost
UNION ALL
SELECT 'Order Over-Refunds After Discount',
       COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END
FROM (
    SELECT
        o.order_id,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_paid,
        COALESCE((SELECT SUM(r.refund_amount) FROM returns r WHERE r.order_id = o.order_id), 0) AS total_refunded
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.order_discount
    HAVING total_refunded > net_paid
) AS over_refund_orders;

