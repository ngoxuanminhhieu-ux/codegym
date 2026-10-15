# BÁO CÁO ĐỐI CHIẾU UML ACTIVITY DIAGRAM VỚI ERD (ER-ACTIVITY MAPPING)
**Dự án:** Hệ thống quản lý cho thuê xe tự lái AutoRide  
**Vai trò:** Data Architect  

---

### 1. Phân tích: Tại sao cột `damage_fee` là bắt buộc phải có để hệ thống toàn vẹn?
*(Đoạn văn ngắn theo yêu cầu đề bài - dưới 200 từ)*

Trong quy trình "Thuê và Trả xe", nhánh rẽ khi xe bị hư hỏng yêu cầu bắt buộc: **Tiền hoàn lại = Tiền cọc - Phí trễ - Phí sửa chữa**. 
Nếu cơ sở dữ liệu thiếu cột `damage_fee`, hệ thống bị gãy hoàn toàn tính toàn vẹn tài chính. Kế toán không có căn cứ hạch toán số tiền bồi thường thực tế, nhân viên lễ tân buộc phải trả đủ 100% tiền cọc cho khách hoặc thỏa thuận tiền mặt ngoài luồng. Điều này gây thất thoát nghiêm trọng ngân sách bảo dưỡng đội xe, làm sai lệch dòng tiền đối soát và biến dữ liệu kiểm tra xe thành vô nghĩa vì không thể quy đổi thiệt hại thành con số khấu trừ. Do đó, `damage_fee` là cột dữ liệu sống còn để khép kín chu trình nghiệp vụ.

---

### 2. Bảng chẩn đoán 3 khoảng trống dữ liệu (Data Gaps) của thiết kế cũ

| STT | Điểm chạm nghiệp vụ (UML Activity) | Thiết kế cũ (Legacy DB) | Khoảng trống dữ liệu (Data Gap) & Hậu quả | Giải pháp tái cấu trúc (Optimized DB) |
|:---:|:---|:---|:---|:---|
| **1** | Quản lý vòng đời hợp đồng: `BOOKED` $\rightarrow$ `ACTIVE` $\rightarrow$ `COMPLETED` / `CANCELLED` | Cột `status VARCHAR(50) DEFAULT 'BOOKED'` | **State Gap:** Cho phép nhập chuỗi tùy ý, không ràng buộc máy trạng thái, dễ lỗi dữ liệu bẩn (`"Active"`, `"Hoàn tất"`...). | Chuẩn hóa sang `ENUM('BOOKED', 'ACTIVE', 'COMPLETED', 'CANCELLED') NOT NULL`. |
| **2** | Nhánh rẽ khấu trừ cọc khi trả xe: Tính phí phạt trễ giờ và phí bồi thường hư hại | Hoàn toàn không có cột tài chính nào trong bảng `Rentals` | **Financial Gap:** Mất dấu vết tiền cọc (`security_deposit`), không thể trừ `late_fee` và `damage_fee`, gây lỗ vốn nặng cho AutoRide. | Bổ sung `security_deposit`, `late_fee`, `damage_fee` kiểu `DECIMAL(12, 2)` kèm ràng buộc `CHECK (>= 0)`. |
| **3** | Nhân viên kiểm tra tình trạng xe (Inspection) lúc khách trả xe | Hoàn toàn không có thực thể kiểm tra xe | **Audit & Inspection Gap:** Không có nơi lưu trữ mô tả hư hỏng, người kiểm tra, ngày giờ kiểm tra; dẫn đến tranh chấp pháp lý với khách. | Tạo bảng mới `Inspections` có khóa ngoại `rental_id` liên kết chặt chẽ với `Rentals(rental_id)`. |

---

### 3. Bảo vệ thiết kế - Trả lời 3 câu hỏi vấn đáp (Chiếm 40% điểm)

#### ❓ Câu hỏi 1: Tại sao việc tách dữ liệu kiểm tra xe ra một bảng riêng (`Inspections`) lại tốt hơn việc nhồi nhét một cột `damage_description` trực tiếp vào bảng `Rentals`?
- **Trả lời:**
  1. **Tuân thủ Chuẩn hóa dữ liệu (1NF & 3NF):** Việc kiểm tra xe có thể diễn ra nhiều lần trong một chu kỳ thuê (kiểm tra lúc giao xe để lập biên bản hiện trạng ban đầu, và kiểm tra lúc nhận xe để đối chiếu hư hại mới) $\rightarrow$ Bản chất là quan hệ $1 - N$. Nếu gộp vào bảng `Rentals`, ta vi phạm chuẩn hóa và chỉ lưu được một lần duy nhất.
  2. **Bảo toàn thông tin pháp lý & kiểm toán:** Bảng `Inspections` lưu độc lập `inspector_name`, `inspection_date`, hình ảnh/mô tả chi tiết. Nếu để chung trong `Rentals`, bảng này sẽ bị phình to (sparse table với nhiều giá trị NULL khi xe không hỏng).

#### ❓ Câu hỏi 2: Khi hợp đồng đang ở trạng thái `BOOKED` (khách chưa nhận xe), làm thế nào để chặn không cho ai chèn dữ liệu vào bảng `Inspections` ngay ở tầng Database?
- **Trả lời:**
  - Áp dụng **Database Trigger** `BEFORE INSERT` trên bảng `Inspections`.
  - Trigger sẽ truy vấn trạng thái hợp đồng trong `Rentals`. Nếu `status = 'BOOKED'`, trigger gọi `SIGNAL SQLSTATE '45000'` phát lỗi và hủy giao dịch:
    ```sql
    IF v_status IS NULL OR v_status = 'BOOKED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Loi toan ven: Khong the lap bien ban kiem tra xe khi hop dong dang o trang thai BOOKED!';
    END IF;
    ```

#### ❓ Câu hỏi 3: Sự thiếu đồng bộ giữa Activity Diagram do BA vẽ và ERD do Dev thiết kế thường dẫn đến những hậu quả gì về mặt trải nghiệm người dùng cuối trên ứng dụng?
- **Trả lời:**
  1. **Trải nghiệm đứt gãy và lỗi hệ thống (Crash/Error):** Giao diện ứng dụng hiển thị nút "Báo cáo hư hại" hoặc "Tính tiền hoàn trả", nhưng khi người dùng bấm gửi thì Backend báo lỗi `500 Internal Server Error` do cơ sở dữ liệu không có cột lưu trữ.
  2. **Mất minh bạch và niềm tin của khách hàng:** Khách hàng không nhận được bảng kê chi tiết minh bạch lý do bị trừ tiền cọc (bao nhiêu tiền phạt trễ, bao nhiêu tiền sửa chữa), dẫn đến khiếu nại, đánh giá 1 sao và hủy bỏ sử dụng dịch vụ của AutoRide.
