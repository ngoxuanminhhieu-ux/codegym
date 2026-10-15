-- =============================================================================
-- [Bài tập] Xây dựng cơ sở dữ liệu Quản lý bán hàng (QuanLyBanHang)
-- Hệ thống gồm 4 bảng: Customer, Order, Product, OrderDetail
-- =============================================================================

CREATE DATABASE IF NOT EXISTS QuanLyBanHang
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE QuanLyBanHang;

-- Xóa bảng cũ nếu tồn tại theo thứ tự ràng buộc khóa ngoại
DROP TABLE IF EXISTS OrderDetail;
DROP TABLE IF EXISTS `Order`;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Customer;

-- =============================================================================
-- 1. BẢNG CUSTOMER (Khách hàng)
-- Lưu danh sách những khách hàng đã đến cửa hàng (cả người có mua và không mua)
-- =============================================================================
CREATE TABLE Customer (
    cID INT AUTO_INCREMENT PRIMARY KEY,
    cName VARCHAR(25) NOT NULL,
    cAge TINYINT CHECK (cAge > 0)
);

-- =============================================================================
-- 2. BẢNG ORDER (Hóa đơn)
-- Mỗi khách hàng có thể có nhiều hóa đơn => Quan hệ 1 - n với Customer qua cID
-- Chú ý: Từ khóa 'Order' trùng từ khóa SQL nên phải bao bọc bằng dấu backtick ``
-- =============================================================================
CREATE TABLE `Order` (
    oID INT AUTO_INCREMENT PRIMARY KEY,
    cID INT NOT NULL,
    oDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    oTotalPrice INT NULL,
    FOREIGN KEY (cID) REFERENCES Customer(cID) ON DELETE RESTRICT
);

-- =============================================================================
-- 3. BẢNG PRODUCT (Sản phẩm)
-- Lưu danh mục sản phẩm và giá tiền của sản phẩm
-- =============================================================================
CREATE TABLE Product (
    pID INT AUTO_INCREMENT PRIMARY KEY,
    pName VARCHAR(25) NOT NULL,
    pPrice INT NOT NULL CHECK (pPrice >= 0)
);

-- =============================================================================
-- 4. BẢNG ORDERDETAIL (Chi tiết hóa đơn)
-- Bảng trung gian giải quyết mối quan hệ nhiều - nhiều giữa Order và Product
-- Khóa chính phức hợp gồm (oID, pID)
-- odQTY: Số lượng mua của từng mặt hàng trong hóa đơn
-- =============================================================================
CREATE TABLE OrderDetail (
    oID INT NOT NULL,
    pID INT NOT NULL,
    odQTY INT NOT NULL CHECK (odQTY > 0),
    PRIMARY KEY (oID, pID),
    FOREIGN KEY (oID) REFERENCES `Order`(oID) ON DELETE CASCADE,
    FOREIGN KEY (pID) REFERENCES Product(pID) ON DELETE RESTRICT
);

-- =============================================================================
-- 5. THÊM DỮ LIỆU MẪU KIỂM THỬ RÀNG BUỘC (DML)
-- =============================================================================

-- Thêm khách hàng
INSERT INTO Customer (cID, cName, cAge)
VALUES 
    (1, 'Minh Quan', 10),
    (2, 'Ngoc Oanh', 20),
    (3, 'Hong Ha', 50);

-- Thêm hóa đơn
INSERT INTO `Order` (oID, cID, oDate, oTotalPrice)
VALUES 
    (1, 1, '2006-03-21', NULL),
    (2, 2, '2006-03-23', NULL),
    (3, 1, '2006-03-16', NULL);

-- Thêm sản phẩm
INSERT INTO Product (pID, pName, pPrice)
VALUES 
    (1, 'May Giat', 3),
    (2, 'Tu Lanh', 5),
    (3, 'Dieu Hoa', 7),
    (4, 'Quat', 1),
    (5, 'Bep Dien', 2);

-- Thêm chi tiết hóa đơn
INSERT INTO OrderDetail (oID, pID, odQTY)
VALUES 
    (1, 1, 3),
    (1, 3, 7),
    (1, 4, 2),
    (2, 1, 1),
    (3, 1, 8),
    (2, 5, 4),
    (2, 3, 3);

-- =============================================================================
-- 6. TÍNH TOÁN VÀ TRUY VẤN DỮ LIỆU
-- =============================================================================

-- Cập nhật tổng tiền oTotalPrice cho các hóa đơn
UPDATE `Order` o
SET oTotalPrice = (
    SELECT SUM(od.odQTY * p.pPrice)
    FROM OrderDetail od
    JOIN Product p ON od.pID = p.pID
    WHERE od.oID = o.oID
);

-- Truy vấn 1: Hiển thị danh sách hóa đơn gồm mã hóa đơn, tên khách và tổng tiền
SELECT 
    o.oID AS 'Mã Hóa Đơn',
    c.cName AS 'Tên Khách Hàng',
    o.oDate AS 'Ngày Mua',
    o.oTotalPrice AS 'Tổng Giá Trị'
FROM `Order` o
JOIN Customer c ON o.cID = c.cID;

-- Truy vấn 2: Hiển thị chi tiết từng sản phẩm trong hóa đơn
SELECT 
    o.oID AS 'Mã Hóa Đơn',
    c.cName AS 'Khách Hàng',
    p.pName AS 'Sản Phẩm',
    od.odQTY AS 'Số Lượng',
    p.pPrice AS 'Đơn Giá',
    (od.odQTY * p.pPrice) AS 'Thành Tiền'
FROM `Order` o
JOIN Customer c ON o.cID = c.cID
JOIN OrderDetail od ON o.oID = od.oID
JOIN Product p ON od.pID = p.pID
ORDER BY o.oID, p.pID;

-- Truy vấn 3: Danh sách khách hàng không mua hàng
SELECT 
    c.cID AS 'Mã Khách Hàng',
    c.cName AS 'Tên Khách Hàng',
    c.cAge AS 'Tuổi'
FROM Customer c
LEFT JOIN `Order` o ON c.cID = o.cID
WHERE o.oID IS NULL;
