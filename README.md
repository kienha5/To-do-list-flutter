# Ghi chú (todo_app)

Ứng dụng ghi chú viết bằng Flutter, cho phép tạo ghi chú có hẹn giờ, xem theo nhóm **All / Today / Upcoming**, tìm kiếm, nhận thông báo nhắc trước 10 phút và xóa nhiều ghi chú cùng lúc. Dữ liệu được lưu ngay trên thiết bị, không cần mạng hay tài khoản.

## Mục lục

1. [Tính năng](#1-tính-năng)
2. [Công nghệ sử dụng](#2-công-nghệ-sử-dụng)
3. [Cấu trúc thư mục](#3-cấu-trúc-thư-mục)
4. [Nguyên lý hoạt động](#4-nguyên-lý-hoạt-động)
5. [Cài đặt và chạy](#5-cài-đặt-và-chạy)
6. [Hướng dẫn sử dụng](#6-hướng-dẫn-sử-dụng)
7. [Cấu hình theo nền tảng](#7-cấu-hình-theo-nền-tảng)
8. [Lưu ý quan trọng](#8-lưu-ý-quan-trọng)
9. [Hạn chế và hướng phát triển](#10-hạn-chế-và-hướng-phát-triển)

---

## 1. Tính năng

| # | Yêu cầu | Cách ứng dụng đáp ứng |
|---|---------|------------------------|
| 1 | Tạo ghi chú, có thể chọn thời gian | Màn hình "Thêm ghi chú" với ô tiêu đề và bộ chọn ngày giờ (không bắt buộc) |
| 2 | Trang chính cho phép xem theo All / Today / Upcoming | Thanh chọn 3 nhóm ở đầu trang chính |
| 3 | Hiển thị danh sách theo từng nhóm | Danh sách tự lọc theo nhóm đang chọn, sắp xếp theo thời gian tăng dần |
| 4 | Tìm kiếm | Ô tìm kiếm theo tiêu đề, không phân biệt hoa thường, kết hợp được với nhóm đang chọn |
| 5 | Thông báo nhắc trước 10 phút | Dùng `flutter_local_notifications` để hẹn giờ thông báo (Android, iOS) |
| 6 | Đánh dấu hoàn thành và xóa khỏi danh sách | Tick chọn nhiều ghi chú, bấm nút **Xóa** ở dưới cùng, xác nhận trong hộp thoại |

## 2. Công nghệ sử dụng

- **Flutter** và **Dart** (Material 3)
- [`shared_preferences`](https://pub.dev/packages/shared_preferences): lưu danh sách ghi chú dưới dạng JSON
- [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications): hiển thị và hẹn giờ thông báo
- [`timezone`](https://pub.dev/packages/timezone): cung cấp thời điểm có múi giờ cho việc hẹn giờ thông báo

Quản lý trạng thái chỉ dùng `setState`, không cần thư viện bên ngoài vì ứng dụng nhỏ.

## 3. Cấu trúc thư mục

```
todo_app/
├── lib/
│   ├── main.dart                         # Điểm vào: khởi tạo thông báo, chạy app
│   ├── models/
│   │   └── todo.dart                     # Lớp Todo (id, tiêu đề, hạn) + chuyển đổi JSON
│   ├── logic/
│   │   └── todo_filter.dart              # Lọc, tìm kiếm, sắp xếp, định dạng ngày giờ
│   ├── services/
│   │   ├── todo_storage.dart             # Đọc/ghi danh sách ghi chú (shared_preferences)
│   │   └── notification_service.dart     # Hẹn giờ và hủy thông báo
│   └── screens/
│       ├── home_screen.dart              # Trang chính: danh sách, tìm kiếm, chọn và xóa
│       └── add_todo_screen.dart          # Trang thêm ghi chú
├── test/
│   └── widget_test.dart                  # Kiểm thử giao diện cơ bản
├── android/                              # Cấu hình Android (Gradle, AndroidManifest)
├── ios/                                  # Cấu hình iOS (AppDelegate)
├── web/                                  # Cấu hình web
└── pubspec.yaml                          # Khai báo thư viện
```

Ứng dụng được tách theo trách nhiệm:

- **models**: dữ liệu thuần, không biết gì về giao diện.
- **logic**: các hàm thuần (nhận vào danh sách, trả ra danh sách), dễ kiểm thử.
- **services**: giao tiếp với bên ngoài (bộ nhớ máy, hệ thống thông báo).
- **screens**: giao diện, gọi xuống các lớp ở trên.

Lưu ý: tên lớp trong code vẫn là `Todo`, `TodoFilter`, `TodoStorage`. Chữ "ghi chú" chỉ dùng cho phần hiển thị với người dùng.

## 4. Nguyên lý hoạt động

### 4.1. Luồng dữ liệu

```
 Người dùng thao tác
        │
        ▼
  HomeScreen (giữ danh sách _todos, nhóm đang chọn, từ khóa, các ô đã tick)
        │
        ├── lưu ──────────► TodoStorage ──► shared_preferences (chuỗi JSON, khóa "todos")
        │
        └── hẹn/hủy ──────► NotificationService ──► hệ thống thông báo của thiết bị
```

1. Khi mở app, `HomeScreen` gọi `TodoStorage.load()` để nạp danh sách đã lưu.
2. Mọi thay đổi (thêm, xóa) đều cập nhật danh sách trong bộ nhớ bằng `setState`, sau đó gọi `TodoStorage.save()` để ghi lại.
3. Khi thêm ghi chú có hạn, app gọi `scheduleReminder` để hẹn thông báo. Khi xóa ghi chú, app gọi `cancel` để hủy thông báo tương ứng.

### 4.2. Đối tượng ghi chú

Mỗi ghi chú gồm:

| Trường | Ý nghĩa |
|--------|---------|
| `id` | Số nguyên duy nhất (số giây từ mốc 1/1/1970 lúc tạo). Dùng làm khóa nhận diện và làm id thông báo |
| `title` | Tiêu đề |
| `dueAt` | Thời điểm đến hạn (có thể không có) |

Dữ liệu được lưu dạng chuỗi JSON, ngày giờ lưu theo chuẩn ISO 8601.

### 4.3. Quy tắc lọc

Hàm `applyFilter` trong `todo_filter.dart` quyết định hiển thị gì:

| Nhóm | Điều kiện |
|------|-----------|
| **All** | Tất cả ghi chú, kể cả ghi chú không có hạn hoặc đã quá hạn |
| **Today** | Ghi chú có hạn rơi vào **hôm nay** (kể cả giờ đã qua trong hôm nay) |
| **Upcoming** | Ghi chú có hạn từ **ngày mai** trở đi |

Từ khóa tìm kiếm được áp dụng cùng lúc với nhóm. Kết quả được sắp xếp theo hạn tăng dần, ghi chú không có hạn nằm cuối. Ghi chú đã quá hạn hiển thị mốc thời gian màu đỏ.

Ghi chú không có hạn chỉ xuất hiện ở **All**. Ghi chú quá hạn từ ngày trước cũng chỉ còn ở **All**.

### 4.4. Cơ chế thông báo

- Thời điểm nhắc = `hạn − 10 phút` (hằng số `reminderBefore` trong `notification_service.dart`).
- Nếu thời điểm nhắc đã qua (tức hạn còn chưa tới 10 phút lúc tạo), app **không hẹn** thông báo.
- Thông báo được hẹn bằng `zonedSchedule` với chế độ chính xác khi thiết bị ở trạng thái nghỉ, dùng id của ghi chú làm id thông báo.
- Khi xóa ghi chú, app hủy thông báo cùng id để tránh thông báo "ma".
- Múi giờ được đặt cố định là `Asia/Ho_Chi_Minh`.
- Thông báo đã hẹn được plugin hẹn lại sau khi thiết bị khởi động lại (Android, nhờ `RECEIVE_BOOT_COMPLETED`).

### 4.5. Chọn và xóa nhiều ghi chú

- Tick ô vuông (hoặc bấm vào cả dòng) để chọn. Id các ghi chú được chọn nằm trong tập `_selected`.
- Khi có ít nhất một ô được chọn: nút **Xóa N ghi chú** hiện ở dưới cùng, nút `+` tạm ẩn.
- Bấm nút xóa sẽ mở hộp thoại xác nhận:
  - **Xóa**: xóa các ghi chú đã chọn, lưu lại và hủy thông báo tương ứng.
  - **Hủy**: đóng hộp thoại, giữ nguyên các ô đã tick.
- Các ô đã tick được giữ khi bạn đổi nhóm hoặc gõ tìm kiếm, nên số lượng trong nút xóa có thể bao gồm cả ghi chú đang bị ẩn bởi bộ lọc.

## 5. Cài đặt và chạy

### Yêu cầu

- Flutter SDK 3.38.1 trở lên (yêu cầu tối thiểu của `flutter_local_notifications`)
- Chạy `flutter doctor` để kiểm tra môi trường
- Để chạy Android: Android SDK (có thể cài qua command-line tools) và một máy ảo hoặc điện thoại thật
- Để chạy iOS: máy Mac có Xcode (xem mục [Lưu ý quan trọng](#8-lưu-ý-quan-trọng))

### Các bước

```bash
# 1. Cài thư viện
flutter pub get

# 2. Xem danh sách thiết bị
flutter devices

# 3. Chạy
flutter run                 # thiết bị đang chọn
flutter run -d chrome       # chạy trên web (Chrome)
```

Trong VS Code, chọn thiết bị ở thanh trạng thái góc phải dưới và nhấn **F5**.

Lần build Android đầu tiên có thể mất vài phút vì Gradle phải tải các thành phần cần thiết.

### Đóng gói

```bash
flutter build apk            # Android (file APK)
flutter build web            # Web (kết quả trong build/web)
```

## 6. Hướng dẫn sử dụng

1. **Thêm ghi chú**: bấm nút `+` ở góc dưới bên phải, nhập tiêu đề. Nếu muốn nhắc việc, bấm "Chọn ngày giờ", chọn ngày rồi chọn giờ. Bấm biểu tượng `×` cạnh ngày giờ để bỏ hạn. Bấm **Lưu**.
2. **Xem theo nhóm**: bấm **All**, **Today** hoặc **Upcoming** ở đầu trang.
3. **Tìm kiếm**: gõ vào ô "Tìm kiếm ghi chú". Danh sách lọc ngay khi gõ.
4. **Nhận nhắc việc**: cho phép quyền thông báo khi app hỏi lần đầu. Thông báo "Sắp đến hạn" sẽ hiện trước giờ hẹn 10 phút.
5. **Xóa ghi chú**: tick các ghi chú muốn xóa, bấm nút **Xóa N ghi chú** ở dưới cùng, rồi chọn **Xóa** trong hộp thoại xác nhận (hoặc **Hủy** để quay lại).

## 7. Cấu hình theo nền tảng

### Android

- `android/app/build.gradle.kts`: bật `isCoreLibraryDesugaring`, đặt Java 17 và thêm phụ thuộc `desugar_jdk_libs`. Android Gradle Plugin cần từ 8.11.1 trở lên (khai báo trong `android/settings.gradle.kts`).
- `android/app/src/main/AndroidManifest.xml`:
  - Quyền `RECEIVE_BOOT_COMPLETED` và `USE_EXACT_ALARM`.
  - Hai `receiver` của plugin: `ScheduledNotificationReceiver` và `ScheduledNotificationBootReceiver`.

### iOS

- `ios/Runner/AppDelegate.swift`: thêm `import UserNotifications` và, trong `didFinishLaunchingWithOptions`, đặt trước dòng `return`:

  ```swift
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
  ```

- Phía Dart, `InitializationSettings` và `NotificationDetails` đã có phần `iOS` (`DarwinInitializationSettings`, `DarwinNotificationDetails`). Thiếu phần này app sẽ báo lỗi khi khởi động trên iOS.

### Web

- Thêm bằng `flutter create --platforms=web .`.
- Thông báo bị tắt trên web bằng cách kiểm tra `kIsWeb` trong `NotificationService`.

## 8. Lưu ý quan trọng

### Về thông báo

- **Web không hỗ trợ nhắc việc hẹn giờ.** Trình duyệt không cho hẹn thông báo, nên trên web các chức năng khác vẫn chạy nhưng sẽ không có thông báo nhắc.
- **Android 13 trở lên** cần người dùng cho phép thông báo. Nếu từ chối, ứng dụng sẽ không hiển thị được thông báo. Hãy bật lại trong phần Cài đặt của máy.
- **Quyền `USE_EXACT_ALARM`** không cần hỏi người dùng nhưng được Google Play kiểm duyệt riêng. Với bài tập hoặc chạy cá nhân thì không sao, còn nếu phát hành lên cửa hàng thì cần xem lại chính sách.
- **Một số hãng máy Android** (như Xiaomi, Huawei) hạn chế ứng dụng chạy nền nên thông báo hẹn giờ có thể không hiện. Đây là giới hạn của hệ điều hành, không phải lỗi ứng dụng.
- **iOS chỉ giữ tối đa 64 thông báo đang chờ** cùng lúc.
- Ghi chú có hạn còn **chưa tới 10 phút** lúc tạo sẽ không có thông báo nhắc.
- Múi giờ đang đặt cố định là Việt Nam. Dùng ở múi giờ khác thì cần đổi trong `NotificationService.init()`.

### Về dữ liệu

- Dữ liệu chỉ lưu **cục bộ trên thiết bị** (hoặc trong trình duyệt khi chạy web). Gỡ cài đặt ứng dụng hoặc xóa dữ liệu trình duyệt sẽ mất toàn bộ ghi chú.
- Trên web, dữ liệu gắn với địa chỉ trang (gồm cả số cổng). Chạy `flutter run -d chrome` thường dùng cổng ngẫu nhiên và hồ sơ Chrome tạm nên dữ liệu có thể mất giữa các lần chạy. Để kiểm tra việc lưu dữ liệu, chạy với cổng cố định rồi mở bằng trình duyệt của bạn:

  ```bash
  flutter run -d web-server --web-port 5000
  ```

- **Xóa là vĩnh viễn**, không có thùng rác hay hoàn tác. Hộp thoại xác nhận là lớp bảo vệ duy nhất.
- `id` được tạo từ số giây hiện tại. Hai ghi chú tạo trong cùng một giây sẽ trùng id, điều này trên thực tế gần như không xảy ra khi thêm tay.

### Về phát triển

- Sau khi sửa file cấu hình gốc (Gradle, AndroidManifest, AppDelegate) hoặc `main()`, cần **dừng và chạy lại** app, hot reload không áp dụng các thay đổi này.
- Khi thử thông báo, đừng đợi 10 phút thật: tạm đổi `reminderBefore` thành `Duration(minutes: 1)`, tạo ghi chú có hạn sau 2 đến 3 phút, rồi đưa app về nền. Thử xong nhớ đổi lại thành 10 phút.
- Mỗi lần chạy `flutter create --platforms=... .` để thêm nền tảng, Flutter có thể tạo lại `test/widget_test.dart` nếu file không còn tồn tại. Giữ lại file test đã viết để tránh việc này.
- API của `flutter_local_notifications` thay đổi giữa các phiên bản lớn. Khi nâng phiên bản, đọc lại hướng dẫn cài đặt của plugin.

## 9. Hạn chế và hướng phát triển

- Chưa có chức năng sửa ghi chú, đặt mức ưu tiên, hay thùng rác để khôi phục.
- Chưa có nhắc việc trên web. Có thể dùng bộ đếm giờ trong app để hiện thông báo khi tab đang mở, nhưng sẽ không hoạt động khi đóng tab.
- Phần iOS đã được cấu hình nhưng **chưa được chạy thử trên thiết bị hoặc trình giả lập** do thiếu máy Mac. Có thể dùng dịch vụ CI trên macOS (GitHub Actions, Codemagic) để xác nhận việc biên dịch bằng `flutter build ios --no-codesign`.
- Khi dữ liệu lớn hơn, nên chuyển từ `shared_preferences` sang cơ sở dữ liệu như SQLite (`sqflite`, `drift`) hoặc Hive.
- Có thể tách logic trạng thái ra khỏi `HomeScreen` bằng Provider, Riverpod hoặc Bloc để dễ kiểm thử và mở rộng.