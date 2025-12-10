set search_path to "order";

CREATE TABLE Customer(
    customer_id SERIAL PRIMARY KEY,
    full_name varchar(100),
    email varchar(100),
    phone varchar(15)
);
CREATE table Orders(
    order_id SERIAL PRIMARY KEY ,
    customer_id INT references Customer(customer_id),
    total_amount decimal(10,2),
    order_date DATE
);

--Tạo một View tên v_order_summary hiển thị
CREATE VIEW v_order_summary as
    Select c.full_name, o.total_amount, o.order_date
    from Customer c
Join Orders O on c.customer_id = O.customer_id;
--Viết truy vấn để xem tất cả dữ liệu từ View
SELECT * From v_order_summary;
--Cập nhật tổng tiền đơn hàng thông qua View
DROP VIEW IF EXISTS v_order_summary;

CREATE VIEW v_order_summary AS
SELECT
    o.order_id,
    c.full_name,
    o.total_amount,
    o.order_date
FROM Orders o
         JOIN Customer c ON c.customer_id = o.customer_id;

--Tạo một View thứ hai v_monthly_sales thống kê tổng doanh thu mỗi tháng
CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(total_amount) AS total_revenue
FROM Orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;
--DROP VIEW

DROP VIEW v_order_summary ;
DROP MATERIALIZED VIEW IF EXISTS v_monthly_sales;



