-- =============================================================================
-- SÀN THƯƠNG MẠI ĐIỆN TỬ FLASHMART (OPTIMIZED REPORT SCRIPTS)
-- Bài thực hành: Tối ưu hóa truy vấn JOIN & Kỹ thuật Anti-Join
-- =============================================================================

CREATE DATABASE IF NOT EXISTS flashmart_db
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE flashmart_db;

-- Dọn dẹp cấu trúc cũ nếu tồn tại
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Customers;

-- =============================================================================
-- 1. KHỞI TẠO CẤU TRÚC BẢNG VÀ CHÈN DỮ LIỆU MẪU
-- =============================================================================

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE
);

-- Chèn dữ liệu mẫu
-- Chú ý: Charlie (id: 3) chưa từng mua bất kỳ đơn hàng nào
INSERT INTO Customers (customer_id, name) VALUES 
    (1, 'Alice'), 
    (2, 'Bob'), 
    (3, 'Charlie');

-- Chú ý: Keyboard (id: 103) chưa từng được khách hàng nào đặt mua
INSERT INTO Products (product_id, product_name) VALUES 
    (101, 'Laptop'), 
    (102, 'Mouse'), 
    (103, 'Keyboard');

-- Các đơn hàng phát sinh
INSERT INTO Orders (order_id, customer_id, product_id) VALUES 
    (1001, 1, 101), -- Alice mua Laptop
    (1002, 1, 102), -- Alice mua Mouse
    (1003, 2, 101); -- Bob mua Laptop

-- =============================================================================
-- 2. BÁO CÁO 1: YÊU CẦU TỪ GIÁM ĐỐC MARKETING
-- Mục tiêu: Lấy danh sách TẤT CẢ khách hàng kèm số lượng đơn hàng đã mua.
-- Khách chưa mua (Charlie) phải hiển thị total_orders = 0 (nhận Voucher 50%).
--
-- GIẢI PHÁP:
-- - Bảng gốc (Driving Table): Customers (nằm bên TRÁI)
-- - Sử dụng: LEFT JOIN với bảng Orders
-- - Đếm số lượng: Bắt buộc dùng COUNT(o.order_id), KHÔNG dùng COUNT(*)
-- =============================================================================

SELECT 
    c.customer_id, 
    c.name, 
    COUNT(o.order_id) AS total_orders
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY c.customer_id;

-- Danh sách khách hàng chưa từng mua hàng để gửi Voucher 50%
SELECT 
    c.customer_id,
    c.name AS potential_customer
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- =============================================================================
-- 3. BÁO CÁO 2: YÊU CẦU TỪ GIÁM ĐỐC KHO VẬN (KỸ THUẬT ANTI-JOIN)
-- Mục tiêu: Tìm các sản phẩm CHƯA TỪNG ĐƯỢC BÁN RA LẦN NÀO để thanh lý thu hồi vốn.
--
-- GIẢI PHÁP:
-- - Bảng gốc (Driving Table): Products (nằm bên TRÁI)
-- - Sử dụng: LEFT JOIN với bảng Orders
-- - Điều kiện lọc: WHERE o.order_id IS NULL (lọc bỏ các dòng đã có giao dịch)
-- =============================================================================

SELECT 
    p.product_id, 
    p.product_name
FROM Products p
LEFT JOIN Orders o ON p.product_id = o.product_id
WHERE o.order_id IS NULL;

-- =============================================================================
-- 4. BỔ SUNG MỞ RỘNG: GIẢ LẬP FULL OUTER JOIN TRONG MYSQL BẰNG UNION
-- Lấy tất cả khách hàng (kể cả chưa mua) và tất cả sản phẩm (kể cả chưa bán)
-- =============================================================================

SELECT 
    c.name AS customer_name,
    p.product_name,
    o.order_id
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
LEFT JOIN Products p ON o.product_id = p.product_id

UNION

SELECT 
    c.name AS customer_name,
    p.product_name,
    o.order_id
FROM Products p
LEFT JOIN Orders o ON p.product_id = o.product_id
LEFT JOIN Customers c ON o.customer_id = c.customer_id;
