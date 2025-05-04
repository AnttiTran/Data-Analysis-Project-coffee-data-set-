SELECT * FROM city; 
SELECT *FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis
---Q1: Coffee Customers Count
---- How many people in each city are estimated to customer coffee, given that 25% of the population does?

SELECT

	city_name,
	ROUND((population * 0.25)/1000000
	,2) as coffee_consumers_in_millions,
	city_rank
	
FROM city 
ORDER By 2 DESC


---Q2: Total Revenue from Coffee Sales
----What is the total revenue from coffee sales across all cities in the last quarter of 2023?

SELECT *,
	EXTRACT (YEAR FROM SALE_DATE) AS year,
	EXTRACT (QUARTER FROM sale_date) AS quarter

FROM sales
WHere 
	Extract (YEAR FROM sale_date) = 2023
	AND
	EXTRACT (quarter FROM sale_date) = 4

-----Total Revenue

SELECT 
	City.city_name,
	SUM(Sales.total)as total_revenue

FROM sales AS Sales
JOIN customers AS Customers
On Sales.customer_id = Customers.customer_id
JOIN city as City
ON City.city_id = Customers.city_id
WHere 
	Extract (YEAR FROM Sales.sale_date) = 2023
	AND
	EXTRACT (quarter FROM Sales.sale_date) = 4
GROUP By 1
ORDER By 2 DESC


---Q3: Sales Count for Each Product
----How many unites of each coffee product have been sold? 

SELECT *
FROM products as Products

LEFT JOIN 
sales as Sales
On Sales.product_id = Products.product_id


SELECT 
	Products.product_name,
	COUNT (Sales.sale_id) as Total_orders
FROM products as Products

LEFT JOIN 
sales as Sales
On Sales.product_id = Products.product_id
GROUP By 1
ORDER By 2 DESC

-----> The store may consider the top 10 products, additionally, the merchandise product such as 'Tote Baf with Coffee Design' had a good number of order as well. 

---Q4: Average Sales Aount per City 
---- WHat is the average sales amount per customer in each city?

----Number of unique customer
SELECT 
	City.city_name,
	SUM(Sales.total)as total_revenue,
	COUNT(DISTINCT Sales.customer_id) as Total_customers
FROM sales AS Sales
JOIN customers AS Customers
On Sales.customer_id = Customers.customer_id
JOIN city as City
ON City.city_id = Customers.city_id
GROUP By 1
ORDER By 2 DESC

----- Average sales per customer

SELECT 
	City.city_name,
	SUM(Sales.total)as total_revenue,
	COUNT(DISTINCT Sales.customer_id) as Total_customers,
	ROUND(
		SUM(Sales.total):: numeric /
		COUNT(DISTINCT Sales.customer_id)::numeric,2) as Average_sales_per_customer
FROM sales AS Sales
JOIN customers AS Customers
On Sales.customer_id = Customers.customer_id
JOIN city as City
ON City.city_id = Customers.city_id
GROUP By 1
ORDER By 2 DESC

--> Pune had the highest sales average per customer


---Q5: City Population and Coffee Consumers
---- Provide a list of cities along with their populations and estimated coffee customers

WITH city_table as
	(SELECT 
		city_name,
		ROUND((population * 0.25)/1000000,2) as coffee_consumers
	FROM city), 

customer_table 

AS
	(SELECT 
		City.city_name, 
	COUNT(DISTINCT Customers.customer_id) as unique_customer
	FROM 
		sales as Sales
	JOIn customers as Customers
	ON Customers.customer_id = Sales.Customer_id
	JOIN city as City 
	On City.city_id = Customers.city_id
	GROUP By 1)

SELECT 
	customer_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customer_table.unique_customer
FROM city_table 
JOIN
customer_table 
ON city_table.city_name = customer_table.city_name


---Q6: Top Selling Products by City 
---- What are the top 3 selling products in each city based on sales volume? 
SELECT *
FROM sales as s
JOIN products as p
On s.product_id = p.product_id
JOIN customers as c
On c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = ci.city_id

-- Total Orders
SELECT * FROM --table

(SELECT 
	ci.city_name, 
	p.product_name, 
	COUNT(s.sale_id) as total_orders, 
	DENSE_RANK () OVER (PARTITION BY ci.city_name ORDER BY COUNT (s.sale_id)DESC) as rank
FROM sales as s
JOIN products as p
On s.product_id = p.product_id
JOIN customers as c
On c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = ci.city_id
Group By 1,2 
ORder BY 1, 3 DESC) as t1
where rank <=3

---Q7: Customer Segmentation by City 
----How many unique customers are there in each city who have purchased coffee products

SELECT * FROM products;

SELECT 
	ci.city_name,
	COUNT (DISTINCT c.customer_id)as unique_cx
	FROM city as ci
	LEFT JOIN customers as c
	On c.city_id = ci.city_id
	JOIN sales as s
	On s.customer_id = c.customer_id
	WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
	GROUP By 1

---Q8: Average Sales vs Rent
----Find each city and their average sales per customer and average rent per customer

SELECT *
FROM city as ci
	LEFT JOIN customers as c
	On c.city_id = ci.city_id
	JOIN sales as s
	On s.customer_id = c.customer_id
	WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)

	
WITH city_table AS (
    SELECT 
        ci.city_name, 
        SUM(s.total) AS total_revenue, 
		COUNT (DISTINCT s.customer_id) as total_cx,
        ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) AS average_sales_pr_cx
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
    ORDER BY total_revenue DESC  -- Removed the comma here
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent 
    FROM city

)
SELECT 
	cr.city_name, 
	cr.estimated_rent,
	ct.total_cx,
	ct.average_sales_pr_cx, 
ROUND(cr.estimated_rent::numeric / ct.total_cx::numeric, 2) AS avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 5 DESC

---> The highest rent Mumbai, Hyderabad, Bangalore, Ahmedabad, Kolkata
---> The highest sales per customer Pune, Chennai and Bangalore

---Q9: Monthly sales growth rate
---- Sales growth rate: calculate the percentage growth (or decline) in sales over time period (monthly)
-----By each city 

SELECT * FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id


WITH monthly_sales AS (
    SELECT 
        ci.city_name, 
        EXTRACT(MONTH FROM sale_date) AS month, 
        EXTRACT(YEAR FROM sale_date) AS year, 
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, month, year
),

growth_ratio AS (  
    SELECT 
        city_name,
        month, 
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER (PARTITION BY city_name ORDER BY year, month) AS last_month_sale
    FROM monthly_sales
    ORDER BY city_name, year, month
)

SELECT 
    city_name, 
    month, 
    year, 
    cr_month_sale, 
    last_month_sale, 
    ROUND((cr_month_sale - last_month_sale)::numeric / 
	last_month_sale::numeric * 100, 2) AS growth_ratio
	
FROM growth_ratio
WHERE last_month_sale IS NOT NULL; 

----Q10: Market potential analysis 
-----Indentify top 3 city based on highest sales, return city name, total sales, total rent and total customer, estimated coffee customer

	
WITH city_table AS (
    SELECT 
        ci.city_name, 
        SUM(s.total) AS total_revenue, 
		COUNT (DISTINCT s.customer_id) as total_cx,
        ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) AS average_sales_pr_cx
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
    ORDER BY total_revenue DESC  -- Removed the comma here
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent, 
		ROUND((population * 0.25)/1000000,3) as estimated_coffee_consumer_in_millions
    FROM city

)
SELECT 
	cr.city_name, 
	total_revenue, 
	cr.estimated_rent as total_rent,
	cr.estimated_rent,
	cr.estimated_coffee_consumer_in_millions,
	ct.total_cx,
	ct.average_sales_pr_cx, 
ROUND(cr.estimated_rent::numeric / ct.total_cx::numeric, 2) AS avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

/*--- Recommendation plan 

- City 1: Pune (average rent per customer is low (294), highest total revenue, average sales per customer is high) 
- City 2: Delhi (highest estimated coffee consumer which is 7.7 millions, highest total customer which is 68, average rent per customer is 330 (under the budget 500)
- City 3: Jaipur (highest number of customer which is 69, average rent per customer is low is 156, average sales per customer is better which is at 11.6 thousands)

