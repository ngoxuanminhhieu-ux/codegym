# BÁO CÁO PHÂN TÍCH TỐI ƯU HÓA TRUY VẤN JOIN (JOIN ANALYSIS)
**Dự án:** Hệ thống Báo cáo Sàn TMĐT FlashMart  
**Vai trò:** Data Engineer  

---

### 1. Giải trình: Tại sao bắt buộc dùng `COUNT(o.order_id)` thay vì `COUNT(*)`?
*(Đoạn giải trình ngắn theo yêu cầu đề bài - dưới 150 từ)*

Khi thực hiện `LEFT JOIN`, những khách hàng chưa từng mua hàng (như Charlie) vẫn được giữ lại trong tập kết quả, nhưng toàn bộ các cột thuộc bảng `Orders` sẽ mang giá trị `NULL`.
Hàm `COUNT(*)` đếm **tất cả các dòng vật lý** được sinh ra sau phép JOIN mà không quan tâm giá trị trong ô là gì. Do đó, dòng chứa Charlie (dù mang giá trị `NULL` ở các cột đơn hàng) vẫn bị tính là 1 dòng, dẫn đến kết quả sai lệch nghiêm trọng: `total_orders = 1`.
Ngược lại, hàm `COUNT(o.order_id)` chỉ đếm những giá trị **khác NULL** trên cột được chỉ định. Khi gặp dòng của Charlie với `o.order_id IS NULL`, hàm sẽ bỏ qua và trả về chính xác `total_orders = 0`. Vì vậy, dùng `COUNT(o.order_id)` là bắt buộc.

---

### 2. Ánh xạ lý thuyết tập hợp (Venn Diagram) & Xác định bảng gốc (Driving Table)

```
       BÁO CÁO MARKETING                      BÁO CÁO KHO VẬN (ANTI-JOIN)
      (LEFT OUTER JOIN)                       (LEFT JOIN ... WHERE IS NULL)

    [ Customers ]     [ Orders ]           [ Products ]     [ Orders ]
   /             \   /          \         /            \   /          \
  |   Charlie     | |            |       |   Keyboard   | |            |
  |   (0 đơn)     | |            |       |  (Chưa bán)  | |            |
  |       \       | |            |       |      \       | |            |
  |        Alice, Bob (Đã mua)   |       |       Laptop, Mouse (Đã bán)|
   \             /   \          /         \            /   \          /
    -------------     ----------           ------------     ----------
    ==> Giữ TOÀN BỘ Customers             ==> Chỉ lấy phần Products RIÊNG BIỆT
    (Gồm cả phần giao và không giao)         (Ngoại trừ phần giao với Orders)
```

1. **Báo cáo Marketing:**
   - **Bảng gốc (Driving table / Left table):** `Customers`.
   - **Mục tiêu:** Giữ nguyên 100% khách hàng đã đăng ký tài khoản, kể cả khách chưa có phát sinh đơn.
2. **Báo cáo Kho vận:**
   - **Bảng gốc (Driving table / Left table):** `Products`.
   - **Mục tiêu:** Sử dụng kỹ thuật **Anti-Join** (`LEFT JOIN ... WHERE o.order_id IS NULL`) để lọc ra những sản phẩm hoàn toàn không có giao điểm với tập hợp `Orders`.

---

### 3. Bảo vệ lựa chọn - Trả lời 3 câu hỏi vấn đáp (Chiếm 40% điểm)

#### ❓ Câu hỏi 1: Giải thích sự khác biệt giữa `INNER JOIN` và `LEFT JOIN`. Nếu trong bài toán Marketing, anh vô tình viết `RIGHT JOIN` nhưng vẫn giữ nguyên thứ tự các bảng (`Customers RIGHT JOIN Orders`) thì chuyện gì sẽ xảy ra?
- **Trả lời:**
  - `INNER JOIN` chỉ trả về các dòng thỏa mãn điều kiện kết nối ở cả 2 bảng (phần giao thoa $A \cap B$). Các dòng không khớp ở cả 2 phía đều bị loại bỏ hoàn toàn.
  - `LEFT JOIN` (hoặc `LEFT OUTER JOIN`) giữ lại toàn bộ các dòng của bảng bên trái ($A$). Nếu bảng bên phải ($B$) không có bản ghi khớp, các cột của $B$ sẽ được điền giá trị `NULL`.
  - **Nếu giữ nguyên thứ tự và đổi sang `RIGHT JOIN`:** 
    `Customers c RIGHT JOIN Orders o ON c.customer_id = o.customer_id`. Lúc này bảng `Orders` trở thành bảng gốc. Kết quả truy vấn sẽ **bị đảo ngược hoàn toàn**: chỉ những khách hàng nào đã có đơn hàng trong `Orders` mới xuất hiện, còn khách hàng chưa từng mua như `Charlie` sẽ biến mất 100%. Báo cáo Marketing tiếp tục thất bại.

---

#### ❓ Câu hỏi 2: Trong câu lệnh lấy sản phẩm ế, tại sao điều kiện `WHERE o.order_id IS NULL` lại bắt buộc phải đi kèm với `LEFT JOIN`? Nếu anh đổi thành `INNER JOIN` thì mệnh đề `WHERE` đó có còn ý nghĩa không?
- **Trả lời:**
  - **Bản chất của Anti-Join:** Phép `LEFT JOIN` giữa `Products` và `Orders` sẽ ghép các dòng không có đơn hàng với các giá trị `NULL` ở phía `Orders`. Do đó, điều kiện `WHERE o.order_id IS NULL` đóng vai trò là "bộ lọc phủ định", giữ lại duy nhất những sản phẩm không có đơn hàng nào khớp.
  - **Nếu đổi thành `INNER JOIN`:** Phép `INNER JOIN` chỉ lấy các bản ghi có khóa ngoại trùng khớp tồn tại ở cả 2 bảng. Vì `o.order_id` là khóa chính của bảng `Orders` (luôn luôn `NOT NULL`), nên trong tập kết quả của `INNER JOIN` **không bao giờ tồn tại dòng nào có `o.order_id IS NULL`**. Mệnh đề `WHERE o.order_id IS NULL` khi đó sẽ triệt tiêu toàn bộ kết quả, trả về bảng rỗng ($0$ dòng).

---

#### ❓ Câu hỏi 3: `Cross Join` (Cartesian Product) là gì và khi nào một câu lệnh JOIN vô tình biến thành Cross Join gây treo hệ thống?
- **Trả lời:**
  - **Định nghĩa:** `Cross Join` (Tích Descartes) là phép kết hợp từng dòng của bảng thứ nhất với tất cả các dòng của bảng thứ hai. Số dòng kết quả bằng tích số dòng của hai bảng: $N \times M$.
  - **Nguyên nhân vô tình gây Cross Join:**
    1. Quên viết mệnh đề liên kết `ON` (hoặc `WHERE` trong cú pháp cũ), ví dụ: `SELECT * FROM Customers, Orders;` hoặc `SELECT * FROM Customers JOIN Orders;` mà không có điều kiện so sánh khóa.
    2. Viết sai điều kiện kết nối thành hằng số luôn đúng: `ON 1 = 1` hoặc `ON c.customer_id = c.customer_id`.
  - **Hậu quả:** Nếu bảng `Customers` có 1.000.000 dòng và bảng `Orders` có 10.000.000 dòng, tích Descartes sẽ sinh ra $10.000.000.000.000$ (10 nghìn tỷ dòng), làm tràn bộ nhớ đệm (RAM / Buffer Pool), đầy ổ cứng tạm (Temp Table on Disk) và làm treo cứng MySQL Server ngay lập tức.
