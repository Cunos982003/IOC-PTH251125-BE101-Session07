set search_path to shop_db;
CREATE TABLE customers(
    customer_id SERIAL PRIMARY KEY ,
    full_name varchar(100),
    email varchar(100) unique,
    city varchar(50)
);

CREATE TABLE Products(
    product_id SERIAL PRIMARY KEY ,
    product_name varchar(100),
    category TEXT[],
    price NUMERIC(10,2)
);

CREATE TABLE Orders(
    order_id SERIAL PRIMARY KEY ,
    customer_id int references customers(customer_id),
    product_id INT references Products(product_id),
    order_date DATE,
    quantity INT
);

INSERT INTO customers (full_name, email, city) VALUES
                                                   ('Nguyen Van A', 'a@example.com', 'Hanoi'),
                                                   ('Tran Thi B', 'b@example.com', 'HCM'),
                                                   ('Le Van C', 'c@example.com', 'Danang'),
                                                   ('Pham Thi D', 'd@example.com', 'Hanoi'),
                                                   ('Do Van E', 'e@example.com', 'HCM');

INSERT INTO Products (product_name, category, price) VALUES
                                                         ('Laptop Dell XPS', ARRAY['Electronics','Laptop'], 1500),
                                                         ('iPhone 14', ARRAY['Electronics','Mobile'], 1200),
                                                         ('AirPods Pro', ARRAY['Electronics','Accessory'], 250),
                                                         ('Office Chair', ARRAY['Furniture'], 180),
                                                         ('Mechanical Keyboard', ARRAY['Electronics','Accessory'], 120);

INSERT INTO Orders (customer_id, product_id, order_date, quantity) VALUES
                                                                       (1, 1, '2024-01-05', 1),
                                                                       (1, 2, '2024-02-10', 1),
                                                                       (2, 3, '2024-01-20', 2),
                                                                       (2, 5, '2024-03-11', 1),
                                                                       (3, 4, '2024-02-14', 3),
                                                                       (3, 1, '2024-01-22', 1),
                                                                       (4, 2, '2024-02-28', 1),
                                                                       (4, 3, '2024-03-15', 2),
                                                                       (5, 5, '2024-01-03', 5),
                                                                       (5, 4, '2024-02-07', 1);

CREATE INDEX idx_customer_email on customers(email);
CREATE INDEX idx_customer_city_hash on customers USING HASH(city);
CREATE INDEX idx_products_category_gin ON products USING GIN(category);
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE INDEX idx_products_price_gist ON products USING GIST(price);

DROP INDEX idx_customer_email, idx_customer_city_hash, idx_products_category_gin,idx_products_price_gist;


EXPLAIN ANALYZE
SELECT * From customers where email = 'a@example.com';
--Truoc
-- Seq Scan on customers  (cost=0.00..1.06 rows=1 width=558) (actual time=0.012..0.013 rows=1.00 loops=1)
--   Filter: ((email)::text = 'a@example.com'::text)
--   Rows Removed by Filter: 4
--   Buffers: shared hit=1
-- Planning:
--   Buffers: shared hit=5 dirtied=1
-- Planning Time: 0.807 ms
-- Execution Time: 0.025 ms
--Sau
-- Seq Scan on customers  (cost=0.00..1.06 rows=1 width=558) (actual time=0.020..0.022 rows=1.00 loops=1)
--   Filter: ((email)::text = 'a@example.com'::text)
--   Rows Removed by Filter: 4
--   Buffers: shared hit=1
-- Planning:
--   Buffers: shared hit=26 read=1
-- Planning Time: 5.990 ms
-- Execution Time: 0.038 ms

EXPLAIN ANALYZE
SELECT *
FROM products
WHERE category @> ARRAY ['Electronics'];
--Truoc
-- Seq Scan on products  (cost=0.00..1.06 rows=1 width=270) (actual time=0.018..0.020 rows=4.00 loops=1)
--   Filter: (category @> '{Electronics}'::text[])
--   Rows Removed by Filter: 1
--   Buffers: shared hit=1
-- Planning:
--   Buffers: shared hit=5
-- Planning Time: 0.767 ms
-- Execution Time: 0.037 ms

--Sau
-- Seq Scan on products  (cost=0.00..1.06 rows=1 width=270) (actual time=0.018..0.020 rows=4.00 loops=1)
--   Filter: (category @> '{Electronics}'::text[])
--   Rows Removed by Filter: 1
--   Buffers: shared hit=1
-- Planning:
--   Buffers: shared hit=27
-- Planning Time: 2.779 ms
-- Execution Time: 0.034 ms

EXPLAIN ANALYZE
SELECT * FROM products WHERE price between 500 AND 1000;
--Truoc
-- Seq Scan on products  (cost=0.00..1.07 rows=1 width=270) (actual time=0.025..0.025 rows=0.00 loops=1)
--   Filter: ((price >= '500'::numeric) AND (price <= '1000'::numeric))
--   Rows Removed by Filter: 5
--   Buffers: shared hit=1
-- Planning Time: 0.118 ms
-- Execution Time: 0.040 ms

--SAU
-- Seq Scan on products  (cost=0.00..1.07 rows=1 width=270) (actual time=0.023..0.023 rows=0.00 loops=1)
--   Filter: ((price >= '500'::numeric) AND (price <= '1000'::numeric))
--   Rows Removed by Filter: 5
--   Buffers: shared hit=1
-- Planning Time: 0.146 ms
-- Execution Time: 0.037 ms


CREATE INDEX idx_orders_date ON orders(order_date);
CLUSTER orders USING idx_orders_date;

CREATE VIEW v_top3_customers as
    SELECT c.customer_id, c.full_name, SUM(o.quantity) as total_item
    From customers c
    JOIN orders o on c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_item
LIMIT 3;

CREATE VIEW v_revenue_by_product as
    SELECT p.product_id,p.product_name,SUM(o.quantity * p.price) as total_revunue
    FROM Products p join Orders O on p.product_id = O.product_id
    GROUP BY p.product_id, p.product_name;

CREATE VIEW v_customer_city AS
SELECT customer_id, full_name, city
FROM customers
        WITH CHECK OPTION;

UPDATE v_customer_city
SET city = 'Hue'
WHERE customer_id = 1;



