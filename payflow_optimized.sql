-- =============================================================================
-- HỆ THỐNG VÍ ĐIỆN TỬ PAYFLOW (DATABASE PERFORMANCE OPTIMIZATION)
-- Dự án: Tối ưu hóa truy vấn Non-SARGable và B-Tree Index cho bảng Transactions
-- Vai trò: Database Performance Engineer
-- =============================================================================

CREATE DATABASE IF NOT EXISTS payflow_db
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE payflow_db;

-- -----------------------------------------------------------------------------
-- 1. KHỞI TẠO CẤU TRÚC BẢNG TRANSACTIONS VÀ DỮ LIỆU KIỂM THỬ
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS Transactions;

CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL, -- 'DEPOSIT', 'WITHDRAW', 'TRANSFER'
    created_at DATETIME NOT NULL
);

-- Chèn dữ liệu mẫu mô phỏng các giao dịch qua các tháng và loại giao dịch
INSERT INTO Transactions (user_id, amount, transaction_type, created_at) VALUES
    (101, 500000.00, 'DEPOSIT', '2026-06-05 10:15:00'),
    (102, 1200000.00, 'DEPOSIT', '2026-06-12 14:30:00'),
    (103, 300000.00, 'WITHDRAW', '2026-06-15 09:00:00'),
    (104, 2500000.00, 'DEPOSIT', '2026-06-28 20:45:00'),
    (101, 150000.00, 'TRANSFER', '2026-06-30 23:59:00'),
    (105, 800000.00, 'DEPOSIT', '2026-05-10 11:00:00'),
    (106, 950000.00, 'DEPOSIT', '2026-07-02 08:30:00'),
    (107, 400000.00, 'WITHDRAW', '2026-06-01 00:00:00'),
    (108, 1000000.00, 'DEPOSIT', '2026-06-01 00:00:00');

-- Nhân bản dữ liệu để kiểm thử hiệu năng và kế hoạch thực thi (Execution Plan)
INSERT INTO Transactions (user_id, amount, transaction_type, created_at)
SELECT user_id, amount, transaction_type, created_at FROM Transactions;
INSERT INTO Transactions (user_id, amount, transaction_type, created_at)
SELECT user_id, amount, transaction_type, created_at FROM Transactions;
INSERT INTO Transactions (user_id, amount, transaction_type, created_at)
SELECT user_id, amount, transaction_type, created_at FROM Transactions;
INSERT INTO Transactions (user_id, amount, transaction_type, created_at)
SELECT user_id, amount, transaction_type, created_at FROM Transactions;
INSERT INTO Transactions (user_id, amount, transaction_type, created_at)
SELECT user_id, amount, transaction_type, created_at FROM Transactions;
INSERT INTO Transactions (user_id, amount, transaction_type, created_at)
SELECT user_id, amount, transaction_type, created_at FROM Transactions;
INSERT INTO Transactions (user_id, amount, transaction_type, created_at)
SELECT user_id, amount, transaction_type, created_at FROM Transactions;
INSERT INTO Transactions (user_id, amount, transaction_type, created_at)
SELECT user_id, amount, transaction_type, created_at FROM Transactions;
INSERT INTO Transactions (user_id, amount, transaction_type, created_at)
SELECT user_id, amount, transaction_type, created_at FROM Transactions;

-- =============================================================================
-- 2. TRUY VẤN CŨ CỦA KẾ TOÁN (LEGACY SCRIPT - NON-SARGABLE)
-- Lỗi: Bọc hàm YEAR() và MONTH() xung quanh cột created_at
-- Hậu quả: Full Table Scan (type = ALL), CPU 100%, gây nghẽn và timeout giao dịch
-- =============================================================================

-- Kế hoạch thực thi của câu lệnh cũ (Chưa có index, quét toàn bảng):
EXPLAIN 
SELECT SUM(amount) AS total_deposit 
FROM Transactions 
WHERE transaction_type = 'DEPOSIT' 
  AND YEAR(created_at) = 2026 
  AND MONTH(created_at) = 6;

-- Kết quả tính toán của câu lệnh cũ:
SELECT SUM(amount) AS total_deposit 
FROM Transactions 
WHERE transaction_type = 'DEPOSIT' 
  AND YEAR(created_at) = 2026 
  AND MONTH(created_at) = 6;

-- =============================================================================
-- 3. THIẾT KẾ GIẢI PHÁP TỐI ƯU HÓA (INDEXING & REFACTORING)
-- =============================================================================

-- Bước 3.1: Tạo Composite Index B-Tree
-- Đặt cột có phép so sánh đẳng thức (=) đứng trước: transaction_type
-- Đặt cột có phép so sánh khoảng (Range) đứng sau: created_at
CREATE INDEX idx_type_date ON Transactions(transaction_type, created_at);

-- (Tùy chọn nâng cao): Covering Index bao gồm cả cột amount
-- Giúp truy vấn đạt trạng thái 'Using index', không cần quay lại bảng dữ liệu chính (Clustered Index)
CREATE INDEX idx_covering ON Transactions(transaction_type, created_at, amount);

-- =============================================================================
-- 4. TRUY VẤN MỚI ĐÃ TỐI ƯU (OPTIMIZED SCRIPT - SARGABLE QUERY)
-- Giải pháp:
-- 1. Chuyển YEAR/MONTH thành Range: created_at >= '2026-06-01' AND created_at < '2026-07-01'
-- 2. Tận dụng B-Tree Index Seek để quét thẳng vào phạm vi ngày tháng cần lấy
-- =============================================================================

-- Kế hoạch thực thi của câu lệnh mới (type chuyển sang range, key sử dụng idx_covering hoặc idx_type_date):
EXPLAIN 
SELECT SUM(amount) AS total_deposit 
FROM Transactions 
WHERE transaction_type = 'DEPOSIT' 
  AND created_at >= '2026-06-01 00:00:00' 
  AND created_at < '2026-07-01 00:00:00';

-- Thực thi câu lệnh tối ưu để kiểm chứng kết quả tài chính (phải đồng nhất 100% với câu cũ):
SELECT SUM(amount) AS total_deposit 
FROM Transactions 
WHERE transaction_type = 'DEPOSIT' 
  AND created_at >= '2026-06-01 00:00:00' 
  AND created_at < '2026-07-01 00:00:00';

-- Đo lường thời gian thực thi bằng Profiling:
SET profiling = 1;

SELECT SUM(amount) AS total_deposit 
FROM Transactions 
WHERE transaction_type = 'DEPOSIT' 
  AND created_at >= '2026-06-01 00:00:00' 
  AND created_at < '2026-07-01 00:00:00';

SHOW PROFILES;
