-- Bước 1: Chọn cơ sở dữ liệu QuanLySinhVien để làm việc
USE QuanLySinhVien;

-- Bước 2: Thêm dữ liệu vào bảng Class
INSERT INTO Class
VALUES (1, 'A1', '2008-12-20', 1);

INSERT INTO Class
VALUES (2, 'A2', '2008-12-22', 1);

INSERT INTO Class
VALUES (3, 'B3', CURRENT_DATE, 0);

-- Bước 3: Thêm dữ liệu vào bảng Student
-- Cột StudentId tự động tăng (AUTO_INCREMENT), ta chỉ định danh sách cột cần thêm:
INSERT INTO Student (StudentName, Address, Phone, Status, ClassId)
VALUES ('Hung', 'Ha Noi', '0912113113', 1, 1);

INSERT INTO Student (StudentName, Address, Status, ClassId)
VALUES ('Hoa', 'Hai phong', 1, 1);

INSERT INTO Student (StudentName, Address, Phone, Status, ClassId)
VALUES ('Manh', 'HCM', '0123123123', 0, 2);

-- Bước 4: Thêm nhiều bản ghi cùng lúc vào bảng Subject
INSERT INTO Subject
VALUES (1, 'CF', 5, 1),
       (2, 'C', 6, 1),
       (3, 'HDJ', 5, 1),
       (4, 'RDBMS', 10, 1);

-- Bước 5: Thêm dữ liệu vào bảng Mark
-- Cột MarkId tự động tăng (AUTO_INCREMENT):
INSERT INTO Mark (SubId, StudentId, Mark, ExamTimes)
VALUES (1, 1, 8, 1),
       (1, 2, 10, 2),
       (2, 1, 12, 1);
