-- =============================================================================
-- BÀI THỰC HÀNH: THÊM DỮ LIỆU VÀO CƠ SỞ DỮ LIỆU QUẢN LÝ SINH VIÊN
-- =============================================================================

-- 1. TẠO CƠ SỞ DỮ LIỆU VÀ CẤU TRÚC BẢNG (NẾU CHƯA CÓ)
CREATE DATABASE IF NOT EXISTS QuanLySinhVien;
USE QuanLySinhVien;

DROP TABLE IF EXISTS Mark;
DROP TABLE IF EXISTS Subject;
DROP TABLE IF EXISTS Student;
DROP TABLE IF EXISTS Class;

CREATE TABLE Class
(
    ClassID   INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    ClassName VARCHAR(60) NOT NULL,
    StartDate DATETIME    NOT NULL,
    Status    BIT
);

CREATE TABLE Student
(
    StudentId   INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    StudentName VARCHAR(30) NOT NULL,
    Address     VARCHAR(50),
    Phone       VARCHAR(20),
    Status      BIT,
    ClassId     INT         NOT NULL,
    FOREIGN KEY (ClassId) REFERENCES Class (ClassID)
);

CREATE TABLE Subject
(
    SubId   INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    SubName VARCHAR(30) NOT NULL,
    Credit  TINYINT     NOT NULL DEFAULT 1 CHECK ( Credit >= 1 ),
    Status  BIT                  DEFAULT 1
);

CREATE TABLE Mark
(
    MarkId    INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    SubId     INT NOT NULL,
    StudentId INT NOT NULL,
    Mark      FLOAT   DEFAULT 0 CHECK ( Mark BETWEEN 0 AND 100 ),
    ExamTimes TINYINT DEFAULT 1,
    UNIQUE (SubId, StudentId),
    FOREIGN KEY (SubId) REFERENCES Subject (SubId),
    FOREIGN KEY (StudentId) REFERENCES Student (StudentId)
);

-- =============================================================================
-- 2. THỰC HIỆN THÊM DỮ LIỆU (INSERT INTO)
-- =============================================================================

-- Bước 2: Thêm lần lượt các bản ghi vào bảng Class
INSERT INTO Class
VALUES (1, 'A1', '2008-12-20', 1);

INSERT INTO Class
VALUES (2, 'A2', '2008-12-22', 1);

INSERT INTO Class
VALUES (3, 'B3', CURRENT_DATE, 0);

-- Bước 3: Thêm dữ liệu vào bảng Student (không truyền StudentId vì AUTO_INCREMENT)
INSERT INTO Student (StudentName, Address, Phone, Status, ClassId)
VALUES ('Hung', 'Ha Noi', '0912113113', 1, 1);

INSERT INTO Student (StudentName, Address, Status, ClassId)
VALUES ('Hoa', 'Hai phong', 1, 1);

INSERT INTO Student (StudentName, Address, Phone, Status, ClassId)
VALUES ('Manh', 'HCM', '0123123123', 0, 2);

-- Bước 4: Thêm dữ liệu nhanh (nhiều bản ghi) vào bảng Subject
INSERT INTO Subject
VALUES (1, 'CF', 5, 1),
       (2, 'C', 6, 1),
       (3, 'HDJ', 5, 1),
       (4, 'RDBMS', 10, 1);

-- Bước 5: Thêm dữ liệu vào bảng Mark
INSERT INTO Mark (SubId, StudentId, Mark, ExamTimes)
VALUES (1, 1, 8, 1),
       (1, 2, 10, 2),
       (2, 1, 12, 1);

-- =============================================================================
-- 3. TRUY VẤN KIỂM TRA DỮ LIỆU SAU KHI THÊM
-- =============================================================================
SELECT * FROM Class;
SELECT * FROM Student;
SELECT * FROM Subject;
SELECT * FROM Mark;
