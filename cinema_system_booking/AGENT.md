# Cinema System Booking - Quy tắc dự án & Kiến trúc

## 1. Công nghệ & Kiến trúc

- Dự án Flutter / Dart quản lý đặt vé xem phim.
- Kiến trúc phân lớp: thư mục `lib/` gồm các layer (domain, data, presentation...).
- Quản lý trạng thái: BLoC / Provider / Riverpod (ghi rõ loại bạn đang dùng).
- Backend: Firebase (Firestore, Auth).

## 2. Quy chuẩn Code (Coding Standards)

- Đặt tên file theo định dạng `snake_case.dart`.
- Tuân thủ file `analysis_options.yaml`.
- Mọi hàm xử lý bất đồng bộ (async) đều phải có try-catch xử lý lỗi.

## 3. Quy tắc hỗ trợ

- Không tự ý xóa code cũ trừ khi được yêu cầu.
- Giải thích code bằng tiếng Việt.
