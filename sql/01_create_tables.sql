-- 01_create_tables.sql
-- Project: SQL Sales Analysis & Reporting Workflow for Global Electronics Retailer
-- Purpose: Create clean MySQL tables for the raw retail dataset.

CREATE DATABASE IF NOT EXISTS electronics_retailer;
USE electronics_retailer;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS stores;
DROP TABLE IF EXISTS exchange_rates;
DROP TABLE IF EXISTS data_dictionary;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE customers (
    customer_key INT NOT NULL COMMENT 'Primary key identifying each customer',
    gender VARCHAR(20) NULL COMMENT 'Customer gender from source data',
    customer_name VARCHAR(150) NULL COMMENT 'Customer full name',
    city VARCHAR(100) NULL COMMENT 'Customer city',
    state_code VARCHAR(20) NULL COMMENT 'Abbreviated state or region code',
    state_name VARCHAR(100) NULL COMMENT 'Full state or region name',
    zip_code VARCHAR(20) NULL COMMENT 'Postal or zip code',
    country VARCHAR(100) NULL COMMENT 'Customer country',
    continent VARCHAR(100) NULL COMMENT 'Customer continent',
    birthday DATE NULL COMMENT 'Customer birth date',
    PRIMARY KEY (customer_key)
) COMMENT = 'Customer master data loaded from Customers.csv';

CREATE TABLE products (
    product_key INT NOT NULL COMMENT 'Primary key identifying each product',
    product_name VARCHAR(255) NOT NULL COMMENT 'Product display name',
    brand VARCHAR(100) NULL COMMENT 'Product brand',
    color VARCHAR(50) NULL COMMENT 'Product color',
    unit_cost_usd DECIMAL(12,2) NULL COMMENT 'Unit product cost in USD',
    unit_price_usd DECIMAL(12,2) NULL COMMENT 'Unit product selling price in USD',
    subcategory_key VARCHAR(20) NULL COMMENT 'Product subcategory key from source',
    subcategory VARCHAR(100) NULL COMMENT 'Product subcategory name',
    category_key VARCHAR(20) NULL COMMENT 'Product category key from source',
    category VARCHAR(100) NULL COMMENT 'Product category name',
    PRIMARY KEY (product_key)
) COMMENT = 'Product master data loaded from Products.csv';

CREATE TABLE stores (
    store_key INT NOT NULL COMMENT 'Primary key identifying each physical store',
    country VARCHAR(100) NULL COMMENT 'Store country',
    state_name VARCHAR(100) NULL COMMENT 'Store state or region',
    square_meters INT NULL COMMENT 'Store footprint in square meters',
    open_date DATE NULL COMMENT 'Date the store opened',
    PRIMARY KEY (store_key)
) COMMENT = 'Store master data loaded from Stores.csv. Sales store_key 0 represents online sales.';

CREATE TABLE exchange_rates (
    rate_date DATE NOT NULL COMMENT 'Exchange rate effective date',
    currency_code CHAR(3) NOT NULL COMMENT 'Currency code',
    exchange_rate DECIMAL(12,6) NOT NULL COMMENT 'Exchange rate compared with USD from source data',
    PRIMARY KEY (rate_date, currency_code)
) COMMENT = 'Daily exchange rates loaded from Exchange_Rates.csv';

CREATE TABLE sales (
    order_number INT NOT NULL COMMENT 'Order identifier',
    line_item INT NOT NULL COMMENT 'Line number within the order',
    order_date DATE NOT NULL COMMENT 'Date the order was placed',
    delivery_date DATE NULL COMMENT 'Date the order was delivered; blank means not delivered or unavailable',
    customer_key INT NOT NULL COMMENT 'Customer who placed the order',
    store_key INT NOT NULL COMMENT 'Store that processed the order. Value 0 represents online sales.',
    product_key INT NOT NULL COMMENT 'Product purchased',
    quantity INT NOT NULL COMMENT 'Units purchased on the order line',
    currency_code CHAR(3) NOT NULL COMMENT 'Currency used for the transaction',
    PRIMARY KEY (order_number, line_item),
    INDEX idx_sales_order_date (order_date),
    INDEX idx_sales_customer_key (customer_key),
    INDEX idx_sales_product_key (product_key),
    INDEX idx_sales_store_key (store_key),
    INDEX idx_sales_currency_date (currency_code, order_date)
) COMMENT = 'Sales order line data loaded from Sales.csv';

CREATE TABLE data_dictionary (
    source_table VARCHAR(100) NOT NULL COMMENT 'Original source table name',
    source_field VARCHAR(100) NOT NULL COMMENT 'Original source field name',
    field_description TEXT NULL COMMENT 'Business description of the field',
    PRIMARY KEY (source_table, source_field)
) COMMENT = 'Source data dictionary loaded from Data_Dictionary.csv';
