-- -----------Create Database--------------------------------------------------

CREATE DATABASE Northwind;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------- DATA MANIPULATION:-------------------------------------------------------------------------

# Insert a new category into the categories table ?

INSERT INTO categories (categoryID, categoryName, description)
VALUES (6, 'New Category', 'Description of New Category');


# Update the product price for a specific product ?

UPDATE products
SET unitPrice = 15.99
WHERE productID = 123;


# Delete a discontinued product from the products table. ?

DELETE FROM products
WHERE productID = 456 AND discontinued = 1;



# Add a new employee to the employees table ?

INSERT INTO employees (employeeID, employeeName, title, city, country, reportsTo)
VALUES (10, 'John Doe', 'Sales Manager', 'New York', 'USA', 1);



#  Update the city for a specific customer?

UPDATE customers
SET city = 'Los Angeles'
WHERE customerID = 'ALFKI';



# Delete an order from the orders table ?

DELETE FROM orders
WHERE orderID = 10248;


-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------- DATA CLEANNIG ------------------------------------------------------------------------------------------

#  Identify and remove duplicate records from the customers table ?

DELETE FROM customers
WHERE customerID IN (
    SELECT customerID
    FROM (
        SELECT customerID, ROW_NUMBER() OVER (PARTITION BY customerID ORDER BY customerID) AS row_num
        FROM customers
    ) AS duplicates
    WHERE row_num > 1
);



#  Replace NULL values in the product quantity column with 0. ?

UPDATE products
SET quantityPerUnit = '0'
WHERE quantityPerUnit IS NULL;




#  Trim leading and trailing spaces from the contact name column in the customers table. ?

UPDATE customers
SET contactName = TRIM(contactName);



#  Convert order dates to a standardized format. ?

UPDATE orders
SET orderDate = DATE_FORMAT(orderDate, '%Y-%m-%d');



#  Remove special characters from the product name column ?

UPDATE products
SET productName = REGEXP_REPLACE(productName, '[^a-zA-Z0-9 ]', '');



#  Normalize city names to uppercase ?

UPDATE customers
SET city = UPPER(city);



-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------- PRODUCT ---------------------------------------------------------------------------------------------------



#  . List all products along with their categories

SELECT p.productID, p.productName, c.categoryName
FROM products p
INNER JOIN categories c ON p.categoryID = c.categoryID;



#  .How many products are there in each category?

SELECT c.categoryID, c.categoryName, COUNT(*) AS total_products
FROM products p
JOIN categories c ON p.categoryID = c.categoryID
GROUP BY c.categoryID, c.categoryName;



# Calculate the total quantity of each product sold. ?

SELECT od.productID, p.productName, SUM(od.quantity) AS total_quantity_sold
FROM Order_details od
INNER JOIN products p ON od.productID = p.productID
GROUP BY od.productID, p.productName;



# Find the top-selling products ?

SELECT od.productID, p.productName, SUM(od.quantity) AS total_quantity_sold
FROM Order_details od
INNER JOIN products p ON od.productID = p.productID
GROUP BY od.productID, p.productName
ORDER BY total_quantity_sold DESC
LIMIT 5;



# Which category has the highest average unit price?

SELECT c.categoryID, c.categoryName, AVG(p.unitPrice) AS avg_unit_price
FROM products p
JOIN categories c ON p.categoryID = c.categoryID
GROUP BY c.categoryID, c.categoryName
ORDER BY avg_unit_price DESC
LIMIT 1;



#  Find products with the highest and lowest unit prices ? 

SELECT MAX(p.unitPrice) AS max_unit_price, MIN(p.unitPrice) AS min_unit_price
FROM products p;



# How many products have been discontinued in each category?

SELECT c.categoryID, c.categoryName, SUM(p.discontinued) AS discontinued_products
FROM products p
JOIN categories c ON p.categoryID = c.categoryID
GROUP BY c.categoryID, c.categoryName;



#Rank products based on their total quantity sold in descending order for each category. ?

SELECT productID, productName, categoryName, total_quantity_sold,
RANK() OVER (PARTITION BY categoryID ORDER BY total_quantity_sold DESC) AS quantity_sold_rank
FROM (
SELECT p.productID, p.productName, c.categoryID, c.categoryName, SUM(od.quantity) AS total_quantity_sold
FROM products p
JOIN order_details od ON p.productID = od.productID
JOIN categories c ON p.categoryID = c.categoryID
GROUP BY p.productID, p.productName, c.categoryID, c.categoryName
) AS subquery;



# What is the total quantity sold for each product in the 'Beverages' category?

SELECT p.productID, p.productName, SUM(od.quantity) AS total_quantity_sold
FROM products p
JOIN order_details od ON p.productID = od.productID
JOIN categories c ON p.categoryID = c.categoryID
WHERE c.categoryName = 'Beverages'
GROUP BY p.productID, p.productName;



-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------- CUSTOMERS  -----------------------------------------------------------------------------------------
# List the orders along with the customer details (customer name and city) where the total quantity of products ordered is greater than 100. ?

SELECT o.orderID, c.companyName AS customer_name, c.city AS customer_city
FROM orders o
JOIN customers c ON o.customerID = c.customerID
JOIN (SELECT orderID, SUM(quantity) AS total_quantity FROM order_details GROUP BY orderID) AS sub ON o.orderID = sub.orderID
WHERE sub.total_quantity > 100;



# Identify customers who have placed the most orders. ?

SELECT o.customerID, COUNT(o.orderID) AS order_count
FROM orders o
GROUP BY o.customerID
ORDER BY order_count DESC
LIMIT 1;



# .  Which customers have not placed any orders?

SELECT customerID, companyName
FROM customers
WHERE customerID NOT IN (SELECT DISTINCT customerID FROM orders);



# Find the customers who have not placed any orders after the year 2000. ?

 SELECT c.customerID, c.companyName
FROM customers c
LEFT JOIN orders o ON c.customerID = o.customerID
WHERE o.orderDate IS NULL OR YEAR(o.orderDate) <= 2000;



#Identify customers with the highest lifetime value. ?

SELECT o.customerID, SUM(od.unitPrice * od.quantity) AS lifetime_value
FROM orders o
INNER JOIN Order_details od ON o.orderID = od.orderID
GROUP BY o.customerID
ORDER BY lifetime_value DESC
LIMIT 1;



-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ---------------------------------------------------------------- SALES & REVENUE--------------------------------------------------------------------------------------------


# Determine the average order value. ?

SELECT AVG(od.unitPrice * od.quantity) AS average_order_value
FROM Order_details od;



# List the orders where the quantity of a single product ordered is greater than the average quantity of that product ordered across all orders. ?

SELECT od.orderID, od.productID, od.quantity
FROM order_details od
JOIN (SELECT productID, AVG(quantity) AS avg_quantity FROM order_details GROUP BY productID) AS sub ON od.productID = sub.productID
WHERE od.quantity > sub.avg_quantity;



# Determine the difference in days between each order and the previous order for each customer ?

SELECT customerID, orderDate, previous_order_date,
DATEDIFF(orderDate, previous_order_date) AS days_between_orders
FROM (
SELECT customerID, orderDate,
LAG(orderDate) OVER (PARTITION BY customerID ORDER BY orderDate) AS previous_order_date
FROM orders
) AS subquery;




#  Calculate the total revenue generated from orders. ? 

SELECT SUM(od.unitPrice * od.quantity) AS total_revenue
FROM Order_details od;



# Calculate total revenue for each month. ?

SELECT YEAR(o.orderDate) AS order_year, MONTH(o.orderDate) AS order_month, SUM(od.unitPrice * od.quantity) AS total_revenue
FROM orders o
INNER JOIN Order_details od ON o.orderID = od.orderID
GROUP BY order_year, order_month;



# Analyze sales performance by category.

SELECT c.categoryName, SUM(od.unitPrice * od.quantity) AS total_revenue
FROM Order_details od
INNER JOIN products p ON od.productID = p.productID
INNER JOIN categories c ON p.categoryID = c.categoryID
GROUP BY c.categoryName;



# Analyze sales trends over time. ?

SELECT YEAR(o.orderDate) AS order_year, MONTH(o.orderDate) AS order_month, SUM(od.unitPrice * od.quantity) AS total_revenue
FROM orders o
INNER JOIN Order_details od ON o.orderID = od.orderID
GROUP BY order_year, order_month
ORDER BY order_year, order_month;



#Analyze sales performance by region (city/country) ?

SELECT c.country, c.city, SUM(od.unitPrice * od.quantity) AS total_revenue
FROM orders o
INNER JOIN customers c ON o.customerID = c.customerID
INNER JOIN Order_details od ON o.orderID = od.orderID
GROUP BY c.country, c.city;



# Calculate the total revenue for each salesperson  ?

SELECT e.employeeID, e.employeeName, SUM(od.unitPrice * od.quantity) AS total_revenue
FROM employees e
INNER JOIN orders o ON e.employeeID = o.employeeID
INNER JOIN Order_details od ON o.orderID = od.orderID
GROUP BY e.employeeID, e.employeeName;



#  . What is the total revenue generated by each product category?

SELECT c.categoryID, c.categoryName, SUM(od.quantity * od.unitPrice) AS total_revenue
FROM order_details od
JOIN products p ON od.productID = p.productID
JOIN categories c ON p.categoryID = c.categoryID
GROUP BY c.categoryID, c.categoryName;



# Identify the top 3 categories with the highest total revenue. ?

SELECT c.categoryID, c.categoryName, SUM(od.quantity * od.unitPrice) AS total_revenue
FROM order_details od
JOIN products p ON od.productID = p.productID
JOIN categories c ON p.categoryID = c.categoryID
GROUP BY c.categoryID, c.categoryName
ORDER BY total_revenue DESC
LIMIT 3;



-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------- SHIPPING -----------------------------------------------------------------------------------------



# Determine the average shipping time for orders. ?

SELECT AVG(DATEDIFF(o.shippedDate, o.orderDate)) AS average_shipping_time
FROM orders o
WHERE o.shippedDate IS NOT NULL;



# Identify the most used shipping companies. ?

SELECT o.shipperID, s.companyName, COUNT(o.shipperID) AS usage_count
FROM orders o
INNER JOIN shippers s ON o.shipperID = s.shipperID
GROUP BY o.shipperID, s.companyName
ORDER BY usage_count DESC
LIMIT 1;



# List orders with the highest freight charges. ?

SELECT *
FROM orders o
WHERE o.freight = (SELECT MAX(freight) FROM orders);




# . How many orders have been shipped late (shipped after the required date)?

SELECT COUNT(*) AS late_orders
FROM orders
WHERE shippedDate > requiredDate;



# . What is the average freight cost per order for each country?

SELECT country, AVG(freight) AS avg_freight_cost
FROM orders
JOIN customers ON orders.customerID = customers.customerID
GROUP BY country;




#  What is the average shipping time (in days) for each shipper?

SELECT 
    s.shipperID, 
    s.companyName, 
    AVG(ABS(DATEDIFF(o.orderDate, o.shippedDate))) AS avg_shipping_time
FROM 
    orders o
JOIN 
    shippers s ON o.shipperID = s.shipperID
GROUP BY 
    s.shipperID, 
    s.companyName;



#How many orders have been shipped via each shipper in each country?

SELECT s.shipperID, s.companyName, c.country, COUNT(*) AS total_orders_shipped
FROM orders o
JOIN shippers s ON o.shipperID = s.shipperID
JOIN customers c ON o.customerID = c.customerID
GROUP BY s.shipperID, s.companyName, c.country;



-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------EMPLOYEE---------------------------------------------------------------------------



#  Identify the best and worst performing salespersons ?

SELECT e.employeeID, e.employeeName, SUM(od.unitPrice * od.quantity) AS total_revenue
FROM employees e
INNER JOIN orders o ON e.employeeID = o.employeeID
INNER JOIN Order_details od ON o.orderID = od.orderID
GROUP BY e.employeeID, e.employeeName
ORDER BY total_revenue DESC
#ORDER BY total_revenue ASC
LIMIT 1;




# . Who are the top 5 employees with the most orders?

SELECT e.employeeID, e.employeeName, COUNT(*) AS total_orders
FROM employees e
JOIN orders o ON e.employeeID = o.employeeID
GROUP BY e.employeeID, e.employeeName
ORDER BY total_orders DESC
LIMIT 5;



# .What is the average number of orders per employee in each city?

SELECT e.city, AVG(sub.total_orders) AS avg_orders_per_employee
FROM employees e
LEFT JOIN (SELECT employeeID, COUNT(*) AS total_orders FROM orders GROUP BY employeeID) AS sub ON e.employeeID = sub.employeeID
GROUP BY e.city;


