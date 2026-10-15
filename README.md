# [Thực hành] Thêm dữ liệu vào trong cơ sở dữ liệu Quản lý Sinh viên

Mã nguồn thực hành bài học Module 3 - Cơ sở dữ liệu quan hệ (RDBMS & SQL) tại [CodeGym](https://codegym.vn).

---

## 🎯 Mục tiêu
- Sử dụng thành thạo câu lệnh `INSERT INTO` để thêm dữ liệu vào các bảng trong MySQL.
- Hiểu được sự khác biệt giữa:
  - Thêm dữ liệu cho tất cả các cột theo thứ tự mặc định (`INSERT INTO Table VALUES (...)`).
  - Thêm dữ liệu chỉ định các cột cụ thể (`INSERT INTO Table (col1, col2, ...) VALUES (...)`) – đặc biệt hữu ích khi bảng có cột `AUTO_INCREMENT` hoặc cho phép giá trị `NULL`.
  - Thêm nhiều dòng dữ liệu cùng một lúc trong một câu lệnh duy nhất.
  - Sử dụng hàm ngày tháng hệ thống như `CURRENT_DATE`.

---

## 📁 Cấu trúc thư mục

- [`QuanLySinhVien.sql`](file:///d:/a/QuanLySinhVien.sql): File tạo cơ sở dữ liệu `QuanLySinhVien` và tạo 4 bảng (`Class`, `Student`, `Subject`, `Mark`) từ bài thực hành trước.
- [`insert-into.sql`](file:///d:/a/insert-into.sql): Các câu lệnh `USE QuanLySinhVien;` và `INSERT INTO` vào 4 bảng theo đúng yêu cầu bài tập.
- [`QuanLySinhVien_Full.sql`](file:///d:/a/QuanLySinhVien_Full.sql): File kịch bản hoàn chỉnh (Tạo CSDL -> Tạo bảng -> Chèn dữ liệu -> `SELECT *` kiểm tra dữ liệu).
- [`create_database.sql`](file:///d:/a/create_database.sql): Script tạo cơ sở dữ liệu `my_database1` trên MySQL Workbench bằng câu lệnh SQL.
- [`drop_database.sql`](file:///d:/a/drop_database.sql): Script xóa cơ sở dữ liệu trên MySQL Workbench bằng câu lệnh SQL.
- [`create_table.sql`](file:///d:/a/create_table.sql): Script tạo bảng `Class` và `Teacher` trong CSDL `student-management`.

---

## 🛠️ [Thực hành] Tạo CSDL trên MySQL Workbench

### Cách 1: Sử dụng giao diện đồ họa (GUI)
1. Mở MySQL Workbench và kết nối tới MySQL Server (nhập mật khẩu tài khoản `root`).
2. Nhìn sang bảng bên trái tại tab **SCHEMAS**, click vào biểu tượng **Create a new schema in the connected server** (biểu tượng hình cái đĩa trụ có dấu `+` nhỏ).
3. Nhập tên CSDL mới: `my_database1`.
4. (Tùy chọn) Chọn **Charset: utf8mb4** và **Collation: utf8mb4_general_ci** để hỗ trợ tiếng Việt đầy đủ.
5. Nhấn **Apply**, xem lại câu lệnh SQL tự sinh rồi nhấn tiếp **Apply** $\rightarrow$ **Finish**.

### Cách 2: Sử dụng câu lệnh SQL
1. Nhấn vào biểu tượng **Create a new SQL tab for executing queries** (hoặc nhấn phím tắt `Ctrl + T`).
2. Nhập câu lệnh:
   ```sql
   CREATE DATABASE `my_database1`;
   ```
3. Nhấn biểu tượng hình tia sét ⚡ (hoặc tổ hợp phím `Ctrl + Enter` / `Ctrl + Shift + Enter`) để thực thi câu lệnh.
4. Chuột phải vào vùng trống trong tab **SCHEMAS** chọn **Refresh All** để thấy `my_database1` xuất hiện.

---

## 🗑️ [Thực hành] Xóa CSDL trên MySQL Workbench

> [!WARNING]
> Thao tác xoá CSDL sẽ xóa toàn bộ các bảng, quan hệ và dữ liệu bên trong CSDL đó vĩnh viễn. Hãy kiểm tra kỹ trước khi xóa!

### Cách 1: Sử dụng giao diện đồ họa (GUI)
1. Bật MySQL Workbench và đăng nhập bằng tài khoản và mật khẩu.
2. Tại tab **SCHEMAS** bên trái, tìm CSDL muốn xóa (ví dụ `my_database1`).
3. Nhấp chuột phải vào tên CSDL và chọn **Drop Schema...**
4. Một hộp thoại cảnh báo sẽ xuất hiện:
   - Chọn **Review SQL**: Nếu muốn xem trước câu lệnh xóa.
   - Chọn **Drop Now**: Để xóa ngay lập tức CSDL.
5. Kiểm tra bảng **Output** phía dưới, nếu có dấu tích xanh là CSDL đã được xóa hoàn tất.

### Cách 2: Sử dụng câu lệnh SQL trên Workbench
1. Nhấn chọn biểu tượng **New Query Tab** (`Ctrl + T`) để mở cửa sổ soạn thảo mới.
2. Nhập câu lệnh SQL sau:
   ```sql
   DROP DATABASE `my_database1`;
   -- Hoặc an toàn hơn (không báo lỗi nếu CSDL không tồn tại):
   -- DROP DATABASE IF EXISTS `my_database1`;
   ```
3. Nhấn vào biểu tượng **Tia sét ⚡** (hoặc `Ctrl + Enter`) để chạy câu lệnh.
4. Kiểm tra cửa sổ **Output** bên dưới: dấu tích màu xanh báo hiệu thành công.
5. Nhấp chuột phải vào tab **SCHEMAS** $\rightarrow$ chọn **Refresh All** để xác nhận CSDL đã biến mất.

---

## 📊 [Thực hành] Tạo bảng trên MySQL Workbench

### 1. Bảng `Class`
| Tên cột | Kiểu dữ liệu | Ràng buộc |
|:---|:---|:---|
| `id` | `INT` | Primary Key (PK), Not Null (NN), Auto Increment (AI) |
| `name` | `VARCHAR(50)` | Cho phép Null |

### 2. Bảng `Teacher`
| Tên cột | Kiểu dữ liệu | Ràng buộc |
|:---|:---|:---|
| `id` | `INT` | Primary Key (PK), Not Null (NN), Auto Increment (AI) |
| `name` | `VARCHAR(50)` | Cho phép Null |
| `age` | `INT` | Cho phép Null |
| `country` | `VARCHAR(50)` | Cho phép Null |

### Cách 1: Sử dụng giao diện đồ họa (GUI)
1. **Khởi động Workbench:** Đăng nhập vào MySQL Server.
2. **Tạo bảng `Class`:**
   - Tại tab **SCHEMAS**, mở rộng hoặc click chuột phải vào CSDL `student-management` (hoặc `student_management`), chọn **Create Table...**
   - Đặt tên bảng tại ô **Table Name**: `Class`.
   - Trong bảng cấu hình cột (Columns):
     - Dòng 1: `id` | kiểu `INT` | tích chọn **PK** (Primary Key), **NN** (Not Null), **AI** (Auto Increment).
     - Dòng 2: `name` | kiểu `VARCHAR(50)`.
   - Nhấn nút **Apply** $\rightarrow$ xem câu lệnh SQL tự sinh $\rightarrow$ nhấn **Apply** $\rightarrow$ **Finish**.
3. **Tạo bảng `Teacher`:**
   - Click chuột phải vào `student-management` $\rightarrow$ chọn **Create Table...**
   - Đặt tên bảng tại ô **Table Name**: `Teacher`.
   - Cấu hình các cột:
     - `id`: `INT` | tích chọn **PK**, **NN**, **AI**.
     - `name`: `VARCHAR(50)`.
     - `age`: `INT`.
     - `country`: `VARCHAR(50)`.
   - Nhấn **Apply** $\rightarrow$ **Apply** $\rightarrow$ **Finish**.

### Cách 2: Sử dụng câu lệnh SQL
Mở tab truy vấn mới (`Ctrl + T`) và thực thi:
```sql
USE `student-management`;

CREATE TABLE IF NOT EXISTS `Class` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `Teacher` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NULL,
    `age` INT NULL,
    `country` VARCHAR(50) NULL,
    PRIMARY KEY (`id`)
);
```

---

## 📋 Chi tiết các câu lệnh `INSERT INTO`

### Bước 1: Chọn cơ sở dữ liệu làm việc
```sql
USE QuanLySinhVien;
```

### Bước 2: Thêm dữ liệu vào bảng `Class`
Thêm lần lượt từng bản ghi vào bảng `Class`. Ở bản ghi thứ 3, dùng hàm `CURRENT_DATE` để lấy ngày hiện tại:
```sql
INSERT INTO Class VALUES (1, 'A1', '2008-12-20', 1);
INSERT INTO Class VALUES (2, 'A2', '2008-12-22', 1);
INSERT INTO Class VALUES (3, 'B3', CURRENT_DATE, 0);
```

### Bước 3: Thêm dữ liệu vào bảng `Student`
Cột `StudentId` là khoá chính tự tăng (`AUTO_INCREMENT`), và học viên `Hoa` không có số điện thoại (cho phép `NULL`). Do đó ta chỉ định rõ danh sách các cột cần thêm:
```sql
INSERT INTO Student (StudentName, Address, Phone, Status, ClassId) 
VALUES ('Hung', 'Ha Noi', '0912113113', 1, 1);

INSERT INTO Student (StudentName, Address, Status, ClassId) 
VALUES ('Hoa', 'Hai phong', 1, 1);

INSERT INTO Student (StudentName, Address, Phone, Status, ClassId) 
VALUES ('Manh', 'HCM', '0123123123', 0, 2);
```

### Bước 4: Thêm dữ liệu nhanh (nhiều bản ghi) vào bảng `Subject`
MySQL cho phép chèn nhiều bản ghi trong cùng một câu lệnh `INSERT INTO` bằng cách phân tách các bộ giá trị bằng dấu phẩy `,`:
```sql
INSERT INTO Subject 
VALUES (1, 'CF', 5, 1), 
       (2, 'C', 6, 1), 
       (3, 'HDJ', 5, 1), 
       (4, 'RDBMS', 10, 1);
```

### Bước 5: Thêm dữ liệu vào bảng `Mark`
Cột `MarkId` tự tăng nên ta không cần truyền giá trị:
```sql
INSERT INTO Mark (SubId, StudentId, Mark, ExamTimes) 
VALUES (1, 1, 8, 1), 
       (1, 2, 10, 2), 
       (2, 1, 12, 1);
```

---

## 🔍 Kiểm tra dữ liệu sau khi chèn
Chạy các câu lệnh truy vấn sau trong MySQL Workbench hoặc Command Line:
```sql
SELECT * FROM Class;
SELECT * FROM Student;
SELECT * FROM Subject;
SELECT * FROM Mark;
```

---

## 🚀 Hướng dẫn nộp bài lên GitHub

1. **Khởi tạo Git Repository tại thư mục hiện tại:**
   ```bash
   git init
   git add .
   git commit -m "feat: complete insert into practice for QuanLySinhVien"
   ```

2. **Tạo repository mới trên GitHub:**
   - Truy cập [https://github.com/new](https://github.com/new)
   - Đặt tên Repository, ví dụ: `jwbd-sql-student-management-insert-into` (chế độ Public).

3. **Liên kết và đẩy mã nguồn lên GitHub:**
   ```bash
   git branch -M main
   git remote add origin https://github.com/<tai-khoan-github-cua-ban>/jwbd-sql-student-management-insert-into.git
   git push -u origin main
   ```

4. **Nộp bài:**
   - Copy đường dẫn GitHub repository vừa tạo (hoặc link commit).
   - Dán vào ô nộp bài trên hệ thống học tập của CodeGym.
