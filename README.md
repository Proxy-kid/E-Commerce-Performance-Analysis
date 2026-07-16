# 🛒 Kolapays E-Commerce Analysis

![Project Status](https://img.shields.io/badge/Status-Complete-success)
![SQL](https://img.shields.io/badge/SQL-MySQL-blue)
![Tableau](https://img.shields.io/badge/Tableau-Dashboard-orange)

## 📑 Table of Contents
- [Project Overview](#project-overview)
- [Project Objectives](#-project-objectives)
- [Business Questions](#business-questions)
- [Data Source](#-data-source)
- [Tools Used](#-tools-used)
- [SQL Analysis & Queries](#sql-analysis--queries)
  - [Q1: Most Engaged Customers](#q1-who-are-our-most-engaged-customers-based-on-completed-purchase-history)
  - [Q2: Top Monthly Revenue Categories](#q2-which-product-categories-generate-the-most-revenue-monthly)
  - [Q3: Customer Cohort Retention](#q3-which-customer-signup-cohorts-have-the-highest-retention-rates)
  - [Q4: Product Category Discounts](#q4-how-often-are-discounts-being-applied-across-product-categories)
  - [Q5: Repeat vs. New Customer Spend](#q5-do-repeat-customers-spend-more-than-new-customers)
  - [Q6: Top 3 Spenders per Country (VIP)](#q6-identify-the-top-3-spenders-per-countries-and-include-them-into-the-vip-loyalty-programme)
- [Key Findings & Recommendations](#-key-findings--recommendations)
  - [Market & Revenue Performance](#1-market--revenue-performance)
  - [Yearly Cohort Retention Analysis](#2-yearly-cohort-retention-analysis)
  - [Catalog Discount Strategy](#3-catalog-discount-strategy)
  - [First-Time vs. Repeat Customer Behavior](#4-first-time-vs-repeat-customer-behavior)
- [Tableau Dashboards](#-interactive-tableau-dashboards)
  - [Executive Performance Dashboard](#-executive-performance-dashboard)
  - [Regional Performance Dashboard](#%EF%B8%8F-regional-performance-dashboard)
  - [Customer Analytics Dashboard](#-customer-analytics-dashboard)
-  [Repository Structure](#-repository-structure)

  


> ## Project Overview
> 
> Kolapays E-Commerce Analysis is a portfolio project based on a fictional e-commerce company, Kolapays, which sells products across multiple categories to customers in different regions worldwide. The project showcases an end-to-end data analytics workflow using SQL and Tableau.
>
---

## 🎯 Project Objectives
**Specific Objectives**:
- Analyze sales performance and revenue trends over time.
- Identify the highest-performing product categories.
- Evaluate customer purchasing behavior and retention patterns.
- Compare first-time and returning customer performance.
- Assess regional sales performance across different markets.
- Build an interactive Tableau dashboard for business stakeholders.

## Business Questions
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
### Q1 Who are our most engaged customers based on completed purchase history
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
#### 📊 Expected Query Output
|  full_name, | country, | number_of_orders |   
|-------------|----------|------------------|
| Olivia Johnson,  | BR,    | 6              | 
| Chris  White,    | IN,    | 6              |   
| Sam     Brown,    | DE,    | 5              |   
| Eve    Miller,   | AU,    | 4              |   
| Alice   Moore,    | ZA,    | 4              |  
| Alice   Taylor,   | BR,    | 4              |   

### Q2 Which product categories generate the most revenue monthly
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
#### 📊 Expected Query Output
| # order_dates | revenue | top_category |
|---------------|---------|--------------|
| 2022-01       | 6160.84 | Electronics  |
| 2022-02       | 5784.80 | Electronics  |
| 2022-03       | 9091.86 | Electronics  |
| 2022-04       | 5790.13 | Electronics  |
| 2022-05       | 5108.69 | Electronics  |
| 2022-06       | 4285.19 | Electronics  |
| 2022-07       | 4209.90 | Travel       |

### Q3 Which customer signup cohorts have the highest retention rates
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
#### 📊 Expected Query Output
| # signup_month | unique_customers | retained_customers | retention_rate_pct | avg_profit_per_order |
|----------------|------------------|--------------------|--------------------|----------------------|
| 2021-01        | 1                | 0                  | 0.00               | 289.95               |
| 2021-02        | 5                | 3                  | 60.00              | 277.32               |
| 2021-03        | 7                | 6                  | 85.71              | 274.88               |
| 2021-04        | 7                | 2                  | 28.57              | 391.78               |
| 2021-05        | 10               | 7                  | 70.00              | 315.80               |

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
#### 📊 Expected Query Output
| category  | total_items | discounted_items | avg_discount |
|-------------|-------------|------------------|--------------|
| Electronics | 324         | 166              | 5.09         |
| Fitness     | 260         | 127              | 5.04         |
| Kitchen     | 133         | 71               | 5.23         |
| Home        | 142         | 69               | 5.21         |
| Accessories | 133         | 67               | 5.41         |
| Travel      | 134         | 59               | 4.14         |
| Footwear    | 106         | 46               | 4.39         |
| Apparel     | 75          | 39               | 5.73         |
                                                                                       
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
#### 📊 Expected Query Output
| category   | number_order | revenue  | avg_order_value |
|--------------|--------------|----------|-----------------|
| first_order  | 127          | 64012.74 | 504.04          |
| repeat_order | 130          | 55149.40 | 424.23          |
### Q6 Identify the top 3 spenders per countries and include them into the VIP Loyalty programme.
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
#### 📊 Brief Snapshot of the Expected Query Output

| full_name    | country | money_spent | country_rank |
|----------------|---------|-------------|--------------|
| Eve Miller     | AU      | 2297.91     | 1            |
| Quinn Thomas   | AU      | 1175.33     | 2            |
| Chris Garcia   | AU      | 1135.13     | 3            |
| Olivia Johnson | BR      | 2528.81     | 1            |
| Chris Moore    | BR      | 2522.79     | 2            |
| Carol Hall     | BR      | 1325.35     | 3            |
---
## 🔍 Key Findings & Recommendations

### 1. Market & Revenue Performance
**Insight:**
* Electronics heavily dominates financial performance, capturing the top slot in over 80% of the months analyzed. This makes it the core driver of overall business revenue.
* India is the strongest market, leading in completed orders (36) and customer volume (13). This indicates strong local engagement and repeat purchasing habits. Conversely, underperforming markets like France (6 orders) present clear opportunities for targeted customer acquisition campaigns.
---

### 2. Yearly Cohort Retention Analysis
#### 💡 Cohort Insights
* **Stagnant Retention:** Overall retention stays below 53% across 2021–2023. For every two customers acquired, only one returns. This structural baseline needs active strategic intervention.
* **Critical Drops:** Four specific cohorts (Jan 2021, Jan 2022, Apr 2022, and Mar 2023) experienced a **0% retention rate**, keeping zero return customers despite healthy initial cohort sizes (3–5 buyers).
* **Sample Size Constraint:** Average monthly cohorts are small (5 customers, max 10). Because a single user's churn skews metrics by 10–20 percentage points, these metrics should be treated as directional rather than absolute.

#### 🛠️ Cohort Recommendations
1. **Increase Sample Sizes:** Expand customer acquisition to build larger cohorts before implementing massive structural policy changes.
2. **Perform Root-Cause Reviews:** Audit the zero-retention cohorts to identify shared patterns in purchased items, marketing channels, or fulfillment delays.

---

### 3. Catalog Discount Strategy
#### 💡 Discount Insights
* **Margin Erosion:** Nearly half the catalog (49.3%, or 644 of 1,307 items) is heavily discounted. Continuous promotional pricing risks training customers to avoid purchasing at full retail value.
* **Concentrated Risk:** Electronics drives the heaviest exposure, accounting for 26% of the company's entire discount volume across 166 unique items.

#### 🛠️ Discount Recommendations
1. **Optimize Electronics Safeguards:** Test lowering the Electronics promotional discount rate by 5 percentage points to see if margin health improves without causing volume drops.
2. **Map Discounts to Conversions:** Connect promotional events to hard conversion and retention margins to confirm if historical price cuts delivered measurable ROI.

---

### 4. First-Time vs. Repeat Customer Behavio
#### 💡 Segment Insights
* **Healthy Acquisition Parity:** Volume split is closely balanced (130 repeat vs. 127 first-time orders). Top-of-funnel channels successfully source high-intent initial purchasers with an average order value of $504.04.
* **The Return Value Gap:** Repeat customers show an 18% decline in transaction value ($80 less per order). While generating 50.5% of total order volume, repeat business accounts for only 46% of total revenue.

#### 🛠️ Segment Recommendations
1. **Deploy Post-Purchase Upsells:** Launch dedicated cross-selling, post-purchase checkout loops, or specialized email sequences to close the $80 gap and boost repeat transaction values.

---
## 📊 Interactive Tableau Dashboards

*💡 **Hiring Team Note:** Click any dashboard image layout below to open the fully interactive visualization on Tableau

.*

### 📈 Executive Performance Dashboard
[![Executive Dashboard](dashboard/Executive%20Dashboard.png)](https://public.tableau.com/views/Kolapays-Ecommerce-Analysis/ExecutiveDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

### 🗺️ Regional Performance Dashboard
[![Regional Performance Dashboard](dashboard/Regional%20Performance%20Dashboard.png)](https://public.tableau.com/views/Kolapays-Ecommerce-Analysis/RegionalPerformanceDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

### 👤 Customer Analytics Dashboard
[![Customer Analytics Dashboard](dashboard/customer%20dashboard%20(1).png)](https://public.tableau.com/views/Kolapays-Ecommerce-Analysis/customerdashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---
## 📂 How to Use This Repository


### Run the SQL Analysis
1. Open the data folder and locate kolapays_schema.sql
2. Run file on a MYSQL Workbench to generate this datase
3. Open the sql folder and locate analysis_query.sql
4. Run the script section by section
5. Review findinds 

## 📁 Repository Structure

```
E-Commerce-Performance-Analysis/
│
├── dashboard/                         		# Screenshots of dashboards
│   ├── Executive Dashboard.png
│   ├── Regional Performance Dashboard.png
│   ├── customer dashboard(1).png
├── sql/		                         	# Main SQL analysis script
|   ├── analysis_query.sql
├── data/                                	# Database schema script
|   ├── kolapays_schema.sql
├── README.md                           	# This file





