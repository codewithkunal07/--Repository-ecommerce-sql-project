-- Step 1: Create Database
CREATE DATABASE IF NOT EXISTS ecommerce_database;
USE ecommerce_database;

-- Step 2: Create Tables

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT,
    customer_name VARCHAR(100),
    region VARCHAR(100),
    PRIMARY KEY (customer_id)
);

CREATE TABLE products (
    product_id INT AUTO_INCREMENT,
    product_name VARCHAR(100),
    category VARCHAR(100),
    price DECIMAL(10, 2),
    PRIMARY KEY (product_id)
);

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT,
    customer_id INT,
    order_date DATE,
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE trucks (
    truck_id INT AUTO_INCREMENT,
    truck_name VARCHAR(100),
    PRIMARY KEY (truck_id)
);

CREATE TABLE shipments (
    shipment_id INT AUTO_INCREMENT,
    order_id INT,
    truck_id INT,
    delivery_status VARCHAR(50),
    PRIMARY KEY (shipment_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (truck_id) REFERENCES trucks(truck_id)
);

-- Step 3: Sample Analytics Queries

-- 1. Total number of orders
SELECT COUNT(*) AS total_orders FROM orders;

-- 2. Top 5 customers by spending
SELECT C.customer_id, customer_name, SUM(order_price) AS total_revenue
FROM customers AS C
JOIN (
    SELECT O.order_id, customer_id, quantity * price AS order_price
    FROM orders AS O
    JOIN order_items AS OI ON O.order_id = OI.order_id
    JOIN products AS P ON OI.product_id = P.product_id
) AS spending ON C.customer_id = spending.customer_id
GROUP BY C.customer_id
ORDER BY total_revenue DESC
LIMIT 5;

-- 3. Top selling products
SELECT P.product_name, SUM(OI.quantity) AS total
FROM order_items AS OI
JOIN products AS P ON OI.product_id = P.product_id
GROUP BY product_name
ORDER BY total DESC;

-- 4. Revenue by product category
SELECT category, SUM(quantity * price) AS revenue
FROM order_items AS OI
JOIN products AS P ON OI.product_id = P.product_id
GROUP BY category;

-- 5. Monthly order trend
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, COUNT(*) AS total_orders
FROM orders
GROUP BY month
ORDER BY month DESC;

-- 6. Delivery status distribution
SELECT delivery_status, COUNT(*) AS total,
ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 2) AS rate
FROM shipments
GROUP BY delivery_status;

-- 7. Truck utilization
SELECT truck_id, COUNT(shipment_id) AS num_shipments
FROM shipments
GROUP BY truck_id
ORDER BY num_shipments DESC;

-- 8. Region-wise sales
SELECT region, COUNT(order_id) AS total_orders, SUM(quantity * price) AS total_revenue
FROM products AS P
JOIN (
    SELECT C.region, O.order_id, OI.product_id, OI.quantity
    FROM orders AS O
    JOIN customers AS C ON O.customer_id = C.customer_id
    JOIN order_items AS OI ON O.order_id = OI.order_id
) AS region_data ON P.product_id = region_data.product_id
GROUP BY region;

-- 9. Average order value
SELECT AVG(order_total) AS avg_order_value
FROM (
    SELECT order_id, SUM(quantity * price) AS order_total
    FROM order_items AS OI
    JOIN products AS P ON OI.product_id = P.product_id
    GROUP BY order_id
) AS order_summary;

-- 10. Repeat customers
SELECT C.customer_id, customer_name, COUNT(*) AS total_orders
FROM customers AS C
JOIN orders AS O ON C.customer_id = O.customer_id
GROUP BY C.customer_id, customer_name
HAVING total_orders > 2
ORDER BY total_orders DESC;

-- 11. Shipment status count
SELECT delivery_status, COUNT(*) AS num_shipments
FROM shipments
GROUP BY delivery_status;

-- 12. Top 5 customer contribution (in %)
SELECT ROUND(
    (
        SELECT SUM(total_revenue)
        FROM (
            SELECT C.customer_id, SUM(order_price) AS total_revenue
            FROM customers AS C
            JOIN (
                SELECT O.order_id, customer_id, quantity * price AS order_price
                FROM orders AS O
                JOIN order_items AS OI ON O.order_id = OI.order_id
                JOIN products AS P ON OI.product_id = P.product_id
            ) AS spend ON C.customer_id = spend.customer_id
            GROUP BY C.customer_id
            ORDER BY total_revenue DESC
            LIMIT 5
        ) AS top5
    ) * 100 /
    (
        SELECT SUM(order_price)
        FROM (
            SELECT quantity * price AS order_price
            FROM order_items AS OI
            JOIN products AS P ON OI.product_id = P.product_id
        ) AS all_data
    ), 2
) AS top_5_contribution;