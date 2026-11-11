-- ============================================================================
-- Project: RetailPulse — E-Commerce Sales & Customer RFM Data Analysis
-- File:    02_seed_data.sql
-- Target:  MySQL 8.0+
-- Purpose: Populates realistic multi-year (2024–2026) e-commerce data across
--          regions, categories, suppliers, products, campaigns, customers,
--          orders, order_items, and returns.
-- ============================================================================

USE retailpulse_dw;

-- Clean tables in child-to-parent order for idempotent re-runs
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE inventory_audit_log;
TRUNCATE TABLE returns;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE campaigns;
TRUNCATE TABLE products;
TRUNCATE TABLE suppliers;
TRUNCATE TABLE categories;
TRUNCATE TABLE customers;
TRUNCATE TABLE regions;
SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------------------------------------------------------
-- 1. Regions (5 Regions)
-- ----------------------------------------------------------------------------
INSERT INTO regions (region_id, region_name, country_group, regional_head) VALUES
(1, 'North America',  'USA, Canada',                   'Rachel Vance'),
(2, 'Europe',         'UK, Germany, France, Italy',    'Henrik Lindqvist'),
(3, 'South Asia',     'India, Sri Lanka',              'Vikramaditya Sen'),
(4, 'Southeast Asia', 'Singapore, Malaysia, Thailand', 'Wei-Ling Tan'),
(5, 'Middle East',    'UAE, Saudi Arabia, Qatar',      'Tariq Al-Sayed');

-- ----------------------------------------------------------------------------
-- 2. Categories (6 Categories)
-- ----------------------------------------------------------------------------
INSERT INTO categories (category_id, category_name, department, target_margin_pct) VALUES
(1, 'Electronics',          'Tech & Gadgets',     28.00),
(2, 'Fashion & Apparel',    'Lifestyle',          48.00),
(3, 'Home & Kitchen',       'Home Living',        38.00),
(4, 'Beauty & Personal Care','Wellness',          55.00),
(5, 'Sports & Fitness',     'Active & Outdoors',  42.00),
(6, 'Books & Stationery',   'Media & Office',     45.00);

-- ----------------------------------------------------------------------------
-- 3. Suppliers (6 Suppliers)
-- ----------------------------------------------------------------------------
INSERT INTO suppliers (supplier_id, supplier_name, country, lead_time_days, reliability_score) VALUES
(1, 'ApexTech Manufacturing',  'Taiwan',      10, 4.75),
(2, 'LoomCraft Textiles',      'India',       12, 4.60),
(3, 'NordicHome Goods',        'Germany',     14, 4.85),
(4, 'AuraBotanicals Lab',      'South Korea',  9, 4.70),
(5, 'Velocity Gear Co.',       'Vietnam',     11, 4.35),
(6, 'Inkwell Publishing House','UK',           7, 4.90);

-- ----------------------------------------------------------------------------
-- 4. Products (24 Products across 6 categories)
-- ----------------------------------------------------------------------------
INSERT INTO products (product_id, sku, product_name, category_id, supplier_id, unit_cost, unit_price, stock_qty, reorder_level, is_active) VALUES
-- Electronics (1..4)
(1,  'EL-101', 'ProSound ANC Wireless Headphones',  1, 1, 82.00,  149.00, 95,  25, TRUE),
(2,  'EL-102', 'ErgoMech Mechanical Keyboard',      1, 1, 58.00,   99.00, 62,  20, TRUE),
(3,  'EL-103', 'SwiftClick Precision Wireless Mouse',1, 1, 21.00,  45.00, 140, 30, TRUE),
(4,  'EL-104', 'AeroStand Aluminum Laptop Stand',   1, 1, 19.00,   39.00, 18,  25, TRUE),
-- Fashion & Apparel (5..8)
(5,  'FA-201', 'Merino Knit Crewneck Sweater',      2, 2, 28.00,   68.00, 84,  20, TRUE),
(6,  'FA-202', 'SlimFit Selvedge Denim Jeans',      2, 2, 32.00,   79.00, 54,  20, TRUE),
(7,  'FA-203', 'Organic Cotton Classic Polo',       2, 2, 14.00,   38.00, 130, 30, TRUE),
(8,  'FA-204', 'All-Weather Commuter Backpack',     2, 2, 34.00,   85.00, 15,  20, TRUE),
-- Home & Kitchen (9..12)
(9,  'HK-301', 'BaristaPro Pour-Over Kettle',       3, 3, 29.00,   64.00, 70,  15, TRUE),
(10, 'HK-302', 'ChefEdge Japanese Santoku Knife',   3, 3, 42.00,   92.00, 44,  15, TRUE),
(11, 'HK-303', 'SmartAir HEPA Desk Purifier',       3, 3, 68.00,  129.00, 26,  20, TRUE),
(12, 'HK-304', 'Borosilicate Glass Storage Set',    3, 3, 18.00,   42.00, 110, 25, TRUE),
-- Beauty & Personal Care (13..16)
(13, 'BP-401', 'HydraGlow Vitamin C Serum 30ml',    4, 4, 11.00,   36.00, 160, 35, TRUE),
(14, 'BP-402', 'BarrierRestore Ceramide Moisturizer',4, 4, 13.00,  42.00, 125, 30, TRUE),
(15, 'BP-403', 'SilkMist SPF 50 Daily Sunscreen',   4, 4,  9.50,   29.00, 14,  30, TRUE),
(16, 'BP-404', 'Botanical Scalp & Hair Elixir',     4, 4, 15.00,   44.00, 88,  20, TRUE),
-- Sports & Fitness (17..20)
(17, 'SF-501', 'GripCore Cork Yoga Mat 6mm',        5, 5, 22.00,   54.00, 75,  20, TRUE),
(18, 'SF-502', 'FlexBand Fabric Resistance Set',    5, 5, 11.00,   28.00, 145, 30, TRUE),
(19, 'SF-503', 'HydroPeak Insulated Bottle 1L',     5, 5,  9.00,   26.00, 190, 35, TRUE),
(20, 'SF-504', 'PulseTrack Smart Jump Rope',        5, 5, 18.00,   46.00, 12,  20, TRUE),
-- Books & Stationery (21..24)
(21, 'BS-601', 'Designing Data Systems (Hardcover)',6, 6, 18.00,   44.00, 95,  20, TRUE),
(22, 'BS-602', 'DotGrid Lay-Flat Leather Notebook', 6, 6,  7.50,   22.00, 210, 40, TRUE),
(23, 'BS-603', 'Precision Brass Rollerball Pen',    6, 6, 12.00,   32.00, 105, 25, TRUE),
(24, 'BS-604', 'SQL & Analytics Field Manual',      6, 6, 16.00,   39.00, 115, 20, TRUE);

-- ----------------------------------------------------------------------------
-- 5. Marketing Campaigns (8 Campaigns across 2024–2026)
-- ----------------------------------------------------------------------------
INSERT INTO campaigns (campaign_id, campaign_name, channel, start_date, end_date, budget, promo_code) VALUES
(1, 'New Year Kickoff 2024',       'Email',         '2024-01-01', '2024-02-15', 140.00, 'NY2024'),
(2, 'Spring Style Refresh 2024',   'Social Media',  '2024-03-15', '2024-05-10', 220.00, 'SPRING24'),
(3, 'Mid-Year Tech Fest 2024',     'Paid Search',   '2024-07-01', '2024-08-31', 260.00, 'TECHFEST24'),
(4, 'Black Friday Mega Sale 2024', 'Seasonal Sale', '2024-11-15', '2024-12-10', 320.00, 'BF2024'),
(5, 'Spring Wellness Drive 2025',  'Influencer',    '2025-03-01', '2025-05-15', 240.00, 'GLOW25'),
(6, 'Summer Gear Rush 2025',       'Paid Search',   '2025-07-01', '2025-09-15', 290.00, 'GEAR25'),
(7, 'Holiday Extravaganza 2025',   'Seasonal Sale', '2025-11-15', '2025-12-31', 350.00, 'HOLIDAY25'),
(8, 'Autumn Productivity 2026',    'Email',         '2026-08-15', '2026-10-31', 280.00, 'WORKFLOW26');

-- ----------------------------------------------------------------------------
-- 6. Customers (30 Customers)
-- ----------------------------------------------------------------------------
INSERT INTO customers (customer_id, full_name, email, gender, birth_date, signup_date, acquisition_channel, loyalty_tier, region_id, city) VALUES
(1,  'Aarav Sharma',      'aarav.sharma@example.com',      'Male',   '1994-05-14', '2024-01-05', 'Organic',      'Platinum', 3, 'Bengaluru'),
(2,  'Maya Verma',        'maya.verma@example.com',        'Female', '1996-09-21', '2024-01-14', 'Paid Search',  'Gold',     3, 'Mumbai'),
(3,  'Liam Carter',       'liam.carter@example.com',       'Male',   '1990-02-11', '2024-01-20', 'Referral',     'Platinum', 1, 'Austin'),
(4,  'Sophia Bennett',    'sophia.bennett@example.com',    'Female', '1993-07-08', '2024-02-02', 'Social Media', 'Gold',     2, 'London'),
(5,  'Noah Kim',          'noah.kim@example.com',          'Male',   '1995-11-30', '2024-02-15', 'Paid Search',  'Silver',   4, 'Singapore'),
(6,  'Zara Al-Mansoor',   'zara.mansoor@example.com',      'Female', '1992-03-19', '2024-03-01', 'Influencer',   'Gold',     5, 'Dubai'),
(7,  'Rohan Mehta',       'rohan.mehta@example.com',       'Male',   '1989-12-04', '2024-03-10', 'Email',        'Silver',   3, 'Pune'),
(8,  'Emma Cole',         'emma.cole@example.com',         'Female', '1997-04-25', '2024-04-04', 'Organic',      'Silver',   1, 'Toronto'),
(9,  'Lucas Muller',      'lucas.muller@example.com',      'Male',   '1991-08-16', '2024-05-12', 'Paid Search',  'Bronze',   2, 'Berlin'),
(10, 'Ananya Iyer',       'ananya.iyer@example.com',       'Female', '1995-01-29', '2024-06-18', 'Referral',     'Platinum', 3, 'Chennai'),
(11, 'Ethan Brooks',      'ethan.brooks@example.com',      'Male',   '1988-06-07', '2024-07-07', 'Social Media', 'Bronze',   1, 'Seattle'),
(12, 'Chloe Tan',         'chloe.tan@example.com',         'Female', '1998-10-12', '2024-08-19', 'Influencer',   'Gold',     4, 'Kuala Lumpur'),
(13, 'Kabir Malhotra',    'kabir.malhotra@example.com',    'Male',   '1993-03-23', '2024-09-02', 'Organic',      'Silver',   3, 'New Delhi'),
(14, 'Olivia Laurent',    'olivia.laurent@example.com',    'Female', '1991-12-18', '2024-10-10', 'Email',        'Silver',   2, 'Paris'),
(15, 'Omar Hassan',       'omar.hassan@example.com',       'Male',   '1987-09-03', '2024-11-01', 'Paid Search',  'Gold',     5, 'Riyadh'),
(16, 'Priya Nair',        'priya.nair@example.com',        'Female', '1994-11-09', '2025-01-08', 'Organic',      'Gold',     3, 'Hyderabad'),
(17, 'Daniel Park',       'daniel.park@example.com',       'Male',   '1996-02-27', '2025-02-14', 'Social Media', 'Silver',   1, 'Chicago'),
(18, 'Hannah Schmidt',    'hannah.schmidt@example.com',    'Female', '1992-07-15', '2025-03-22', 'Referral',     'Silver',   2, 'Munich'),
(19, 'Vikram Joshi',      'vikram.joshi@example.com',      'Male',   '1999-05-06', '2025-04-11', 'Paid Search',  'Bronze',   3, 'Jaipur'),
(20, 'Amira Khalid',      'amira.khalid@example.com',      'Female', '1995-08-22', '2025-05-19', 'Influencer',   'Silver',   5, 'Doha'),
(21, 'Ryan Cooper',       'ryan.cooper@example.com',       'Male',   '1990-10-31', '2025-06-25', 'Organic',      'Bronze',   1, 'Denver'),
(22, 'Mei Ling',          'mei.ling@example.com',          'Female', '1997-01-17', '2025-08-03', 'Social Media', 'Gold',     4, 'Singapore'),
(23, 'Siddharth Rao',     'siddharth.rao@example.com',     'Male',   '1993-06-14', '2025-09-14', 'Email',        'Silver',   3, 'Bengaluru'),
(24, 'Isabella Rossi',    'isabella.rossi@example.com',    'Female', '1994-04-02', '2025-11-05', 'Paid Search',  'Bronze',   2, 'Milan'),
(25, 'Neha Kulkarni',     'neha.kulkarni@example.com',     'Female', '1996-12-08', '2026-01-10', 'Referral',     'Silver',   3, 'Pune'),
(26, 'Mason Reed',        'mason.reed@example.com',        'Male',   '1991-09-19', '2026-02-18', 'Paid Search',  'Bronze',   1, 'Boston'),
(27, 'Farah Zayed',       'farah.zayed@example.com',       'Female', '1998-03-11', '2026-04-07', 'Influencer',   'Silver',   5, 'Abu Dhabi'),
(28, 'Arjun Deshmukh',    'arjun.deshmukh@example.com',    'Male',   '1995-07-26', '2026-05-20', 'Organic',      'Bronze',   3, 'Mumbai'),
(29, 'Grace Lim',         'grace.lim@example.com',         'Female', '2000-01-22', '2026-07-09', 'Social Media', 'Bronze',   4, 'Bangkok'),
(30, 'Elena Novak',       'elena.novak@example.com',       'Female', '1993-10-05', '2026-08-25', 'Email',        'Bronze',   2, 'London');

-- ----------------------------------------------------------------------------
-- 7. Orders (72 Orders spanning 2024-01 through 2026-10)
-- ----------------------------------------------------------------------------
INSERT INTO orders (order_id, customer_id, campaign_id, region_id, order_date, shipped_date, delivered_date, promised_days, order_status, payment_method, shipping_fee, order_discount) VALUES
-- 2024 Q1
(1,  1,  1,    3, '2024-01-10 10:15:00', '2024-01-11 14:00:00', '2024-01-14 16:30:00', 5, 'Delivered', 'UPI',            0.00, 15.00),
(2,  2,  1,    3, '2024-01-18 19:40:00', '2024-01-19 11:20:00', '2024-01-23 13:10:00', 5, 'Delivered', 'Credit Card',    0.00, 10.00),
(3,  3,  1,    1, '2024-01-25 09:05:00', '2024-01-26 16:45:00', '2024-01-30 15:00:00', 5, 'Delivered', 'Credit Card',    0.00, 20.00),
(4,  1,  1,    3, '2024-02-08 14:22:00', '2024-02-09 10:10:00', '2024-02-12 18:00:00', 5, 'Delivered', 'UPI',            4.00,  0.00),
(5,  4,  NULL, 2, '2024-02-14 16:50:00', '2024-02-15 09:30:00', '2024-02-22 14:15:00', 5, 'Delivered', 'Debit Card',     6.00,  0.00), -- late SLA
(6,  5,  NULL, 4, '2024-02-20 11:10:00', '2024-02-21 15:00:00', '2024-02-25 11:45:00', 5, 'Delivered', 'Digital Wallet', 5.00,  0.00),
(7,  3,  NULL, 1, '2024-03-03 20:15:00', '2024-03-04 12:30:00', '2024-03-08 17:20:00', 5, 'Delivered', 'Credit Card',    0.00,  0.00),
(8,  6,  2,    5, '2024-03-19 13:00:00', '2024-03-20 10:00:00', '2024-03-24 19:00:00', 5, 'Delivered', 'Credit Card',    0.00, 12.00),
(9,  7,  2,    3, '2024-03-27 17:45:00', NULL,                  NULL,                  5, 'Cancelled', 'COD',            0.00,  0.00),

-- 2024 Q2
(10, 2,  2,    3, '2024-04-06 12:30:00', '2024-04-07 14:20:00', '2024-04-11 10:40:00', 5, 'Delivered', 'UPI',            0.00,  8.00),
(11, 8,  2,    1, '2024-04-15 15:10:00', '2024-04-16 11:00:00', '2024-04-20 16:00:00', 5, 'Delivered', 'Debit Card',     5.00, 10.00),
(12, 4,  2,    2, '2024-05-02 18:05:00', '2024-05-03 13:15:00', '2024-05-07 12:00:00', 5, 'Returned',  'Credit Card',    0.00, 10.00),
(13, 9,  NULL, 2, '2024-05-20 09:40:00', '2024-05-22 10:00:00', '2024-05-29 15:30:00', 5, 'Delivered', 'Net Banking',    6.00,  0.00), -- late SLA
(14, 1,  NULL, 3, '2024-06-09 21:00:00', '2024-06-10 10:30:00', '2024-06-13 14:00:00', 5, 'Delivered', 'UPI',            0.00,  0.00),
(15, 10, NULL, 3, '2024-06-22 11:25:00', '2024-06-23 09:45:00', '2024-06-26 17:10:00', 5, 'Delivered', 'UPI',            0.00,  0.00),

-- 2024 Q3
(16, 3,  3,    1, '2024-07-08 13:50:00', '2024-07-09 15:00:00', '2024-07-13 11:30:00', 5, 'Delivered', 'Credit Card',    0.00, 25.00),
(17, 11, 3,    1, '2024-07-16 16:20:00', '2024-07-17 12:15:00', '2024-07-24 18:00:00', 5, 'Delivered', 'Debit Card',     7.00, 15.00), -- late SLA
(18, 10, 3,    3, '2024-07-29 10:05:00', '2024-07-30 10:00:00', '2024-08-02 15:40:00', 5, 'Delivered', 'UPI',            0.00, 15.00),
(19, 6,  3,    5, '2024-08-12 19:30:00', '2024-08-13 14:00:00', '2024-08-17 12:15:00', 5, 'Delivered', 'Digital Wallet', 0.00, 15.00),
(20, 12, 3,    4, '2024-08-25 14:40:00', '2024-08-26 09:20:00', '2024-08-30 16:00:00', 5, 'Delivered', 'Credit Card',    0.00, 10.00),
(21, 13, NULL, 3, '2024-09-10 11:15:00', '2024-09-11 11:30:00', '2024-09-15 14:50:00', 5, 'Delivered', 'COD',            4.00,  0.00),
(22, 8,  NULL, 1, '2024-09-22 17:00:00', '2024-09-23 13:00:00', '2024-09-27 11:00:00', 5, 'Delivered', 'Credit Card',    0.00,  0.00),

-- 2024 Q4
(23, 14, NULL, 2, '2024-10-18 12:45:00', '2024-10-19 10:00:00', '2024-10-23 16:20:00', 5, 'Delivered', 'Credit Card',    5.00,  0.00),
(24, 15, 4,    5, '2024-11-18 20:10:00', '2024-11-19 14:30:00', '2024-11-23 17:00:00', 5, 'Delivered', 'Credit Card',    0.00, 30.00),
(25, 1,  4,    3, '2024-11-24 22:15:00', '2024-11-25 11:00:00', '2024-11-28 15:45:00', 5, 'Delivered', 'UPI',            0.00, 25.00),
(26, 10, 4,    3, '2024-11-28 15:30:00', '2024-11-29 12:00:00', '2024-12-03 14:10:00', 5, 'Delivered', 'UPI',            0.00, 20.00),
(27, 3,  4,    1, '2024-11-29 11:00:00', '2024-11-30 16:00:00', '2024-12-06 18:20:00', 5, 'Delivered', 'Credit Card',    0.00, 35.00), -- late SLA
(28, 12, 4,    4, '2024-12-05 14:20:00', '2024-12-06 09:30:00', '2024-12-10 13:00:00', 5, 'Delivered', 'Digital Wallet', 0.00, 15.00),
(29, 5,  NULL, 4, '2024-12-19 16:05:00', NULL,                  NULL,                  5, 'Cancelled', 'COD',            0.00,  0.00),

-- 2025 Q1
(30, 16, NULL, 3, '2025-01-12 10:30:00', '2025-01-13 11:00:00', '2025-01-16 15:00:00', 5, 'Delivered', 'UPI',            0.00,  0.00),
(31, 2,  NULL, 3, '2025-01-25 18:45:00', '2025-01-26 10:20:00', '2025-01-30 14:30:00', 5, 'Delivered', 'Credit Card',    0.00,  0.00),
(32, 17, NULL, 1, '2025-02-18 13:15:00', '2025-02-19 14:00:00', '2025-02-23 12:10:00', 5, 'Delivered', 'Debit Card',     5.00,  0.00),
(33, 6,  5,    5, '2025-03-08 19:20:00', '2025-03-09 09:40:00', '2025-03-13 17:00:00', 5, 'Delivered', 'Credit Card',    0.00, 12.00),
(34, 18, 5,    2, '2025-03-26 15:50:00', '2025-03-27 12:10:00', '2025-03-31 16:40:00', 5, 'Delivered', 'Net Banking',    5.00, 10.00),

-- 2025 Q2
(35, 16, 5,    3, '2025-04-07 11:40:00', '2025-04-08 10:00:00', '2025-04-11 18:15:00', 5, 'Delivered', 'UPI',            0.00, 10.00),
(36, 19, 5,    3, '2025-04-18 21:05:00', '2025-04-20 14:00:00', '2025-04-27 19:00:00', 5, 'Returned',  'COD',            4.00,  8.00), -- late SLA + returned
(37, 4,  5,    2, '2025-05-04 14:15:00', '2025-05-05 11:30:00', '2025-05-09 13:45:00', 5, 'Delivered', 'Credit Card',    0.00, 15.00),
(38, 20, NULL, 5, '2025-05-24 17:30:00', '2025-05-25 13:00:00', '2025-05-29 16:00:00', 5, 'Delivered', 'Digital Wallet', 0.00,  0.00),
(39, 1,  NULL, 3, '2025-06-11 09:50:00', '2025-06-12 10:15:00', '2025-06-15 14:20:00', 5, 'Delivered', 'UPI',            0.00,  0.00),
(40, 21, NULL, 1, '2025-06-29 20:40:00', NULL,                  NULL,                  5, 'Cancelled', 'Debit Card',     0.00,  0.00),

-- 2025 Q3
(41, 10, 6,    3, '2025-07-10 12:10:00', '2025-07-11 11:20:00', '2025-07-14 15:30:00', 5, 'Delivered', 'UPI',            0.00, 18.00),
(42, 3,  6,    1, '2025-07-21 16:00:00', '2025-07-22 14:45:00', '2025-07-26 12:00:00', 5, 'Delivered', 'Credit Card',    0.00, 20.00),
(43, 22, 6,    4, '2025-08-10 13:35:00', '2025-08-11 09:50:00', '2025-08-15 17:15:00', 5, 'Delivered', 'Digital Wallet', 0.00, 12.00),
(44, 15, 6,    5, '2025-08-26 18:20:00', '2025-08-27 15:10:00', '2025-09-03 16:50:00', 5, 'Delivered', 'Credit Card',    0.00, 22.00), -- late SLA
(45, 13, 6,    3, '2025-09-09 10:45:00', '2025-09-10 12:00:00', '2025-09-14 14:00:00', 5, 'Delivered', 'UPI',            4.00,  8.00),
(46, 23, NULL, 3, '2025-09-20 15:15:00', '2025-09-21 10:30:00', '2025-09-24 16:40:00', 5, 'Delivered', 'UPI',            0.00,  0.00),

-- 2025 Q4
(47, 17, NULL, 1, '2025-10-14 19:05:00', '2025-10-15 13:30:00', '2025-10-19 11:50:00', 5, 'Delivered', 'Credit Card',    0.00,  0.00),
(48, 24, NULL, 2, '2025-11-08 11:30:00', '2025-11-09 10:00:00', '2025-11-16 14:20:00', 5, 'Returned',  'COD',            6.00,  0.00), -- late SLA + returned
(49, 1,  7,    3, '2025-11-22 21:40:00', '2025-11-23 11:00:00', '2025-11-26 16:00:00', 5, 'Delivered', 'UPI',            0.00, 30.00),
(50, 22, 7,    4, '2025-11-28 14:25:00', '2025-11-29 12:15:00', '2025-12-03 15:30:00', 5, 'Delivered', 'Credit Card',    0.00, 20.00),
(51, 16, 7,    3, '2025-12-04 17:10:00', '2025-12-05 10:40:00', '2025-12-08 18:10:00', 5, 'Delivered', 'UPI',            0.00, 15.00),
(52, 12, 7,    4, '2025-12-12 20:00:00', '2025-12-13 09:30:00', '2025-12-17 13:20:00', 5, 'Delivered', 'Digital Wallet', 0.00, 18.00),
(53, 18, 7,    2, '2025-12-20 12:50:00', '2025-12-21 15:00:00', '2025-12-27 17:00:00', 5, 'Delivered', 'Credit Card',    0.00, 15.00), -- late SLA

-- 2026 Q1–Q2
(54, 25, NULL, 3, '2026-01-16 11:15:00', '2026-01-17 10:00:00', '2026-01-20 15:40:00', 5, 'Delivered', 'UPI',            0.00,  0.00),
(55, 2,  NULL, 3, '2026-02-04 16:30:00', '2026-02-05 12:00:00', '2026-02-08 14:20:00', 5, 'Delivered', 'Credit Card',    0.00,  0.00),
(56, 26, NULL, 1, '2026-02-22 14:00:00', NULL,                  NULL,                  5, 'Cancelled', 'Debit Card',     0.00,  0.00),
(57, 10, NULL, 3, '2026-03-14 10:20:00', '2026-03-15 11:10:00', '2026-03-18 16:00:00', 5, 'Delivered', 'UPI',            0.00,  0.00),
(58, 27, NULL, 5, '2026-04-12 19:15:00', '2026-04-13 13:00:00', '2026-04-17 15:30:00', 5, 'Delivered', 'Digital Wallet', 0.00,  0.00),
(59, 25, NULL, 3, '2026-05-03 12:40:00', '2026-05-04 10:30:00', '2026-05-07 14:50:00', 5, 'Delivered', 'UPI',            0.00,  0.00),
(60, 28, NULL, 3, '2026-05-28 21:10:00', '2026-05-29 14:00:00', '2026-06-02 18:00:00', 5, 'Delivered', 'COD',            4.00,  0.00),
(61, 20, NULL, 5, '2026-06-19 15:25:00', '2026-06-20 11:45:00', '2026-06-24 13:30:00', 5, 'Delivered', 'Credit Card',    0.00,  0.00),

-- 2026 Q3–Q4 (Recent orders up to Oct 2026)
(62, 29, NULL, 4, '2026-07-15 13:50:00', '2026-07-16 10:15:00', '2026-07-20 12:40:00', 5, 'Delivered', 'Digital Wallet', 5.00,  0.00),
(63, 22, NULL, 4, '2026-08-05 18:10:00', '2026-08-06 09:40:00', '2026-08-10 15:10:00', 5, 'Delivered', 'Credit Card',    0.00,  0.00),
(64, 1,  8,    3, '2026-08-21 20:30:00', '2026-08-22 10:50:00', '2026-08-25 16:15:00', 5, 'Delivered', 'UPI',            0.00, 20.00),
(65, 30, 8,    2, '2026-09-02 11:45:00', '2026-09-03 14:20:00', '2026-09-07 17:00:00', 5, 'Delivered', 'Net Banking',    5.00, 10.00),
(66, 3,  8,    1, '2026-09-15 14:00:00', '2026-09-16 12:00:00', '2026-09-20 14:30:00', 5, 'Delivered', 'Credit Card',    0.00, 25.00),
(67, 16, 8,    3, '2026-09-24 17:35:00', '2026-09-25 09:30:00', '2026-09-28 15:20:00', 5, 'Delivered', 'UPI',            0.00, 15.00),
(68, 23, 8,    3, '2026-10-04 12:20:00', '2026-10-05 10:45:00', '2026-10-08 16:40:00', 5, 'Delivered', 'UPI',            0.00, 12.00),
(69, 10, 8,    3, '2026-10-12 19:50:00', '2026-10-13 11:15:00', '2026-10-16 14:10:00', 5, 'Delivered', 'UPI',            0.00, 18.00),
(70, 27, 8,    5, '2026-10-19 16:05:00', '2026-10-20 13:30:00', '2026-10-24 18:00:00', 5, 'Delivered', 'Digital Wallet', 0.00, 12.00),
(71, 25, 8,    3, '2026-10-25 10:30:00', '2026-10-26 11:00:00', NULL,                  5, 'Shipped',   'UPI',            0.00, 10.00),
(72, 1,  8,    3, '2026-10-28 21:15:00', NULL,                  NULL,                  5, 'Processing','Credit Card',    0.00, 15.00);

-- ----------------------------------------------------------------------------
-- 8. Order Items (142 line items — realistic multi-item baskets for MBA)
-- ----------------------------------------------------------------------------
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price, unit_cost, line_discount) VALUES
-- Order 1 (cust 1): Tech setup basket
(1,   1,  1,  1, 149.00, 82.00, 0.00),
(2,   1,  4,  1,  39.00, 19.00, 0.00),
-- Order 2 (cust 2): Skincare duo
(3,   2,  13, 1,  36.00, 11.00, 0.00),
(4,   2,  14, 1,  42.00, 13.00, 0.00),
-- Order 3 (cust 3): Desk bundle
(5,   3,  2,  1,  99.00, 58.00, 0.00),
(6,   3,  3,  1,  45.00, 21.00, 0.00),
(7,   3,  4,  1,  39.00, 19.00, 0.00),
-- Order 4 (cust 1): Books + notebook
(8,   4,  21, 1,  44.00, 18.00, 0.00),
(9,   4,  22, 2,  22.00,  7.50, 4.00),
-- Order 5 (cust 4): Fashion
(10,  5,  5,  1,  68.00, 28.00, 0.00),
(11,  5,  8,  1,  85.00, 34.00, 0.00),
-- Order 6 (cust 5): Fitness starter
(12,  6,  17, 1,  54.00, 22.00, 0.00),
(13,  6,  19, 1,  26.00,  9.00, 0.00),
-- Order 7 (cust 3): Home coffee + knife
(14,  7,  9,  1,  64.00, 29.00, 0.00),
(15,  7,  10, 1,  92.00, 42.00, 0.00),
-- Order 8 (cust 6): Skincare trio
(16,  8,  13, 1,  36.00, 11.00, 0.00),
(17,  8,  14, 1,  42.00, 13.00, 0.00),
(18,  8,  15, 1,  29.00,  9.50, 0.00),
-- Order 9 (cust 7 - Cancelled)
(19,  9,  6,  1,  79.00, 32.00, 0.00),
-- Order 10 (cust 2): Apparel
(20,  10, 7,  2,  38.00, 14.00, 5.00),
(21,  10, 15, 1,  29.00,  9.50, 0.00),
-- Order 11 (cust 8): Yoga + resistance + bottle
(22,  11, 17, 1,  54.00, 22.00, 0.00),
(23,  11, 18, 1,  28.00, 11.00, 0.00),
(24,  11, 19, 1,  26.00,  9.00, 0.00),
-- Order 12 (cust 4 - Returned)
(25,  12, 6,  1,  79.00, 32.00, 0.00),
(26,  12, 5,  1,  68.00, 28.00, 0.00),
-- Order 13 (cust 9)
(27,  13, 2,  1,  99.00, 58.00, 0.00),
(28,  13, 3,  1,  45.00, 21.00, 0.00),
-- Order 14 (cust 1)
(29,  14, 11, 1, 129.00, 68.00, 0.00),
(30,  14, 24, 1,  39.00, 16.00, 0.00),
-- Order 15 (cust 10)
(31,  15, 13, 1,  36.00, 11.00, 0.00),
(32,  15, 16, 1,  44.00, 15.00, 0.00),
(33,  15, 12, 1,  42.00, 18.00, 0.00),
-- Order 16 (cust 3)
(34,  16, 1,  1, 149.00, 82.00, 0.00),
(35,  16, 2,  1,  99.00, 58.00, 0.00),
(36,  16, 4,  1,  39.00, 19.00, 0.00),
-- Order 17 (cust 11)
(37,  17, 1,  1, 149.00, 82.00, 0.00),
(38,  17, 3,  1,  45.00, 21.00, 0.00),
-- Order 18 (cust 10)
(39,  18, 2,  1,  99.00, 58.00, 0.00),
(40,  18, 3,  1,  45.00, 21.00, 0.00),
(41,  18, 22, 1,  22.00,  7.50, 0.00),
-- Order 19 (cust 6)
(42,  19, 11, 1, 129.00, 68.00, 0.00),
(43,  19, 14, 1,  42.00, 13.00, 0.00),
-- Order 20 (cust 12)
(44,  20, 13, 1,  36.00, 11.00, 0.00),
(45,  20, 14, 1,  42.00, 13.00, 0.00),
(46,  20, 17, 1,  54.00, 22.00, 0.00),
-- Order 21 (cust 13)
(47,  21, 7,  1,  38.00, 14.00, 0.00),
(48,  21, 19, 1,  26.00,  9.00, 0.00),
-- Order 22 (cust 8)
(49,  22, 9,  1,  64.00, 29.00, 0.00),
(50,  22, 12, 1,  42.00, 18.00, 0.00),
-- Order 23 (cust 14)
(51,  23, 5,  1,  68.00, 28.00, 0.00),
(52,  23, 16, 1,  44.00, 15.00, 0.00),
-- Order 24 (cust 15)
(53,  24, 1,  1, 149.00, 82.00, 0.00),
(54,  24, 11, 1, 129.00, 68.00, 0.00),
-- Order 25 (cust 1)
(55,  25, 2,  1,  99.00, 58.00, 0.00),
(56,  25, 3,  1,  45.00, 21.00, 0.00),
(57,  25, 10, 1,  92.00, 42.00, 0.00),
-- Order 26 (cust 10)
(58,  26, 1,  1, 149.00, 82.00, 0.00),
(59,  26, 8,  1,  85.00, 34.00, 0.00),
-- Order 27 (cust 3)
(60,  27, 11, 1, 129.00, 68.00, 0.00),
(61,  27, 10, 1,  92.00, 42.00, 0.00),
(62,  27, 21, 1,  44.00, 18.00, 0.00),
-- Order 28 (cust 12)
(63,  28, 5,  1,  68.00, 28.00, 0.00),
(64,  28, 13, 1,  36.00, 11.00, 0.00),
(65,  28, 15, 1,  29.00,  9.50, 0.00),
-- Order 29 (cust 5 - Cancelled)
(66,  29, 20, 1,  46.00, 18.00, 0.00),
-- Order 30 (cust 16)
(67,  30, 21, 1,  44.00, 18.00, 0.00),
(68,  30, 24, 1,  39.00, 16.00, 0.00),
(69,  30, 22, 1,  22.00,  7.50, 0.00),
-- Order 31 (cust 2)
(70,  31, 9,  1,  64.00, 29.00, 0.00),
(71,  31, 12, 1,  42.00, 18.00, 0.00),
-- Order 32 (cust 17)
(72,  32, 2,  1,  99.00, 58.00, 0.00),
(73,  32, 4,  1,  39.00, 19.00, 0.00),
-- Order 33 (cust 6)
(74,  33, 13, 1,  36.00, 11.00, 0.00),
(75,  33, 14, 1,  42.00, 13.00, 0.00),
(76,  33, 16, 1,  44.00, 15.00, 0.00),
-- Order 34 (cust 18)
(77,  34, 17, 1,  54.00, 22.00, 0.00),
(78,  34, 18, 1,  28.00, 11.00, 0.00),
-- Order 35 (cust 16)
(79,  35, 13, 1,  36.00, 11.00, 0.00),
(80,  35, 15, 1,  29.00,  9.50, 0.00),
-- Order 36 (cust 19 - Returned)
(81,  36, 17, 1,  54.00, 22.00, 0.00),
(82,  36, 20, 1,  46.00, 18.00, 0.00),
-- Order 37 (cust 4)
(83,  37, 13, 1,  36.00, 11.00, 0.00),
(84,  37, 14, 1,  42.00, 13.00, 0.00),
(85,  37, 15, 1,  29.00,  9.50, 0.00),
-- Order 38 (cust 20)
(86,  38, 16, 1,  44.00, 15.00, 0.00),
(87,  38, 5,  1,  68.00, 28.00, 0.00),
-- Order 39 (cust 1)
(88,  39, 3,  1,  45.00, 21.00, 0.00),
(89,  39, 23, 1,  32.00, 12.00, 0.00),
-- Order 40 (cust 21 - Cancelled)
(90,  40, 8,  1,  85.00, 34.00, 0.00),
-- Order 41 (cust 10)
(91,  41, 17, 1,  54.00, 22.00, 0.00),
(92,  41, 18, 1,  28.00, 11.00, 0.00),
(93,  41, 19, 1,  26.00,  9.00, 0.00),
-- Order 42 (cust 3)
(94,  42, 8,  1,  85.00, 34.00, 0.00),
(95,  42, 19, 2,  26.00,  9.00, 4.00),
-- Order 43 (cust 22)
(96,  43, 17, 1,  54.00, 22.00, 0.00),
(97,  43, 20, 1,  46.00, 18.00, 0.00),
-- Order 44 (cust 15)
(98,  44, 6,  1,  79.00, 32.00, 0.00),
(99,  44, 7,  2,  38.00, 14.00, 0.00),
-- Order 45 (cust 13)
(100, 45, 18, 1,  28.00, 11.00, 0.00),
(101, 45, 19, 1,  26.00,  9.00, 0.00),
-- Order 46 (cust 23)
(102, 46, 21, 1,  44.00, 18.00, 0.00),
(103, 46, 24, 1,  39.00, 16.00, 0.00),
-- Order 47 (cust 17)
(104, 47, 1,  1, 149.00, 82.00, 0.00),
-- Order 48 (cust 24 - Returned)
(105, 48, 6,  1,  79.00, 32.00, 0.00),
-- Order 49 (cust 1)
(106, 49, 1,  1, 149.00, 82.00, 0.00),
(107, 49, 2,  1,  99.00, 58.00, 0.00),
(108, 49, 4,  1,  39.00, 19.00, 0.00),
-- Order 50 (cust 22)
(109, 50, 13, 1,  36.00, 11.00, 0.00),
(110, 50, 14, 1,  42.00, 13.00, 0.00),
(111, 50, 8,  1,  85.00, 34.00, 0.00),
-- Order 51 (cust 16)
(112, 51, 9,  1,  64.00, 29.00, 0.00),
(113, 51, 10, 1,  92.00, 42.00, 0.00),
-- Order 52 (cust 12)
(114, 52, 5,  1,  68.00, 28.00, 0.00),
(115, 52, 16, 1,  44.00, 15.00, 0.00),
-- Order 53 (cust 18)
(116, 53, 11, 1, 129.00, 68.00, 0.00),
-- Order 54 (cust 25)
(117, 54, 21, 1,  44.00, 18.00, 0.00),
(118, 54, 22, 1,  22.00,  7.50, 0.00),
(119, 54, 23, 1,  32.00, 12.00, 0.00),
-- Order 55 (cust 2)
(120, 55, 13, 1,  36.00, 11.00, 0.00),
(121, 55, 15, 1,  29.00,  9.50, 0.00),
-- Order 56 (cust 26 - Cancelled)
(122, 56, 2,  1,  99.00, 58.00, 0.00),
-- Order 57 (cust 10)
(123, 57, 9,  1,  64.00, 29.00, 0.00),
(124, 57, 12, 1,  42.00, 18.00, 0.00),
-- Order 58 (cust 27)
(125, 58, 13, 1,  36.00, 11.00, 0.00),
(126, 58, 14, 1,  42.00, 13.00, 0.00),
-- Order 59 (cust 25)
(127, 59, 17, 1,  54.00, 22.00, 0.00),
(128, 59, 19, 1,  26.00,  9.00, 0.00),
-- Order 60 (cust 28)
(129, 60, 7,  1,  38.00, 14.00, 0.00),
(130, 60, 24, 1,  39.00, 16.00, 0.00),
-- Order 61 (cust 20)
(131, 61, 14, 1,  42.00, 13.00, 0.00),
(132, 61, 15, 1,  29.00,  9.50, 0.00),
-- Order 62 (cust 29)
(133, 62, 13, 1,  36.00, 11.00, 0.00),
(134, 62, 18, 1,  28.00, 11.00, 0.00),
-- Order 63 (cust 22)
(135, 63, 1,  1, 149.00, 82.00, 0.00),
(136, 63, 3,  1,  45.00, 21.00, 0.00),
-- Order 64 (cust 1)
(137, 64, 2,  1,  99.00, 58.00, 0.00),
(138, 64, 3,  1,  45.00, 21.00, 0.00),
(139, 64, 4,  1,  39.00, 19.00, 0.00),
-- Order 65 (cust 30)
(140, 65, 22, 2,  22.00,  7.50, 0.00),
(141, 65, 23, 1,  32.00, 12.00, 0.00),
(142, 65, 24, 1,  39.00, 16.00, 0.00),
-- Order 66 (cust 3)
(143, 66, 1,  1, 149.00, 82.00, 0.00),
(144, 66, 4,  1,  39.00, 19.00, 0.00),
(145, 66, 21, 1,  44.00, 18.00, 0.00),
-- Order 67 (cust 16)
(146, 67, 2,  1,  99.00, 58.00, 0.00),
(147, 67, 4,  1,  39.00, 19.00, 0.00),
-- Order 68 (cust 23)
(148, 68, 21, 1,  44.00, 18.00, 0.00),
(149, 68, 22, 1,  22.00,  7.50, 0.00),
(150, 68, 24, 1,  39.00, 16.00, 0.00),
-- Order 69 (cust 10)
(151, 69, 13, 1,  36.00, 11.00, 0.00),
(152, 69, 14, 1,  42.00, 13.00, 0.00),
(153, 69, 10, 1,  92.00, 42.00, 0.00),
-- Order 70 (cust 27)
(154, 70, 5,  1,  68.00, 28.00, 0.00),
(155, 70, 16, 1,  44.00, 15.00, 0.00),
-- Order 71 (cust 25 - Shipped)
(156, 71, 2,  1,  99.00, 58.00, 0.00),
(157, 71, 22, 1,  22.00,  7.50, 0.00),
-- Order 72 (cust 1 - Processing)
(158, 72, 1,  1, 149.00, 82.00, 0.00),
(159, 72, 23, 1,  32.00, 12.00, 0.00);

-- ----------------------------------------------------------------------------
-- 9. Returns (10 Return records tied strictly to matching order_id + order_item_id)
-- ----------------------------------------------------------------------------
INSERT INTO returns (return_id, order_id, order_item_id, return_date, return_reason, refund_amount, restocked) VALUES
(1,  5,  11,  '2024-02-26', 'Late Delivery',         85.00, TRUE),
(2,  12, 25,  '2024-05-11', 'Size / Fit Issue',      74.00, TRUE),
(3,  12, 26,  '2024-05-11', 'Size / Fit Issue',      63.00, TRUE),
(4,  17, 37,  '2024-07-28', 'Defective / Damaged',  149.00, FALSE),
(5,  27, 60,  '2024-12-10', 'Late Delivery',        129.00, TRUE),
(6,  36, 81,  '2025-05-01', 'Customer Changed Mind', 50.00, TRUE),
(7,  36, 82,  '2025-05-01', 'Defective / Damaged',   42.00, FALSE),
(8,  44, 98,  '2025-09-07', 'Size / Fit Issue',      79.00, TRUE),
(9,  48, 105, '2025-11-20', 'Not as Described',      79.00, TRUE),
(10, 53, 116, '2025-12-30', 'Late Delivery',        114.00, TRUE);

