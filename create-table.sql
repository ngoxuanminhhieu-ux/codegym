-- =============================================================================
-- [Thực hành] Tạo bảng trong CSDL bằng câu lệnh
-- Cơ sở dữ liệu: QuanLyDiemThi
-- Mã nguồn tham khảo: https://github.com/codegym-vn/jwbd-2023-sql-create-table
-- =============================================================================

-- Bước 1: Tạo cơ sở dữ liệu có tên là QuanLyDiemThi
CREATE DATABASE IF NOT EXISTS QuanLyDiemThi;

-- Bước 2: Chọn Database QuanLyDiemThi để thao tác
USE QuanLyDiemThi;

-- Bước 3: Tạo bảng HocSinh
CREATE TABLE IF NOT EXISTS HocSinh (
    MaHS VARCHAR(20) PRIMARY KEY,
    TenHS VARCHAR(50),
    NgaySinh DATETIME,
    Lop VARCHAR(20),
    GT VARCHAR(20)
);

-- Bước 4: Tạo bảng MonHoc
CREATE TABLE IF NOT EXISTS MonHoc (
    MaMH VARCHAR(50) PRIMARY KEY,
    TenMH VARCHAR(50),
    MaGV VARCHAR(20)
);

-- Bước 5: Tạo bảng BangDiem là bảng trung gian của mối quan hệ n - n giữa 2 thực thể HocSinh và MonHoc
CREATE TABLE IF NOT EXISTS BangDiem (
    MaHS VARCHAR(20),
    MaMH VARCHAR(50),
    DiemThi INT,
    NgayKT DATETIME,
    PRIMARY KEY (MaHS, MaMH),
    FOREIGN KEY (MaHS) REFERENCES HocSinh(MaHS),
    FOREIGN KEY (MaMH) REFERENCES MonHoc(MaMH)
);

-- Bước 6: Tạo bảng GiaoVien
CREATE TABLE IF NOT EXISTS GiaoVien (
    MaGV VARCHAR(20) PRIMARY KEY,
    TenGV VARCHAR(50),
    SDT VARCHAR(10)
);

-- Bước 7: Chỉnh sửa lại bảng MonHoc bổ sung thêm khoá ngoại của bảng MonHoc
ALTER TABLE MonHoc ADD CONSTRAINT FK_MaGV FOREIGN KEY (MaGV) REFERENCES GiaoVien(MaGV);
