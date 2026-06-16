-- 05_reporting_views.sql
-- Purpose: Create reusable reporting views for portfolio analysis.
-- Run after 04_cleaning_and_transformation.sql.

USE electronics_retailer;

CREATE OR REPLACE VIEW rpt_sales AS
SELECT
    order_number,
    line_item,
    order_date,
    delivery_date,
    delivery_status,
    delivery_days,
    customer_key,
    customer_name,
    customer_country,
    customer_continent,
    store_key,
    sales_channel,
    store_country,
    store_state,
    product_key,
    product_name,
    brand,
    subcategory,
    category,
    quantity,
    currency_code,
    revenue_usd,
    cost_usd,
    profit_usd,
    profit_margin
FROM vw_sales_enriched;

CREATE OR REPLACE VIEW rpt_monthly_sales AS
SELECT
    DATE_FORMAT(order_date, '%Y-%m-01') AS sales_month,
    YEAR(order_date) AS sales_year,
    MONTH(order_date) AS sales_month_number,
    COUNT(DISTINCT order_number) AS order_count,
    COUNT(*) AS sales_line_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue_usd), 2) AS revenue_usd,
    ROUND(SUM(cost_usd), 2) AS cost_usd,
    ROUND(SUM(profit_usd), 2) AS profit_usd,
    ROUND(SUM(profit_usd) / NULLIF(SUM(revenue_usd), 0), 4) AS profit_margin
FROM vw_sales_enriched
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01'), YEAR(order_date), MONTH(order_date);

CREATE OR REPLACE VIEW rpt_product_performance AS
SELECT
    product_key,
    product_name,
    brand,
    subcategory,
    category,
    COUNT(DISTINCT order_number) AS order_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue_usd), 2) AS revenue_usd,
    ROUND(SUM(cost_usd), 2) AS cost_usd,
    ROUND(SUM(profit_usd), 2) AS profit_usd,
    ROUND(SUM(profit_usd) / NULLIF(SUM(revenue_usd), 0), 4) AS profit_margin
FROM vw_sales_enriched
GROUP BY product_key, product_name, brand, subcategory, category;

CREATE OR REPLACE VIEW rpt_country_sales AS
SELECT
    customer_country AS country,
    customer_continent AS continent,
    COUNT(DISTINCT order_number) AS order_count,
    COUNT(DISTINCT customer_key) AS customer_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue_usd), 2) AS revenue_usd,
    ROUND(SUM(profit_usd), 2) AS profit_usd,
    ROUND(SUM(profit_usd) / NULLIF(SUM(revenue_usd), 0), 4) AS profit_margin
FROM vw_sales_enriched
GROUP BY customer_country, customer_continent;

CREATE OR REPLACE VIEW rpt_store_performance AS
SELECT
    store_key,
    sales_channel,
    store_country,
    store_state,
    square_meters,
    COUNT(DISTINCT order_number) AS order_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue_usd), 2) AS revenue_usd,
    ROUND(SUM(profit_usd), 2) AS profit_usd,
    ROUND(SUM(revenue_usd) / NULLIF(square_meters, 0), 2) AS revenue_per_square_meter,
    ROUND(SUM(profit_usd) / NULLIF(SUM(revenue_usd), 0), 4) AS profit_margin
FROM vw_sales_enriched
GROUP BY store_key, sales_channel, store_country, store_state, square_meters;

CREATE OR REPLACE VIEW rpt_category_performance AS
SELECT
    category,
    subcategory,
    COUNT(DISTINCT order_number) AS order_count,
    COUNT(DISTINCT product_key) AS product_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(revenue_usd), 2) AS revenue_usd,
    ROUND(SUM(profit_usd), 2) AS profit_usd,
    ROUND(SUM(profit_usd) / NULLIF(SUM(revenue_usd), 0), 4) AS profit_margin
FROM vw_sales_enriched
GROUP BY category, subcategory;

CREATE OR REPLACE VIEW rpt_customer_summary AS
SELECT
    customer_key,
    customer_name,
    gender,
    customer_country,
    customer_continent,
    COUNT(DISTINCT order_number) AS order_count,
    SUM(quantity) AS units_purchased,
    ROUND(SUM(revenue_usd), 2) AS revenue_usd,
    ROUND(SUM(profit_usd), 2) AS profit_usd,
    ROUND(AVG(revenue_usd), 2) AS avg_line_revenue_usd,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS customer_lifespan_days
FROM vw_sales_enriched
GROUP BY customer_key, customer_name, gender, customer_country, customer_continent;
