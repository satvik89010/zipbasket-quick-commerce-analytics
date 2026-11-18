-- =========================================================
-- ZipBasket Quick-Commerce Analytics
-- 01_create_and_load_tables.sql
-- Creates the zipbasket database and its 7 tables, then loads
-- the cleaned CSV files (exported from the Phase 1 Excel workbook).
-- Tool: MySQL 8.0 (Workbench)
-- Note: CSV files must sit in the secure_file_priv folder
--       (C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/).
-- =========================================================

CREATE DATABASE IF NOT EXISTS zipbasket;
USE zipbasket;

-- ---------------------------------------------------------
-- 1. Create tables
--    (parent tables first, so the foreign keys work)
-- ---------------------------------------------------------

CREATE TABLE stores (
  store_id        VARCHAR(10) PRIMARY KEY,
  store_name      VARCHAR(100),
  city_name       VARCHAR(50),
  area            VARCHAR(50),
  opened_on       DATE,
  store_size_sqft INT,
  store_manager   VARCHAR(100)
);

CREATE TABLE riders (
  rider_id        VARCHAR(10) PRIMARY KEY,
  rider_name      VARCHAR(100),
  store_id        VARCHAR(10),
  vehicle_type    VARCHAR(30),
  employment_type VARCHAR(30),
  joining_date    DATE
);

CREATE TABLE products (
  product_id    VARCHAR(10) PRIMARY KEY,
  product_name  VARCHAR(50),
  category      VARCHAR(50),
  brand         VARCHAR(20),
  mrp           INT,
  cost_price    DECIMAL(10,2),
  is_perishable VARCHAR(10)
);

CREATE TABLE customer (
  customer_id   VARCHAR(10) PRIMARY KEY,
  customer_name VARCHAR(100),
  email         VARCHAR(150),
  phone         VARCHAR(15),
  city          VARCHAR(50),
  gender        VARCHAR(20),
  date_of_birth DATE,
  sign_up_date  DATE
);

CREATE TABLE orders (
  order_id        VARCHAR(15) PRIMARY KEY,
  customer_id     VARCHAR(10),
  store_id        VARCHAR(10),
  rider_id        VARCHAR(10),
  order_ts        DATETIME,
  picked_ts       DATETIME,
  delivered_ts    DATETIME,
  promised_mins   INT,
  order_status    VARCHAR(20),
  payment_method  VARCHAR(20),
  coupon_code     VARCHAR(20),
  delivery_fee    INT,
  distance_km     DECIMAL(6,2),
  customer_rating INT,
  is_raining      VARCHAR(5),
  FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
  FOREIGN KEY (store_id)    REFERENCES stores(store_id),
  FOREIGN KEY (rider_id)    REFERENCES riders(rider_id)
);

CREATE TABLE order_items (
  order_item_id      INT PRIMARY KEY,
  order_id           VARCHAR(20),
  product_id         VARCHAR(10),
  quantity           INT,
  unit_selling_price DECIMAL(10,2),
  discount           INT,
  FOREIGN KEY (order_id)   REFERENCES orders(order_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE targets (
  store_id      VARCHAR(10),
  store_name    VARCHAR(100),
  month         VARCHAR(10),
  target_orders INT,
  FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

-- ---------------------------------------------------------
-- 2. Placeholder rows for unknown IDs found in the raw data
--    (P9999 / P0000 products, DS999 / DS000 stores), so the
--    foreign keys accept those rows. They are flagged and
--    fixed later in SQL.
-- ---------------------------------------------------------

INSERT INTO products (product_id, product_name, category)
VALUES ('P9999', 'Unknown product', 'Unknown'),
       ('P0000', 'Unknown product', 'Unknown');

INSERT INTO stores (store_id, store_name, city_name)
VALUES ('DS999', 'Unknown store', 'Unknown'),
       ('DS000', 'Unknown store', 'Unknown');

-- ---------------------------------------------------------
-- 3. Load the cleaned CSV files
--    Blank values are turned into NULL with NULLIF.
-- ---------------------------------------------------------

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/store.csv'
INTO TABLE stores CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(store_id, store_name, city_name, area, @op, store_size_sqft, store_manager)
SET opened_on = NULLIF(@op, '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/rider.csv'
INTO TABLE riders CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(rider_id, rider_name, store_id, vehicle_type, employment_type, @jd)
SET joining_date = NULLIF(@jd, '');

-- IGNORE skips the duplicate P1011 row
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
IGNORE INTO TABLE products CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(product_id, product_name, category, brand, mrp, @cp, is_perishable)
SET cost_price = NULLIF(@cp, '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customer.csv'
INTO TABLE customer CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(customer_id, customer_name, @em, @ph, city, gender, @dob, @sd)
SET email         = NULLIF(@em, ''),
    phone         = NULLIF(@ph, ''),
    date_of_birth = NULLIF(@dob, ''),
    sign_up_date  = NULLIF(@sd, '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv'
INTO TABLE orders CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(order_id, customer_id, store_id, @rid, order_ts, @pt, @dt, promised_mins, order_status,
 payment_method, @cc, delivery_fee, @dist, @rat, is_raining)
SET rider_id        = NULLIF(@rid, ''),
    picked_ts       = NULLIF(@pt, ''),
    delivered_ts    = NULLIF(@dt, ''),
    coupon_code     = NULLIF(@cc, ''),
    distance_km     = NULLIF(@dist, ''),
    customer_rating = NULLIF(@rat, '');

-- IGNORE skips exact duplicate order_item rows
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv'
IGNORE INTO TABLE order_items CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(order_item_id, order_id, product_id, quantity, @usp, discount)
SET unit_selling_price = NULLIF(@usp, '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/targets.csv'
INTO TABLE targets CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(store_id, store_name, month, @t)
SET target_orders = NULLIF(@t, '');

-- ---------------------------------------------------------
-- 4. Check: row count of every table
-- ---------------------------------------------------------

SELECT 'stores' AS table_name, COUNT(*) AS total_rows FROM stores
UNION ALL SELECT 'riders',      COUNT(*) FROM riders
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'customers',   COUNT(*) FROM customer
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'targets',     COUNT(*) FROM targets;
