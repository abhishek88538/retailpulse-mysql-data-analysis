-- ============================================================================
-- Project: RetailPulse — E-Commerce Sales & Customer RFM Data Analysis
-- File:    05_advanced_analytics_rfm_cohorts.sql
-- Target:  MySQL 8.0+
-- Purpose: Advanced SQL analytics featuring CTEs, window functions, NTILE RFM
--          segmentation, cohort retention matrix, Pareto ABC, Market Basket
--          Analysis, rolling moving averages, and churn/reorder alerts (Q13–Q24).
-- ============================================================================

USE retailpulse_dw;

-- ============================================================================
-- Q13. Customer Lifetime Value (CLV) Leaderboard & Regional Ranking
-- ============================================================================
WITH order_net AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY o.order_id, o.customer_id, o.order_date, o.order_discount
),
ret_net AS (
    SELECT order_id, SUM(refund_amount) AS refunds
    FROM returns
    GROUP BY order_id
),
cust_ltv AS (
    SELECT
        c.customer_id,
        c.full_name,
        reg.region_name,
        c.loyalty_tier,
        COUNT(DISTINCT onet.order_id) AS total_orders,
        MIN(DATE(onet.order_date)) AS first_order_date,
        MAX(DATE(onet.order_date)) AS last_order_date,
        ROUND(SUM(onet.net_sales - COALESCE(rn.refunds, 0)), 2) AS realized_ltv
    FROM customers c
    JOIN regions reg      ON c.region_id = reg.region_id
    JOIN order_net onet   ON c.customer_id = onet.customer_id
    LEFT JOIN ret_net rn  ON onet.order_id = rn.order_id
    GROUP BY c.customer_id, c.full_name, reg.region_name, c.loyalty_tier
)
SELECT
    customer_id,
    full_name,
    region_name,
    loyalty_tier,
    total_orders,
    first_order_date,
    last_order_date,
    realized_ltv,
    ROUND(realized_ltv / NULLIF(total_orders, 0), 2) AS avg_order_value,
    DENSE_RANK() OVER (ORDER BY realized_ltv DESC) AS global_ltv_rank,
    DENSE_RANK() OVER (PARTITION BY region_name ORDER BY realized_ltv DESC) AS regional_ltv_rank
FROM cust_ltv
ORDER BY realized_ltv DESC
LIMIT 15;


-- ============================================================================
-- Q14. Full RFM (Recency, Frequency, Monetary) Customer Segmentation (NTILE 5)
-- ============================================================================
WITH ref_date AS (
    SELECT MAX(DATE(order_date)) AS as_of_date
    FROM orders
    WHERE order_status <> 'Cancelled'
),
order_net AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY o.order_id, o.customer_id, o.order_date, o.order_discount
),
ret_net AS (
    SELECT order_id, SUM(refund_amount) AS refunds
    FROM returns
    GROUP BY order_id
),
rfm_base AS (
    SELECT
        c.customer_id,
        c.full_name,
        reg.region_name,
        c.loyalty_tier,
        DATEDIFF(rd.as_of_date, MAX(DATE(onet.order_date))) AS recency_days,
        COUNT(DISTINCT onet.order_id) AS frequency,
        ROUND(SUM(onet.net_sales - COALESCE(rn.refunds, 0)), 2) AS monetary
    FROM customers c
    CROSS JOIN ref_date rd
    JOIN regions reg     ON c.region_id = reg.region_id
    JOIN order_net onet  ON c.customer_id = onet.customer_id
    LEFT JOIN ret_net rn ON onet.order_id = rn.order_id
    GROUP BY c.customer_id, c.full_name, reg.region_name, c.loyalty_tier, rd.as_of_date
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    full_name,
    region_name,
    loyalty_tier,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_code,
    ROUND((r_score + f_score + m_score) / 3.0, 2) AS rfm_avg_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2                  THEN 'Recent / Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
        WHEN r_score = 2  AND f_score <= 2                  THEN 'About to Sleep'
        WHEN r_score = 1  AND f_score <= 2                  THEN 'Hibernating / Lost'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM rfm_scores
ORDER BY monetary DESC;


-- ============================================================================
-- Q15. RFM Segment Revenue Contribution & Customer Mix Summary
-- ============================================================================
WITH ref_date AS (
    SELECT MAX(DATE(order_date)) AS as_of_date
    FROM orders
    WHERE order_status <> 'Cancelled'
),
order_net AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY o.order_id, o.customer_id, o.order_date, o.order_discount
),
ret_net AS (
    SELECT order_id, SUM(refund_amount) AS refunds
    FROM returns
    GROUP BY order_id
),
rfm_base AS (
    SELECT
        c.customer_id,
        DATEDIFF(rd.as_of_date, MAX(DATE(onet.order_date))) AS recency_days,
        COUNT(DISTINCT onet.order_id) AS frequency,
        ROUND(SUM(onet.net_sales - COALESCE(rn.refunds, 0)), 2) AS monetary
    FROM customers c
    CROSS JOIN ref_date rd
    JOIN order_net onet  ON c.customer_id = onet.customer_id
    LEFT JOIN ret_net rn ON onet.order_id = rn.order_id
    GROUP BY c.customer_id, rd.as_of_date
),
rfm_segmented AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
    FROM rfm_base
),
labeled AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2                  THEN 'Recent / Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
            WHEN r_score = 2  AND f_score <= 2                  THEN 'About to Sleep'
            WHEN r_score = 1  AND f_score <= 2                  THEN 'Hibernating / Lost'
            ELSE 'Needs Attention'
        END AS rfm_segment
    FROM rfm_segmented
)
SELECT
    rfm_segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS customer_share_pct,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_ltv,
    ROUND(SUM(monetary), 2) AS segment_total_revenue,
    ROUND(100.0 * SUM(monetary) / NULLIF(SUM(SUM(monetary)) OVER (), 0), 2) AS revenue_share_pct
FROM labeled
GROUP BY rfm_segment
ORDER BY segment_total_revenue DESC;


-- ============================================================================
-- Q16. Quarterly Cohort Retention Matrix (Based on Customer First Order Quarter)
-- ============================================================================
WITH valid_orders AS (
    SELECT
        customer_id,
        order_date,
        STR_TO_DATE(CONCAT(YEAR(order_date), '-', LPAD((QUARTER(order_date) - 1) * 3 + 1, 2, '0'), '-01'), '%Y-%m-%d') AS order_q_start
    FROM orders
    WHERE order_status <> 'Cancelled'
),
first_purchase AS (
    SELECT
        customer_id,
        MIN(order_q_start) AS cohort_q_start
    FROM valid_orders
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT
        fp.customer_id,
        CONCAT(YEAR(fp.cohort_q_start), '-Q', QUARTER(fp.cohort_q_start)) AS cohort_quarter,
        fp.cohort_q_start,
        TIMESTAMPDIFF(QUARTER, fp.cohort_q_start, vo.order_q_start) AS q_index
    FROM first_purchase fp
    JOIN valid_orders vo ON fp.customer_id = vo.customer_id
),
cohort_counts AS (
    SELECT
        cohort_quarter,
        cohort_q_start,
        COUNT(DISTINCT CASE WHEN q_index = 0 THEN customer_id END) AS q0_users,
        COUNT(DISTINCT CASE WHEN q_index = 1 THEN customer_id END) AS q1_users,
        COUNT(DISTINCT CASE WHEN q_index = 2 THEN customer_id END) AS q2_users,
        COUNT(DISTINCT CASE WHEN q_index = 3 THEN customer_id END) AS q3_users,
        COUNT(DISTINCT CASE WHEN q_index = 4 THEN customer_id END) AS q4_users,
        COUNT(DISTINCT CASE WHEN q_index >= 5 THEN customer_id END) AS q5_plus_users
    FROM cohort_activity
    GROUP BY cohort_quarter, cohort_q_start
)
SELECT
    cohort_quarter,
    q0_users AS cohort_size,
    ROUND(100.0 * q1_users / NULLIF(q0_users, 0), 1) AS q1_retention_pct,
    ROUND(100.0 * q2_users / NULLIF(q0_users, 0), 1) AS q2_retention_pct,
    ROUND(100.0 * q3_users / NULLIF(q0_users, 0), 1) AS q3_retention_pct,
    ROUND(100.0 * q4_users / NULLIF(q0_users, 0), 1) AS q4_retention_pct,
    ROUND(100.0 * q5_plus_users / NULLIF(q0_users, 0), 1) AS q5_plus_retention_pct
FROM cohort_counts
ORDER BY cohort_q_start;


-- ============================================================================
-- Q17. Repeat Purchase Gap Analysis (Days Between Consecutive Orders)
-- ============================================================================
WITH ordered_events AS (
    SELECT
        o.customer_id,
        c.full_name,
        o.order_id,
        DATE(o.order_date) AS order_day,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS order_seq,
        LAG(DATE(o.order_date)) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS prev_order_day
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status <> 'Cancelled'
),
gaps AS (
    SELECT
        customer_id,
        full_name,
        order_seq,
        order_day,
        prev_order_day,
        DATEDIFF(order_day, prev_order_day) AS days_since_prev_order
    FROM ordered_events
    WHERE prev_order_day IS NOT NULL
)
SELECT
    customer_id,
    full_name,
    COUNT(*) AS repeat_order_transitions,
    MIN(days_since_prev_order) AS min_gap_days,
    ROUND(AVG(days_since_prev_order), 1) AS avg_gap_days,
    MAX(days_since_prev_order) AS max_gap_days
FROM gaps
GROUP BY customer_id, full_name
ORDER BY repeat_order_transitions DESC, avg_gap_days ASC;


-- ============================================================================
-- Q18. Personalized Churn Risk Detection (Overdue vs. Customer's Own Cadence)
-- ============================================================================
WITH ref_date AS (
    SELECT MAX(DATE(order_date)) AS as_of_date
    FROM orders
    WHERE order_status <> 'Cancelled'
),
cust_orders AS (
    SELECT
        o.customer_id,
        c.full_name,
        c.loyalty_tier,
        DATE(o.order_date) AS order_day,
        LAG(DATE(o.order_date)) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS prev_order_day
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status <> 'Cancelled'
),
cadence AS (
    SELECT
        customer_id,
        full_name,
        loyalty_tier,
        COUNT(*) AS order_count,
        MAX(order_day) AS last_order_day,
        ROUND(AVG(DATEDIFF(order_day, prev_order_day)), 1) AS avg_cycle_days
    FROM cust_orders
    GROUP BY customer_id, full_name, loyalty_tier
    HAVING COUNT(*) >= 2
)
SELECT
    cad.customer_id,
    cad.full_name,
    cad.loyalty_tier,
    cad.order_count,
    cad.last_order_day,
    cad.avg_cycle_days,
    DATEDIFF(rd.as_of_date, cad.last_order_day) AS days_inactive,
    ROUND(DATEDIFF(rd.as_of_date, cad.last_order_day) / NULLIF(cad.avg_cycle_days, 0), 2) AS overdue_ratio,
    CASE
        WHEN DATEDIFF(rd.as_of_date, cad.last_order_day) > 2.0 * cad.avg_cycle_days THEN 'High Churn Risk'
        WHEN DATEDIFF(rd.as_of_date, cad.last_order_day) > 1.25 * cad.avg_cycle_days THEN 'Watchlist'
        ELSE 'Healthy Cadence'
    END AS churn_status
FROM cadence cad
CROSS JOIN ref_date rd
ORDER BY overdue_ratio DESC;


-- ============================================================================
-- Q19. ABC Product Classification (Pareto 80/20 Cumulative Revenue Analysis)
-- ============================================================================
WITH prod_rev AS (
    SELECT
        p.product_id,
        p.sku,
        p.product_name,
        cat.category_name,
        ROUND(SUM(oi.quantity * oi.unit_price - oi.line_discount) - SUM(COALESCE(r.refund_amount, 0)), 2) AS net_revenue
    FROM products p
    JOIN categories cat ON p.category_id = cat.category_id
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o       ON oi.order_id = o.order_id
    LEFT JOIN returns r ON oi.order_item_id = r.order_item_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY p.product_id, p.sku, p.product_name, cat.category_name
),
pareto AS (
    SELECT
        sku,
        product_name,
        category_name,
        net_revenue,
        SUM(net_revenue) OVER () AS total_company_revenue,
        SUM(net_revenue) OVER (ORDER BY net_revenue DESC, product_id ASC) AS cumulative_revenue
    FROM prod_rev
)
SELECT
    sku,
    product_name,
    category_name,
    net_revenue,
    ROUND(100.0 * net_revenue / NULLIF(total_company_revenue, 0), 2) AS revenue_pct,
    ROUND(100.0 * cumulative_revenue / NULLIF(total_company_revenue, 0), 2) AS cumulative_pct,
    CASE
        WHEN (100.0 * cumulative_revenue / NULLIF(total_company_revenue, 0)) <= 70.0 THEN 'Class A (Core Stars)'
        WHEN (100.0 * cumulative_revenue / NULLIF(total_company_revenue, 0)) <= 90.0 THEN 'Class B (Moderate)'
        ELSE 'Class C (Long Tail)'
    END AS abc_class
FROM pareto
ORDER BY net_revenue DESC;


-- ============================================================================
-- Q20. Market Basket Analysis (Frequently Bought Together Product Pairs)
-- ============================================================================
WITH valid_baskets AS (
    SELECT DISTINCT oi.order_id, oi.product_id
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status <> 'Cancelled'
),
total_orders AS (
    SELECT COUNT(DISTINCT order_id) AS n_orders
    FROM valid_baskets
),
prod_freq AS (
    SELECT product_id, COUNT(*) AS prod_orders
    FROM valid_baskets
    GROUP BY product_id
),
pair_freq AS (
    SELECT
        a.product_id AS prod_a_id,
        b.product_id AS prod_b_id,
        COUNT(*) AS pair_orders
    FROM valid_baskets a
    JOIN valid_baskets b
      ON a.order_id = b.order_id
     AND a.product_id < b.product_id
    GROUP BY a.product_id, b.product_id
    HAVING COUNT(*) >= 2
)
SELECT
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    pf.pair_orders AS co_purchase_count,
    ROUND(100.0 * pf.pair_orders / t.n_orders, 2) AS support_pct,
    ROUND(100.0 * pf.pair_orders / pa.prod_orders, 2) AS confidence_a_to_b_pct,
    ROUND(100.0 * pf.pair_orders / pb.prod_orders, 2) AS confidence_b_to_a_pct,
    ROUND((pf.pair_orders * 1.0 / t.n_orders) / ((pa.prod_orders * 1.0 / t.n_orders) * (pb.prod_orders * 1.0 / t.n_orders)), 2) AS lift_score
FROM pair_freq pf
JOIN products p1  ON pf.prod_a_id = p1.product_id
JOIN products p2  ON pf.prod_b_id = p2.product_id
JOIN prod_freq pa ON pf.prod_a_id = pa.product_id
JOIN prod_freq pb ON pf.prod_b_id = pb.product_id
CROSS JOIN total_orders t
ORDER BY co_purchase_count DESC, lift_score DESC
LIMIT 12;


-- ============================================================================
-- Q21. Cumulative Running Revenue & 3-Month Rolling Moving Average
-- ============================================================================
WITH order_net AS (
    SELECT
        o.order_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY o.order_id, DATE_FORMAT(o.order_date, '%Y-%m'), o.order_discount
),
monthly AS (
    SELECT
        order_month,
        ROUND(SUM(net_revenue), 2) AS monthly_revenue
    FROM order_net
    GROUP BY order_month
)
SELECT
    order_month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY order_month), 2) AS cumulative_revenue,
    ROUND(AVG(monthly_revenue) OVER (ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3m_avg_revenue
FROM monthly
ORDER BY order_month;


-- ============================================================================
-- Q22. Acquisition Channel Quality (LTV, Repeat Rate & Return Rate by Channel)
-- ============================================================================
WITH order_net AS (
    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price - oi.line_discount) - o.order_discount AS net_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY o.order_id, o.customer_id, o.order_discount
),
ret_net AS (
    SELECT order_id, SUM(refund_amount) AS refunds
    FROM returns
    GROUP BY order_id
),
cust_summary AS (
    SELECT
        c.customer_id,
        c.acquisition_channel,
        COUNT(DISTINCT onet.order_id) AS order_count,
        COALESCE(SUM(onet.net_sales - COALESCE(rn.refunds, 0)), 0) AS customer_ltv
    FROM customers c
    LEFT JOIN order_net onet ON c.customer_id = onet.customer_id
    LEFT JOIN ret_net rn     ON onet.order_id = rn.order_id
    GROUP BY c.customer_id, c.acquisition_channel
)
SELECT
    acquisition_channel,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) AS repeat_buyers,
    ROUND(100.0 * SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_buyer_rate_pct,
    ROUND(AVG(order_count), 2) AS avg_orders_per_customer,
    ROUND(AVG(customer_ltv), 2) AS avg_customer_ltv,
    ROUND(SUM(customer_ltv), 2) AS total_channel_ltv
FROM cust_summary
GROUP BY acquisition_channel
ORDER BY avg_customer_ltv DESC;


-- ============================================================================
-- Q23. Inventory Stock-Out Risk & Supplier Reorder Alert
-- ============================================================================
WITH ref_date AS (
    SELECT MAX(order_date) AS max_dt
    FROM orders
    WHERE order_status <> 'Cancelled'
),
velocity_180d AS (
    SELECT
        oi.product_id,
        SUM(oi.quantity) AS units_sold_180d
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status <> 'Cancelled'
      AND o.order_date >= DATE_SUB((SELECT max_dt FROM ref_date), INTERVAL 180 DAY)
    GROUP BY oi.product_id
)
SELECT
    p.sku,
    p.product_name,
    s.supplier_name,
    s.lead_time_days,
    p.stock_qty,
    p.reorder_level,
    COALESCE(v.units_sold_180d, 0) AS units_sold_last_180d,
    ROUND(COALESCE(v.units_sold_180d, 0) / 180.0, 3) AS daily_run_rate,
    CASE
        WHEN COALESCE(v.units_sold_180d, 0) = 0 THEN 999.0
        ELSE ROUND(p.stock_qty / (v.units_sold_180d / 180.0), 1)
    END AS estimated_days_of_cover,
    CASE
        WHEN p.stock_qty <= p.reorder_level THEN 'REORDER NOW (Below Reorder Level)'
        WHEN COALESCE(v.units_sold_180d, 0) > 0
             AND (p.stock_qty / (v.units_sold_180d / 180.0)) <= (s.lead_time_days * 2) THEN 'LOW BUFFER (Order Soon)'
        ELSE 'HEALTHY'
    END AS inventory_status
FROM products p
JOIN suppliers s       ON p.supplier_id = s.supplier_id
LEFT JOIN velocity_180d v ON p.product_id = v.product_id
ORDER BY p.stock_qty <= p.reorder_level DESC, estimated_days_of_cover ASC;


-- ============================================================================
-- Q24. Customer Order Conversion & Retention Funnel (1st -> 2nd -> 3rd+ Order)
-- ============================================================================
WITH cust_order_counts AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT CASE WHEN o.order_status <> 'Cancelled' THEN o.order_id END) AS completed_orders
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
)
SELECT
    COUNT(*) AS total_signed_up_customers,
    SUM(CASE WHEN completed_orders >= 1 THEN 1 ELSE 0 END) AS made_at_least_1_order,
    SUM(CASE WHEN completed_orders >= 2 THEN 1 ELSE 0 END) AS made_at_least_2_orders,
    SUM(CASE WHEN completed_orders >= 3 THEN 1 ELSE 0 END) AS made_3_plus_orders,
    ROUND(100.0 * SUM(CASE WHEN completed_orders >= 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS signup_to_1st_order_pct,
    ROUND(100.0 * SUM(CASE WHEN completed_orders >= 2 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN completed_orders >= 1 THEN 1 ELSE 0 END), 0), 2) AS first_to_2nd_repeat_pct,
    ROUND(100.0 * SUM(CASE WHEN completed_orders >= 3 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN completed_orders >= 2 THEN 1 ELSE 0 END), 0), 2) AS second_to_3rd_repeat_pct
FROM cust_order_counts;
