-- =============================================================================
-- [Thực hành] Xây dựng mô hình ERD cho cơ sở dữ liệu Quản lý đơn đặt hàng
-- =============================================================================

CREATE DATABASE IF NOT EXISTS QuanLyDonHang;
USE QuanLyDonHang;

-- Xóa bảng cũ nếu tồn tại (theo thứ tự khóa ngoại để tránh xung đột)
DROP TABLE IF EXISTS ChiTietGiao;
DROP TABLE IF EXISTS PhieuGiaoHang;
DROP TABLE IF EXISTS ChiTietDat;
DROP TABLE IF EXISTS DonDatHang;
DROP TABLE IF EXISTS Hang;
DROP TABLE IF EXISTS NoiGiao;
DROP TABLE IF EXISTS NguoiGiao;
DROP TABLE IF EXISTS NguoiNhan;
DROP TABLE IF EXISTS NguoiDat;
DROP TABLE IF EXISTS DonViKhach;

-- 1. BẢNG ĐƠN VỊ KHÁCH (Gộp từ Đơn vị ĐH và Đơn vị KH)
CREATE TABLE DonViKhach (
    MaDV INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    TenDV VARCHAR(100) NOT NULL,
    DiaChi VARCHAR(200),
    DienThoai VARCHAR(20)
);

-- 2. BẢNG NGƯỜI ĐẶT (Thuộc Đơn vị khách)
CREATE TABLE NguoiDat (
    MaND INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    HoTenND VARCHAR(50) NOT NULL,
    MaDV INT NOT NULL,
    FOREIGN KEY (MaDV) REFERENCES DonViKhach(MaDV) ON DELETE CASCADE
);

-- 3. BẢNG NGƯỜI NHẬN (Thuộc Đơn vị khách)
CREATE TABLE NguoiNhan (
    MaNN INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    HoTenNN VARCHAR(50) NOT NULL,
    MaDV INT NOT NULL,
    FOREIGN KEY (MaDV) REFERENCES DonViKhach(MaDV) ON DELETE CASCADE
);

-- 4. BẢNG NGƯỜI GIAO (Nhân viên giao hàng)
CREATE TABLE NguoiGiao (
    MaNG INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    HoTenNG VARCHAR(50) NOT NULL
);

-- 5. BẢNG NƠI GIAO (Địa điểm giao hàng)
CREATE TABLE NoiGiao (
    MaDDG INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    TenNoiGiao VARCHAR(200) NOT NULL
);

-- 6. BẢNG HÀNG (Hàng hóa, sản phẩm)
CREATE TABLE Hang (
    MaHang INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    TenHang VARCHAR(100) NOT NULL,
    DvTinh VARCHAR(20) NOT NULL,
    MoTa TEXT
);

-- 7. BẢNG ĐƠN ĐẶT HÀNG
CREATE TABLE DonDatHang (
    SoDH VARCHAR(20) NOT NULL PRIMARY KEY,
    NgayDat DATE NOT NULL,
    MaND INT NOT NULL,
    FOREIGN KEY (MaND) REFERENCES NguoiDat(MaND)
);

-- 8. BẢNG CHI TIẾT ĐẶT (Quan hệ N - N giữa Đơn Đặt Hàng và Hàng)
CREATE TABLE ChiTietDat (
    SoDH VARCHAR(20) NOT NULL,
    MaHang INT NOT NULL,
    SoLuongDat INT NOT NULL CHECK (SoLuongDat > 0),
    PRIMARY KEY (SoDH, MaHang),
    FOREIGN KEY (SoDH) REFERENCES DonDatHang(SoDH) ON DELETE CASCADE,
    FOREIGN KEY (MaHang) REFERENCES Hang(MaHang)
);

-- 9. BẢNG PHIẾU GIAO HÀNG
CREATE TABLE PhieuGiaoHang (
    SoPG VARCHAR(20) NOT NULL PRIMARY KEY,
    NgayGiao DATE NOT NULL,
    SoDH VARCHAR(20),
    MaNG INT NOT NULL,
    MaNN INT NOT NULL,
    MaDDG INT NOT NULL,
    FOREIGN KEY (SoDH) REFERENCES DonDatHang(SoDH),
    FOREIGN KEY (MaNG) REFERENCES NguoiGiao(MaNG),
    FOREIGN KEY (MaNN) REFERENCES NguoiNhan(MaNN),
    FOREIGN KEY (MaDDG) REFERENCES NoiGiao(MaDDG)
);

-- 10. BẢNG CHI TIẾT GIAO (Quan hệ N - N giữa Phiếu Giao Hàng và Hàng)
CREATE TABLE ChiTietGiao (
    SoPG VARCHAR(20) NOT NULL,
    MaHang INT NOT NULL,
    SoLuongGiao INT NOT NULL CHECK (SoLuongGiao > 0),
    DonGia DECIMAL(15, 2) NOT NULL CHECK (DonGia >= 0),
    ThanhTien DECIMAL(15, 2) GENERATED ALWAYS AS (SoLuongGiao * DonGia) STORED,
    PRIMARY KEY (SoPG, MaHang),
    FOREIGN KEY (SoPG) REFERENCES PhieuGiaoHang(SoPG) ON DELETE CASCADE,
    FOREIGN KEY (MaHang) REFERENCES Hang(MaHang)
);

-- =============================================================================
-- THÊM DỮ LIỆU MẪU ĐỂ KIỂM THỬ MÔ HÌNH
-- =============================================================================

-- Thêm Đơn vị khách
INSERT INTO DonViKhach (TenDV, DiaChi, DienThoai)
VALUES 
    ('Công ty TNHH Ánh Dương', '123 Cầu Giấy, Hà Nội', '0243888999'),
    ('Tập đoàn Hòa Phát', '456 Lê Duẩn, Đà Nẵng', '0236777888');

-- Thêm Người đặt & Người nhận thuộc đơn vị khách
INSERT INTO NguoiDat (HoTenND, MaDV) VALUES ('Nguyễn Văn An', 1), ('Trần Thị Bình', 2);
INSERT INTO NguoiNhan (HoTenNN, MaDV) VALUES ('Lê Văn Cường', 1), ('Phạm Minh Đức', 2);

-- Thêm Người giao & Nơi giao
INSERT INTO NguoiGiao (HoTenNG) VALUES ('Hoàng Văn Giao 1'), ('Vũ Đình Giao 2');
INSERT INTO NoiGiao (TenNoiGiao) VALUES ('Kho số 1 - Cảng Hà Nội'), ('Văn phòng đại diện Đà Nẵng');

-- Thêm Hàng hóa
INSERT INTO Hang (TenHang, DvTinh, MoTa)
VALUES 
    ('Bàn làm việc gỗ sồi', 'Chiếc', 'Bàn kích thước 1m4 x 0.7m'),
    ('Ghế công thái học', 'Chiếc', 'Ghế lưới xoay ngả lưng'),
    ('Tủ tài liệu 3 ngăn', 'Tủ', 'Tủ sắt sơn tĩnh điện');

-- Thêm Đơn đặt hàng
INSERT INTO DonDatHang (SoDH, NgayDat, MaND)
VALUES ('DH001', '2026-10-10', 1);

-- Thêm Chi tiết đặt hàng
INSERT INTO ChiTietDat (SoDH, MaHang, SoLuongDat)
VALUES 
    ('DH001', 1, 10),
    ('DH001', 2, 20);

-- Thêm Phiếu giao hàng
INSERT INTO PhieuGiaoHang (SoPG, NgayGiao, SoDH, MaNG, MaNN, MaDDG)
VALUES ('PG001', '2026-10-12', 'DH001', 1, 1, 1);

-- Thêm Chi tiết giao hàng
INSERT INTO ChiTietGiao (SoPG, MaHang, SoLuongGiao, DonGia)
VALUES 
    ('PG001', 1, 10, 1500000),
    ('PG001', 2, 20, 2200000);

-- =============================================================================
-- TRUY VẤN KIỂM TRA MÔ HÌNH
-- =============================================================================
-- Xem thông tin chi tiết phiếu giao hàng đầy đủ
SELECT 
    pgh.SoPG,
    pgh.NgayGiao,
    pgh.SoDH,
    dvk.TenDV AS DonViKhach,
    ng.HoTenNG AS NguoiGiao,
    nn.HoTenNN AS NguoiNhan,
    ngiao.TenNoiGiao AS DiaDiemGiao,
    h.TenHang,
    h.DvTinh,
    ctg.SoLuongGiao,
    ctg.DonGia,
    ctg.ThanhTien
FROM PhieuGiaoHang pgh
JOIN NguoiGiao ng ON pgh.MaNG = ng.MaNG
JOIN NguoiNhan nn ON pgh.MaNN = nn.MaNN
JOIN DonViKhach dvk ON nn.MaDV = dvk.MaDV
JOIN NoiGiao ngiao ON pgh.MaDDG = ngiao.MaDDG
JOIN ChiTietGiao ctg ON pgh.SoPG = ctg.SoPG
JOIN Hang h ON ctg.MaHang = h.MaHang;
