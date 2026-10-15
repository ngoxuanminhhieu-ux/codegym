-- =============================================================================
-- [Thực hành] Tạo bảng trong CSDL bằng câu lệnh
-- Tên CSDL: QuanLyDiemThi
-- =============================================================================

CREATE DATABASE IF NOT EXISTS QuanLyDiemThi;
USE QuanLyDiemThi;

-- Xóa bảng cũ nếu đã tồn tại để chạy lại sạch sẽ
DROP TABLE IF EXISTS BangDiem;
DROP TABLE IF EXISTS MonHoc;
DROP TABLE IF EXISTS GiaoVien;
DROP TABLE IF EXISTS HocSinh;

-- Bước 3: Tạo bảng HocSinh
CREATE TABLE HocSinh (
    MaHS VARCHAR(20) PRIMARY KEY,
    TenHS VARCHAR(50),
    NgaySinh DATETIME,
    Lop VARCHAR(20),
    GT VARCHAR(20)
);

-- Bước 4: Tạo bảng MonHoc
CREATE TABLE MonHoc (
    MaMH VARCHAR(50) PRIMARY KEY,
    TenMH VARCHAR(50),
    MaGV VARCHAR(20)
);

-- Bước 6: Tạo bảng GiaoVien
CREATE TABLE GiaoVien (
    MaGV VARCHAR(20) PRIMARY KEY,
    TenGV VARCHAR(50),
    SDT VARCHAR(10)
);

-- Bước 5: Tạo bảng BangDiem (bảng trung gian giữa HocSinh và MonHoc)
CREATE TABLE BangDiem (
    MaHS VARCHAR(20),
    MaMH VARCHAR(50),
    DiemThi INT,
    NgayKT DATETIME,
    PRIMARY KEY (MaHS, MaMH),
    FOREIGN KEY (MaHS) REFERENCES HocSinh(MaHS),
    FOREIGN KEY (MaMH) REFERENCES MonHoc(MaMH)
);

-- Bước 7: Bổ sung khóa ngoại FK_MaGV cho bảng MonHoc
ALTER TABLE MonHoc ADD CONSTRAINT FK_MaGV FOREIGN KEY (MaGV) REFERENCES GiaoVien(MaGV);

-- =============================================================================
-- DỮ LIỆU MẪU ĐỂ KIỂM THỬ (TEST DATA)
-- =============================================================================
INSERT INTO GiaoVien (MaGV, TenGV, SDT)
VALUES 
    ('GV01', 'Thầy Nguyễn Văn A', '0901234567'),
    ('GV02', 'Cô Trần Thị B', '0907654321');

INSERT INTO MonHoc (MaMH, TenMH, MaGV)
VALUES 
    ('MH01', 'Toán Học', 'GV01'),
    ('MH02', 'Vật Lý', 'GV02');

INSERT INTO HocSinh (MaHS, TenHS, NgaySinh, Lop, GT)
VALUES 
    ('HS01', 'Lê Hoàng Nam', '2006-05-15', '12A1', 'Nam'),
    ('HS02', 'Phạm Quỳnh Nga', '2006-08-20', '12A1', 'Nữ');

INSERT INTO BangDiem (MaHS, MaMH, DiemThi, NgayKT)
VALUES 
    ('HS01', 'MH01', 9, '2026-10-15 08:00:00'),
    ('HS01', 'MH02', 8, '2026-10-16 08:00:00'),
    ('HS02', 'MH01', 10, '2026-10-15 08:00:00');

-- =============================================================================
-- KIỂM TRA DỮ LIỆU
-- =============================================================================
SELECT 
    hs.MaHS,
    hs.TenHS,
    hs.Lop,
    mh.TenMH,
    gv.TenGV AS GiaoVienPhuTrach,
    bd.DiemThi,
    bd.NgayKT
FROM BangDiem bd
JOIN HocSinh hs ON bd.MaHS = hs.MaHS
JOIN MonHoc mh ON bd.MaMH = mh.MaMH
JOIN GiaoVien gv ON mh.MaGV = gv.MaGV;
