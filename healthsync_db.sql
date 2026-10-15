-- =============================================================================
-- HỆ THỐNG PHÒNG KHÁM ĐA KHOA HEALTHSYNC (OPTIMIZED DATABASE SCHEMA)
-- Bài thực hành: Phân tích & Tái cấu trúc CSDL theo UML Activity Diagram
-- =============================================================================

CREATE DATABASE IF NOT EXISTS healthsync_db
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE healthsync_db;

-- Dọn dẹp cấu trúc cũ nếu tồn tại
DROP TRIGGER IF EXISTS trg_check_appointment_completed_before_prescription;
DROP TABLE IF EXISTS Prescriptions;
DROP TABLE IF EXISTS Appointments;
DROP TABLE IF EXISTS Doctors;
DROP TABLE IF EXISTS Patients;

-- =============================================================================
-- 1. TẠO CÁC BẢNG NỀN TẢNG (PATIENTS & DOCTORS)
-- =============================================================================

CREATE TABLE Patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(50) NOT NULL
);

-- =============================================================================
-- 2. TÁI CẤU TRÚC BẢNG APPOINTMENTS (KHẮC PHỤC LỖI THIẾT KẾ CŨ)
-- - Loại bỏ cột is_active BOOLEAN
-- - Thay thế bằng status ENUM thể hiện đầy đủ vòng đời 5 trạng thái
-- - Bổ sung deposit_amount, penalty_fee (DECIMAL) và cancel_reason
-- =============================================================================

CREATE TABLE Appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED') 
        NOT NULL DEFAULT 'PENDING',
    deposit_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00 CHECK (deposit_amount >= 0),
    penalty_fee DECIMAL(12, 2) NOT NULL DEFAULT 0.00 CHECK (penalty_fee >= 0),
    cancel_reason VARCHAR(255) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Ràng buộc logic nghiệp vụ: Phí phạt không được vượt quá số tiền cọc
    CONSTRAINT chk_penalty_limit CHECK (penalty_fee <= deposit_amount),
    
    -- Khóa ngoại liên kết
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id) ON DELETE RESTRICT
);

-- =============================================================================
-- 3. BỔ SUNG BẢNG PRESCRIPTIONS (ĐƠN THUỐC)
-- - Quan hệ 1-1 với mỗi lịch hẹn khám hoàn tất (UNIQUE appointment_id)
-- =============================================================================

CREATE TABLE Prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    medication_details TEXT NOT NULL,
    issued_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT NULL,
    
    FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id) ON DELETE RESTRICT
);

-- =============================================================================
-- 4. BẢO VỆ TÍNH TOÀN VẸN NGHIỆP VỤ BẰNG DATABASE TRIGGER
-- Ngăn chặn chèn Đơn thuốc nếu Lịch hẹn chưa ở trạng thái 'COMPLETED'
-- =============================================================================

DELIMITER //

CREATE TRIGGER trg_check_appointment_completed_before_prescription
BEFORE INSERT ON Prescriptions
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    
    -- Lấy trạng thái hiện tại của lịch hẹn
    SELECT status INTO v_status 
    FROM Appointments 
    WHERE appointment_id = NEW.appointment_id;
    
    -- Kiểm tra: Chỉ cho phép kê đơn khi lịch hẹn đã COMPLETED
    IF v_status IS NULL OR v_status != 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Loi toan ven nghiep vu: Chi duoc phep ke don thuoc cho lich hen da kham xong (status = COMPLETED)!';
    END IF;
END //

DELIMITER ;

-- =============================================================================
-- 5. MÔ PHỎNG DỮ LIỆU THỰC TẾ THEO CÁC KỊCH BẢN NGHIỆP VỤ (DML)
-- =============================================================================

-- Thêm dữ liệu bác sĩ và bệnh nhân
INSERT INTO Doctors (full_name, specialty)
VALUES 
    ('BS. Nguyễn Văn A', 'Nội tổng quát'),
    ('BS. Trần Thị B', 'Tai Mũi Họng');

INSERT INTO Patients (full_name, phone)
VALUES 
    ('Bệnh nhân Lê Hoàng', '0912345678'),
    ('Bệnh nhân Phạm Mai', '0987654321');

-- -----------------------------------------------------------------------------
-- KỊCH BẢN 1: QUY TRÌNH KHÁM BỆNH THÀNH CÔNG HOÀN TẤT
-- -----------------------------------------------------------------------------
-- Bước 1.1: Đặt lịch PENDING, đóng cọc 500.000 VNĐ
INSERT INTO Appointments (patient_id, doctor_id, appointment_date, status, deposit_amount)
VALUES (1, 1, '2026-10-20 09:00:00', 'PENDING', 500000.00);

SET @app_success_id = LAST_INSERT_ID();

-- Bước 1.2: Xác nhận tiền cọc -> Chuyển sang CONFIRMED
UPDATE Appointments 
SET status = 'CONFIRMED' 
WHERE appointment_id = @app_success_id;

-- Bước 1.3: Bệnh nhân đến phòng khám -> Chuyển sang CHECKED_IN
UPDATE Appointments 
SET status = 'CHECKED_IN' 
WHERE appointment_id = @app_success_id;

-- Bước 1.4: Bác sĩ khám xong -> Chuyển sang COMPLETED
UPDATE Appointments 
SET status = 'COMPLETED' 
WHERE appointment_id = @app_success_id;

-- Bước 1.5: Bác sĩ kê đơn thuốc cho lịch hẹn đã COMPLETED
INSERT INTO Prescriptions (appointment_id, medication_details, notes)
VALUES (
    @app_success_id, 
    '1. Paracetamol 500mg: 20 viên (Uống 1 viên sau ăn khi sốt)\n2. Amoxicillin 500mg: 14 viên (Uống sáng 1 - chiều 1)\n3. Vitamin C 500mg: 10 viên',
    'Tái khám sau 7 ngày nếu không đỡ triệu chứng sốt.'
);

-- -----------------------------------------------------------------------------
-- KỊCH BẢN 2: BỆNH NHÂN HỦY LỊCH SAU KHI ĐÃ CONFIRMED (PHẠT TIỀN CỌC)
-- -----------------------------------------------------------------------------
-- Bước 2.1: Đặt lịch và đã CONFIRMED tiền cọc 300.000 VNĐ
INSERT INTO Appointments (patient_id, doctor_id, appointment_date, status, deposit_amount)
VALUES (2, 2, '2026-10-22 14:30:00', 'CONFIRMED', 300000.00);

SET @app_cancel_id = LAST_INSERT_ID();

-- Bước 2.2: Bệnh nhân gọi điện hủy lịch -> Chuyển sang CANCELLED, phạt 150.000 VNĐ
UPDATE Appointments 
SET status = 'CANCELLED',
    cancel_reason = 'Bận việc đột xuất không thể sắp xếp đến khám',
    penalty_fee = 150000.00
WHERE appointment_id = @app_cancel_id;

-- =============================================================================
-- 6. CÁC CÂU LỆNH TRUY VẤN KIỂM CHỨNG & BÁO CÁO NGHIỆP VỤ
-- =============================================================================

-- Truy vấn 1: Danh sách bệnh nhân đã hoàn tất khám bệnh và chi tiết đơn thuốc
SELECT 
    a.appointment_id AS 'Mã Lịch Hẹn',
    p.full_name AS 'Tên Bệnh Nhân',
    p.phone AS 'Số ĐT',
    d.full_name AS 'Bác Sĩ Khám',
    d.specialty AS 'Chuyên Khoa',
    a.appointment_date AS 'Ngày Khám',
    a.status AS 'Trạng Thái',
    a.deposit_amount AS 'Tiền Cọc (VNĐ)',
    pr.prescription_id AS 'Mã Đơn Thuốc',
    pr.medication_details AS 'Chi Tiết Đơn Thuốc',
    pr.issued_date AS 'Ngày Kê Đơn'
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Doctors d ON a.doctor_id = d.doctor_id
JOIN Prescriptions pr ON a.appointment_id = pr.appointment_id
WHERE a.status = 'COMPLETED';

-- Truy vấn 2: Báo cáo đối soát tài chính tiền cọc và phí phạt lịch hẹn
SELECT 
    status AS 'Trạng Thái Lịch Hẹn',
    COUNT(*) AS 'Số Lượng Lịch',
    SUM(deposit_amount) AS 'Tổng Tiền Cọc Đã Đóng',
    SUM(penalty_fee) AS 'Tổng Phí Phạt Thu Được',
    SUM(deposit_amount - penalty_fee) AS 'Tiền Cọc Còn Lại/Hoàn Trả'
FROM Appointments
GROUP BY status;

-- Truy vấn 3: Chi tiết các lịch hẹn bị hủy và lý do phạt
SELECT 
    a.appointment_id,
    p.full_name AS 'Bệnh Nhân',
    a.appointment_date AS 'Ngày Hẹn Ban Đầu',
    a.deposit_amount AS 'Tiền Cọc',
    a.penalty_fee AS 'Phí Phạt',
    a.cancel_reason AS 'Lý Do Hủy'
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
WHERE a.status = 'CANCELLED';
