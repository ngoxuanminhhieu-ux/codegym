-- =============================================================================
-- [Thực hành] Xóa CSDL trên MySQL Workbench
-- Mục tiêu: Luyện tập các thao tác xóa CSDL bằng câu lệnh SQL
-- =============================================================================

-- 1. Xóa cơ sở dữ liệu my_database1 (sử dụng IF EXISTS để tránh lỗi nếu CSDL không tồn tại)
-- LƯU Ý QUAN TRỌNG: Câu lệnh DROP DATABASE sẽ xóa vĩnh viễn CSDL cùng toàn bộ bảng và dữ liệu bên trong!
DROP DATABASE IF EXISTS `my_database1`;

-- 2. Xóa cơ sở dữ liệu my_database (nếu có)
DROP DATABASE IF EXISTS `my_database`;

-- 3. Hiển thị lại danh sách CSDL để xác nhận CSDL đã được xóa khỏi hệ thống
SHOW DATABASES;
