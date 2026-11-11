-- ============================================================================
-- RetailPulse — Student CSV Loader Script (MySQL 8.0+)
-- File:   01_load_csv_data.sql
-- Usage:  1. Run 00_student_schema.sql first.
--         2. Run this script from inside Student_Assignment_Kit/ (so ./csv_data/
--            resolves automatically), OR replace ./csv_data/ with your full
--            folder path using forward slashes '/'.
--         3. If MySQL blocks local infile, connect with --local-infile=1 or
--            use MySQL Workbench -> Table Data Import Wizard instead.
-- ============================================================================

USE retailpulse_dw;

-- Enable local_infile on the server session (requires SUPER/SYSTEM_VARIABLES_ADMIN,
-- or run mysql CLI with --local-infile=1; in Workbench add OPT_LOCAL_INFILE=1 in
-- Connection -> Advanced -> Others).
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE './csv_data/regions.csv'
INTO TABLE regions
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(region_id, region_name, country_group, regional_head, created_at);

LOAD DATA LOCAL INFILE './csv_data/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(customer_id, full_name, email, gender, @birth_date, signup_date, acquisition_channel, loyalty_tier, region_id, city, created_at)
SET birth_date = NULLIF(@birth_date, '');

LOAD DATA LOCAL INFILE './csv_data/categories.csv'
INTO TABLE categories
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(category_id, category_name, department, target_margin_pct);

LOAD DATA LOCAL INFILE './csv_data/suppliers.csv'
INTO TABLE suppliers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(supplier_id, supplier_name, country, lead_time_days, reliability_score);

LOAD DATA LOCAL INFILE './csv_data/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(product_id, sku, product_name, category_id, supplier_id, unit_cost, unit_price, stock_qty, reorder_level, is_active, created_at);

LOAD DATA LOCAL INFILE './csv_data/campaigns.csv'
INTO TABLE campaigns
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(campaign_id, campaign_name, channel, start_date, end_date, budget, @promo_code)
SET promo_code = NULLIF(@promo_code, '');

LOAD DATA LOCAL INFILE './csv_data/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(order_id, customer_id, @campaign_id, region_id, order_date, @shipped_date, @delivered_date, promised_days, order_status, payment_method, shipping_fee, order_discount)
SET campaign_id    = NULLIF(@campaign_id, ''),
    shipped_date   = NULLIF(@shipped_date, ''),
    delivered_date = NULLIF(@delivered_date, '');

LOAD DATA LOCAL INFILE './csv_data/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(order_item_id, order_id, product_id, quantity, unit_price, unit_cost, line_discount);

LOAD DATA LOCAL INFILE './csv_data/returns.csv'
INTO TABLE returns
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(return_id, order_id, order_item_id, return_date, return_reason, refund_amount, restocked);

