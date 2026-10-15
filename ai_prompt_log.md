# NHẬT KÝ SỬ DỤNG AI TRONG THIẾT KẾ HỆ THỐNG (AI PROMPT LOG)
**Dự án:** Hệ thống Phòng khám đa khoa HealthSync  
**Vai trò của AI:** Data Modeling Assistant (Trợ lý mô hình hóa dữ liệu) & Logic Reviewer  

---

## 📌 Prompt 1: Phân tích Anti-pattern về trạng thái vòng đời
- **Ngữ cảnh (Context):** Đang thẩm định bảng `Appointments` của hệ thống cũ dùng cột `is_active BOOLEAN`.
- **Prompt:**
  > "Trong thiết kế cơ sở dữ liệu quan hệ, tại sao việc dùng một cột `is_active` (kiểu `TINYINT` / `BOOLEAN`) để theo dõi vòng đời của một Đơn hàng hoặc Lịch hẹn lại là một thiết kế tồi (Anti-pattern)? Tôi nên thay thế bằng cấu trúc nào để phản ánh đúng quy trình PENDING -> CONFIRMED -> CHECKED_IN -> COMPLETED -> CANCELLED?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - Kiểu Boolean chỉ lưu được 2 trạng thái nhị phân (Có/Không), hoàn toàn không thể thể hiện được máy trạng thái hữu hạn (Finite State Machine).
  - Sử dụng cột `is_active` dẫn đến việc lập trình viên phải thêm hàng loạt cờ nhị phân khác (`is_confirmed`, `is_cancelled`, `is_paid`...), gây phình to bảng và tạo ra các trạng thái xung đột không hợp lệ (ví dụ: `is_active = TRUE` nhưng `is_cancelled = TRUE`).
  - **Giải pháp tối ưu:** Sử dụng kiểu dữ liệu `ENUM` với danh sách trạng thái rõ ràng, hoặc tách thành bảng từ điển trạng thái `AppointmentStatuses` nếu cần mở rộng động.

---

## 📌 Prompt 2: Thảo luận về rủi ro làm tròn số trong tính toán tài chính
- **Ngữ cảnh (Context):** Thiết kế trường lưu trữ tiền cọc (`deposit_amount`) và phí phạt (`penalty_fee`).
- **Prompt:**
  > "Khi thiết kế cột `deposit_amount` và `penalty_fee` trong MySQL phục vụ tính toán tài chính và đối soát doanh thu, tôi nên dùng kiểu dữ liệu `FLOAT`, `DOUBLE` hay `DECIMAL`? Phân tích nguy cơ sai số làm tròn (Floating-point precision error) và đưa ra cú pháp chuẩn."
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - `FLOAT` và `DOUBLE` là kiểu số thực dấu phẩy động (IEEE 754), lưu trữ dưới dạng xấp xỉ nhị phân, dẫn đến sai số tích lũy nghiêm trọng khi thực hiện các phép cộng trừ dồn tiền (ví dụ: `0.1 + 0.2 = 0.30000000000000004`).
  - `DECIMAL(M, D)` là kiểu số dấu phẩy tĩnh (Fixed-point), lưu trữ chính xác từng chữ số thập phân, đảm bảo số dư kế toán luôn khớp đến từng đồng mà không bị mất tiền do làm tròn.
  - **Cấu hình lựa chọn:** `DECIMAL(12, 2)` (hỗ trợ tối đa 999 tỷ VNĐ, có 2 chữ số lẻ).

---

## 📌 Prompt 3: Lựa chọn ràng buộc khóa ngoại (ON DELETE RESTRICT vs CASCADE)
- **Ngữ cảnh (Context):** Thiết kế khóa ngoại giữa `Appointments` và `Prescriptions`, cũng như giữa `Patients`/`Doctors` với `Appointments`.
- **Prompt:**
  > "Đối với hệ thống y tế và đặt lịch khám, tại sao ở bảng `Appointments` và `Prescriptions` ta nên áp dụng `ON DELETE RESTRICT` thay vì `ON DELETE CASCADE` cho các khóa ngoại liên quan đến bệnh nhân và lịch hẹn? Hậu quả pháp lý hoặc y khoa nếu dùng sai là gì?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - Dữ liệu y tế và hồ sơ bệnh án là tài liệu pháp lý bắt buộc phải lưu trữ nguyên trạng phục vụ thanh tra, giám định và lịch sử điều trị.
  - Nếu dùng `ON DELETE CASCADE`, khi một tài khoản bệnh nhân hoặc bác sĩ bị xóa vô tình, toàn bộ lịch hẹn và đơn thuốc liên quan sẽ bị xóa sạch theo dạng chuỗi.
  - **Giải pháp tối ưu:** Áp dụng `ON DELETE RESTRICT` để chặn hoàn toàn hành vi xóa các đối tượng gốc khi đã có lịch sử khám bệnh và đơn thuốc phát sinh.

---

## 📌 Prompt 4: Bảo vệ tính toàn vẹn dữ liệu bằng Database Trigger
- **Ngữ cảnh (Context):** Giải quyết câu hỏi vấn đáp: Ngăn chặn hành vi chèn đơn thuốc cho lịch hẹn chưa hoàn tất khám.
- **Prompt:**
  > "Làm thế nào để chặn hoàn toàn hành vi cố tình chèn (INSERT) một đơn thuốc vào bảng `Prescriptions` khi lịch hẹn (`Appointments`) chưa đạt trạng thái `COMPLETED` ngay tại tầng cơ sở dữ liệu MySQL bằng Trigger?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - Dùng `BEFORE INSERT TRIGGER` trên bảng `Prescriptions`.
  - Truy vấn trạng thái lịch hẹn hiện tại bằng `SELECT status INTO v_status FROM Appointments WHERE appointment_id = NEW.appointment_id;`.
  - Nếu `v_status != 'COMPLETED'`, phát lệnh lỗi `SIGNAL SQLSTATE '45000'` với thông báo lỗi tường minh, buộc giao dịch (Transaction) phải Rollback ngay lập tức mà không phụ thuộc vào code Backend.

---

## 📌 Prompt 5: Truy vấn kiểm thử và báo cáo đối soát tài chính
- **Ngữ cảnh (Context):** Viết câu lệnh DML kiểm thử luồng nghiệp vụ và báo cáo cho Giám đốc phòng khám.
- **Prompt:**
  > "Viết cho tôi các câu lệnh SQL SELECT kết hợp INNER JOIN giữa `Appointments`, `Patients`, `Doctors`, và `Prescriptions` để hiển thị danh sách các ca khám hoàn tất; đồng thời viết câu lệnh GROUP BY để tính tổng tiền cọc, tổng tiền phạt và số dư còn lại của từng trạng thái lịch hẹn."
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - Tạo bảng truy vấn tổng hợp dùng `SUM(deposit_amount)`, `SUM(penalty_fee)` và `SUM(deposit_amount - penalty_fee)` để hỗ trợ kế toán đối soát ngay tức thì mà không cần xuất Excel tính toán thủ công.

---
---

# PHẦN 2: DỰ ÁN HỆ THỐNG CHO THUÊ XE TỰ LÁI AUTORIDE
**Dự án:** Ứng dụng Quản lý Thuê và Trả xe tự lái AutoRide  
**Vai trò của AI:** Database Tuning Assistant (Trợ lý thiết kế và tối ưu CSDL)  

---

## 📌 Prompt 1 (AutoRide): Rủi ro sai số dấu phẩy động trong công thức hoàn cọc
- **Ngữ cảnh:** Thiết kế các cột tiền cọc `security_deposit`, phí phạt trễ `late_fee`, phí sửa chữa `damage_fee`.
- **Prompt:**
  > "Trong bài toán hoàn trả tiền cọc cho thuê xe: `refund = security_deposit - late_fee - damage_fee`, việc dùng kiểu `FLOAT` hoặc `DOUBLE` trong MySQL có thể dẫn đến rủi ro sai lệch tài chính nào? Tại sao bắt buộc phải dùng `DECIMAL(12, 2)`?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - Kiểu `FLOAT` lưu trữ xấp xỉ nhị phân, khi thực hiện phép trừ trừ liên tiếp (ví dụ: `10000000.00 - 0.00 - 2000000.00`) có thể phát sinh các số thập phân siêu nhỏ ngầm (`7999999.999999999`), khiến hệ thống thanh toán tự động qua cổng ngân hàng bị từ chối hoặc sai lệch sổ sách kế toán.
  - `DECIMAL(12, 2)` lưu trữ định dạng BCD (Binary Coded Decimal) bảo toàn độ chính xác tuyệt đối 100% đến từng hào/xu tiền tệ, hoàn toàn loại bỏ rủi ro sai số tích lũy.

---

## 📌 Prompt 2 (AutoRide): Phân tích quan hệ 1-1 vs 1-N cho bảng `Inspections`
- **Ngữ cảnh:** Lựa chọn giữa gộp cột vào `Rentals`, quan hệ 1-1 hay quan hệ 1-N cho Biên bản kiểm tra xe.
- **Prompt:**
  > "Khi thiết kế bảng lưu trữ Biên bản kiểm tra xe (`Inspections`), tôi nên thiết kế quan hệ 1-1 hay 1-N với bảng `Rentals`? Hãy phân tích theo thực tế quy trình kiểm tra xe trước khi nhận (lúc giao xe) và sau khi trả (lúc thu hồi xe)."
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - Trong thực tế vận hành cho thuê xe, một hợp đồng luôn có ít nhất **2 lần kiểm tra xe**:
    1. Lần 1: Kiểm tra trước bàn giao (ghi nhận mức xăng, đồng hồ ODO, các vết xước cũ sẵn có).
    2. Lần 2: Kiểm tra khi khách trả xe (phát hiện vết xước/hư hỏng mới phát sinh so với lần 1).
  - Do đó, thiết kế quan hệ **1 - N (`Rentals 1 --- N Inspections`)** là tối ưu nhất, tuân thủ chuẩn 3NF và cho phép lưu trữ lịch sử nhiều biên bản kiểm tra xe của cùng một hợp đồng thuê.

---

## 📌 Prompt 3 (AutoRide): Thiết kế Database Trigger bảo vệ trạng thái `BOOKED`
- **Ngữ cảnh:** Giải quyết câu hỏi vấn đáp: Chặn không cho lập biên bản kiểm tra khi hợp đồng đang `BOOKED`.
- **Prompt:**
  > "Hãy hướng dẫn viết Database Trigger trên MySQL để chặn không cho nhân viên lập biên bản kiểm tra xe (`INSERT INTO Inspections`) nếu hợp đồng thuê xe tương ứng đang ở trạng thái `BOOKED` (khách hàng chưa nhận xe)."
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - Viết `BEFORE INSERT TRIGGER` trên bảng `Inspections`.
  - Truy vấn trạng thái hợp đồng: `SELECT status INTO v_status FROM Rentals WHERE rental_id = NEW.rental_id;`.
  - Nếu `v_status = 'BOOKED'`, dùng lệnh `SIGNAL SQLSTATE '45000'` kèm thông báo lỗi rõ ràng.
  - **Ý nghĩa:** Đảm bảo toàn vẹn dữ liệu ở tầng thấp nhất (Database Level), dù Backend có lỗi logic hay hacker cố tình gọi API thì CSDL vẫn kiên quyết từ chối.

---

## 📌 Prompt 4 (AutoRide): Xử lý giá trị NULL trong tính toán hoàn tiền
- **Ngữ cảnh:** Tránh rủi ro công thức hoàn cọc bị trả về NULL do các cột phí chưa cập nhật.
- **Prompt:**
  > "Trong MySQL, nếu `late_fee` hoặc `damage_fee` bị giá trị NULL thì phép tính `security_deposit - late_fee - damage_fee` sẽ trả về NULL. Làm thế nào để phòng chống điều này ở cả tầng cấu trúc bảng (DDL) và tầng truy vấn (DML)?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - **Ở tầng cấu trúc bảng (DDL):** Định nghĩa rõ `NOT NULL DEFAULT 0.00` cho tất cả các cột chi phí tài chính (`security_deposit`, `late_fee`, `damage_fee`).
  - **Ở tầng truy vấn (DML):** Sử dụng hàm `COALESCE(late_fee, 0)` và `COALESCE(damage_fee, 0)` để luôn đảm bảo tính toán an toàn trong mọi trường hợp dữ liệu cũ bị NULL.
