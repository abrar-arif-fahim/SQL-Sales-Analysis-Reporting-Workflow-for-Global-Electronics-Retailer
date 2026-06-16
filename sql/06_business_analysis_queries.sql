-- 06_business_analysis_queries.sql
-- Purpose: Business analysis queries for the portfolio project.
-- Run after 05_reporting_views.sql.
-- These queries calculate results from your database; no results are hard-coded.

USE electronics_retailer;

-- 1. Total revenue, cost, profit, and margin
SELECT
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(*) AS total_sales_lines,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(revenue_usd), 2) AS total_revenue_usd,
    ROUND(SUM(cost_usd), 2) AS total_cost_usd,
    ROUND(SUM(profit_usd), 2) AS total_profit_usd,
    ROUND(SUM(profit_usd) / NULLIF(SUM(revenue_usd), 0), 4) AS profit_margin
FROM rpt_sales;

-- 2. Monthly sales and profit trends
SELECT
    sales_month,
    order_count,
    units_sold,
    revenue_usd,
    profit_usd,
    profit_margin
FROM rpt_monthly_sales
ORDER BY sales_month;

-- 3. Top countries by revenue
SELECT
    country,
    continent,
    order_count,
    customer_count,
    units_sold,
    revenue_usd,
    profit_usd,
    profit_margin
FROM rpt_country_sales
ORDER BY revenue_usd DESC
LIMIT 10;

-- 4. Top products by revenue
SELECT
    product_key,
    product_name,
    brand,
    category,
    subcategory,
    units_sold,
    revenue_usd,
    profit_usd,
    profit_margin
FROM rpt_product_performance
ORDER BY revenue_usd DESC
LIMIT 10;

-- 5. Top brands by revenue and profit
SELECT
    brand,
    COUNT(DISTINCT product_key) AS product_count,
    SUM(units_sold) AS units_sold,
    ROUND(SUM(revenue_usd), 2) AS revenue_usd,
    ROUND(SUM(profit_usd), 2) AS profit_usd,
    ROUND(SUM(profit_usd) / NULLIF(SUM(revenue_usd), 0), 4) AS profit_margin
FROM rpt_product_performance
GROUP BY brand
ORDER BY revenue_usd DESC
LIMIT 10;

-- 6. Best stores and sales channels by revenue
SELECT
    store_key,
    sales_channel,
    store_country,
    store_state,
    order_count,
    units_sold,
    revenue_usd,
    profit_usd,
    revenue_per_square_meter,
    profit_margin
FROM rpt_store_performance
ORDER BY revenue_usd DESC
LIMIT 10;

-- 7. Delivery performance
SELECT
    delivery_status,
    COUNT(*) AS sales_line_count,
    COUNT(DISTINCT order_number) AS order_count,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    MIN(delivery_days) AS min_delivery_days,
    MAX(delivery_days) AS max_delivery_days
FROM rpt_sales
GROUP BY delivery_status
ORDER BY sales_line_count DESC;

-- 8. Customer value segments based on revenue
WITH customer_segments AS (
    SELECT
        customer_key,
        customer_name,
        customer_country,
        order_count,
        units_purchased,
        revenue_usd,
        profit_usd,
        CASE
            WHEN revenue_usd >= 5000 THEN 'High Value'
            WHEN revenue_usd >= 1000 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM rpt_customer_summary
)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(order_count), 2) AS avg_orders_per_customer,
    ROUND(AVG(revenue_usd), 2) AS avg_revenue_per_customer,
    ROUND(SUM(revenue_usd), 2) AS total_revenue_usd,
    ROUND(SUM(profit_usd), 2) AS total_profit_usd
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_revenue_usd DESC;

-- 9. Category and subcategory performance
SELECT
    category,
    subcategory,
    product_count,
    units_sold,
    revenue_usd,
    profit_usd,
    profit_margin
FROM rpt_category_performance
ORDER BY revenue_usd DESC;

-- 10. Repeat purchase behavior
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time Customer'
        WHEN order_count BETWEEN 2 AND 5 THEN 'Repeat Customer'
        ELSE 'Frequent Customer'
    END AS purchase_behavior_segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(revenue_usd), 2) AS revenue_usd,
    ROUND(SUM(profit_usd), 2) AS profit_usd
FROM rpt_customer_summary
GROUP BY purchase_behavior_segment
ORDER BY revenue_usd DESC;
