--function_name() OVER (
--    [PARTITION BY partition_expression]
--    [ORDER BY sort_expression]
--    [frame_specification]
--)

SELECT
	AVG(list_price) OVER() AS avg_price
FROM production.products;


SELECT 
	ROW_NUMBER() OVER(
		ORDER BY first_name
	) AS RN,
	first_name,
	last_name,
	city
FROM sales.customers;

SELECT 
	ROW_NUMBER() OVER(
		PARTITION BY city
		ORDER BY first_name
	) AS RN,
	first_name,
	last_name,
	city
FROM sales.customers;


SELECT 
	ROW_NUMBER() OVER(
		PARTITION BY city
		ORDER BY first_name, last_name
	) AS RN,
	first_name,
	last_name,
	city
FROM sales.customers;

SELECT
	product_name,
	list_price,
	RANK() OVER(ORDER BY list_price) AS ranking,
	DENSE_RANK() OVER(ORDER BY list_price) AS dense_ranking
FROM production.products;

WITH cte_ranking AS (
	SELECT
		product_name,
		list_price,
		category_id,
		RANK() OVER(
			PARTITION BY category_id
			ORDER BY list_price
		) AS ranking
	FROM production.products
)
SELECT * FROM cte_ranking
WHERE ranking <= 2;

-- 4 ntile --> 100% = 25 * 4
-- 10 ntile --> 100% = 10 * 10
SELECT
	product_name,
	list_price,
	NTILE(4) OVER(
		ORDER BY list_price
	) AS ranking
FROM production.products;

WITH cte_date AS (
	SELECT 
	  customer_id,
	  order_date,
	  LAG(order_date, 1) OVER(
			PARTITION BY customer_id
			ORDER BY order_date 
		) AS prev_order,
	-- prev_diff
	  LEAD(order_date, 1) OVER(
			PARTITION BY customer_id
			ORDER BY order_date 
		) AS next_order
	-- next_diff
	FROM sales.orders
)
SELECT
	prev_order,
	next_order,
	DATEDIFF(DAY,prev_order,next_order)
FROM cte_date
WHERE prev_order IS NOT NULL
	AND next_order IS NOT NULL;

-- based on category I want to get the cheapest and expensive product
SELECT DISTINCT
	category_id,
	FIRST_VALUE(product_name) OVER (
		PARTITION BY category_id
		ORDER BY list_price
	) AS cheapest_product,
	LAST_VALUE(product_name) OVER (
		PARTITION BY category_id
		ORDER BY list_price
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS expensive_product
FROM production.products;

WITH ranked_products AS
(
    SELECT
        category_id,
        product_name,
        list_price,
        ROW_NUMBER() OVER (
            PARTITION BY category_id
            ORDER BY list_price
        ) AS cheapest_rank,
        ROW_NUMBER() OVER (
            PARTITION BY category_id
            ORDER BY list_price DESC
        ) AS expensive_rank
    FROM production.products
)
SELECT
    category_id,
    MAX(CASE WHEN cheapest_rank = 1 THEN product_name END) AS cheapest_product,
    MAX(CASE WHEN expensive_rank = 1 THEN product_name END) AS expensive_product
FROM ranked_products
GROUP BY category_id;

--ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  -- from first row to current
--ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING           -- current row plus one on each side
--RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- entire partition


--Partition rows: [1, 2, 3, 4, 5]
--Current row: 3

-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  -> [1, 2, 3]
-- ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING          -> [2, 3, 4]
-- ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING -> [1, 2, 3, 4, 5]


SELECT 
	o.order_id,
    o.order_date,
    oi.list_price
FROM sales.orders o
INNER JOIN sales.order_items oi
	ON o.order_id = oi.order_id
ORDER BY o.order_date, list_price;




SELECT
    o.order_id,
    o.order_date,
    oi.list_price,
    SUM(list_price) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM sales.order_items oi
INNER JOIN sales.orders o
ON o.order_id = oi.order_id
ORDER BY o.order_date;

-- DML -> Data manipulation Languages

SELECT * FROM production.categories;

INSERT INTO production.categories(category_name)
VALUES ('Electric Scooters');

DELETE FROM production.categories
WHERE category_id = 8;

UPDATE production.categories
SET category_name = 'Road Bikes'
WHERE category_id = 7; -- Road Bikes


