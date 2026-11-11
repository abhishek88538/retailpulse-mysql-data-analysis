-- ============================================================================
-- RetailPulse — Student Starter Schema
-- File:   00_student_schema.sql
-- Target: MySQL 8.0+
-- Usage:  Run this script first to create the retailpulse_dw database and
--         empty tables before importing the 9 CSV files from csv_data/.
-- ============================================================================

DROP DATABASE IF EXISTS retailpulse_dw;
CREATE DATABASE retailpulse_dw
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE retailpulse_dw;

CREATE TABLE regions (
    region_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    region_name     VARCHAR(80)  NOT NULL UNIQUE,
    country_group   VARCHAR(100) NOT NULL,
    regional_head   VARCHAR(100) NOT NULL,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE customers (
    customer_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name            VARCHAR(120) NOT NULL,
    email                VARCHAR(160) NOT NULL UNIQUE,
    gender               ENUM('Female', 'Male', 'Non-Binary', 'Prefer Not to Say') NOT NULL,
    birth_date           DATE         NULL,
    signup_date          DATE         NOT NULL,
    acquisition_channel  ENUM('Organic', 'Paid Search', 'Social Media', 'Email', 'Referral', 'Influencer') NOT NULL,
    loyalty_tier         ENUM('Bronze', 'Silver', 'Gold', 'Platinum') NOT NULL DEFAULT 'Bronze',
    region_id            INT UNSIGNED NOT NULL,
    city                 VARCHAR(80)  NOT NULL,
    created_at           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customers_region
        FOREIGN KEY (region_id) REFERENCES regions(region_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE categories (
    category_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name      VARCHAR(80)  NOT NULL UNIQUE,
    department         VARCHAR(80)  NOT NULL,
    target_margin_pct  DECIMAL(5,2) NOT NULL CHECK (target_margin_pct BETWEEN 0 AND 100)
) ENGINE=InnoDB;

CREATE TABLE suppliers (
    supplier_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    supplier_name     VARCHAR(120) NOT NULL UNIQUE,
    country           VARCHAR(80)  NOT NULL,
    lead_time_days    INT UNSIGNED NOT NULL CHECK (lead_time_days > 0),
    reliability_score DECIMAL(3,2) NOT NULL CHECK (reliability_score BETWEEN 1.00 AND 5.00)
) ENGINE=InnoDB;

CREATE TABLE products (
    product_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku           VARCHAR(40)    NOT NULL UNIQUE,
    product_name  VARCHAR(150)   NOT NULL,
    category_id   INT UNSIGNED   NOT NULL,
    supplier_id   INT UNSIGNED   NOT NULL,
    unit_cost     DECIMAL(10,2)  NOT NULL CHECK (unit_cost >= 0),
    unit_price    DECIMAL(10,2)  NOT NULL CHECK (unit_price > 0),
    stock_qty     INT UNSIGNED   NOT NULL DEFAULT 0,
    reorder_level INT UNSIGNED   NOT NULL DEFAULT 20,
    is_active     BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_product_price_gt_cost CHECK (unit_price >= unit_cost),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_products_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE campaigns (
    campaign_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    campaign_name  VARCHAR(120)  NOT NULL UNIQUE,
    channel        ENUM('Email', 'Paid Search', 'Social Media', 'Influencer', 'Seasonal Sale', 'Referral') NOT NULL,
    start_date     DATE          NOT NULL,
    end_date       DATE          NOT NULL,
    budget         DECIMAL(12,2) NOT NULL CHECK (budget >= 0),
    promo_code     VARCHAR(40)   NULL UNIQUE,
    CONSTRAINT chk_campaign_dates CHECK (end_date >= start_date)
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id       INT UNSIGNED  NOT NULL,
    campaign_id       INT UNSIGNED  NULL,
    region_id         INT UNSIGNED  NOT NULL,
    order_date        DATETIME      NOT NULL,
    shipped_date      DATETIME      NULL,
    delivered_date    DATETIME      NULL,
    promised_days     INT UNSIGNED  NOT NULL DEFAULT 5,
    order_status      ENUM('Delivered', 'Shipped', 'Processing', 'Cancelled', 'Returned') NOT NULL,
    payment_method    ENUM('Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Digital Wallet', 'COD') NOT NULL,
    shipping_fee      DECIMAL(8,2)  NOT NULL DEFAULT 0.00 CHECK (shipping_fee >= 0),
    order_discount    DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (order_discount >= 0),
    CONSTRAINT chk_shipped_after_order CHECK (shipped_date IS NULL OR shipped_date >= order_date),
    CONSTRAINT chk_delivered_after_shipped CHECK (delivered_date IS NULL OR (shipped_date IS NOT NULL AND delivered_date >= shipped_date)),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_campaign
        FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_orders_region
        FOREIGN KEY (region_id) REFERENCES regions(region_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE order_items (
    order_item_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id        INT UNSIGNED  NOT NULL,
    product_id      INT UNSIGNED  NOT NULL,
    quantity        INT UNSIGNED  NOT NULL CHECK (quantity > 0),
    unit_price      DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    unit_cost       DECIMAL(10,2) NOT NULL CHECK (unit_cost >= 0),
    line_discount   DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (line_discount >= 0),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE returns (
    return_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id       INT UNSIGNED  NOT NULL,
    order_item_id  INT UNSIGNED  NOT NULL UNIQUE,
    return_date    DATE          NOT NULL,
    return_reason  ENUM('Defective / Damaged', 'Wrong Item Sent', 'Size / Fit Issue', 'Not as Described', 'Customer Changed Mind', 'Late Delivery') NOT NULL,
    refund_amount  DECIMAL(10,2) NOT NULL CHECK (refund_amount >= 0),
    restocked      BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_returns_order
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_returns_order_item
        FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE inventory_audit_log (
    audit_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id      INT UNSIGNED NOT NULL,
    order_id        INT UNSIGNED NULL,
    qty_change      INT          NOT NULL,
    reason          VARCHAR(100) NOT NULL,
    logged_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_customers_signup       ON customers(signup_date);
CREATE INDEX idx_customers_region       ON customers(region_id);
CREATE INDEX idx_customers_channel      ON customers(acquisition_channel);
CREATE INDEX idx_products_category      ON products(category_id);
CREATE INDEX idx_products_supplier      ON products(supplier_id);
CREATE INDEX idx_orders_order_date      ON orders(order_date);
CREATE INDEX idx_orders_customer_date   ON orders(customer_id, order_date);
CREATE INDEX idx_orders_status_date     ON orders(order_status, order_date);
CREATE INDEX idx_orders_campaign        ON orders(campaign_id);
CREATE INDEX idx_orders_region          ON orders(region_id);
CREATE INDEX idx_order_items_order      ON order_items(order_id);
CREATE INDEX idx_order_items_product    ON order_items(product_id);
CREATE INDEX idx_returns_order          ON returns(order_id);
CREATE INDEX idx_returns_date           ON returns(return_date);

