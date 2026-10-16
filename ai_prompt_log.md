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

---
---

# PHẦN 3: DỰ ÁN SÀN THƯƠNG MẠI ĐIỆN TỬ FLASHMART (TỐI ƯU HÓA JOIN)
**Dự án:** Hệ thống Báo cáo Sàn TMĐT FlashMart  
**Vai trò của AI:** SQL Tuning Assistant (Trợ lý phân tích truy vấn SQL)  

---

## 📌 Prompt 1 (FlashMart): Hành vi mặc định của từ khóa `JOIN` trong MySQL
- **Ngữ cảnh:** Thẩm định đoạn script cũ khi lập trình viên chỉ viết `Customers c JOIN Orders o`.
- **Prompt:**
  > "Trong cơ sở dữ liệu MySQL, mặc định từ khóa `JOIN` (khi không ghi rõ `LEFT`, `RIGHT` hay `INNER`) sẽ hoạt động như thế nào? Nó sẽ bỏ qua hay giữ lại các bản ghi không có sự trùng khớp ở cả hai bảng theo lý thuyết tập hợp (Set Theory)?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - Trong chuẩn ANSI SQL và MySQL, từ khóa `JOIN` viết đơn độc mặc định chính là `INNER JOIN`.
  - Phép toán này tương đương với phép giao của 2 tập hợp ($A \cap B$). Bất kỳ phần tử nào thuộc tập $A$ (khách hàng chưa mua) hoặc thuộc tập $B$ (sản phẩm chưa bán) không có cặp khóa ngoại tương ứng đều bị loại bỏ ngay lập tức.
  - **Bài học:** Muốn bảo toàn tính toàn vẹn của bảng bên trái, bắt buộc phải chỉ định tường minh `LEFT JOIN` (hoặc `LEFT OUTER JOIN`).

---

## 📌 Prompt 2 (FlashMart): Sự khác biệt cốt lõi giữa `COUNT(*)` và `COUNT(cột)` trong `LEFT JOIN`
- **Ngữ cảnh:** Báo cáo Marketing cần tính số đơn hàng của từng khách hàng, bao gồm cả khách có 0 đơn.
- **Prompt:**
  > "Khi tôi sử dụng `LEFT JOIN` và đếm số lượng đơn hàng bằng hàm `COUNT`, tôi nên dùng `COUNT(*)` hay `COUNT(o.order_id)`? Sự khác biệt khi kết quả phía bảng phụ trả về `NULL` là gì?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - `COUNT(*)`: Đếm tổng số hàng vật lý trong nhóm, không cần kiểm tra giá trị của từng cột có `NULL` hay không. Đối với khách hàng chưa mua hàng (`Charlie`), sau khi `LEFT JOIN` sẽ có 1 hàng với các cột bên `Orders` mang giá trị `NULL`. `COUNT(*)` vẫn đếm hàng này và trả về `1` (sai thực tế).
  - `COUNT(o.order_id)`: Đếm số lượng giá trị không phải `NULL` (`NON-NULL`) trong cột được chỉ định. Vì `Charlie` không có đơn hàng nên `o.order_id` là `NULL`, hàm sẽ bỏ qua và trả về chính xác `0`.

---

## 📌 Prompt 3 (FlashMart): Phân tích hiệu năng Anti-Join vs Subquery (NOT IN / NOT EXISTS)
- **Ngữ cảnh:** Tìm kiếm các sản phẩm tồn kho chưa từng được bán ra lần nào.
- **Prompt:**
  > "Hãy phân tích hiệu năng (Performance) và kế hoạch thực thi (Execution Plan) của việc dùng `LEFT JOIN ... WHERE o.order_id IS NULL` so với việc dùng subquery `NOT IN` hoặc `NOT EXISTS` khi tìm kiếm các bản ghi mồ côi."
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - `NOT IN`: Cực kỳ nguy hiểm nếu cột trong subquery chứa giá trị `NULL` (vì so sánh với `NULL` sẽ trả về `UNKNOWN`, làm toàn bộ câu truy vấn không trả về bản ghi nào).
  - `LEFT JOIN ... WHERE IS NULL` (Anti-Join): Tận dụng được Index trên khóa ngoại của bảng `Orders`. MySQL Optimizer sẽ nhận diện mẫu truy vấn này và tự động dừng quét ngay khi tìm thấy bản ghi khớp đầu tiên (Not-exists optimization), giúp tốc độ truy vấn trên bảng hàng triệu dòng nhanh vượt trội.
  - `NOT EXISTS`: Cũng rất tối ưu và dễ đọc logic, thường có hiệu năng tương đương Anti-Join trên MySQL 8.0+.

---

## 📌 Prompt 4 (FlashMart): Thuật toán tối ưu hóa JOIN của MySQL Optimizer
- **Ngữ cảnh:** Nâng cao tư duy thiết kế và bảo vệ vấn đáp trước Chief Data Officer (CDO).
- **Prompt:**
  > "MySQL Optimizer thực hiện các phép JOIN bằng các thuật toán nào? Hãy giải thích cơ chế của Nested-Loop Join (NLJ), Block Nested-Loop (BNL) và Hash Join trong MySQL 8.0."
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - **Index Nested-Loop Join:** Bảng ngoài (Driving table) quét tuần tự, sau đó dùng Index của bảng trong để tìm kiếm nhanh $\rightarrow$ Hiệu năng tốt nhất khi có Index.
  - **Block Nested-Loop (BNL):** Được dùng khi bảng trong không có Index. Đọc một khối các dòng từ bảng ngoài vào bộ nhớ đệm (`join_buffer_size`) rồi quét toàn bộ bảng trong một lần để so khớp.
  - **Hash Join (Từ MySQL 8.0.18 trở đi):** Thay thế hoàn toàn BNL cho các phép kết nối đẳng thức (Equi-join) không có Index. Tạo bảng băm (In-memory Hash Table) từ bảng nhỏ hơn và duyệt qua bảng lớn hơn để tra cứu $\rightarrow$ Tăng tốc độ JOIN gấp nhiều lần trên cơ sở dữ liệu lớn.

---

## 📌 Prompt 5 (FlashMart): Giả lập FULL OUTER JOIN trong MySQL
- **Ngữ cảnh:** Báo cáo tổng thể khách hàng và sản phẩm phục vụ giám sát toàn diện.
- **Prompt:**
  > "MySQL không hỗ trợ cú pháp `FULL OUTER JOIN`. Có cú pháp chuẩn nào cho phép tôi kết hợp kết quả của `LEFT JOIN` và `RIGHT JOIN` để giả lập `FULL OUTER JOIN` không?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - Sử dụng toán tử `UNION` giữa câu lệnh `LEFT JOIN` và câu lệnh `RIGHT JOIN`.
  - Toán tử `UNION` tự động loại bỏ các bản ghi trùng lặp ở phần giao thoa ($A \cap B$), giữ lại toàn vẹn tập $A$ và tập $B$.
  - Cú pháp chuẩn: `(SELECT ... FROM A LEFT JOIN B ON ...) UNION (SELECT ... FROM A RIGHT JOIN B ON ...);`.

---
---

# PHẦN 4: DỰ ÁN VÍ ĐIỆN TỬ PAYFLOW (TỐI ƯU HÓA B-TREE INDEX & SARGABLE QUERY)
**Dự án:** Hệ thống Thống kê Tài chính Ví điện tử PayFlow  
**Vai trò của AI:** Database Tuning Assistant (Trợ lý phân tích hiệu năng truy vấn)  

---

## 📌 Prompt 1 (PayFlow): Tại sao bọc hàm ngày tháng lại vô hiệu hóa B-Tree Index?
- **Ngữ cảnh:** Đánh giá câu truy vấn của Kế toán: `WHERE YEAR(created_at) = 2026 AND MONTH(created_at) = 6`.
- **Prompt:**
  > "Trong MySQL, nếu tôi đã tạo B-Tree Index cho một cột ngày tháng, nhưng trong mệnh đề WHERE tôi lại viết `WHERE YEAR(created_at) = 2026 AND MONTH(created_at) = 6`, tại sao MySQL lại từ chối sử dụng Index và phải quét toàn bộ bảng (Full Table Scan)?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - B-Tree Index lưu trữ các giá trị của cột `created_at` đã được sắp xếp theo thứ tự nguyên bản (raw datetime).
  - Khi bọc hàm `YEAR()` hoặc `MONTH()` quanh cột, MySQL không thể suy diễn được giá trị đầu vào ban đầu nếu không tính toán trước. CSDL buộc phải duyệt qua từng dòng một của bảng (hàng triệu dòng), áp hàm tính toán cho từng dòng rồi mới so sánh với giá trị `2026` hay `6`.
  - Đây chính là **Non-SARGable (Not Search-Argument-Able)**.
  - **Khắc phục:** Giữ nguyên vẹn cột ở vế so sánh và chuyển điều kiện sang dạng khoảng (Range): `created_at >= '2026-06-01' AND created_at < '2026-07-01'`.

---

## 📌 Prompt 2 (PayFlow): Quy tắc sắp xếp thứ tự các cột trong Composite Index
- **Ngữ cảnh:** Thiết kế Composite Index trên 2 cột `transaction_type` và `created_at`.
- **Prompt:**
  > "Khi thiết kế một Composite Index trong MySQL cho 2 cột `(transaction_type, created_at)` phục vụ điều kiện `WHERE transaction_type = 'DEPOSIT' AND created_at >= ... AND created_at < ...`, thứ tự các cột trong Index có quan trọng không? Tôi nên đặt cột nào đứng trước để có hiệu suất tốt nhất?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - **Quy tắc vàng của Composite Index:** Cột tham gia phép so sánh đẳng thức (`=`) bắt buộc phải đặt trước, cột tham gia phép so sánh khoảng (Range: `>`, `<`, `BETWEEN`) phải đặt phía sau.
  - Cụ thể: Phải tạo Index là `(transaction_type, created_at)`.
  - **Lý do:** B-Tree sẽ dùng nhánh đầu tiên để định vị chính xác nhánh con chứa `transaction_type = 'DEPOSIT'`, sau đó quét một dải liên tục (Range Scan) các giá trị `created_at` trong tháng 6. Nếu đảo ngược lại thành `(created_at, transaction_type)`, MySQL chỉ dùng được Range Scan trên ngày tháng và không thể tận dụng tiếp cột `transaction_type` để lọc nhị phân.

---

## 📌 Prompt 3 (PayFlow): Bản chất của Index Seek vs Index Scan trên cây B-Tree
- **Ngữ cảnh:** Tìm hiểu sâu về cơ chế vật lý của B-Tree Index để bảo vệ giải pháp trước CTO.
- **Prompt:**
  > "Hãy giải thích sự khác biệt giữa Index Seek và Index Scan trên cấu trúc cây B-Tree trong hệ quản trị cơ sở dữ liệu. Tại sao Index Seek lại có độ phức tạp thuật toán O(log N)?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - **Index Seek:** Đi từ nút gốc (Root) qua các nút trung gian (Branch/Non-leaf) bằng thuật toán tìm kiếm nhị phân để chạm tới đúng vị trí bản ghi đầu tiên tại nút lá (Leaf node). Độ phức tạp thuật toán là $O(\log N)$, chỉ mất 3-4 lần đọc khối đĩa cho bảng hàng chục triệu dòng.
  - **Index Scan:** Duyệt qua toàn bộ danh sách liên kết của các nút lá (Leaf nodes) từ đầu đến cuối (hoặc một dải lớn). Độ phức tạp là $O(N)$ trên số nút lá.
  - **Ý nghĩa:** Câu truy vấn SARGable cho phép thực hiện **Index Seek** để định vị điểm bắt đầu và điểm kết thúc của tháng 6, chỉ đọc đúng dải dữ liệu cần thiết.

---

## 📌 Prompt 4 (PayFlow): Tối ưu hóa đỉnh cao với Covering Index
- **Ngữ cảnh:** Đọc hiểu trường `Extra` trong EXPLAIN khi xuất hiện `Using where; Using index`.
- **Prompt:**
  > "Trong kết quả EXPLAIN, dòng Extra hiện chữ `Using index condition` khác gì với `Using index` (Covering Index)? Làm thế nào để loại bỏ hoàn toàn việc truy cập vào bảng chính (Table Lookup)?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - `Using index condition` (Index Condition Pushdown - ICP): MySQL dùng Index để lọc dữ liệu ở tầng lưu trữ, nhưng vẫn phải quay về Clustered Index trên đĩa để lấy các cột khác (`amount`).
  - `Using index` (Covering Index): Tất cả các cột được yêu cầu trong câu truy vấn (`transaction_type`, `created_at`, `amount`) đều đã nằm trọn vẹn trong cây Index phụ.
  - **Lợi ích:** Database chỉ đọc dữ liệu trực tiếp trong bộ nhớ đệm RAM của Index, **không cần tốn bất kỳ một lượt I/O nào xuống ổ đĩa** để đọc bảng chính, mang lại tốc độ phản hồi tính toán tức thì.

---

## 📌 Prompt 5 (PayFlow): Đo lường thời gian thực thi chuẩn xác bằng MySQL Profiling
- **Ngữ cảnh:** Thay thế việc ước lượng thời gian cảm tính bằng công cụ đo lường microsecond chính xác của MySQL.
- **Prompt:**
  > "Làm thế nào để đo lường chính xác thời gian thực thi (Execution Time) của một câu lệnh SQL chi tiết đến từng microsecond trong MySQL thay vì chỉ nhìn vào Execution Plan?"
- **Phản hồi cốt lõi từ AI & Bài học rút ra:**
  - Bật tính năng đo lường: `SET profiling = 1;`
  - Chạy câu lệnh SQL cần đo kiểm.
  - Xem danh sách câu lệnh vừa thực thi: `SHOW PROFILES;`
  - Xem chi tiết từng giai đoạn CPU/IO của truy vấn: `SHOW PROFILE FOR QUERY 1;` (phân tích thời gian mở bảng, tối ưu hóa, thực thi và dọn dẹp).

