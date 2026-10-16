-- =============================================================================
-- [Bài tập] Thao tác với CSDL Quản lý bán hàng (QuanLyBanHang)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS QuanLyBanHang
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE QuanLyBanHang;

-- Xóa bảng cũ theo thứ tự ràng buộc khóa ngoại nếu tồn tại
DROP TABLE IF EXISTS OrderDetail;
DROP TABLE IF EXISTS `Order`;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Customer;

-- =============================================================================
-- 1. TẠO CẤU TRÚC 4 BẢNG
-- =============================================================================

CREATE TABLE Customer (
    cID INT AUTO_INCREMENT PRIMARY KEY,
    cName VARCHAR(25) NOT NULL,
    cAge TINYINT
);

CREATE TABLE `Order` (
    oID INT AUTO_INCREMENT PRIMARY KEY,
    cID INT NOT NULL,
    oDate DATETIME NOT NULL,
    oTotalPrice INT NULL,
    FOREIGN KEY (cID) REFERENCES Customer(cID)
);

CREATE TABLE Product (
    pID INT AUTO_INCREMENT PRIMARY KEY,
    pName VARCHAR(25) NOT NULL,
    pPrice INT NOT NULL
);

CREATE TABLE OrderDetail (
    oID INT NOT NULL,
    pID INT NOT NULL,
    odQTY INT NOT NULL,
    PRIMARY KEY (oID, pID),
    FOREIGN KEY (oID) REFERENCES `Order`(oID),
    FOREIGN KEY (pID) REFERENCES Product(pID)
);

-- =============================================================================
-- 2. THÊM DỮ LIỆU VÀO TRONG 4 BẢNG THEO ĐỀ BÀI
-- =============================================================================

-- Bảng Customer
INSERT INTO Customer (cID, cName, cAge) VALUES
    (1, 'Minh Quan', 10),
    (2, 'Ngoc Oanh', 20),
    (3, 'Hong Ha', 50);

-- Bảng Order
INSERT INTO `Order` (oID, cID, oDate, oTotalPrice) VALUES
    (1, 1, '2006-03-21', NULL),
    (2, 2, '2006-03-23', NULL),
    (3, 1, '2006-03-16', NULL);

-- Bảng Product
INSERT INTO Product (pID, pName, pPrice) VALUES
    (1, 'May Giat', 3),
    (2, 'Tu Lanh', 5),
    (3, 'Dieu Hoa', 7),
    (4, 'Quat', 1),
    (5, 'Bep Dien', 2);

-- Bảng OrderDetail
INSERT INTO OrderDetail (oID, pID, odQTY) VALUES
    (1, 1, 3),
    (1, 3, 7),
    (1, 4, 2),
    (2, 1, 1),
    (3, 1, 8),
    (2, 5, 4),
    (2, 3, 3);

-- =============================================================================
-- 3. CÁC CÂU LỆNH TRUY VẤN THEO YÊU CẦU ĐỀ BÀI
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Yêu cầu 1: Hiển thị các thông tin gồm oID, oDate, oPrice của tất cả các hóa đơn trong bảng Order
-- -----------------------------------------------------------------------------
SELECT 
    oID, 
    oDate, 
    oTotalPrice AS oPrice 
FROM `Order`;


-- -----------------------------------------------------------------------------
-- Yêu cầu 2: Hiển thị danh sách các khách hàng đã mua hàng, và danh sách sản phẩm được mua bởi các khách
-- Sử dụng DISTINCT để hiển thị danh mục sản phẩm từng khách đã mua
-- -----------------------------------------------------------------------------
SELECT DISTINCT 
    c.cName AS CustomerName, 
    p.pName AS ProductName
FROM Customer c
JOIN `Order` o ON c.cID = o.cID
JOIN OrderDetail od ON o.oID = od.oID
JOIN Product p ON od.pID = p.pID;


-- -----------------------------------------------------------------------------
-- Yêu cầu 3: Hiển thị tên những khách hàng không mua bất kỳ một sản phẩm nào
-- Áp dụng kỹ thuật Anti-Join: LEFT JOIN giữa Customer và Order, lọc WHERE o.oID IS NULL
-- -----------------------------------------------------------------------------
SELECT 
    c.cName AS CustomerWithoutOrders
FROM Customer c
LEFT JOIN `Order` o ON c.cID = o.cID
WHERE o.oID IS NULL;


-- -----------------------------------------------------------------------------
-- Yêu cầu 4: Hiển thị mã hóa đơn, ngày bán và giá tiền của từng hóa đơn
-- Giá một hóa đơn được tính bằng tổng giá bán của từng loại mặt hàng (odQTY * pPrice)
-- Sử dụng GROUP BY theo hóa đơn kết hợp hàm tổng SUM(od.odQTY * p.pPrice)
-- -----------------------------------------------------------------------------
SELECT 
    o.oID, 
    o.oDate, 
    SUM(od.odQTY * p.pPrice) AS TotalPrice
FROM `Order` o
JOIN OrderDetail od ON o.oID = od.oID
JOIN Product p ON od.pID = p.pID
GROUP BY o.oID, o.oDate;
