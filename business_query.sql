use ecommerce_practice;
# Q1 Who are our most engaged customers based on completed purchase history?

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
-- ----------------------------------------------------------------------------------
# Q2 Which product categories generate the most revenue monthly?

# I wrote a query that showed, for each month (formatted as YYYY-MM), the total revenue from completed orders only,
# the total number of completed orders, and the top-earning product category for that month. 

WITH M_Revenue AS
( 
SELECT
    DATE_FORMAT(order_date, '%Y-%m') as order_dates,
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
-- --------------------------------------------------------------------------------
# Q3 Which customer signup cohorts have the highest retention rates?

# I Wrote a query that groups customers by their signup month (YYYY-MM). For each cohort i showed: the number of customers  
# who signed up, the number who were retained (ordered in 2+ distinct months), the retention rate as a percentage,  
# and the average profit per order forthat cohort — where profit per order_item = (unit_price - cost_price) * quantity. 

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
-- -------------------------------------------------------------------------------
# Q4 How often are discounts being applied across product categories
 
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
-- -----------------------------------------------------------------------
# Q5 Do repeat customers spend more than new customers?

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
-- ---------------------------------------------------------------------------
# Q6 Identify the top 3 spenders per contries and include them into the VIP Loyalty programme.
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