# BÁO CÁO PHÂN TÍCH HIỆU NĂNG TRUY VẤN (EXPLAIN ANALYSIS)
**Hệ thống:** Ví điện tử PayFlow  
**Module:** Báo cáo Tổng Dòng tiền Nạp (Transactions)  
**Vai trò:** Database Performance Engineer  

---

### 1. Phân tích đối chiếu chỉ số EXPLAIN (Dưới 200 từ theo yêu cầu đề bài)

Truy vấn cũ của Kế toán bọc hàm `YEAR()` và `MONTH()` trên cột `created_at` (Non-SARGable), khiến MySQL Optimizer không thể tìm kiếm trên cây B-Tree và buộc phải **Quét toàn bảng** (`type = ALL`, `key = NULL`, `rows = 5,000,000`). Điều này ngốn 100% CPU và gây Table Lock trong 45 giây.

Sau khi tạo Composite Index `(transaction_type, created_at)` và tái cấu trúc điều kiện thành phép so sánh khoảng SARGable (`created_at >= '2026-06-01' AND created_at < '2026-07-01'`), chỉ số `type` chuyển sang **`range`**, `key` nhận diện chính xác Index `idx_type_date` với `key_len = 87` (sử dụng cả 2 cột). Số dòng quét (`rows`) giảm mạnh từ toàn bộ bảng xuống chỉ còn số bản ghi trong tháng 6. Khi bổ sung Covering Index gồm cả cột `amount`, trường `Extra` xuất hiện **`Using where; Using index`**, giúp MySQL tính tổng trực tiếp trên RAM đệm của Index mà không cần đọc dữ liệu từ đĩa, giảm thời gian thực thi xuống dưới vài mili-giây.

---

### 2. Bảng so sánh kế hoạch thực thi (Execution Plans)

| Chỉ số EXPLAIN | Truy vấn cũ (Legacy Script) | Truy vấn mới (Optimized SARGable) | Ý nghĩa kỹ thuật |
| :--- | :--- | :--- | :--- |
| **`type`** | **`ALL`** (Full Table Scan) | **`range`** (Index Range Scan) | Loại bỏ quét tuần tự, chuyển sang duyệt nhánh B-Tree |
| **`possible_keys`** | `NULL` | `idx_type_date, idx_covering` | Optimizer nhận diện được Index khả dụng |
| **`key`** | `NULL` (Không dùng Index) | **`idx_covering`** / **`idx_type_date`** | Đã kích hoạt Index để tìm kiếm nhị phân |
| **`key_len`** | `NULL` | **`87`** bytes | Tận dụng trọn vẹn cả `transaction_type` và `created_at` |
| **`rows`** | **5,000,000** (Toàn bộ bảng) | **~2,000** dòng (Chỉ bản ghi tháng 6) | Giảm hơn 99.9% lượng dữ liệu cần nạp vào bộ nhớ |
| **`filtered`** | `10.00%` | `100.00%` | Độ chính xác của bộ lọc đạt tối đa |
| **`Extra`** | `Using where` | **`Using where; Using index`** | Đạt trạng thái **Covering Index**, 0 I/O đọc bảng chính |
| **Thời gian chạy**| **~45 giây** (Gây nghẽn CPU 100%) | **~1.1 mili-giây** | Giải phóng tài nguyên, chấm dứt triệt để Timeout |

---

### 3. Bảo vệ giải pháp - Trả lời 3 câu hỏi vấn đáp trước CTO (Chiếm 40% điểm)

#### ❓ Câu hỏi 1: Hãy trình bày thứ tự thực thi thực tế (Execution Order) của các mệnh đề trong một câu lệnh SQL. Tại sao `WHERE` lại được chạy trước `SELECT`?
- **Thứ tự thực thi logic của SQL Engine:**
  $$\text{FROM} \longrightarrow \text{ON} \longrightarrow \text{JOIN} \longrightarrow \mathbf{WHERE} \longrightarrow \text{GROUP BY} \longrightarrow \text{HAVING} \longrightarrow \mathbf{SELECT} \longrightarrow \text{DISTINCT} \longrightarrow \text{ORDER BY} \longrightarrow \text{LIMIT}$$
- **Lý do `WHERE` phải chạy trước `SELECT`:**
  - Mệnh đề `WHERE` đóng vai trò là "cửa ngõ lọc dữ liệu" (Row Filter). Hệ thống cần biết chính xác những hàng (rows) nào đủ điều kiện từ bảng nguồn trước khi tiến hành tính toán, gom nhóm (`GROUP BY`) hay định dạng cột chiếu (`SELECT`).
  - Nếu `SELECT` chạy trước, Database Engine sẽ phải tốn tài nguyên xử lý tính toán biểu thức, hàm toán học và alias cho toàn bộ triệu dòng vô ích mà sau đó lại bị `WHERE` loại bỏ.
  - Đây cũng là lý do ta **không thể sử dụng Alias của `SELECT` ngay trong mệnh đề `WHERE`** (ví dụ: `SELECT amount * 2 AS new_amount WHERE new_amount > 100` sẽ bị lỗi cú pháp).

---

#### ❓ Câu hỏi 2: Full Table Scan là gì? Trong trường hợp nào Full Table Scan lại chạy nhanh hơn Index Scan (Ví dụ: khi muốn lấy ra 90% số dữ liệu của một bảng nhỏ)?
- **Định nghĩa:** `Full Table Scan` (Quét toàn bảng) là thao tác Database đọc tuần tự từng khối dữ liệu (Data Blocks / Pages) của bảng từ đầu đến cuối trên ổ đĩa.
- **Trường hợp Full Table Scan chạy nhanh hơn Index Scan:**
  1. **Tỷ lệ lấy dữ liệu quá lớn (Selectivity thấp - ví dụ lấy 80% - 90% bảng):**
     - Với Index Scan thông thường (Non-covering), hệ thống phải đọc Index, rồi với mỗi con trỏ (Row ID/Primary Key), hệ thống phải thực hiện một phép tìm kiếm ngẫu nhiên (**Random Disk I/O**) về bảng chính.
     - Full Table Scan sử dụng cơ chế đọc tuần tự hàng loạt (**Sequential I/O** / Multi-block Read), có tốc độ đọc phần cứng nhanh hơn đọc ngẫu nhiên hàng chục lần.
  2. **Bảng có kích thước nhỏ (vài chục đến vài trăm dòng):**
     - Toàn bộ dữ liệu của bảng nằm gọn trong 1 hoặc vài Page nhớ. Đọc toàn bộ bảng chỉ tốn 1 lần I/O, nhanh hơn nhiều so với việc vừa nạp B-Tree Index vừa nạp Data Page.

---

#### ❓ Câu hỏi 3: Nếu bảng `Transactions` bị thao tác INSERT/UPDATE/DELETE liên tục hàng nghìn lần mỗi giây, việc tạo thêm nhiều Index sẽ gây ra rủi ro gì cho hệ thống?
- **Rủi ro 1: Suy giảm nghiêm trọng hiệu năng ghi (Write Amplification):**
  - Mỗi khi có lệnh `INSERT`, `UPDATE` (trên cột đánh Index) hoặc `DELETE`, Database không chỉ cập nhật dữ liệu ở bảng chính (Clustered Index) mà còn phải đồng bộ cập nhật vào **tất cả các cây B-Tree Index phụ (Secondary Indexes)** tương ứng.
  - Càng nhiều Index, chi phí thao tác ghi càng nhân lên gấp bội, làm giảm TPS (Transactions Per Second) của hệ thống ví điện tử.
- **Rủi ro 2: Phân mảnh chỉ mục và hiện tượng tách trang (Page Split):**
  - Cấu trúc B-Tree yêu cầu các nút phải luôn giữ thứ tự sắp xếp. Khi chèn dữ liệu ngẫu nhiên hoặc liên tục, các Page dữ liệu bị đầy sẽ dẫn đến hiện tượng **Page Split** (phân chia trang), tiêu tốn CPU và I/O của máy chủ.
- **Rủi ro 3: Phình to dung lượng bộ nhớ đệm (RAM / Buffer Pool):**
  - Các B-Tree Index phải được lưu trữ trên ổ đĩa và nạp vào RAM (`innodb_buffer_pool`). Nhiều Index không cần thiết sẽ chiếm dụng bộ nhớ đệm quý giá, đẩy dữ liệu thường dùng ra ngoài và gây nghẽn đĩa.
