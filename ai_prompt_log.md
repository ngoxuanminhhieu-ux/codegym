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
