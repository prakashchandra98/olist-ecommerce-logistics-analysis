
# Olist E-Commerce Logistics Analysis

## 1. Project Overview

This project analyzes the Brazilian E-Commerce Public Dataset by Olist using MySQL 8.0.

The objective is to identify patterns in delivery delays, seller performance, customer behavior, regional delivery performance, and product revenue.

The analysis focuses on answering practical business questions that can support operational decision-making and logistics performance improvement.

## 2. Business Questions

This project explores the following questions:

- How many orders are there in each order status?
- Which orders have the highest total value?
- How does average freight value vary by customer state?
- Which orders were delivered late?
- How does order volume change over time?
- Which sellers have lower on-time delivery performance?
- Which product categories generate the highest revenue?
- Which customers place repeat orders?
- Which states have longer delivery times?
- Which states have late-delivery rates above the overall average?
- Which sellers rank highest within customer states?
- How are monthly and daily order trends changing?
- Which products generate the most revenue within each category?
- How long do customers take to place repeat orders?
- How does cumulative freight value change over time?
- Which seller-origin/destination-state lanes contribute most to late deliveries?

## 3. Tools and Technologies

- MySQL 8.0
- MySQL Workbench 8.0 CE
- SQL

## 4. SQL Concepts Used

The project includes 20 SQL case-study queries using:

- SELECT, WHERE, ORDER BY and DISTINCT
- Aggregate functions: COUNT, SUM, AVG, MIN and MAX
- GROUP BY and HAVING
- INNER JOIN and LEFT JOIN
- CASE statements
- Subqueries
- Common Table Expressions (CTEs)
- Recursive CTEs
- Window functions
- ROW_NUMBER(), RANK() and LAG()
- Cumulative calculations
- Date and time functions
- NULL handling and COALESCE

## 5. Key Business Findings

1. **Regional delivery performance:** Alagoas recorded a late-delivery rate of approximately 23.93%, compared with the overall rate of 8.11%.

2. **Delivery time differences:** Roraima had the longest average delivery time at approximately 29.34 days, while São Paulo averaged approximately 8.70 days.

3. **Product revenue:** The beauty and health category generated approximately R$1.26 million in product revenue.

4. **Seller performance:** Ten sellers with at least 500 delivered orders had on-time delivery rates below 90%. The lowest observed rate was approximately 87.81%.

5. **High-impact lanes:** The four highest-volume seller-origin/destination-state combinations represented approximately 51% of lane-level late-order counts.

## 6. Dataset

Brazilian E-Commerce Public Dataset by Olist.

The dataset contains information about orders, customers, sellers, products, payments, reviews, geolocation and product categories.

Dataset source:
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## 7. Project Structure

Olist_SQL_Project/
│
├── data/
│   └── raw/
│
├── sql/
│   └── Olist_Business_Analysis.sql
│
├── documentation/
│   └── Olist_Business_Findings_Summary.pdf
│
├── er_diagram/
│   └── Olist_ER_Diagram
│
└── README.md

## 8. Data Limitations

- The dataset does not contain carrier identifiers. Seller-level delivery performance is used as a proxy, not a direct measure of carrier performance.
- Customer state is used for geographic analysis because a predefined region field is unavailable.
- Freight value is used as a proxy for shipping cost.
- A single order may contain items from multiple sellers. Lane-level late counts can therefore count the same order across multiple lanes.
- The dataset represents historical activity from 2016 to 2018.

## 9. Project Outcome

This project demonstrates the application of SQL to real-world e-commerce logistics analysis, including data aggregation, multi-table joins, delivery KPI calculations, customer analysis, seller ranking, and time-based performance analysis.
