-- 03_data_quality_checks.sql
-- Purpose: Run validation checks after loading the raw tables.
-- Run after 02_load_data.sql.

USE electronics_retailer;

-- 1. Row counts by table
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'stores', COUNT(*) FROM stores
UNION ALL SELECT 'exchange_rates', COUNT(*) FROM exchange_rates
UNION ALL SELECT 'sales', COUNT(*) FROM sales
UNION ALL SELECT 'data_dictionary', COUNT(*) FROM data_dictionary;

-- 2. Duplicate primary key checks
SELECT 'customers.customer_key' AS check_name, customer_key, COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

SELECT 'products.product_key' AS check_name, product_key, COUNT(*) AS duplicate_count
FROM products
GROUP BY product_key
HAVING COUNT(*) > 1;

SELECT 'stores.store_key' AS check_name, store_key, COUNT(*) AS duplicate_count
FROM stores
GROUP BY store_key
HAVING COUNT(*) > 1;

SELECT 'exchange_rates.rate_date_currency_code' AS check_name, rate_date, currency_code, COUNT(*) AS duplicate_count
FROM exchange_rates
GROUP BY rate_date, currency_code
HAVING COUNT(*) > 1;

SELECT 'sales.order_number_line_item' AS check_name, order_number, line_item, COUNT(*) AS duplicate_count
FROM sales
GROUP BY order_number, line_item
HAVING COUNT(*) > 1;

-- 3. Missing value checks for critical fields
SELECT 'customers' AS table_name,
       SUM(customer_key IS NULL) AS missing_customer_key,
       SUM(customer_name IS NULL) AS missing_customer_name,
       SUM(country IS NULL) AS missing_country,
       SUM(birthday IS NULL) AS missing_birthday
FROM customers;

SELECT 'products' AS table_name,
       SUM(product_key IS NULL) AS missing_product_key,
       SUM(product_name IS NULL) AS missing_product_name,
       SUM(brand IS NULL) AS missing_brand,
       SUM(unit_cost_usd IS NULL) AS missing_unit_cost_usd,
       SUM(unit_price_usd IS NULL) AS missing_unit_price_usd
FROM products;

SELECT 'stores' AS table_name,
       SUM(store_key IS NULL) AS missing_store_key,
       SUM(country IS NULL) AS missing_country,
       SUM(square_meters IS NULL) AS missing_square_meters,
       SUM(open_date IS NULL) AS missing_open_date
FROM stores;

SELECT 'sales' AS table_name,
       SUM(order_number IS NULL) AS missing_order_number,
       SUM(line_item IS NULL) AS missing_line_item,
       SUM(order_date IS NULL) AS missing_order_date,
       SUM(delivery_date IS NULL) AS missing_delivery_date,
       SUM(customer_key IS NULL) AS missing_customer_key,
       SUM(store_key IS NULL) AS missing_store_key,
       SUM(product_key IS NULL) AS missing_product_key,
       SUM(quantity IS NULL) AS missing_quantity,
       SUM(currency_code IS NULL) AS missing_currency_code
FROM sales;

-- 4. Invalid value checks
SELECT 'products_negative_or_zero_price_cost' AS check_name, COUNT(*) AS issue_count
FROM products
WHERE unit_cost_usd < 0 OR unit_price_usd < 0 OR unit_price_usd < unit_cost_usd;

SELECT 'sales_non_positive_quantity' AS check_name, COUNT(*) AS issue_count
FROM sales
WHERE quantity <= 0;

SELECT 'stores_non_positive_square_meters' AS check_name, COUNT(*) AS issue_count
FROM stores
WHERE square_meters <= 0;

SELECT 'exchange_rates_non_positive_rate' AS check_name, COUNT(*) AS issue_count
FROM exchange_rates
WHERE exchange_rate <= 0;

SELECT 'unexpected_sales_currency_codes' AS check_name, currency_code, COUNT(*) AS row_count
FROM sales
WHERE currency_code NOT IN (SELECT DISTINCT currency_code FROM exchange_rates)
GROUP BY currency_code;

-- 5. Date logic checks
SELECT 'delivery_before_order' AS check_name, COUNT(*) AS issue_count
FROM sales
WHERE delivery_date IS NOT NULL
  AND delivery_date < order_date;

SELECT 'customer_birthday_after_order' AS check_name, COUNT(*) AS issue_count
FROM sales s
JOIN customers c ON s.customer_key = c.customer_key
WHERE c.birthday IS NOT NULL
  AND c.birthday > s.order_date;

SELECT 'store_opened_after_order' AS check_name, COUNT(*) AS issue_count
FROM sales s
JOIN stores st ON s.store_key = st.store_key
WHERE s.store_key <> 0
  AND st.open_date IS NOT NULL
  AND st.open_date > s.order_date;

-- 6. Relationship checks
SELECT 'sales_missing_customer' AS check_name, COUNT(*) AS issue_count
FROM sales s
LEFT JOIN customers c ON s.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

SELECT 'sales_missing_product' AS check_name, COUNT(*) AS issue_count
FROM sales s
LEFT JOIN products p ON s.product_key = p.product_key
WHERE p.product_key IS NULL;

SELECT 'sales_missing_store_excluding_online' AS check_name, COUNT(*) AS issue_count
FROM sales s
LEFT JOIN stores st ON s.store_key = st.store_key
WHERE s.store_key <> 0
  AND st.store_key IS NULL;

SELECT 'sales_missing_exchange_rate' AS check_name, COUNT(*) AS issue_count
FROM sales s
LEFT JOIN exchange_rates er
       ON s.order_date = er.rate_date
      AND s.currency_code = er.currency_code
WHERE er.currency_code IS NULL;

-- 7. Useful profiling checks
SELECT MIN(order_date) AS first_order_date, MAX(order_date) AS last_order_date
FROM sales;

SELECT currency_code, COUNT(*) AS sales_lines
FROM sales
GROUP BY currency_code
ORDER BY sales_lines DESC;
