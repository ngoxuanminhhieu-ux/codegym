-- =============================================================================
-- [Thực hành] Tạo CSDL trên MySQL Workbench
-- Mục tiêu: Luyện tập các thao tác tạo CSDL trên MySQL Workbench bằng câu lệnh SQL
-- =============================================================================

-- 1. Tạo cơ sở dữ liệu mới với tên là my_database1 (nếu chưa tồn tại)
CREATE DATABASE IF NOT EXISTS `my_database1`;

-- 2. Chọn và sử dụng cơ sở dữ liệu my_database1 để làm việc
USE `my_database1`;

-- 3. Kiểm tra danh sách tất cả các cơ sở dữ liệu trên server
SHOW DATABASES;

-- 4. Xem câu lệnh và cấu hình chi tiết (Charset, Collation) của my_database1
SHOW CREATE DATABASE `my_database1`;

-- 5. Lệnh xóa CSDL khi cần dọn dẹp (tùy chọn)
-- DROP DATABASE IF EXISTS `my_database1`;
