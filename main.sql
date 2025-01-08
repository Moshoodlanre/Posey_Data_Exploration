-- Parch and Posey Data Exploration

-- Viewing the different tables
SELECT * 
FROM orders
WHERE occurred_at IS NOT NULL 
ORDER BY occurred_at;

SELECT * 
FROM accounts;

SELECT * 
FROM region;

SELECT * 
FROM sales_reps;

SELECT * 
FROM web_events;

-- Exploring the total amount of poster_qty paper ordered
SELECT COALESCE(SUM(poster_qty), 0) AS total_poster_sales
FROM orders;

-- Exploring total amount of standard_qty paper ordered
SELECT COALESCE(SUM(standard_qty), 0) AS total_standard_sales
FROM orders;

-- Finding the total dollar amount of sales
SELECT COALESCE(SUM(total_amt_usd), 0) AS total_dollar_sales
FROM orders;

-- Finding the standard_amt_usd per unit of standard_qty paper
SELECT 
    COALESCE(SUM(standard_amt_usd), 0) / NULLIF(SUM(standard_qty), 0) AS standard_price_per_unit
FROM orders;

-- Finding the earliest order ever placed
SELECT MIN(occurred_at) AS earliest_order_date
FROM orders;

-- Mean amounts spent and quantities purchased for each paper type
SELECT 
    COALESCE(AVG(standard_qty), 0) AS mean_standard_qty, 
    COALESCE(AVG(gloss_qty), 0) AS mean_gloss_qty, 
    COALESCE(AVG(poster_qty), 0) AS mean_poster_qty, 
    COALESCE(AVG(standard_amt_usd), 0) AS mean_standard_amt_usd, 
    COALESCE(AVG(gloss_amt_usd), 0) AS mean_gloss_amt_usd, 
    COALESCE(AVG(poster_amt_usd), 0) AS mean_poster_amt_usd
FROM orders;

-- Exploring the name for each region for every order where standard_qty > 100 and poster_qty > 50
SELECT 
    r.name AS region, 
    a.name AS account, 
    COALESCE(o.total_amt_usd, 0) / NULLIF(o.total, 0) AS unit_price
FROM region r
JOIN sales_reps s ON s.region_id = r.id
JOIN accounts a ON a.sales_rep_id = s.id
JOIN orders o ON o.account_id = a.id
WHERE o.standard_qty > 100 AND o.poster_qty > 50
ORDER BY unit_price;

-- Exploring the region, sales reps, and accounts for the Midwest region
SELECT 
    r.name AS region, 
    s.name AS rep, 
    a.name AS account
FROM sales_reps s
JOIN region r ON s.region_id = r.id
JOIN accounts a ON a.sales_rep_id = s.id
WHERE r.name = 'Midwest'
ORDER BY a.name;

-- Exploring all the orders that occurred in 2015
SELECT 
    o.occurred_at, 
    a.name AS account_name, 
    o.total, 
    o.total_amt_usd
FROM accounts a
JOIN orders o ON o.account_id = a.id
WHERE o.occurred_at BETWEEN '2015-01-01' AND '2015-12-31'
ORDER BY o.occurred_at DESC;

-- Determining the number of times a particular channel was used for each sales rep
SELECT 
    s.name AS sales_rep_name, 
    w.channel, 
    COUNT(*) AS num_events
FROM accounts a
JOIN web_events w ON a.id = w.account_id
JOIN sales_reps s ON s.id = a.sales_rep_id
GROUP BY s.name, w.channel
ORDER BY num_events DESC;

-- Determining the number of times a particular channel was used for each region
SELECT 
    r.name AS region, 
    w.channel, 
    COUNT(*) AS num_events
FROM accounts a
JOIN web_events w ON a.id = w.account_id
JOIN sales_reps s ON s.id = a.sales_rep_id
JOIN region r ON r.id = s.region_id
GROUP BY r.name, w.channel
ORDER BY num_events DESC;

-- How many sales reps manage more than 5 accounts?
SELECT 
    s.id, 
    s.name, 
    COUNT(*) AS num_accounts
FROM accounts a
JOIN sales_reps s ON s.id = a.sales_rep_id
GROUP BY s.id, s.name
HAVING COUNT(*) > 5
ORDER BY num_accounts;

-- Classifying customers into levels based on total sales
SELECT 
    a.name AS account_name, 
    SUM(total_amt_usd) AS total_spent, 
    CASE 
        WHEN SUM(total_amt_usd) > 200000 THEN 'top'
        WHEN SUM(total_amt_usd) > 100000 THEN 'middle'
        ELSE 'low' 
    END AS customer_level
FROM orders o
JOIN accounts a ON o.account_id = a.id
GROUP BY a.name
ORDER BY total_spent DESC;

-- Classifying customers based on their spending in 2016 and 2017
SELECT 
    a.name AS account_name, 
    SUM(total_amt_usd) AS total_spent, 
    CASE 
        WHEN SUM(total_amt_usd) > 200000 THEN 'top'
        WHEN SUM(total_amt_usd) > 100000 THEN 'middle'
        ELSE 'low' 
    END AS customer_level
FROM orders o
JOIN accounts a ON o.account_id = a.id
WHERE occurred_at BETWEEN '2016-01-01' AND '2017-12-31'
GROUP BY a.name
ORDER BY total_spent DESC;

-- Sales reps with the largest sales total in each region
WITH t1 AS (
    SELECT 
        s.name AS sales_rep_name, 
        r.name AS region_name, 
        SUM(o.total_amt_usd) AS total_sales
    FROM sales_reps s
    JOIN accounts a ON a.sales_rep_id = s.id
    JOIN orders o ON o.account_id = a.id
    JOIN region r ON r.id = s.region_id
    GROUP BY s.name, r.name
), 
t2 AS (
    SELECT 
        region_name, 
        MAX(total_sales) AS max_sales
    FROM t1
    GROUP BY region_name
)
SELECT 
    t1.sales_rep_name, 
    t1.region_name, 
    t1.total_sales
FROM t1
JOIN t2 ON t1.region_name = t2.region_name 
AND t1.total_sales = t2.max_sales;
