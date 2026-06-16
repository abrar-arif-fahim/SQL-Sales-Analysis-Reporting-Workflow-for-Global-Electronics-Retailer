-- 02_load_data.sql
-- Purpose: Load CSV files from data/raw into MySQL tables.
-- Run after 01_create_tables.sql.
--
-- Important:
-- 1. Enable local infile in your MySQL client/session if needed:
--    SET GLOBAL local_infile = 1;
-- 2. Run the client with local infile enabled:
--    mysql --local-infile=1 -u root -p electronics_retailer
-- 3. Run this script from the project root so relative paths resolve correctly.

USE electronics_retailer;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE sales;
TRUNCATE TABLE customers;
TRUNCATE TABLE products;
TRUNCATE TABLE stores;
TRUNCATE TABLE exchange_rates;
TRUNCATE TABLE data_dictionary;

SET FOREIGN_KEY_CHECKS = 1;

LOAD DATA LOCAL INFILE 'data/raw/Customers.csv'
INTO TABLE customers
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@customer_key, @gender, @customer_name, @city, @state_code, @state_name, @zip_code, @country, @continent, @birthday)
SET
    customer_key = CAST(NULLIF(TRIM(@customer_key), '') AS UNSIGNED),
    gender = NULLIF(TRIM(@gender), ''),
    customer_name = NULLIF(TRIM(@customer_name), ''),
    city = NULLIF(TRIM(@city), ''),
    state_code = NULLIF(TRIM(@state_code), ''),
    state_name = NULLIF(TRIM(@state_name), ''),
    zip_code = NULLIF(TRIM(@zip_code), ''),
    country = NULLIF(TRIM(@country), ''),
    continent = NULLIF(TRIM(@continent), ''),
    birthday = STR_TO_DATE(NULLIF(TRIM(@birthday), ''), '%c/%e/%Y');

LOAD DATA LOCAL INFILE 'data/raw/Products.csv'
INTO TABLE products
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@product_key, @product_name, @brand, @color, @unit_cost_usd, @unit_price_usd, @subcategory_key, @subcategory, @category_key, @category)
SET
    product_key = CAST(NULLIF(TRIM(@product_key), '') AS UNSIGNED),
    product_name = NULLIF(TRIM(@product_name), ''),
    brand = NULLIF(TRIM(@brand), ''),
    color = NULLIF(TRIM(@color), ''),
    unit_cost_usd = CAST(NULLIF(REPLACE(REPLACE(TRIM(@unit_cost_usd), '$', ''), ',', ''), '') AS DECIMAL(12,2)),
    unit_price_usd = CAST(NULLIF(REPLACE(REPLACE(TRIM(@unit_price_usd), '$', ''), ',', ''), '') AS DECIMAL(12,2)),
    subcategory_key = NULLIF(TRIM(@subcategory_key), ''),
    subcategory = NULLIF(TRIM(@subcategory), ''),
    category_key = NULLIF(TRIM(@category_key), ''),
    category = NULLIF(TRIM(@category), '');

LOAD DATA LOCAL INFILE 'data/raw/Stores.csv'
INTO TABLE stores
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@store_key, @country, @state_name, @square_meters, @open_date)
SET
    store_key = CAST(NULLIF(TRIM(@store_key), '') AS UNSIGNED),
    country = NULLIF(TRIM(@country), ''),
    state_name = NULLIF(TRIM(@state_name), ''),
    square_meters = CAST(NULLIF(TRIM(@square_meters), '') AS UNSIGNED),
    open_date = STR_TO_DATE(NULLIF(TRIM(@open_date), ''), '%c/%e/%Y');

LOAD DATA LOCAL INFILE 'data/raw/Exchange_Rates.csv'
INTO TABLE exchange_rates
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@rate_date, @currency_code, @exchange_rate)
SET
    rate_date = STR_TO_DATE(NULLIF(TRIM(@rate_date), ''), '%c/%e/%Y'),
    currency_code = NULLIF(TRIM(@currency_code), ''),
    exchange_rate = CAST(NULLIF(REPLACE(TRIM(@exchange_rate), ',', ''), '') AS DECIMAL(12,6));

LOAD DATA LOCAL INFILE 'data/raw/Sales.csv'
INTO TABLE sales
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@order_number, @line_item, @order_date, @delivery_date, @customer_key, @store_key, @product_key, @quantity, @currency_code)
SET
    order_number = CAST(NULLIF(TRIM(@order_number), '') AS UNSIGNED),
    line_item = CAST(NULLIF(TRIM(@line_item), '') AS UNSIGNED),
    order_date = STR_TO_DATE(NULLIF(TRIM(@order_date), ''), '%c/%e/%Y'),
    delivery_date = STR_TO_DATE(NULLIF(TRIM(@delivery_date), ''), '%c/%e/%Y'),
    customer_key = CAST(NULLIF(TRIM(@customer_key), '') AS UNSIGNED),
    store_key = CAST(NULLIF(TRIM(@store_key), '') AS UNSIGNED),
    product_key = CAST(NULLIF(TRIM(@product_key), '') AS UNSIGNED),
    quantity = CAST(NULLIF(TRIM(@quantity), '') AS UNSIGNED),
    currency_code = NULLIF(TRIM(@currency_code), '');

LOAD DATA LOCAL INFILE 'data/raw/Data_Dictionary.csv'
INTO TABLE data_dictionary
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@source_table, @source_field, @field_description)
SET
    source_table = NULLIF(TRIM(@source_table), ''),
    source_field = NULLIF(TRIM(@source_field), ''),
    field_description = NULLIF(TRIM(@field_description), '');

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'stores', COUNT(*) FROM stores
UNION ALL SELECT 'exchange_rates', COUNT(*) FROM exchange_rates
UNION ALL SELECT 'sales', COUNT(*) FROM sales
UNION ALL SELECT 'data_dictionary', COUNT(*) FROM data_dictionary;
