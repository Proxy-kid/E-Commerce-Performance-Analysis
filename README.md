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
1. Who are our most loyal customers based on completed purchase history?
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
### Q1 Who are our most loyal customers based on completed purchase history?
```sql
# Write a query that returns each customer's full name, country, and total number of orders they have placed. Only include customers 
# who have placed at least 2 orders. Sort the results by order count from highest to lowest.

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

