# FaceLive AI — cài trên iPhone từ Windows

## Trạng thái build

GitHub Actions tự động tạo:

- `FaceLiveIOS-unsigned.ipa`
- `FaceLiveIOS-unsigned-app.zip`

IPA hiện là **unsigned IPA**. GitHub Actions có thể build ứng dụng iOS nhưng không thể tự ký ứng dụng bằng Apple account của người dùng.

## Cách dùng với Windows

Có thể dùng một công cụ sideload như **AltStore Classic** để ký lại IPA trên máy tính Windows rồi cài lên iPhone. AltStore Classic hỗ trợ sideload trên toàn thế giới và ứng dụng sideload bằng tài khoản miễn phí cần refresh định kỳ 7 ngày.

### Các bước

1. Tải artifact `FaceLiveIOS-unsigned` từ GitHub Actions của repository.
2. Giải nén và lấy `FaceLiveIOS-unsigned.ipa`.
3. Cài AltStore Classic/AltServer trên Windows theo hướng dẫn chính thức của AltStore.
4. Kết nối iPhone với Windows và hoàn tất thiết lập sideload theo AltStore.
5. Import `FaceLiveIOS-unsigned.ipa` vào AltStore.
6. Trên iPhone mở FaceLive AI và cấp quyền Camera/Ảnh.
7. Nhập API key Amigo AI trong app.
8. Chọn ảnh khuôn mặt mẫu.
9. Camera chuyển sang chế độ `512 LIVE • ON-DEVICE`.

## Lưu ý

- Không gửi Apple ID, mật khẩu hoặc mã xác minh cho repository hay cho người khác.
- API key chỉ nhập trực tiếp trong app; app hiện không lưu API key vào giao diện cấu hình lâu dài.
- Nếu AltStore báo lỗi ký, cần kiểm tra provisioning/signing trên chính máy Windows và phiên bản iOS đang dùng.
- Build hiện dùng iOS 16.0 làm deployment target.

## Kiến trúc live

App dùng `AmigoLiveCameraView(targetLatent:)`. SDK xử lý camera, face detection, CoreML inference và Metal rendering trên thiết bị; tài liệu SDK công bố live 512px và mục tiêu 30fps trên iPhone 12.
