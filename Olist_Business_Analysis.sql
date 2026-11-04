/*
=========================================================
PROJECT: Olist E-Commerce Logistics Analysis
=========================================================

OBJECTIVE:
Analyze Brazilian e-commerce order and delivery data to
identify delivery delays, seller performance, customer
behavior, regional trends, and product revenue patterns.

DATASET:
Brazilian E-Commerce Public Dataset by Olist

DATABASE:
MySQL 8.0 CE

TOOLS:
MySQL Workbench 8.0 CE
SQL

KEY ANALYSIS AREAS:
1. Order and revenue analysis
2. Freight cost analysis
3. Late delivery analysis
4. Seller performance analysis
5. Customer repeat purchase behavior
6. Product category performance
7. Regional delivery performance
8. Cumulative and trend analysis

SQL CONCEPTS USED:
SELECT, WHERE, GROUP BY, HAVING, JOINs, CASE,
Aggregate Functions, Subqueries, CTEs, Recursive CTEs,
Window Functions, RANK, ROW_NUMBER, LAG, and
Cumulative Calculations.

DATASET LIMITATIONS:
- Seller performance is used as a proxy for carrier
  performance because carrier information is unavailable.
- Customer state is used for geographical analysis
  because a predefined region column is unavailable.
- Freight value is used as a proxy for shipping cost.

=========================================================
*/

-- How many orders are there in each order status?
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Find the top 10 orders by total order value
-- (product price + freight value)

SELECT
    order_id,
    SUM(price + freight_value) AS total_order_value
FROM order_items
GROUP BY order_id
ORDER BY total_order_value DESC
LIMIT 10;

-- Calculate average freight value per order item by customer state
SELECT
    c.customer_state,
    AVG(oi.freight_value) AS avg_freight
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY avg_freight DESC;

-- Identify orders delivered after their estimated delivery date

SELECT
    order_id,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND order_delivered_customer_date > order_estimated_delivery_date;

-- Calculate total orders placed in each month across the dataset
SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders
FROM orders
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)
ORDER BY
    order_year,
    order_month;
    
-- Which sellers have the highest on-time delivery percentage?

SELECT
    oi.seller_id,

    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNT(DISTINCT CASE
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
        THEN o.order_id
    END) AS on_time_orders,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN o.order_delivered_customer_date
                 <= o.order_estimated_delivery_date
            THEN o.order_id
        END) * 100.0
        / COUNT(DISTINCT o.order_id),
        2
    ) AS on_time_delivery_percentage

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  

GROUP BY oi.seller_id

ORDER BY on_time_delivery_percentage DESC;

-- Identify Sellers with On-Time Delivery Below 90% and at Least 500 Orders

with orders_new as 
(select oi.seller_id,
count(DISTINCT o.order_id) as total_orders,
COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN o.order_id  END) as on_time_delivered_orders,
ROUND (
COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN o.order_id  END)*100.0/ count(DISTINCT o.order_id),2) as on_time_delivery_percentage
from orders o
join order_items oi on o.order_id = oi.order_id
where o.order_status = 'Delivered'
AND o.order_delivered_customer_date IS NOT NULL
AND o.order_estimated_delivery_date IS NOT NULL  
group by oi.seller_id
)

SELECT *
FROM orders_new
WHERE on_time_delivery_percentage < 90
  AND total_orders >= 500
ORDER BY on_time_delivery_percentage ASC;

-- Revenue by product category

SELECT
    p.product_category_name,
    SUM(oi.price) AS total_revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;

-- Which customers have placed more than three orders?
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 3
ORDER BY total_orders DESC;

-- Average delivery days by customer state
select c.customer_state,  AVG(datediff( o.order_delivered_customer_date, o.order_purchase_timestamp)) as avg_delivery_days
from customers c
join orders o on
c.customer_id = o.customer_id
where o.order_delivered_customer_date IS NOT NULL
group by c.customer_state
order by avg_delivery_days DESC;

-- Which customer states have a late-delivery percentage higher than the overall late-delivery percentage across all states?
WITH late_delivery_percentage AS (
    SELECT
        c.customer_state,
        SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*) AS late_delivery_percentage
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY c.customer_state
),

overall_late AS (
    SELECT
        SUM(
            CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*) AS overall_late_delivery_percentage
    FROM orders
    WHERE order_status = 'Delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)

SELECT
    l.customer_state,
    l.late_delivery_percentage,
    o.overall_late_delivery_percentage
FROM late_delivery_percentage l
CROSS JOIN overall_late o
WHERE l.late_delivery_percentage > o.overall_late_delivery_percentage
ORDER BY l.late_delivery_percentage DESC;

-- Are there any orders in the orders table that do not have a corresponding record in the order_items table?
SELECT
    o.order_id
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
;

-- Which sellers perform best in terms of on-time delivery within each customer state?
WITH seller_performance AS
(
SELECT
    c.customer_state,
    oi.seller_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
        THEN o.order_id
    END) AS on_time_orders,
COUNT(DISTINCT CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
        THEN o.order_id
    END)*100.0/ COUNT(DISTINCT o.order_id) as on_time_delivery_percentage
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    c.customer_state,
    oi.seller_id
    )
    SELECT
    customer_state,
    seller_id,
    total_orders,
    on_time_orders,
    on_time_delivery_percentage,
    RANK() OVER (
        PARTITION BY customer_state
        ORDER BY on_time_delivery_percentage DESC
    ) AS seller_rank
FROM seller_performance
ORDER BY customer_state, seller_rank;

-- How does the monthly order volume change compared with the previous month?
WITH RECURSIVE monthly_calendar AS (
    SELECT DATE_FORMAT(
        MIN(order_purchase_timestamp), '%Y-%m-01'
    ) AS month_start
    FROM orders

    UNION ALL

    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
    FROM monthly_calendar
    WHERE month_start < (
        SELECT DATE_FORMAT(
            MAX(order_purchase_timestamp), '%Y-%m-01'
        )
        FROM orders
    )
),
monthly_orders AS (
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
),
complete_monthly_orders AS (
    SELECT
        DATE_FORMAT(mc.month_start, '%Y-%m') AS order_month,
        COALESCE(mo.total_orders, 0) AS total_orders
    FROM monthly_calendar mc
    LEFT JOIN monthly_orders mo
        ON DATE_FORMAT(mc.month_start, '%Y-%m') = mo.order_month
)
SELECT
    order_month,
    total_orders,
    LAG(total_orders) OVER (ORDER BY order_month) AS previous_month_orders,
    total_orders - LAG(total_orders) OVER (ORDER BY order_month) AS mom_order_change,
    ROUND(
        (total_orders - LAG(total_orders) OVER (ORDER BY order_month))
        * 100.0
        / NULLIF(LAG(total_orders) OVER (ORDER BY order_month), 0),
        2
    ) AS mom_percentage_change
FROM complete_monthly_orders
ORDER BY order_month;

-- Q15: Calculate true 7-calendar-day moving average of daily orders

WITH RECURSIVE date_bounds AS (
    -- Find the first and last order dates
    SELECT
        MIN(DATE(order_purchase_timestamp)) AS min_date,
        MAX(DATE(order_purchase_timestamp)) AS max_date
    FROM orders
),

calendar_dates (calendar_date) AS (
    -- Generate the first calendar date
    SELECT min_date
    FROM date_bounds

    UNION ALL

    -- Generate the next date until the last order date
    SELECT DATE_ADD(calendar_date, INTERVAL 1 DAY)
    FROM calendar_dates
    JOIN date_bounds
        ON calendar_date < max_date
),

daily_orders AS (
    -- Calculate actual daily order counts
    SELECT
        DATE(order_purchase_timestamp) AS order_date,
        COUNT(*) AS daily_orders
    FROM orders
    GROUP BY DATE(order_purchase_timestamp)
),

complete_daily_orders AS (
    -- Include dates with zero orders
    SELECT
        c.calendar_date,
        COALESCE(d.daily_orders, 0) AS daily_orders
    FROM calendar_dates c
    LEFT JOIN daily_orders d
        ON c.calendar_date = d.order_date
)

-- Calculate the 7-calendar-day moving average
SELECT
    calendar_date,
    daily_orders,
    ROUND(
        AVG(daily_orders) OVER (
            ORDER BY calendar_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_7_days
FROM complete_daily_orders
ORDER BY calendar_date;

-- Top 3 products by revenue in each product category
SELECT *
FROM (
    SELECT
        oi.product_id,
        p.product_category_name,
        SUM(oi.price) AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY p.product_category_name
            ORDER BY SUM(oi.price) DESC
        ) AS product_rank
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY
        oi.product_id,
        p.product_category_name
) AS ranked_products
WHERE product_rank <= 3
ORDER BY
    product_category_name,
    product_rank;

-- Find each customer's first and second order and the number of days between them.
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS order_number
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
)

SELECT
    a.customer_unique_id,
    a.order_purchase_timestamp AS first_order_date,
    b.order_purchase_timestamp AS second_order_date,
    DATEDIFF(
        b.order_purchase_timestamp,
        a.order_purchase_timestamp
    ) AS days_between_orders
FROM customer_orders a
JOIN customer_orders b
    ON a.customer_unique_id = b.customer_unique_id
WHERE a.order_number = 1
  AND b.order_number = 2
ORDER BY days_between_orders DESC;

-- Calculate cumulative shipping cost by month
SELECT
    order_month,
    monthly_shipping_cost,
    SUM(monthly_shipping_cost) OVER (
        ORDER BY order_month
    ) AS cumulative_shipping_cost
FROM (
    SELECT
        DATE_FORMAT(shipping_limit_date, '%Y-%m') AS order_month,
        SUM(freight_value) AS monthly_shipping_cost
    FROM order_items
    GROUP BY DATE_FORMAT(shipping_limit_date, '%Y-%m')
) AS monthly_data
ORDER BY order_month;

-- Identify lanes that account for 50% of all late deliveries
WITH lane_late_orders AS (
    SELECT
        s.seller_state AS origin_state,
        c.customer_state AS destination_state,
        COUNT(DISTINCT o.order_id) AS late_orders
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
    GROUP BY
        s.seller_state,
        c.customer_state
),
cumulative_lanes AS (
    SELECT
        origin_state,
        destination_state,
        late_orders,
        SUM(late_orders) OVER (
            ORDER BY late_orders DESC, origin_state, destination_state
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_late_orders,
        ROUND(
            SUM(late_orders) OVER (
                ORDER BY late_orders DESC, origin_state, destination_state
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) * 100.0
            / SUM(late_orders) OVER (),
            2
        ) AS cumulative_late_percentage
    FROM lane_late_orders
)
SELECT *
FROM cumulative_lanes
WHERE cumulative_late_orders - late_orders <
      (SELECT SUM(late_orders) * 0.50
       FROM lane_late_orders)

-- Identify duplicate order IDs and demonstrate safe removal
SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT order_id
    FROM orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS duplicates;





