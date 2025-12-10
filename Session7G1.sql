set search_path to internet;

CREATE TABLE post(
    post_id serial Primary Key ,
    user_id INT NOT NULL ,
    content TEXT,
    tags text[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_public BOOLEAN DEFAULT true
);

CREATE TABLE post_like(
    user_id INT NOT NULL ,
    post_id INT NOT NULL ,
    liked_at TIMESTAMP DEFAULT current_timestamp,
    PRIMARY KEY (user_id,post_id)
);
-- Tối ưu hóa truy vấn tìm kiếm bài đăng công khai theo từ khóa:
-- Tạo Expression Index sử dụng LOWER(content) để tăng tốc tìm kiếm
-- So sánh hiệu suất trước và sau khi tạo chỉ mục

CREATE INDEX idx_post_content_lower
    ON post (LOWER(content));
DROP INDEX idx_post_content_lower;

EXPLAIN ANALYSE SELECT * from Post
                where is_public = true and content ILIKE '%du lịch%';
-- Truoc chi muc
-- Seq Scan on post  (cost=0.00..19.25 rows=1 width=81) (actual time=0.006..0.006 rows=0.00 loops=1)
--   Filter: (is_public AND (content ~~* '%du lịch%'::text))
-- Planning:
--   Buffers: shared hit=1
-- Planning Time: 0.080 ms
-- Execution Time: 0.019 ms

--Sau chi muc
-- Seq Scan on post  (cost=0.00..19.25 rows=1 width=81) (actual time=0.012..0.013 rows=0.00 loops=1)
--   Filter: (is_public AND (content ~~* '%du lịch%'::text))
-- Planning:
--   Buffers: shared hit=18
-- Planning Time: 1.028 ms
-- Execution Time: 0.035 ms


-- Tối ưu hóa truy vấn lọc bài đăng theo thẻ (tags):
-- Tạo GIN Index cho cột tags
-- Phân tích hiệu suất bằng EXPLAIN ANALYZE

CREATE INDEX idx_post_tags_gin
    ON post USING GIN (tags);
DROP INDEX idx_post_tags_gin;
EXPLAIN ANALYZE
SELECT *
FROM post
WHERE tags @> ARRAY['du_lich'];

--TRƯỚC
-- Seq Scan on post  (cost=0.00..19.25 rows=4 width=81) (actual time=0.017..0.017 rows=0.00 loops=1)
--   Filter: (tags @> '{du_lich}'::text[])
-- Planning:
--   Buffers: shared hit=8 dirtied=1
-- Planning Time: 0.567 ms
-- Execution Time: 0.034 ms

--SAU
-- Bitmap Heap Scan on post  (cost=8.57..17.03 rows=4 width=81) (actual time=0.584..0.584 rows=0.00 loops=1)
--   Recheck Cond: (tags @> '{du_lich}'::text[])
--   Buffers: shared hit=2
--   ->  Bitmap Index Scan on idx_post_tags_gin  (cost=0.00..8.57 rows=4 width=0) (actual time=0.550..0.550 rows=0.00 loops=1)
--         Index Cond: (tags @> '{du_lich}'::text[])
--         Index Searches: 1
--         Buffers: shared hit=2
-- Planning:
--   Buffers: shared hit=25
-- Planning Time: 1.106 ms
-- Execution Time: 0.868 ms

-- Tối ưu hóa truy vấn tìm bài đăng mới trong 7 ngày gần nhất:
-- Tạo Partial Index cho bài viết công khai gần đây:
CREATE INDEX idx_post_recent_public
ON post(created_at DESC)
WHERE is_public = TRUE;

EXPLAIN ANALYZE
SELECT * FROM post
WHERE is_public = true
  AND created_at >= NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;

--Truoc
-- Sort  (cost=27.22..27.53 rows=123 width=81) (actual time=0.058..0.059 rows=0.00 loops=1)
--   Sort Key: created_at DESC
--   Sort Method: quicksort  Memory: 25kB
--   Buffers: shared hit=3
--   ->  Seq Scan on post  (cost=0.00..22.95 rows=123 width=81) (actual time=0.029..0.029 rows=0.00 loops=1)
--         Filter: (is_public AND (created_at >= (now() - '7 days'::interval)))
-- Planning:
--   Buffers: shared hit=26
-- Planning Time: 2.585 ms
-- Execution Time: 0.086 ms

--SAU
-- Sort  (cost=20.59..20.90 rows=123 width=81) (actual time=0.019..0.019 rows=0.00 loops=1)
--   Sort Key: created_at DESC
--   Sort Method: quicksort  Memory: 25kB
--   Buffers: shared hit=2
--   ->  Bitmap Heap Scan on post  (cost=4.17..16.32 rows=123 width=81) (actual time=0.015..0.015 rows=0.00 loops=1)
--         Recheck Cond: ((created_at >= (now() - '7 days'::interval)) AND is_public)
--         Buffers: shared hit=2
--         ->  Bitmap Index Scan on idx_post_recent_public  (cost=0.00..4.14 rows=123 width=0) (actual time=0.003..0.003 rows=0.00 loops=1)
--               Index Cond: (created_at >= (now() - '7 days'::interval))
--               Index Searches: 1
--               Buffers: shared hit=2
-- Planning:
--   Buffers: shared hit=23 read=1
-- Planning Time: 0.921 ms
-- Execution Time: 0.035 ms

CREATE INDEX idx_post_user_created_at
    ON post (user_id, created_at DESC);

EXPLAIN ANALYZE
SELECT *
FROM post
WHERE user_id = 10
ORDER BY created_at DESC
LIMIT 20;

--Truoc
-- Limit  (cost=19.29..19.30 rows=4 width=81) (actual time=0.028..0.028 rows=0.00 loops=1)
--   ->  Sort  (cost=19.29..19.30 rows=4 width=81) (actual time=0.027..0.027 rows=0.00 loops=1)
--         Sort Key: created_at DESC
--         Sort Method: quicksort  Memory: 25kB
--         ->  Seq Scan on post  (cost=0.00..19.25 rows=4 width=81) (actual time=0.019..0.019 rows=0.00 loops=1)
--               Filter: (user_id = 10)
-- Planning:
--   Buffers: shared hit=3
-- Planning Time: 0.172 ms
-- Execution Time: 0.050 ms

--Sau
-- Limit  (cost=12.68..12.69 rows=4 width=81) (actual time=0.016..0.016 rows=0.00 loops=1)
--   Buffers: shared hit=2
--   ->  Sort  (cost=12.68..12.69 rows=4 width=81) (actual time=0.015..0.015 rows=0.00 loops=1)
--         Sort Key: created_at DESC
--         Sort Method: quicksort  Memory: 25kB
--         Buffers: shared hit=2
--         ->  Bitmap Heap Scan on post  (cost=4.18..12.64 rows=4 width=81) (actual time=0.011..0.011 rows=0.00 loops=1)
--               Recheck Cond: (user_id = 10)
--               Buffers: shared hit=2
--               ->  Bitmap Index Scan on idx_post_user_created_at  (cost=0.00..4.18 rows=4 width=0) (actual time=0.001..0.002 rows=0.00 loops=1)
--                     Index Cond: (user_id = 10)
--                     Index Searches: 1
--                     Buffers: shared hit=2
-- Planning:
--   Buffers: shared hit=22 read=1
-- Planning Time: 0.911 ms
-- Execution Time: 0.034 ms


