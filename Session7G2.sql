Set search_path to revenue;
CREATE TABLE Customer(
    customer_id SERIAL Primary Key ,
    full_name varchar(100),
    region varchar(50)
);

CREATE TABLE orders(
    order_id SERIAL PRIMARY KEY ,
    customer_id INT REFERENCES Customer(customer_id),
    total_amount DECIMAL(10,2),
    order_date DATE,
    status varchar(20)
);
CREATE TABLE product(
    product_id SERIAL PRIMARY KEY ,
    name varchar(100),
    price DECIMAL(10,2),
    category varchar(50)
);
CREATE TABLE order_detail(
    order_id INT references orders(order_id),
    product_id INT references product(product_id),
    quantity INT
);

CREATE VIEW v_revenue_by_region as
    SELECT c.region , SUM(o.total_amount) as total_revunue
From Customer c
Join Orders o on c.customer_id = o.customer_id
GROUP BY c.region;

SELECT * from v_revenue_by_region
order by total_revunue
LIMIT 3;

CREATE MATERIALIZED VIEW mv_monthly_sales as
    Select date_trunc('month',order_date) as month,
    Sum(total_amount) as monthly_revunue
    From Orders
    GROUP BY date_trunc('month',order_date);

CREATE OR REPLACE VIEW v_order_status AS
SELECT order_id, status
FROM orders
WHERE status IN ('pending', 'processing')
        WITH CHECK OPTION;

UPDATE v_order_status
Set status = 'processing'
WHERE order_id=10;

-- Tạo View phức hợp (Nested View):
-- Từ v_revenue_by_region, tạo View mới v_revenue_above_avg chỉ hiển thị khu vực có doanh thu > trung bình toàn quốc
CREATE OR REPLACE VIEW v_revenue_above_avg AS
SELECT region,total_revunue
FROM v_revenue_by_region
WHERE total_revunue > (
    SELECT AVG(total_revunue)
    FROM v_revenue_by_region
);

