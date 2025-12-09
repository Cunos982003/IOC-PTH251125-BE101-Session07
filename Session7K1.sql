set search_path to book;
CREATE TABLE book(
    book_id SERIAL PRIMARY KEY,
    title varchar(225),
    author varchar(100),
    genre varchar(50),
    price DECIMAL(10,2),
    Description TEXT,
    create_at TIMESTAMP DEFAULT current_timestamp
);

--Tạo các chỉ mục phù hợp để tối ưu truy vấn

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_book_author_trgm
    ON book
        USING gin (author gin_trgm_ops);

CREATE INDEX idx_book_genre
    ON book (genre);
--So sánh thời gian truy vấn trước và sau khi tạo Index (dùng EXPLAIN ANALYZE)
EXPLAIN ANALYZE
SELECT * FROM book WHERE author LIKE '%Rowling';

EXPLAIN ANALYZE
SELECT * FROM book WHERE genre= 'Fantasy';

--Truoc index
--     Seq Scan on book  (cost=0.00..11.12 rows=1 width=864) (actual time=0.009..0.009 rows=0.00 loops=1)
--       Filter: ((author)::text ~~ '%Rowling'::text)
--     Planning:
--       Buffers: shared hit=9 dirtied=1
--     Planning Time: 0.250 ms
--     Execution Time: 0.021 ms

--Sau Index
-- Seq Scan on book  (cost=0.00..11.12 rows=1 width=864) (actual time=0.009..0.009 rows=0.00 loops=1)
--   Filter: ((author)::text ~~ '%Rowling'::text)
-- Planning:
--   Buffers: shared hit=31 read=1
-- Planning Time: 1.614 ms
-- Execution Time: 0.019 ms


--B-tree cho genre
CREATE INDEX idx_book_genre
    ON book (genre);
-- GIN cho title hoặc description (phục vụ tìm kiếm full-text)
CREATE INDEX idx_book_description_trgm
    ON book
        USING gin (description gin_trgm_ops);

--Tạo một Clustered Index (sử dụng lệnh CLUSTER) trên bảng book theo cột genre và kiểm tra sự khác biệt trong hiệu suất
CLUSTER book USING idx_book_genre;

--Truoc
-- Seq Scan on book  (cost=0.00..0.00 rows=1 width=864) (actual time=0.009..0.009 rows=0.00 loops=1)
--   Filter: ((genre)::text = 'Fantasy'::text)
-- Planning:
--   Buffers: shared hit=10
-- Planning Time: 0.367 ms
-- Execution Time: 0.025 ms

--Sau
-- Seq Scan on book  (cost=0.00..0.00 rows=1 width=864) (actual time=0.008..0.009 rows=0.00 loops=1)
--   Filter: ((genre)::text = 'Fantasy'::text)
-- Planning:
--   Buffers: shared hit=96 read=3
-- Planning Time: 3.088 ms
-- Execution Time: 0.021 ms


-- Trong PostgreSQL, truy vấn tìm kiếm theo genre = 'Fantasy' hiệu quả nhất khi sử dụng B-Tree Index, vì B-Tree tối ưu cho so sánh bằng, lớn hơn, nhỏ hơn. Đối với truy vấn author LIKE '%Rowling',
-- chỉ mục hiệu quả nhất là GIN index với pg_trgm,
-- cho phép tìm kiếm chuỗi con nhanh và tránh quét toàn bảng.
-- Hash Index trong PostgreSQL không được khuyến khích vì chúng không hỗ trợ nhiều loại toán tử,
-- không dùng được cho ORDER BY,
-- không hỗ trợ range scan và trước PostgreSQL 10 còn không được WAL-logged,
-- dễ mất dữ liệu. Ngay cả bản WAL-safe sau này,
-- hiệu năng Hash Index vẫn kém ổn định và ít lợi ích hơn B-Tree,
-- nên hiếm khi được ưu tiên sử dụng.