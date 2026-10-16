-- =============================================================================
-- [Bài tập] Truy vấn dữ liệu nâng cao với CSDL Quản lý sinh viên
-- =============================================================================

USE QuanLySinhVien;

-- -----------------------------------------------------------------------------
-- 1. Hiển thị tất cả các sinh viên có tên bắt đầu bằng ký tự 'h'
-- Sử dụng toán tử LIKE với mẫu 'h%' (không phân biệt chữ hoa/thường trong MySQL)
-- -----------------------------------------------------------------------------
SELECT * 
FROM Student 
WHERE StudentName LIKE 'h%';


-- -----------------------------------------------------------------------------
-- 2. Hiển thị các thông tin lớp học có thời gian bắt đầu vào tháng 12
-- Sử dụng hàm MONTH(StartDate) = 12 để trích xuất tháng từ trường DATETIME
-- -----------------------------------------------------------------------------
SELECT * 
FROM Class 
WHERE MONTH(StartDate) = 12;


-- -----------------------------------------------------------------------------
-- 3. Hiển thị tất cả các thông tin môn học có credit trong khoảng từ 3-5
-- Sử dụng mệnh đề BETWEEN ... AND ... (tương đương Credit >= 3 AND Credit <= 5)
-- -----------------------------------------------------------------------------
SELECT * 
FROM Subject 
WHERE Credit BETWEEN 3 AND 5;


-- -----------------------------------------------------------------------------
-- 4. Thay đổi mã lớp (ClassID) của sinh viên có tên 'Hung' là 2
-- Sử dụng lệnh UPDATE kết hợp mệnh đề WHERE
-- (Tắt tạm safe updates mode nếu làm việc trên MySQL Workbench)
-- -----------------------------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

UPDATE Student 
SET ClassId = 2 
WHERE StudentName = 'Hung';

-- Kiểm tra lại dữ liệu sau khi cập nhật
SELECT * 
FROM Student 
WHERE StudentName = 'Hung';


-- -----------------------------------------------------------------------------
-- 5. Hiển thị các thông tin: StudentName, SubName, Mark.
-- Dữ liệu sắp xếp theo điểm thi (Mark) giảm dần; nếu trùng điểm sắp theo tên tăng dần
-- Kết hợp 3 bảng Student, Mark, Subject bằng INNER JOIN và mệnh đề ORDER BY
-- -----------------------------------------------------------------------------
SELECT 
    S.StudentName, 
    Sub.SubName, 
    M.Mark 
FROM Student S 
JOIN Mark M ON S.StudentId = M.StudentId 
JOIN Subject Sub ON M.SubId = Sub.SubId 
ORDER BY M.Mark DESC, S.StudentName ASC;
