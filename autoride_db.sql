-- =============================================================================
-- HỆ THỐNG CHO THUÊ XE TỰ LÁI AUTORIDE (OPTIMIZED DATABASE SCHEMA)
-- Bài thực hành: Phân tích & Tái cấu trúc CSDL theo UML Activity Diagram
-- =============================================================================

CREATE DATABASE IF NOT EXISTS autoride_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE autoride_db;

-- Dọn dẹp cấu trúc cũ nếu tồn tại
DROP TRIGGER IF EXISTS trg_check_rental_active_before_inspection;
DROP TABLE IF EXISTS Inspections;
DROP TABLE IF EXISTS Rentals;
DROP TABLE IF EXISTS Cars;

-- =============================================================================
-- 1. BẢNG CARS (Danh mục phương tiện)
-- =============================================================================
CREATE TABLE Cars (
    car_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    status ENUM('AVAILABLE', 'RENTED', 'MAINTENANCE') DEFAULT 'AVAILABLE'
);

-- =============================================================================
-- 2. TÁI CẤU TRÚC BẢNG RENTALS (Khắc phục toàn bộ 3 Data Gaps)
-- - status: ENUM('BOOKED', 'ACTIVE', 'COMPLETED', 'CANCELLED')
-- - Bổ sung các cột tài chính: security_deposit, late_fee, damage_fee kiểu DECIMAL(12, 2)
-- - Ràng buộc khóa ngoại ON DELETE RESTRICT bảo vệ lịch sử giao dịch
-- =============================================================================
CREATE TABLE Rentals (
    rental_id INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    rent_date DATETIME NOT NULL,
    return_date DATETIME NULL,
    status ENUM('BOOKED', 'ACTIVE', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'BOOKED',
    security_deposit DECIMAL(12, 2) NOT NULL DEFAULT 0.00 CHECK (security_deposit >= 0),
    late_fee DECIMAL(12, 2) NOT NULL DEFAULT 0.00 CHECK (late_fee >= 0),
    damage_fee DECIMAL(12, 2) NOT NULL DEFAULT 0.00 CHECK (damage_fee >= 0),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (car_id) REFERENCES Cars(car_id) ON DELETE RESTRICT
);

-- =============================================================================
-- 3. BẢNG MỚI INSPECTIONS (Biên bản kiểm tra xe)
-- - Ghi nhận chi tiết tình trạng xe lúc giao/nhận và hư hỏng phát sinh
-- - Lưu vết người kiểm tra và thời điểm kiểm tra độc lập
-- =============================================================================
CREATE TABLE Inspections (
    inspection_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_id INT NOT NULL,
    inspection_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    damage_description TEXT NULL,
    inspector_name VARCHAR(100) NOT NULL,
    
    FOREIGN KEY (rental_id) REFERENCES Rentals(rental_id) ON DELETE RESTRICT
);

-- =============================================================================
-- 4. BẢO VỆ TÍNH TOÀN VẸN NGHIỆP VỤ BẰNG DATABASE TRIGGER
-- Ngăn chặn lập biên bản kiểm tra khi hợp đồng đang ở trạng thái BOOKED
-- (Khách chưa nhận xe thì không thể phát sinh kiểm tra lúc trả xe)
-- =============================================================================
DELIMITER //

CREATE TRIGGER trg_check_rental_active_before_inspection
BEFORE INSERT ON Inspections
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    
    SELECT status INTO v_status 
    FROM Rentals 
    WHERE rental_id = NEW.rental_id;
    
    IF v_status IS NULL OR v_status = 'BOOKED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Loi toan ven: Khong the lap bien ban kiem tra xe khi hop dong dang o trang thai BOOKED (khach chua nhan xe)!';
    END IF;
END //

DELIMITER ;

-- =============================================================================
-- 5. MÔ PHỎNG KỊCH BẢN NGHIỆP VỤ THỰC TẾ (DML)
-- =============================================================================

-- Thêm xe mẫu
INSERT INTO Cars (model_name, license_plate)
VALUES 
    ('VinFast VF8 Plus', '30K-999.88'),
    ('Mazda CX-5 2.5 Signature', '51H-123.45');

-- Kịch bản:
-- Bước 5.1: Khách hàng "Nguyen Van A" thuê xe, đóng cọc 10.000.000 VNĐ. Trạng thái ACTIVE
INSERT INTO Rentals (car_id, customer_name, rent_date, status, security_deposit)
VALUES (1, 'Nguyen Van A', '2026-10-10 08:00:00', 'ACTIVE', 10000000.00);

SET @current_rental_id = LAST_INSERT_ID();

-- Cập nhật trạng thái xe sang RENTED
UPDATE Cars SET status = 'RENTED' WHERE car_id = 1;

-- Bước 5.2: Khách trả xe. Nhân viên kiểm tra phát hiện vỡ đèn pha trái
-- Insert vào bảng Inspections ghi nhận lỗi hư hỏng
INSERT INTO Inspections (rental_id, inspection_date, damage_description, inspector_name)
VALUES (
    @current_rental_id, 
    '2026-10-15 17:30:00', 
    'Vỡ cụm đèn pha LED phía trước bên trái, trầy xước ba-đờ-sốc cản trước', 
    'Kỹ thuật viên Tran Van B'
);

-- Bước 5.3: Update bảng Rentals: Trạng thái COMPLETED, ghi nhận late_fee = 0, damage_fee = 2.000.000 VNĐ
UPDATE Rentals
SET status = 'COMPLETED',
    return_date = '2026-10-15 17:30:00',
    late_fee = 0.00,
    damage_fee = 2000000.00
WHERE rental_id = @current_rental_id;

-- Cập nhật trạng thái xe về MAINTENANCE để sửa chữa
UPDATE Cars SET status = 'MAINTENANCE' WHERE car_id = 1;

-- =============================================================================
-- 6. TRUY VẤN TÍNH TOÁN TIỀN HOÀN TRẢ VÀ ĐỐI SOÁT TÀI CHÍNH
-- Tiền hoàn lại = Tiền cọc - Phí phạt trễ - Phí sửa chữa hư hỏng
-- =============================================================================

-- Truy vấn 1: Tính toán chi tiết số tiền thực tế cần hoàn trả cho khách hàng
SELECT 
    r.rental_id AS 'Mã Hợp Đồng',
    r.customer_name AS 'Khách Hàng',
    c.model_name AS 'Mẫu Xe',
    c.license_plate AS 'Biển Số',
    r.rent_date AS 'Ngày Nhận Xe',
    r.return_date AS 'Ngày Trả Xe',
    r.status AS 'Trạng Thái',
    r.security_deposit AS 'Tiền Cọc (VNĐ)',
    r.late_fee AS 'Phí Phạt Trễ (VNĐ)',
    r.damage_fee AS 'Phí Sửa Chữa (VNĐ)',
    (r.security_deposit - r.late_fee - r.damage_fee) AS 'Tiền Thực Hoàn Trả (VNĐ)',
    insp.damage_description AS 'Biên Bản Hư Hỏng',
    insp.inspector_name AS 'Người Kiểm Tra'
FROM Rentals r
JOIN Cars c ON r.car_id = c.car_id
LEFT JOIN Inspections insp ON r.rental_id = insp.rental_id
WHERE r.rental_id = @current_rental_id;

-- Truy vấn 2: Báo cáo tài chính phòng ngừa thất thoát doanh thu của AutoRide
SELECT 
    COUNT(*) AS 'Tổng Hợp Đồng Đã Xử Lý',
    SUM(security_deposit) AS 'Tổng Tiền Cọc Đã Thu (VNĐ)',
    SUM(late_fee) AS 'Tổng Tiền Phạt Trễ (VNĐ)',
    SUM(damage_fee) AS 'Tổng Thu Bồi Thường Hư Hỏng (VNĐ)',
    SUM(security_deposit - late_fee - damage_fee) AS 'Tổng Tiền Hoàn Trả Khách (VNĐ)'
FROM Rentals
WHERE status = 'COMPLETED';
