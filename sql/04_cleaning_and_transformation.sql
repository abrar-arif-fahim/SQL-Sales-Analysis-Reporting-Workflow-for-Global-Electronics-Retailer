-- 04_cleaning_and_transformation.sql
-- Purpose: Create cleaned views and analysis-ready calculated fields.
-- Run after 03_data_quality_checks.sql.

USE electronics_retailer;

CREATE OR REPLACE VIEW vw_customers_clean AS
SELECT
    customer_key,
    NULLIF(TRIM(gender), '') AS gender,
    NULLIF(TRIM(customer_name), '') AS customer_name,
    NULLIF(TRIM(city), '') AS city,
    NULLIF(UPPER(TRIM(state_code)), '') AS state_code,
    NULLIF(TRIM(state_name), '') AS state_name,
    NULLIF(TRIM(zip_code), '') AS zip_code,
    NULLIF(TRIM(country), '') AS country,
    NULLIF(TRIM(continent), '') AS continent,
    birthday,
    TIMESTAMPDIFF(YEAR, birthday, CURDATE()) AS customer_age
FROM customers;

CREATE OR REPLACE VIEW vw_products_clean AS
SELECT
    product_key,
    NULLIF(TRIM(product_name), '') AS product_name,
    NULLIF(TRIM(brand), '') AS brand,
    NULLIF(TRIM(color), '') AS color,
    unit_cost_usd,
    unit_price_usd,
    NULLIF(TRIM(subcategory_key), '') AS subcategory_key,
    NULLIF(TRIM(subcategory), '') AS subcategory,
    NULLIF(TRIM(category_key), '') AS category_key,
    NULLIF(TRIM(category), '') AS category
FROM products;

CREATE OR REPLACE VIEW vw_stores_clean AS
SELECT
    store_key,
    NULLIF(TRIM(country), '') AS country,
    NULLIF(TRIM(state_name), '') AS state_name,
    square_meters,
    open_date
FROM stores;

CREATE OR REPLACE VIEW vw_exchange_rates_clean AS
SELECT
    rate_date,
    UPPER(TRIM(currency_code)) AS currency_code,
    exchange_rate
FROM exchange_rates;

CREATE OR REPLACE VIEW vw_sales_clean AS
SELECT
    s.order_number,
    s.line_item,
    s.order_date,
    s.delivery_date,
    CASE
        WHEN s.delivery_date IS NULL THEN 'Not Delivered / Unknown'
        WHEN s.delivery_date < s.order_date THEN 'Invalid Delivery Date'
        ELSE 'Delivered'
    END AS delivery_status,
    CASE
        WHEN s.delivery_date IS NULL THEN NULL
        ELSE DATEDIFF(s.delivery_date, s.order_date)
    END AS delivery_days,
    s.customer_key,
    s.store_key,
    s.product_key,
    s.quantity,
    UPPER(TRIM(s.currency_code)) AS currency_code,
    p.unit_cost_usd,
    p.unit_price_usd,
    er.exchange_rate,
    ROUND(s.quantity * p.unit_price_usd, 2) AS revenue_usd,
    ROUND(s.quantity * p.unit_cost_usd, 2) AS cost_usd,
    ROUND(s.quantity * (p.unit_price_usd - p.unit_cost_usd), 2) AS profit_usd,
    ROUND(
        (s.quantity * (p.unit_price_usd - p.unit_cost_usd))
        / NULLIF(s.quantity * p.unit_price_usd, 0),
        4
    ) AS profit_margin
FROM sales s
LEFT JOIN vw_products_clean p
       ON s.product_key = p.product_key
LEFT JOIN vw_exchange_rates_clean er
       ON s.order_date = er.rate_date
      AND UPPER(TRIM(s.currency_code)) = er.currency_code;

CREATE OR REPLACE VIEW vw_sales_enriched AS
SELECT
    sc.order_number,
    sc.line_item,
    sc.order_date,
    sc.delivery_date,
    sc.delivery_status,
    sc.delivery_days,
    sc.customer_key,
    c.customer_name,
    c.gender,
    c.city AS customer_city,
    c.state_name AS customer_state,
    c.country AS customer_country,
    c.continent AS customer_continent,
    sc.store_key,
    CASE WHEN sc.store_key = 0 THEN 'Online' ELSE 'Physical Store' END AS sales_channel,
    COALESCE(st.country, 'Online') AS store_country,
    COALESCE(st.state_name, 'Online') AS store_state,
    st.square_meters,
    st.open_date AS store_open_date,
    sc.product_key,
    p.product_name,
    p.brand,
    p.color,
    p.subcategory,
    p.category,
    sc.quantity,
    sc.currency_code,
    sc.unit_cost_usd,
    sc.unit_price_usd,
    sc.exchange_rate,
    sc.revenue_usd,
    sc.cost_usd,
    sc.profit_usd,
    sc.profit_margin
FROM vw_sales_clean sc
LEFT JOIN vw_customers_clean c ON sc.customer_key = c.customer_key
LEFT JOIN vw_stores_clean st ON sc.store_key = st.store_key
LEFT JOIN vw_products_clean p ON sc.product_key = p.product_key;
