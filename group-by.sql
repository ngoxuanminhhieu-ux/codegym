-- =============================================================================
-- [Thực hành] Sử dụng các hàm thông dụng trong SQL (GROUP BY, COUNT, AVG, HAVING)
-- Mã nguồn tham khảo: https://github.com/codegym-vn/jwbd-2023-sql-student-management-group-by
-- =============================================================================

-- Bước 1: Sử dụng cơ sở dữ liệu QuanLySinhVien
USE QuanLySinhVien;

-- -----------------------------------------------------------------------------
-- Bước 2: Sử dụng hàm COUNT để hiển thị số lượng sinh viên ở từng nơi
-- -----------------------------------------------------------------------------
SELECT Address, COUNT(StudentId) AS 'Số lượng học viên'
FROM Student
GROUP BY Address;

-- -----------------------------------------------------------------------------
-- Bước 3: Tính điểm trung bình các môn học của mỗi học viên bằng hàm AVG
-- -----------------------------------------------------------------------------
SELECT S.StudentId, S.StudentName, AVG(Mark) AS 'Điểm trung bình'
FROM Student S 
JOIN Mark M ON S.StudentId = M.StudentId
GROUP BY S.StudentId, S.StudentName;

-- -----------------------------------------------------------------------------
-- Bước 4: Hiển thị những bạn học viên có điểm trung bình các môn học lớn hơn 15
-- Sử dụng mệnh đề HAVING để lọc kết quả sau khi đã GROUP BY
-- -----------------------------------------------------------------------------
SELECT S.StudentId, S.StudentName, AVG(Mark) AS 'Điểm trung bình'
FROM Student S 
JOIN Mark M ON S.StudentId = M.StudentId
GROUP BY S.StudentId, S.StudentName
HAVING AVG(Mark) > 15;

-- -----------------------------------------------------------------------------
-- Bước 5: Hiển thị thông tin các học viên có điểm trung bình lớn nhất
-- Kết hợp HAVING và toán tử so sánh >= ALL (Subquery)
-- -----------------------------------------------------------------------------
SELECT S.StudentId, S.StudentName, AVG(Mark) AS 'Điểm trung bình cao nhất'
FROM Student S 
JOIN Mark M ON S.StudentId = M.StudentId
GROUP BY S.StudentId, S.StudentName
HAVING AVG(Mark) >= ALL (
    SELECT AVG(Mark) 
    FROM Mark 
    GROUP BY Mark.StudentId
);
