-- =============================================================================
-- [Thực hành] Truy vấn dữ liệu với CSDL Quản lý sinh viên
-- Mã nguồn tham khảo: https://github.com/codegym-vn/jwbd-2023-sql-student-management-select-query
-- =============================================================================

-- Bước 1: Sử dụng cơ sở dữ liệu QuanLySinhVien
USE QuanLySinhVien;

-- Bước 2: Hiển thị danh sách tất cả các học viên
SELECT * 
FROM Student;

-- Bước 3: Hiển thị danh sách các học viên đang theo học (Status = true)
SELECT * 
FROM Student 
WHERE Status = true;

-- Bước 4: Hiển thị danh sách các môn học có thời gian học nhỏ hơn 10 giờ (Credit < 10)
SELECT * 
FROM Subject 
WHERE Credit < 10;

-- Bước 5: Hiển thị danh sách học viên lớp A1 (JOIN 2 bảng Student và Class)
SELECT S.StudentId, S.StudentName, C.ClassName 
FROM Student S 
JOIN Class C ON S.ClassId = C.ClassID 
WHERE C.ClassName = 'A1';

-- Bước 6: Hiển thị điểm môn CF của các học viên (JOIN 3 bảng Student, Mark và Subject)
SELECT S.StudentId, S.StudentName, Sub.SubName, M.Mark 
FROM Student S 
JOIN Mark M ON S.StudentId = M.StudentId 
JOIN Subject Sub ON M.SubId = Sub.SubId 
WHERE Sub.SubName = 'CF';
