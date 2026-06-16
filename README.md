# SQL Sales Analysis & Reporting Workflow for Global Electronics Retailer

## Project Objective

This project demonstrates a professional SQL data analysis workflow for a global electronics retailer. The goal is to load retail sales data into MySQL, validate data quality, clean and transform the data, create reporting-ready SQL views, and answer business questions with structured analysis queries.

## Dataset Description

The dataset represents retail operations for an electronics business and may include customer, product, sales, store, exchange rate, and data dictionary files:

- `Customers.csv`
- `Products.csv`
- `Sales.csv`
- `Stores.csv`
- `Exchange_Rates.csv`
- `Data_Dictionary.csv`

Raw source files are stored in `data/raw`. Cleaned or transformed exports can be stored in `data/cleaned`.

## Tools Used

- MySQL
- SQL
- VS Code
- GitHub

## Workflow Steps

1. **Data loading**: Create database tables and load raw CSV data into MySQL.
2. **Quality checks**: Validate row counts, missing values, duplicates, invalid dates, and referential integrity.
3. **Cleaning and transformation**: Standardize fields, prepare derived columns, and resolve data quality issues.
4. **Reporting views**: Build reusable SQL views for sales, customers, products, stores, and exchange-rate reporting.
5. **Business analysis**: Write SQL queries to analyze revenue, order trends, product performance, store performance, customer behavior, and regional insights.

## Expected Outputs

- Structured MySQL tables for the retailer dataset
- Data quality check results
- Cleaned and transformed SQL-ready datasets
- Reporting views for repeatable analysis
- Business analysis query outputs
- Screenshots of key query results or dashboards
- Documentation of assumptions, issues, and insights

## Project Structure

```text
data/
  raw/
  cleaned/
sql/
outputs/
screenshots/
docs/
```
