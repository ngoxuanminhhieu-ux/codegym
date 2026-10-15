# BÁO CÁO PHÂN TÍCH BẤT NHẤT DỮ LIỆU (GAP ANALYSIS REPORT)
**Dự án:** Số hóa quy trình "Đặt lịch và Khám bệnh" - Phòng khám đa khoa HealthSync  
**Người thực hiện:** System Analyst & Database Administrator  

---

### 1. Bối cảnh & Thực trạng
Qua đối chiếu giữa **Lưu đồ hoạt động (UML Activity Diagram)** do Business Analyst (BA) thiết kế và **Cơ sở dữ liệu Legacy (MySQL)** của phòng khám HealthSync, chúng tôi phát hiện 3 điểm "vênh" nghiêm trọng khiến hệ thống liên tục phát sinh lỗi nghiệp vụ khi đưa vào vận hành thử nghiệm:

1. **Sai lệch mô hình trạng thái (State Lifecycle Gap):**  
   Quy trình nghiệp vụ thực tế trải qua vòng đời 5 trạng thái liên tục: `PENDING` $\rightarrow$ `CONFIRMED` $\rightarrow$ `CHECKED_IN` $\rightarrow$ `COMPLETED` hoặc `CANCELLED`. Tuy nhiên, cơ sở dữ liệu cũ lại sử dụng cột `is_active BOOLEAN`. Kiểu Boolean nhị phân chỉ lưu được 2 trạng thái (`TRUE`/`FALSE`), hoàn toàn làm tê liệt khả năng nhận diện bệnh nhân đã đóng cọc hay chưa, đã đến phòng khám hay đã khám xong.

2. **Thiếu hụt dữ liệu tài chính và giải trình hủy lịch (Financial & Audit Gap):**  
   Quy trình quy định bệnh nhân phải đóng tiền cọc (`deposit_amount`) và nếu hủy hẹn sau khi đã xác nhận thì phòng khám áp dụng chế tài thu phí phạt (`penalty_fee`) kèm lý do hủy (`cancel_reason`). Cơ sở dữ liệu cũ không có các trường này, khiến bộ phận kế toán không thể đối soát dòng tiền, không tính toán được doanh thu từ tiền phạt và gây thất thoát tài chính.

3. **Vắng mặt hoàn toàn thực thể Đơn thuốc (Missing Entity & Medical Workflow Gap):**  
   Theo nghiệp vụ, kết quả cốt lõi của bước `COMPLETED` là Bác sĩ kê Đơn thuốc cho bệnh nhân. Thiết kế cũ hoàn toàn không có bảng `Prescriptions`, không có liên kết khóa ngoại với lịch hẹn, dẫn đến việc dữ liệu điều trị y tế bị bỏ trống ngoài hệ thống.

---

### 2. Tác động của sự bất nhất (Consistency) giữa BA và Dev
Sự thiếu nhất quán giữa UML Activity Diagram và ERD là nguyên nhân trực tiếp gây đứt gãy giao tiếp giữa BA và Lập trình viên Backend:
- **Lập trình viên** phải tự "chắp vá" logic ở tầng code ứng dụng, dẫn đến code rối rắm và lỗi dữ liệu ngầm (data corruption).
- **Bộ phận vận hành & Kế toán** mất dấu vết dữ liệu kiểm toán (audit trail), không đối soát được doanh thu thực thu so với công suất phục vụ thực tế của phòng khám.
- Việc chuẩn hóa lại schema MySQL với kiểu `ENUM`, `DECIMAL(12,2)`, bổ sung bảng `Prescriptions` và thiết lập Database Trigger đã giải quyết triệt để sự bất nhất này, đảm bảo tính toàn vẹn 100% cho hệ thống.
