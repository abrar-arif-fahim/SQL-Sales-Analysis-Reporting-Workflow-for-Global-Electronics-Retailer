# Project Notes

## Project

**SQL Sales Analysis & Reporting Workflow for Global Electronics Retailer**

Database: `electronics_retailer`

This project uses MySQL to create a structured workflow from raw CSV files to reporting-ready SQL views and business analysis queries.

## Source Files

Raw files are stored in `data/raw`:

- `Customers.csv`
- `Products.csv`
- `Sales.csv`
- `Stores.csv`
- `Exchange_Rates.csv`
- `Data_Dictionary.csv`

## Cleaning Decisions

- Source column names were converted to clean `snake_case` names in MySQL.
- Date fields are converted with `STR_TO_DATE(..., '%c/%e/%Y')`.
- Blank values are converted to `NULL` with `NULLIF`.
- Product cost and price values are cleaned by removing `$` and commas before casting to decimal.
- Text fields are trimmed in cleaned views.
- Currency codes and state codes are standardized to uppercase where useful.
- `StoreKey = 0` is treated as online sales and is not expected to match a physical store record.
- Delivery status is derived from `delivery_date`:
  - `Delivered` when a delivery date exists and is on or after the order date
  - `Not Delivered / Unknown` when delivery date is missing
  - `Invalid Delivery Date` when delivery date is before order date

## Calculated Fields

The cleaned sales view creates:

- `delivery_status`
- `delivery_days`
- `revenue_usd`
- `cost_usd`
- `profit_usd`
- `profit_margin`

Revenue and profit are calculated from product USD cost and price fields:

```text
revenue_usd = quantity * unit_price_usd
cost_usd = quantity * unit_cost_usd
profit_usd = revenue_usd - cost_usd
profit_margin = profit_usd / revenue_usd
```

## Assumptions

- The CSV files use comma delimiters and include a header row.
- MySQL local infile loading is enabled.
- Scripts are run from the project root so relative file paths work.
- Sales are analyzed in USD using the product cost and price fields already provided in USD.
- Exchange rates are loaded and validated for relationship checks, but revenue calculations use the USD product fields.
- No fake results are documented; all numeric outputs should come from running the SQL scripts.

## Quality Checks Included

- Row counts for all tables
- Duplicate primary key checks
- Missing critical value checks
- Negative or invalid numeric value checks
- Delivery date before order date checks
- Customer birthday after order date checks
- Store open date after order date checks
- Missing customer, product, store, and exchange rate relationships

## Reporting Views

- `rpt_sales`
- `rpt_monthly_sales`
- `rpt_product_performance`
- `rpt_country_sales`
- `rpt_store_performance`
- `rpt_category_performance`
- `rpt_customer_summary`

## Business Questions Covered

- What are total revenue, cost, profit, and margin?
- How do sales trend by month?
- Which countries generate the most revenue?
- Which products and brands perform best?
- Which stores and channels generate the most revenue?
- How does delivery performance vary?
- How can customers be segmented by value and repeat behavior?

## Future Improvements

- Save query outputs to the `outputs` folder.
- Add screenshots of key result sets to the `screenshots` folder.
- Create a dashboard using the reporting views.
- Add automated tests or stored procedures for the refresh workflow.
- Expand customer segmentation with recency, frequency, and monetary value analysis.
