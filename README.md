# Kolapays E-Commerce-Performance-Analysis

![Project Status](https://img.shields.io/badge/Status-Complete-success)
![SQL](https://img.shields.io/badge/SQL-MySQL-blue)
![Tableau](https://img.shields.io/badge/Tableau-Dashboard-orange)

> **Kolapays Project overview**
>   
> Kolapays E-Commerce Analysis is a portfolio project based on a fictional e-commerce company, Kolapays, which sells products across multiple categories to customers in different regions worldwide.
>
>The project demonstrates how SQL and Tableau can be used together to analyze business data, answer real-world business questions, and generate actionable insights. Using customer, order, and product data, the analysis explores key business metrics such as revenue trends, customer behavior, product performance, and regional sales patterns.
>
>The goal of this project is to showcase the end-to-end data analytics process—from querying and transforming data with SQL to building interactive dashboards in Tableau—while providing insights that could help the business make informed, data-driven decisions.
---

## 🎯 Business Task
The aim of this project is to analyze Kolapays' e-commerce data and uncover actionable insights that support data-driven decision-making. This project explores customer behavior, sales performance, and product trends to identify opportunities for business growth.

**Specific Objectives**:
- Analyze sales performance and revenue trends over time.
- Identify the highest-performing product categories.
- Evaluate customer purchasing behavior and retention patterns.
- Compare first-time and returning customer performance.
- Assess regional sales performance across different markets.
- Build an interactive Tableau dashboard for business stakeholders.

**Key Questions Answered**:
1. Who are our most engaged customers based on completed purchase history?
2. Which product categories generate the most revenue monthly?
3. Which customer signup cohorts have the highest retention rates?
4. how often are discounts being applied across product categories
5. Do repeat customers spend more than new customers?
6. Identify the top 3 spenders per contries and include them into the VIP Loyalty programme.

## Dataset

The dataset used in this project consists of four relational tables:

| Table | Description |
|---|---|
| `customers` | Customer profiles including full name, country, and signup date |
| `orders` | Order-level records with order date and fulfilment status (completed, cancelled, pending) |
| `order_items` | Line-item detail per order, including product, quantity, unit price, cost price, and discount applied |
| `products` | Product catalogue with category and cost price |

All names, figures, and records are entirely fictional.

---

## 🛠 Tools Used
| Tool | Purpose |
|------|---------|
| **MySQL** | Exploaratory Data Analysis |
| **Tableau Public** | Interactive dashboard and data visualization |
| **Microsoft Word** | Executive summary report |
| **GitHub** | Version control and project documentation |

---

## SQL Analysis & Queries
### Q1 Who are our most engaged customers based on completed purchase history?
```sql
# I wrote a query that returns each customer's full name, country, and total number of orders they have palced and completed. 
# I Only included customers who have completed at least 2 orders.

SELECT
    customers.full_name,
    customers.country,
    count(orders.customer_id) as number_of_orders
FROM customers
JOIN
    orders
ON customers.customer_id = orders.customer_id
Where orders.status = 'completed'
GROUP BY 
    orders.customer_id,
    customers.full_name,
    customers.country
HAVING COUNT(orders.customer_id) >= 2
ORDER BY number_of_orders  DESC;
```
### Q2 Which product categories generate the most revenue monthly?
```sql
# I wrote a query that showed, for each month (formatted as YYYY-MM), the total revenue from completed orders only,
# the total number of completed orders, and the top-earning product category for that month. 

WITH M_Revenue AS
( 
SELECT
    DATE_FORMAT(order_date, '%Y-%m') as order_date,
    p.category,
    sum(b.quantity * b.unit_price) AS revenue,
    a.status
FROM
orders a
JOIN order_items b
    ON a.order_id = b.order_id
JOIN products p
    on b.product_id = p.product_id
WHERE a.status = 'completed'
GROUP BY
    order_date,
    category,
    a.status
),
sumed_revenue as
(
SELECT
    order_date,
    category,
    sum(revenue) grouped_revenue
FROM M_Revenue
GROUP BY
    order_date,
    category
ORDER BY order_date, category
),
ranked_revenue AS
(
SELECT
    order_date,
    category,
    grouped_revenue,
    ROW_NUMBER() OVER(
        PARTITION BY order_date ORDER BY grouped_revenue DESC) AS ranked_row
FROM sumed_revenue
)
SELECT
    order_date,
    ROUND(SUM(grouped_revenue), 2) AS revenue,
    MAX(CASE WHEN ranked_row = 1 THEN category END)AS top_category
FROM ranked_revenue
group by order_date;
```
### Q3 Which customer signup cohorts have the highest retention rates?
```sql
# I Wrote a query that groups customers by their signup month (YYYY-MM). For each cohort i showed: the number of customers  
# who signed up, the number who were retained (ordered in 2+ distinct months), the retention rate as a percentage,  
# and the average profit per order forthat cohort — where profit per order_item = (unit_price - cost_price) * quantity. 


-- signup_date for each customer
WITH signup_cohort AS
(
SELECT
    customer_id,
    DATE_FORMAT(signup_date, '%Y-%m') signup_date
FROM customers
),

-- retained customer
retained_customers AS
(

SELECT 
    customer_id,
	COUNT(DISTINCT(DATE_FORMAT(order_date, '%Y-%m'))) AS active_dates
FROM orders
GROUP BY customer_id
),

order_profit AS
(
SELECT
    o.customer_id,
    oi.order_id,
    SUM((oi.unit_price - p.cost_price) * oi.quantity) as order_profit
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p 
    ON p.product_id = oi.product_id
GROUP BY o.customer_id, oi.order_id
)
SELECT 
    s_c.signup_date,
    COUNT(DISTINCT s_c.customer_id) unique_customers,
    COUNT(DISTINCT CASE WHEN COALESCE(r_c.active_dates, 0) >= 2 THEN s_c.customer_id END) AS retained_customer,
    ROUND(
	    (100 /COUNT(DISTINCT s_c.customer_id) 
        * COUNT(DISTINCT CASE WHEN COALESCE(r_c.active_dates, 0) >= 2 THEN s_c.customer_id END))
        , 2) AS retention_rate_pct,
	ROUND(AVG(order_profit), 2) AS avg_profit_per_order

FROM signup_cohort s_c
LEFT JOIN retained_customers r_c
    ON s_c.customer_id = r_c.customer_id
LEFT JOIN order_profit o_p
    ON o_p.customer_id = s_c.customer_id
GROUP BY s_c.signup_date;
```
### Q4 How often are discounts being applied across product categories 
```sql
-- I wrote a query that returns each product category, the total number of order items in that category, the number of order 
-- items where a discount was applied (discount_pct > 0), and the average discount percentage across all items in that category. 
-- Sorting it by the number of discounted items in descending order.

SELECT 
  p.category,
  COUNT(oi.item_id) AS total_items,
  COUNT(CASE WHEN discount_pct > 0 THEN discount_pct END) AS discounted_items,
  ROUND(AVG(discount_pct), 2) AS avg_discount
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.category
ORDER BY discounted_items DESC;
```
### Q5 Do repeat customers spend more than new customers?
```sql
# I wrote a query that classified every completed order as either 'first_order' or 'repeat_order' based on whether it is the 
# customer's first ever order (by date). Then return two rows — one per classification — showing the total number of orders,
# total revenue, and average order value. 

WITH categorized_orders AS (
    SELECT 
        o.order_id,
        o.customer_id,
        CASE 
            WHEN ROW_NUMBER() OVER(PARTITION BY o.customer_id ORDER BY o.order_date) = 1 
            THEN 'first_order'
            ELSE 'repeat_order'
        END AS category,
        SUM(oi.unit_price * oi.quantity) AS order_value
    FROM orders o
    JOIN order_items oi 
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_id, o.customer_id, o.order_date
)

SELECT
    category,
    COUNT(*) AS number_order,
    ROUND(SUM(order_value), 2) AS revenue,
    ROUND(AVG(order_value), 2) AS avg_order_value
FROM categorized_orders
GROUP BY category;
```
### Q6 Identify the top 3 spenders per contries and include them into the VIP Loyalty programme.
``` sql
# This query returns the top 3 customers by total spend (completed orders only) within each country. Including their full name, 
# country, total spend rounded to 2 decimal places, and their rank within their country. If two customers tie on spend, 
# both should appear and the next rank should be skipped.

WITH country_rank AS
(
SELECT
    c.customer_id,
    c.full_name,
    c.country,
    round(sum(oi.quantity*oi.unit_price), 2) AS money_spent
FROM customers c
JOIN orders o
  ON c.customer_id = o.customer_id
JOIN order_items oi
  ON oi.order_id = o.order_id
WHERE o.status = 'completed'
group by customer_id, c.full_name, c.country
),
ranked_customer as
(
SELECT
    full_name,
    country,
    money_spent,
    rank() over(partition by country order by money_spent DESC) country_rank
FROM country_rank
)
SELECT
    full_name,
    country,
    money_spent,
    country_rank
FROM ranked_customer
where country_rank between 1 and 3;
```
---

## 🔍 Key Findings

