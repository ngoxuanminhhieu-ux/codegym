-- =============================================================================
-- [Bài tập] Chuyển đổi mô hình ERD sang mô hình dữ liệu quan hệ
-- Cơ sở dữ liệu: QuanLyVatTu
-- =============================================================================

CREATE DATABASE IF NOT EXISTS QuanLyVatTu
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE QuanLyVatTu;

-- Xóa bảng cũ nếu tồn tại theo thứ tự ràng buộc khóa ngoại
DROP TABLE IF EXISTS ChiTietPhieuXuat;
DROP TABLE IF EXISTS PhieuXuat;
DROP TABLE IF EXISTS ChiTietPhieuNhap;
DROP TABLE IF EXISTS PhieuNhap;
DROP TABLE IF EXISTS ChiTietDonDH;
DROP TABLE IF EXISTS VatTu;
DROP TABLE IF EXISTS DonDH;
DROP TABLE IF EXISTS NhaCC_SDT;
DROP TABLE IF EXISTS NhaCC;

-- =============================================================================
-- 1. BẢNG TẠO TỪ THỰC THỂ ĐƠN LẺ & QUAN HỆ 1 - N
-- =============================================================================

-- Thực thể NHACC (Nhà cung cấp)
CREATE TABLE NhaCC (
    MaNCC VARCHAR(20) PRIMARY KEY,
    TenNCC VARCHAR(100) NOT NULL,
    DiaChi VARCHAR(200) NOT NULL
);

-- Thuộc tính đa trị SDT của NHACC tách thành bảng riêng (Bước 3)
CREATE TABLE NhaCC_SDT (
    MaNCC VARCHAR(20) NOT NULL,
    SDT VARCHAR(15) NOT NULL,
    PRIMARY KEY (MaNCC, SDT),
    FOREIGN KEY (MaNCC) REFERENCES NhaCC(MaNCC) ON DELETE CASCADE
);

-- Thực thể DONDH (Đơn đặt hàng)
-- Quan hệ 1 - n: 1 NhaCC cung cấp nhiều DonDH => mang MaNCC làm FK
CREATE TABLE DonDH (
    SoDH VARCHAR(20) PRIMARY KEY,
    NgayDH DATE NOT NULL,
    MaNCC VARCHAR(20) NOT NULL,
    FOREIGN KEY (MaNCC) REFERENCES NhaCC(MaNCC)
);

-- Thực thể VATTU (Vật tư)
CREATE TABLE VatTu (
    MaVT VARCHAR(20) PRIMARY KEY,
    TenVT VARCHAR(100) NOT NULL
);

-- Thực thể PHIEUNHAP (Phiếu nhập kho)
CREATE TABLE PhieuNhap (
    SoPN VARCHAR(20) PRIMARY KEY,
    NgayNhap DATE NOT NULL
);

-- Thực thể PHIEUXUAT (Phiếu xuất kho)
CREATE TABLE PhieuXuat (
    SoPX VARCHAR(20) PRIMARY KEY,
    NgayXuat DATE NOT NULL
);

-- =============================================================================
-- 2. CÁC BẢNG TRUNG GIAN SINH RA TỪ MỐI QUAN HỆ NHIỀU - NHIỀU (N - M)
-- =============================================================================

-- Mối quan hệ Đặt (n - m) giữa DonDH và VatTu
CREATE TABLE ChiTietDonDH (
    SoDH VARCHAR(20) NOT NULL,
    MaVT VARCHAR(20) NOT NULL,
    PRIMARY KEY (SoDH, MaVT),
    FOREIGN KEY (SoDH) REFERENCES DonDH(SoDH) ON DELETE CASCADE,
    FOREIGN KEY (MaVT) REFERENCES VatTu(MaVT)
);

-- Mối quan hệ Nhập (n - m) giữa PhieuNhap và VatTu (có thuộc tính riêng DGNhap, SLNhap)
CREATE TABLE ChiTietPhieuNhap (
    SoPN VARCHAR(20) NOT NULL,
    MaVT VARCHAR(20) NOT NULL,
    DGNhap DECIMAL(15, 2) NOT NULL CHECK (DGNhap >= 0),
    SLNhap INT NOT NULL CHECK (SLNhap > 0),
    PRIMARY KEY (SoPN, MaVT),
    FOREIGN KEY (SoPN) REFERENCES PhieuNhap(SoPN) ON DELETE CASCADE,
    FOREIGN KEY (MaVT) REFERENCES VatTu(MaVT)
);

-- Mối quan hệ Xuất (n - m) giữa PhieuXuat và VatTu (có thuộc tính riêng DGXuat, SLXuat)
CREATE TABLE ChiTietPhieuXuat (
    SoPX VARCHAR(20) NOT NULL,
    MaVT VARCHAR(20) NOT NULL,
    DGXuat DECIMAL(15, 2) NOT NULL CHECK (DGXuat >= 0),
    SLXuat INT NOT NULL CHECK (SLXuat > 0),
    PRIMARY KEY (SoPX, MaVT),
    FOREIGN KEY (SoPX) REFERENCES PhieuXuat(SoPX) ON DELETE CASCADE,
    FOREIGN KEY (MaVT) REFERENCES VatTu(MaVT)
);

-- =============================================================================
-- 3. DỮ LIỆU MẪU KIỂM THỬ MÔ HÌNH QUAN HỆ
-- =============================================================================

-- Thêm Nhà cung cấp
INSERT INTO NhaCC (MaNCC, TenNCC, DiaChi)
VALUES 
    ('NCC01', 'Công ty Cổ phần Thép Hòa Phát', 'KCN Phố Nối, Hưng Yên'),
    ('NCC02', 'Xi Măng Hà Tiên 1', 'Kiên Lương, Kiên Giang');

-- Thêm thuộc tính đa trị Số điện thoại cho Nhà cung cấp
INSERT INTO NhaCC_SDT (MaNCC, SDT)
VALUES 
    ('NCC01', '0243888999'),
    ('NCC01', '0988111222'),
    ('NCC02', '0283777666');

-- Thêm Đơn đặt hàng (thuộc nhà cung cấp)
INSERT INTO DonDH (SoDH, NgayDH, MaNCC)
VALUES 
    ('DH01', '2026-10-01', 'NCC01'),
    ('DH02', '2026-10-05', 'NCC02');

-- Thêm Danh mục Vật tư
INSERT INTO VatTu (MaVT, TenVT)
VALUES 
    ('VT01', 'Thép cuộn phi 8'),
    ('VT02', 'Thép cây phi 16'),
    ('VT03', 'Xi măng PCB40');

-- Chi tiết đơn đặt hàng (DonDH - VatTu)
INSERT INTO ChiTietDonDH (SoDH, MaVT)
VALUES 
    ('DH01', 'VT01'),
    ('DH01', 'VT02'),
    ('DH02', 'VT03');

-- Thêm Phiếu nhập & Chi tiết phiếu nhập
INSERT INTO PhieuNhap (SoPN, NgayNhap)
VALUES ('PN01', '2026-10-08');

INSERT INTO ChiTietPhieuNhap (SoPN, MaVT, DGNhap, SLNhap)
VALUES 
    ('PN01', 'VT01', 14500000, 10),
    ('PN01', 'VT02', 15200000, 15);

-- Thêm Phiếu xuất & Chi tiết phiếu xuất
INSERT INTO PhieuXuat (SoPX, NgayXuat)
VALUES ('PX01', '2026-10-12');

INSERT INTO ChiTietPhieuXuat (SoPX, MaVT, DGXuat, SLXuat)
VALUES 
    ('PX01', 'VT01', 15500000, 5);

-- =============================================================================
-- 4. TRUY VẤN KIỂM TRA MỐI QUAN HỆ GIỮA CÁC BẢNG
-- =============================================================================

-- Truy vấn 1: Xem Nhà cung cấp kèm các số điện thoại đa trị
SELECT 
    ncc.MaNCC,
    ncc.TenNCC,
    ncc.DiaChi,
    GROUP_CONCAT(sdt.SDT SEPARATOR ', ') AS DanhSachSDT
FROM NhaCC ncc
LEFT JOIN NhaCC_SDT sdt ON ncc.MaNCC = sdt.MaNCC
GROUP BY ncc.MaNCC, ncc.TenNCC, ncc.DiaChi;

-- Truy vấn 2: Xem chi tiết phiếu nhập kho
SELECT 
    pn.SoPN,
    pn.NgayNhap,
    vt.TenVT,
    ctpn.DGNhap,
    ctpn.SLNhap,
    (ctpn.DGNhap * ctpn.SLNhap) AS ThanhTienNhap
FROM PhieuNhap pn
JOIN ChiTietPhieuNhap ctpn ON pn.SoPN = ctpn.SoPN
JOIN VatTu vt ON ctpn.MaVT = vt.MaVT;
