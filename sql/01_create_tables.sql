-- ============================================================
-- 01_create_tables.sql
-- Cria o schema relacional do e-commerce (PostgreSQL)
-- ============================================================

DROP TABLE IF EXISTS order_reviews CASCADE;
DROP TABLE IF EXISTS order_payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS category_translation CASCADE;
DROP TABLE IF EXISTS geolocation CASCADE;

CREATE TABLE customers (
    customer_id             VARCHAR(40) PRIMARY KEY,
    customer_unique_id      VARCHAR(40) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city           VARCHAR(80),
    customer_state          CHAR(2)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat          DECIMAL(10, 7),
    geolocation_lng          DECIMAL(10, 7),
    geolocation_city        VARCHAR(80),
    geolocation_state       CHAR(2)
);

CREATE TABLE orders (
    order_id                VARCHAR(40) PRIMARY KEY,
    customer_id             VARCHAR(40) REFERENCES customers (customer_id),
    order_status            VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at       TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date DATE
);

CREATE TABLE order_items (
    order_id                VARCHAR(40) REFERENCES orders (order_id),
    order_item_id           INT,
    product_id              VARCHAR(40),
    seller_id               VARCHAR(40),
    shipping_limit_date     TIMESTAMP,
    price                   DECIMAL(12, 2) CHECK (price >= 0),
    freight_value           DECIMAL(12, 2) CHECK (freight_value >= 0),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id                VARCHAR(40) REFERENCES orders (order_id),
    payment_sequential      INT,
    payment_type            VARCHAR(20),
    payment_installments    INT,
    payment_value           DECIMAL(12, 2),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE order_reviews (
    review_id               VARCHAR(40),
    order_id                VARCHAR(40) REFERENCES orders (order_id),
    review_score            INT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE TABLE products (
    product_id              VARCHAR(40) PRIMARY KEY,
    product_category_name   VARCHAR(60),
    product_name_lenght     DECIMAL(6, 2),
    product_description_lenght DECIMAL(8, 2),
    product_photos_qty      DECIMAL(6, 2),
    product_weight_g        DECIMAL(10, 2),
    product_length_cm       DECIMAL(8, 2),
    product_height_cm       DECIMAL(8, 2),
    product_width_cm        DECIMAL(8, 2)
);

CREATE TABLE sellers (
    seller_id               VARCHAR(40) PRIMARY KEY,
    seller_zip_code_prefix  INT,
    seller_city             VARCHAR(80),
    seller_state            CHAR(2)
);

CREATE TABLE category_translation (
    product_category_name       VARCHAR(60) PRIMARY KEY,
    product_category_name_english VARCHAR(60)
);

CREATE INDEX idx_orders_customer        ON orders (customer_id);
CREATE INDEX idx_orders_purchase_ts     ON orders (order_purchase_timestamp);
CREATE INDEX idx_items_product          ON order_items (product_id);
CREATE INDEX idx_items_seller           ON order_items (seller_id);
CREATE INDEX idx_reviews_order          ON order_reviews (order_id);
CREATE INDEX idx_geolocation_zip_prefix ON geolocation (geolocation_zip_code_prefix);

-- ------------------------------------------------------------
-- Carga a partir dos CSVs em data/raw/ (ajuste o caminho/encoding)
-- ------------------------------------------------------------
-- Exemplo (metadado \copy do psql; UTF-8 com BOM exige encoding adequado):
-- \copy customers               FROM 'data/raw/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
-- \copy geolocation             FROM 'data/raw/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
-- \copy orders                  FROM 'data/raw/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
-- \copy order_items             FROM 'data/raw/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
-- \copy order_payments          FROM 'data/raw/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
-- \copy order_reviews           FROM 'data/raw/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
-- \copy products                FROM 'data/raw/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
-- \copy sellers                 FROM 'data/raw/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
-- \copy category_translation    FROM 'data/raw/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
