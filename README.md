# TCL 65C6K (Android 14) Debloat & Material 3 Expressive Launcher

Dự án tối ưu hóa, debloat và tùy biến toàn diện giao diện cho **TCL 65C6K Google TV (Android 14)** qua kết nối không dây ADB:
- Loại bỏ toàn bộ quảng cáo, tracking, telemetry và bloatware của TCL & Google TV.
- Thay thế Google TV LauncherX bằng **Material 3 Expressive Launcher** (km-launcher dựa trên freeTV & CleanYourTV).
- Tích hợp font chữ **Google Sans Flex TV** (hỗ trợ 100% tiếng Việt có dấu).
- **Hệ thống Widgets thông minh**:
  - Thời tiết (Open-Meteo) và Chất lượng không khí (AQI) tự động theo vị trí IP.
  - Đồng hồ hiển thị thời gian, lời chào buổi sáng/trưa/chiều/tối theo tên chủ sở hữu.
  - Lịch âm Việt Nam: Hiển thị năm Canh/Tân/Nhâm/Quý/Bính..., ngày/tháng âm lịch và đếm ngược tới các ngày lễ (Tết, Giáng sinh).
  - Đồng hồ đo tài nguyên hệ thống (RAM, Bộ nhớ trong, CPU).
- **Hiệu ứng chuyển động Material 3 Expressive**:
  - Hình nền chuyển động hữu cơ M3 (Expressive shapes: Cookie & Clover) tự xoay nhẹ, đổi hình dạng và tạo hiệu ứng chiều sâu parallax.
  - Thẻ ứng dụng đang chọn (Focus) phóng to mượt mà, bao quanh bởi viền bo tròn màu chủ đạo (M3 Primary indicator).
- Gán toàn bộ các phím tắt cứng trên Remote TCL RC813A (Netflix, YouTube, Web, TCL Channel, VTV Go, Settings).
- Tuyệt đối an toàn: Sử dụng `pm disable-user --user 0`, không root, không sửa phân vùng hệ thống, có script hoàn nguyên 1-click `restore.sh`.

---

## 📺 Thông số phần cứng thiết bị kiểm thử
- **Model**: TCL 65C6K (4K QLED Google TV)
- **Bo mạch (Board)**: G08 (MediaTek)
- **Firmware build**: `UTT2.250416.001`
- **Hệ điều hành**: Android 14 (API 34)
- **Điều khiển (Remote)**: TCL RC813A
- **Thiết bị âm thanh ngoại vi**: Soundbar qua kết nối eARC / HDMI-CEC

---

## 📁 Cấu trúc thư mục kho lưu trữ
```
tcl-c6k/
├── README.md                  # Hướng dẫn chi tiết dự án
├── ORIGINAL_SPEC.md           # Đặc tả yêu cầu kỹ thuật & quy tắc an toàn ban đầu
├── config.json                # Cấu hình theme M3 Expressive, dock & phím remote
├── disabled.txt               # Danh sách 25 package bloatware đã tắt an toàn
├── settings-changes.txt       # Nhật ký các cài đặt hệ thống đã thay đổi
├── lib.zsh                    # Thư viện hàm shell zsh (dis, restore_all, home_new, ...)
├── restore.sh                 # Kịch bản cứu hộ độc lập 1-click về trạng thái xuất xưởng
├── apk/
│   └── CleanYourTV-TCL-C6K.apk# File APK đã compile sẵn đầy đủ tùy biến cho TCL 65C6K
├── backup/                    # Sao lưu toàn diện trạng thái xuất xưởng trước khi can thiệp
│   ├── packages-all-f.txt     # Danh sách toàn bộ package + đường dẫn APK gốc
│   ├── packages-enabled.txt   # Danh sách package đang bật lúc ban đầu
│   ├── packages-disabled.txt  # Danh sách package đã tắt từ nhà máy
│   ├── packages-system.txt    # Danh sách package hệ thống
│   ├── packages-thirdparty.txt# Danh sách package người dùng cài
│   ├── settings-global.txt    # Cài đặt global gốc
│   ├── settings-secure.txt    # Cài đặt secure gốc
│   ├── settings-system.txt    # Cài đặt system gốc
│   ├── home.txt               # Default launcher ban đầu
│   └── wifi-cname.txt         # Tên tiến trình quản lý Wi-Fi (android.uid.system:1000)
└── cleanyourtv/               # Toàn bộ mã nguồn launcher đã tích hợp M3 Expressive
    ├── launcher/              # Source code Android Studio / Gradle
    ├── examples/              # Cấu hình mẫu cho các dòng TV
    └── tools/                 # Bộ công cụ build & cấu hình theme
```

---

## 🎮 Ánh xạ phím cứng Remote (TCL RC813A)

Tất cả các phím bấm nhanh trên remote đều được can thiệp trực tiếp qua launcher (`InputKeyService` & `HomeKeyService`), không cần cài đặt thêm ứng dụng thứ 3:

| Nút cứng trên Remote | Keycode / Scan code | Hành động / Ứng dụng khởi chạy |
| :--- | :--- | :--- |
| **Home** | `KEYCODE_HOME` (3) | Trở về thẳng màn hình chính launcher |
| **Netflix** | `4062`, `191`, `scan:242` | Mở ứng dụng **Netflix** (`com.netflix.ninja`) |
| **YouTube** | `190`, `4065` | Mở ứng dụng **YouTube** (`com.google.android.youtube.tv`) |
| **Web** | `4159` (`usage:0x000c029c`) | Mở trình duyệt **Cốc Cốc TV** (`com.coccoc.trinhduyet_tv`) |
| **TCL Channel** | `4020` (`usage:0x000c0053`) | Mở ứng dụng xem phim **Phim 4K** (`com.oxootv.spagreen`) |
| **VTV Go** | `4168` (`usage:0x000c0165`) | Mở **VTV Go** (`vn.vtv.vtvgotv`) *(tự động mở Google Play Store nếu chưa cài)* |
| **Cài đặt (Bánh răng)**| `83` (`KEYCODE_SETTINGS`) | Mở bảng **Cài đặt hệ thống TV TCL** |

---

## 🎨 Tùy biến Material 3 Expressive

### 1. Bố cục ứng dụng (Grid & Dock)
* **Hàng Dock (Hàng 1)**: Netflix, YouTube, FPT Play, Apple TV.
* **Hàng Lưới (Hàng 2)**: Phim 4K, Kodi, YouTube Music, Cốc Cốc TV.

### 2. Bảng Widgets thông minh
* Tự động lấy thông tin thời tiết & chất lượng không khí theo định vị IP.
* Lịch âm tiếng Việt chuẩn xác.
* Đo RAM và bộ nhớ khả dụng theo thời gian thực.

### 3. Font chữ Google Sans Flex TV
* Tích hợp font biến thiên chính thức `google_sans_flex.ttf`.
* Đảm bảo hiển thị đầy đủ 100% các ký tự dấu tiếng Việt sắc nét.

---

## 🛡️ Danh sách 25 Package đã vô hiệu hóa (Debloat List)

Toàn bộ các gói bên dưới được tắt bằng lệnh `pm disable-user --user 0 <package>`:

### Nhóm A: Thu thập dữ liệu & Telemetry
1. `com.tcl.ttvs` - TCL TV Service (telemetry nền)
2. `com.tcl.logkit` - Bộ ghi log chẩn đoán của TCL
3. `com.tcl.usercenter` - Trung tâm tài khoản TCL
4. `com.google.android.feedback` - Thu thập lỗi của Google
5. `com.android.tv.feedbackconsent` - Xin quyền phản hồi TV

### Nhóm B: Quảng cáo, Đề xuất & Kênh đối tác
6. `com.tcl.channelplus` - Kênh nội dung TCL Channel Plus
7. `com.tcl.tv.tclhome_passive` - TCL Home Passive
8. `com.tcl.partnercustomizer` - Tùy biến đối tác quảng cáo
9. `com.tcl.interactive` - Dịch vụ tương tác quảng cáo
10. `com.tcl.messagebox` - Thông báo quảng bá TCL
11. `com.tcl.waterfall.overseas` - Giao diện tin tức/video dạng thác nước
12. `android.autoinstalls.config.google.gtvpai` - Cấu hình tự động cài app rác lúc kích hoạt
13. `com.google.android.partnersetup` - Thiết lập đối tác Google

### Nhóm C: Chế độ trưng bày & Khách sạn (Retail/Demo)
14. `com.tcl.exhibit` - Chế độ trưng bày siêu thị
15. `com.tcl.esticker` - Banner sticker điện tử dán màn hình
16. `com.tcl.hotelmenu` - Menu khách sạn

### Nhóm D: Ứng dụng rác độc lập (Bloatware)
17. `com.tcl.ocean.instructions` - Hướng dẫn sử dụng TCL
18. `com.tcl.repairguide` - Cẩm nang sửa chữa TCL
19. `com.tcl.smartalexa` - Tích hợp Alexa của TCL
20. `com.tcl.guard` - Trình dọn rác TCL Guard
21. `com.tcl.ui_mediaCenter` - Trình đa phương tiện mặc định TCL
22. `com.tcl.gallery` - Bộ sưu tập ảnh TCL
23. `com.google.android.play.games` - Google Play Games TV

### Nhóm E: App rác mở rộng
24. `com.tcl.magiconnectfree` - Kết nối MagiConnect

### Thay thế Launcher gốc
25. `com.google.android.apps.tv.launcherx` - Google TV Launcher gốc (nhiều banner quảng cáo)

---

## 🔒 Các tính năng cốt lõi được bảo toàn nguyên vẹn
* **Tìm kiếm giọng nói**: Nút Mic Remote & Google Assistant (`com.google.android.katniss`).
* **Chromecast**: Cast video/hình ảnh từ điện thoại lên TV (`com.google.android.apps.mediashell`).
* **AirPlay & Miracast**: Kết nối từ iPhone/iPad/Android không dây (`com.tcl.airplay2`, `com.mediatek.*`, `com.tcl.miracast`).
* **Đầu vào HDMI & Game Bar**: Chuyển cổng HDMI, Game Master Mode (`com.tcl.tv`, `com.tcl.tvinput`).
* **Soundbar eARC / CEC**: Điều khiển âm lượng và cập nhật thiết bị ngoại vi (`com.tcl.UpdatePeripheral`, `system_audio_control = 1`).

---

## 🚀 Hướng dẫn cài đặt nhanh

### 1. Kết nối TV qua ADB
Bật **Tùy chọn nhà phát triển** trên TV và bật **Gỡ lỗi không dây (Wireless debugging)**:
```bash
adb connect <IP_CỦA_TV>:5555
```

### 2. Cài đặt APK tùy biến
```bash
adb install -r apk/CleanYourTV-TCL-C6K.apk
```

### 3. Đẩy cấu hình theme & thiết lập quyền
```bash
adb push config.json /sdcard/Android/data/com.gathin.tvhome/files/config.json
adb shell pm grant com.gathin.tvhome android.permission.ACCESS_FINE_LOCATION
adb shell pm grant com.gathin.tvhome android.permission.WRITE_SECURE_SETTINGS
```

---

## 🆘 Khôi phục cài đặt gốc 1-Click (Restore)

Nếu bạn muốn trở lại hoàn toàn giao diện Google TV mặc định và bật lại tất cả ứng dụng như lúc xuất xưởng:
```bash
bash restore.sh <IP_CỦA_TV>
```
