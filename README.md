# 🛒 Kolapays E-Commerce Analysis

![Project Status](https://img.shields.io/badge/Status-Complete-success)
![SQL](https://img.shields.io/badge/SQL-MySQL-blue)
![Tableau](https://img.shields.io/badge/Tableau-Dashboard-orange)

## 📑 Table of Contents
- [Project Overview](#project-overview)
- [Business Task](#-business-task)
- [Data Source](#-data-source)

> ## Project Overview
> 
> Kolapays E-Commerce Analysis is a portfolio project based on a fictional e-commerce company, Kolapays, which sells products across multiple categories to customers in different regions worldwide. The project showcases an end-to-end data analytics workflow using SQL and Tableau.
>
---

## 🎯 Business Task
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

## 📊 Data Source

**Database Schema**: [Kolapays_schema](data/kolapays_schema.sql)

**SQL Analysis**: [Analysis Query](sql/analysis_query.sql)

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
    DATE_FORMAT(order_date, '%Y-%m') as order_dates,
    p.category,
    sum(b.quantity * b.unit_price * (1 - COALESCE(b.discount_pct, 0) / 100.0)) AS revenue,
    a.status
FROM
orders a
JOIN order_items b
    ON a.order_id = b.order_id
JOIN products p
    on b.product_id = p.product_id
WHERE a.status = 'completed'
GROUP BY
    order_dates,
    category,
    a.status
),
ranked_revenue AS
(
SELECT
    order_dates,
    category,
    revenue,
    ROW_NUMBER() OVER(
        PARTITION BY order_dates ORDER BY revenue DESC) AS ranked_row
FROM M_Revenue
)
SELECT
    order_dates,
    ROUND(SUM(revenue), 2) AS revenue,
    MAX(CASE WHEN ranked_row = 1 THEN category END)AS top_category
FROM ranked_revenue
group by order_dates;
```
### Q3 Which customer signup cohorts have the highest retention rates?
```sql
# I Wrote a query that groups customers by their signup month (YYYY-MM). For each cohort i showed: the number of customers  
# who signed up, the number who were retained (ordered in 2+ distinct months), the retention rate as a percentage,  
# and the average profit per order for that cohort — where profit per order_item = (unit_price - cost_price) * quantity. 


-- signup_date for each customer
WITH signup_cohort AS (
    SELECT
        customer_id,
        DATE_FORMAT(signup_date, '%Y-%m') AS signup_month
    FROM customers
),

retained_customers AS (
    SELECT
        customer_id,
        COUNT(DISTINCT DATE_FORMAT(order_date, '%Y-%m')) AS active_months
    FROM orders
    WHERE status = 'completed'      
    GROUP BY customer_id
),

order_profit AS (
    SELECT
        o.customer_id,
        o.order_id,
        SUM((oi.unit_price - p.cost_price) * oi.quantity) AS order_profit
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p     ON p.product_id = oi.product_id
    WHERE o.status = 'completed'     
    GROUP BY o.customer_id, o.order_id
)

SELECT
    sc.signup_month,
    COUNT(DISTINCT sc.customer_id) AS unique_customers,
    COUNT(DISTINCT CASE WHEN COALESCE(rc.active_months, 0) >= 2 THEN sc.customer_id END) AS retained_customers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN COALESCE(rc.active_months, 0) >= 2 THEN sc.customer_id END)
		/ COUNT(DISTINCT sc.customer_id), 2 )  AS retention_rate_pct,
    ROUND(AVG(op.order_profit), 2) AS avg_profit_per_order
FROM signup_cohort sc
LEFT JOIN retained_customers rc ON sc.customer_id = rc.customer_id
LEFT JOIN order_profit op       ON op.customer_id = sc.customer_id   -- joins directly to signup_cohort
GROUP BY sc.signup_month
ORDER BY sc.signup_month;
```
### Q4 How often are discounts being applied across product categories 
```sql
-- I wrote a query that returns each product category, the total number of order items in that category, the number of order 
-- items where a discount was applied (discount_pct > 0), and the average discount percentage across all items 
-- in that category. Sorting it by the number of discounted items in descending order.

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
        SUM(oi.unit_price * oi.quantity * (1 - COALESCE(oi.discount_pct, 0) / 100.0)) AS order_value
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
    round(sum((oi.quantity*oi.unit_price) * (1 - COALESCE(oi.discount_pct, 0) / 100.0)), 2) AS money_spent
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
**Brief snapshot of Customer activity**
| Country | Number of completed orders | Number of Customers | 
|---------|----------|-------|
| **India** | 36 | 13  |
| **Britain** | 28 | 9  |
| **Canada** | 28 | 11  |
| **USA** | 12 | 5  |
| **France** | 6 | 3  |

**Insight**: India represents the company's strongest market, accounting for the highest number of completed orders (36) from 13 customers. This suggests strong customer engagement and repeat purchasing behavior. In contrast, countries such as France recorded only 6 completed orders, highlighting potential opportunities to improve customer acquisition, engagement, and retention efforts in underperforming markets.

---
**Brief snapshot of monthly Revenue generated from product category**
| Order_date | Revenue | Top Category | 
|---------|----------|-------|
| 2022-01 | 6160.84 | Electronics  |
| 2022-02 | 5784.80 | Electronics  |
| 2022-09 | 3686.51 | Electronics  |
| 2022-10 | 534.29 | Apparel  |
| 2022-11 | 1306.98 | Travel  |

**Insight**: Electronics dominated monthly revenue performance, leading all product categories in over 80% of the months analyzed. This highlights its importance as the company's primary revenue-generating category.

---
### Yearly Cohort
| Year | Cohorts | Customer acquired |  Retained  | Avg retention | Avg profit per order |
|---------|----------|-------|--------|--------|--------|
| 2021     | 12  |   71   | 38    | 50.3%  | $307.07  |         
| 2022     | 12  |   50   |  24  |   48.9%  | $315.77  |        
| 2023     |  6 |   29   |  16   |  50.2%   | $397.03   |        

**Insight** 
- ⚠️ An overall retention rate less than 53% means that for every two customers we accquire only one come back. This has been essentially unchanged across 2021, 2022, and 2023. This is a structural pattern that our business has normalized, and we shouldn't.
- The four cohorts we need to investigate immediately: January 2021, January 2022, April 2022, and March 2023 each retained zero customers. These aren't small cohorts either — some had up to 3–5 customers with no return at all.
- Cohort sizes remain small. Average cohort is just 5 customers (max: 10). A single churn shifts rates by 10–20pp. Conclusions are directionally useful but should not drive high-confidence policy alone.

**Recommendations**
1. Grow cohort sizes before making structural decisions — at 5 customers per cohort on average, the margin of error is too high for confident policy changes.
2. Diagnose the four zero-retention cohorts — Jan 2021, Jan/Apr 2022, and Mar 2023 need a root-cause review. What products did those customers buy? What channel did they come from? Patterns here may reveal acquisition or fulfilment issues.
3. 
--- 

**Brief snapshot showing how discounts are being used**
| Category | Total_items | Discounted Items |  Avg Discounts |
|---------|----------|-------|--------|
| Electronics | 324 | 166  | 5.09  |
| Fitness | 260 | 127  | 5.04  |
| Home | 142 | 69  | 5.21  |
| Travel | 134 | 59  | 4.14  |

**Insight**:
- Half the catalog is discounted: 49.3%(644 of 1,307 items discounted) of all items carry a discount — essentially every second item. At scale, this risks training customers to wait for deals rather than buy at full price.
- Electronics drives the bulk of exposure: With 166 discounted items and a 5.09% avg depth, Electronics alone accounts for 26% of total discount burden — the single largest margin risk.

**Recommendations**
1. Audit the Electronics discount strategy — its sheer volume makes it the top margin risk. Test whether reducing the discount rate by even 5pp makes a positive difference
2. Link discount data to sales conversion and margin outcomes — the current dataset can't tell us if any of this spending is working. That linkage is the critical next step before any strategic decisions.

---
### Customer Behavior Analysis Report (First-time vs Repeat Customers)
| Customer Type | Orders | Revenue   | Avg Order Value |
| ------------- | ------ | --------- | --------------- |
| First-time    | 127    | 64,012.38 | 504.04          |
| Repeat        | 130    | 55,149.40 | 424.23          |

**Insight**:
- Volume is balanced — 130 repeat orders against 127 first-time orders. That near-parity is actually encouraging. What this tells us is that customers are coming back. Acquisition is also performing: first-time buyers are spending at a $504 average. The channels bringing people in are bringing in high-intent customers.
- Now here's the problem: The moment that same customer returns, their average order drops to $424 — a $80 fall, or 18% less per transaction. Revenue from repeat orders is 46% of total, even though repeat orders are 50.5% of volume. They're placing more orders but generating disproportionately less money.

**Recommendations**
- Introduce post-purchase upsell and cross-sell touchpoints — if repeat customers are buying fewer or cheaper items, product recommendations at checkout or in follow-up emails are the most direct lever to close the $80 gap.

---
## Executive Dashboard
![Executive Dashboard](dashboard/Executive%20Dashboard.png)

---
## Regional Performance Dashboard
![Regional Performance Dashboard](dashboard/Regional%20Performance%20Dashboard.png)

---
## Customer Analytics Dashboard
![Customer Analytic Dashboard](dashboard/customer%20dashboard%20(1).png)






