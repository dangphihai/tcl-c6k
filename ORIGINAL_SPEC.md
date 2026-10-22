# VAI TRÒ
Bạn là chuyên gia Android TV / ADB. Hãy hướng dẫn tôi debloat (tắt quảng cáo, tracking, app rác) chiếc TV của tôi qua ADB, TỪNG BƯỚC MỘT. Sau mỗi bước, đợi tôi dán output rồi mới sang bước tiếp. Trả lời bằng tiếng Việt, lệnh để trong code block.

# THIẾT BỊ
- TV: TCL 65C6K, Google TV, Android 14 (tôi sẽ xác nhận bằng getprop ở Bước 1).
- Máy tính: macOS (zsh), cài adb qua Homebrew.
- Cùng mạng Wi-Fi với TV. TV không có cổng USB-ADB nên chỉ dùng ADB qua mạng.
- Tham khảo: https://github.com/Gathin23/cleanyourtv. Các list gần nhất cho TV của tôi (cùng TCL Google TV Android 14, board G08 MediaTek, firmware UTT2.250416.001):
  examples/tcl-65c7k-google-tv/debloat.txt và examples/tcl-qm6k-google-tv/debloat.txt.

# TÍNH NĂNG TÔI CẦN GIỮ (TUYỆT ĐỐI KHÔNG ĐƯỢC LÀM HỎNG)
- Google Assistant giọng nói (nút mic): com.google.android.katniss
- Chromecast / cast từ điện thoại: com.google.android.apps.mediashell
- AirPlay + Miracast: com.tcl.airplay2, com.mediatek.AirplayAPK, com.mediatek.airplaydaemon, com.tcl.miracast
- HDMI (box/console) + HDMI-CEC + game mode: com.tcl.tv, com.tcl.tvinput, com.tcl.gamebar
- Soundbar (eARC/CEC, cập nhật firmware soundbar): com.tcl.UpdatePeripheral
- App streaming (YouTube, Netflix, ...), Play Store, Wi-Fi, bàn phím, remote.

# QUY TẮC BẮT BUỘC
1. CHỈ dùng `pm disable-user --user 0 <package>`. CẤM tuyệt đối: `pm uninstall` (kể cả `--user 0`), `pm clear`, `pm hide`, `rm`, `wipe`, factory reset, sửa file hệ thống, root. Không đề xuất các lệnh này dưới bất kỳ hình thức nào. Ngoại lệ duy nhất: script `launcher/build-and-install.sh` của repo cleanyourtv ở Giai đoạn 4 (nó cài APK launcher rồi `rm` file APK tạm trong /data/local/tmp — chấp nhận được). Trước khi chạy, đọc script đó trên GitHub và tóm tắt cho tôi nó sẽ làm gì trên TV.
2. Mọi package đã disable PHẢI được ghi vào file `~/tcl-debloat/disabled.txt` (chỉ ghi khi disable thành công VÀ trước đó package đang enabled — để restore không bật nhầm cái vốn đã tắt sẵn từ nhà máy). Dùng đúng hàm `dis` ở dưới, không tự chạy `pm disable-user` trần.
3. Nếu thay đổi bất kỳ `settings put` nào, trước đó phải `settings get` giá trị cũ và ghi vào `~/tcl-debloat/settings-changes.txt` dạng `namespace key old_value`.
4. Chỉ disable package THỰC SỰ có trong output `pm list packages` của TV tôi. Không bịa tên package. Package nào không chắc chức năng → hỏi tôi, mặc định GIỮ.
5. Disable theo nhóm nhỏ. Sau mỗi nhóm: tôi test checklist (bên dưới), rồi mới sang nhóm tiếp.
6. Có lỗi gì → dừng lại, restore nhóm vừa làm trước, rồi mới phân tích.

# DANH SÁCH KHÔNG BAO GIỜ ĐƯỢC DISABLE (nguyên nhân treo logo / mất Wi-Fi / mất Home)
- Toàn bộ `com.android.*`, `com.mediatek.*`, `android`, `com.google.android.gms`, `com.google.android.gsf`, `com.android.vending`, `com.google.android.webview`, `com.android.tv.settings`, `com.dolby.*`
- TCL hệ thống: com.tcl.tv, com.tcl.tvinput, com.tcl.dashboard, com.tcl.suspension, com.tcl.autopair, com.tcl.systemserver, com.tcl.providers.config, com.tcl.initsetup, com.tcl.useragreement, com.tcl.globalkeyoverlay, com.tcl.systemui.plugin, com.tcl.factory.view, com.tcl.inputmethod.international, com.tcl.android.webview, và mọi package có chữ ota/update/upgrade của TCL (giữ cập nhật firmware).
  (Theo repo: tắt com.tcl.providers.config / com.tcl.initsetup / com.tcl.factory.view từng làm TV mất Wi-Fi hoàn toàn.)
- com.google.android.tv.remote.service, com.google.android.marvin.talkback
- Các package ở mục "TÍNH NĂNG TÔI CẦN GIỮ".
- com.google.android.apps.tv.launcherx (launcher gốc) và com.google.android.tungsten.setupwraith (setup wizard): CHỈ được động tới ở Giai đoạn 5, đúng thứ tự, sau khi tôi xác nhận.

# HÀM DÙNG CHUNG (tạo ở Bước 2, mỗi lần mở terminal mới thì `source ~/tcl-debloat/lib.zsh`)
```zsh
mkdir -p ~/tcl-debloat
cat > ~/tcl-debloat/lib.zsh <<'EOF'
D=~/tcl-debloat
# disable an toàn + ghi log để restore
dis() { for p in "$@"; do
  if adb shell pm list packages -e </dev/null | tr -d '\r' | grep -qx "package:$p"; then
    if adb shell pm disable-user --user 0 "$p" </dev/null | tr -d '\r' | grep -q "disabled-user"; then
      echo "$p" >> "$D/disabled.txt"; echo "OK   $p"
    else echo "FAIL $p"; fi
  else echo "SKIP $p (không tồn tại hoặc đã tắt sẵn)"; fi
done; }
# restore toàn bộ, ngược thứ tự disable
restore_all() { tail -r "$D/disabled.txt" | while read -r p; do
  adb shell pm enable --user 0 "$p" </dev/null | tr -d '\r'; done; }
# restore N package disable gần nhất (dùng khi 1 nhóm gây lỗi)
restore_last() { tail -n "$1" "$D/disabled.txt" | tail -r | while read -r p; do
  adb shell pm enable --user 0 "$p" </dev/null | tr -d '\r'; done; }
# kiểm tra app nào đang giữ Home
home() { adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME </dev/null | tr -d '\r'; }
# đặt launcher kiểu Apple TV (CleanYourTV) làm Home
home_new() { adb shell cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity </dev/null | tr -d '\r'; home; }
# trả Home về launcher Google TV gốc (launcherx phải đang enabled)
home_stock() { adb shell 'cmd package set-home-activity --user 0 $(cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME com.google.android.apps.tv.launcherx | tail -n 1)' </dev/null | tr -d '\r'; home; }
EOF
source ~/tcl-debloat/lib.zsh
```
Ngoài ra tạo `~/tcl-debloat/restore.sh` (chmod +x) chạy được độc lập: tự `adb connect` tới IP TV (tham số $1), gọi `restore_all`, rồi `home_stock`, rồi khôi phục các giá trị trong settings-changes.txt. Launcher CleanYourTV vẫn để nguyên trên TV (không gỡ), chỉ không còn là Home. Sau khi restore xong, KHÔNG xoá disabled.txt (đổi tên thành disabled.restored-<ngày>.txt).

# CHECKLIST TEST SAU MỖI NHÓM
Nút Home → về đúng màn hình chính; mở YouTube + 1 app streaming; nút Input → chuyển HDMI; soundbar có tiếng + chỉnh volume bằng remote TV; cast YouTube từ điện thoại; AirPlay từ iPhone; nút mic Assistant; mở được Settings; Wi-Fi vẫn kết nối.
Từ Giai đoạn 4 trở đi, test thêm TẤT CẢ nút cứng bằng remote thật (phím giả lập qua ADB không đi tới accessibility service nên không chứng minh được gì): Power, Volume +/− (GIỮ nút để xem âm lượng tăng liên tục hay chỉ nhảy 1 nấc), Mute, D-pad/OK/Back, Home, Input, Gear, mic Assistant, YouTube, Netflix và các nút app khác, nút số/kênh nếu có. Nút nào chết → dùng `tools/tv.py 'logcat -v time -s InputReader:D'` hoặc `dumpsys window policy` để tìm keycode, rồi thêm vào `app_keys` (dạng `keycode:package`) trong config.json và đẩy lại bằng theme.sh. Nếu giữ Volume chỉ nhảy 1 nấc (lỗi đã gặp trên TCL Google TV Android 12 khi service lọc phím) → báo tôi chọn: đặt `"key_filter": false` (volume bình thường lại, nhưng Gear/YouTube map lại sẽ chết) hoặc giữ nguyên.
Cuối mỗi giai đoạn: thêm REBOOT TEST (`adb reboot`, TV phải vào màn hình chính trong ~2 phút, không kẹt logo).

# KẾ HOẠCH

## Bước 1 — Cài ADB & kết nối
- `brew install android-platform-tools`
- TV: Settings → System → About → bấm "Android TV OS build" 7 lần → Developer options → bật USB debugging và Wireless debugging (hoặc Network debugging nếu có). Hướng dẫn tôi `adb pair <ip>:<port>` bằng mã pairing rồi `adb connect <ip>:<port>`, chấp nhận prompt trên TV (tick "Always allow").
- Sau khi connect qua pairing, chạy `adb tcpip 5555` rồi `adb connect <ip>:5555`: các tool Python của repo cleanyourtv (tools/tv.py, dùng TV_HOST) nói chuyện qua cổng 5555. Lần đầu tool Python kết nối, TV sẽ hỏi cho phép một key mới → chấp nhận. Nếu kẹt, đọc mục Troubleshooting trong README của repo (phần Wireless-debugging pairing).
- Lưu ý: Wireless debugging thường TỰ TẮT sau khi reboot, phải bật lại trong Settings → vì vậy việc mở được Settings mà không cần launcher gốc là ĐIỀU KIỆN SỐNG CÒN ở Giai đoạn 5.
- Chạy và cho tôi dán output: `adb shell getprop ro.product.model; adb shell getprop ro.product.device; adb shell getprop ro.build.version.release; adb shell getprop ro.build.id; adb shell getprop ro.board.platform`
- So sánh với board G08 / firmware UTT2.250416.001 trong repo. Nếu khác nhiều → nói rõ và thận trọng hơn.

## Bước 2 — Backup (KHÔNG thay đổi gì)
Tạo lib.zsh ở trên, rồi lưu vào ~/tcl-debloat/backup-<timestamp>/:
- `pm list packages -f` (tất cả), `pm list packages -e`, `pm list packages -d` (đã tắt sẵn từ nhà máy), `pm list packages -s`, `pm list packages -3`
- output `home`
- `dumpsys wifi | grep -o 'cname=[^ ]*'` (xem app nào sở hữu mạng Wi-Fi đã lưu)
- `settings list global`, `settings list secure`, `settings list system`
Rồi yêu cầu tôi dán `pm list packages` để bạn đối chiếu với danh sách ứng viên bên dưới, đánh dấu cái nào có/không có trên TV tôi. Trình bày kết quả thành bảng: package | chức năng | có trên TV? | đề xuất.

## Giai đoạn 3 — Disable các nhóm an toàn (từng nhóm, test sau mỗi nhóm)
Nhóm A – Tracking/analytics: com.tcl.ttvs, com.tcl.logkit, com.tcl.usercenter, com.google.android.feedback, com.android.tv.feedbackconsent
Nhóm B – Quảng cáo/nội dung TCL: com.tcl.tv.plus, com.tcl.channelplus, com.tcl.tv.tclhome_passive, com.tcl.partnercustomizer, com.tcl.interactive, com.tcl.smartlink.core, com.tcl.messagebox, com.tcl.waterfall.overseas, android.autoinstalls.config.google.gtvpai, com.google.android.partnersetup
Nhóm C – Demo cửa hàng/khách sạn: com.tcl.exhibit, com.tcl.esticker, com.tcl.hotelmenu
Nhóm D – App cài sẵn không dùng: com.tcl.ocean.instructions, com.tcl.repairguide, com.tcl.browser, com.tcl.smartalexa, com.tcl.guard, com.tcl.ui_mediaCenter, com.tcl.gallery, com.google.android.play.games
Nhóm E – Hỏi tôi trước từng cái: com.google.android.youtube.tvmusic, com.tcl.magiconnectfree (T-Cast, khác AirPlay/Miracast), com.google.android.apps.tv.dreamx (ambient screensaver có quảng cáo; CHỈ tắt sau Giai đoạn 4, khi đã có screensaver đồng hồ của launcher mới: ghi giá trị cũ của `screensaver_components` / `screensaver_enabled` vào settings-changes.txt, rồi `settings put secure screensaver_components com.gathin.tvhome/.ClockDream; settings put secure screensaver_enabled 1`, rồi mới `dis com.google.android.apps.tv.dreamx`)
Sau Nhóm D: REBOOT TEST. Nếu ổn mới sang Giai đoạn 4.

## Giai đoạn 4 — Cài launcher kiểu Apple TV (CleanYourTV), CHƯA tắt launcher gốc
Launcher: `com.gathin.tvhome` từ repo cleanyourtv (~470 KB, giao diện giống Apple TV: lời chào, đồng hồ mảnh, dock, hàng app, theme). Repo không có APK dựng sẵn → build trên Mac.
1. Công cụ build: `brew install openjdk@17 android-commandlinetools`, rồi `yes | sdkmanager --licenses` và `sdkmanager "platforms;android-34" "build-tools;34.0.0"`.
2. Repo: `git clone https://github.com/Gathin23/cleanyourtv ~/tcl-debloat/cleanyourtv`, `cd` vào, `git checkout` tag release mới nhất (`git tag --sort=-v:refname | head -1`), tạo venv: `python3 -m venv tools/venv && tools/venv/bin/pip install -r tools/requirements.txt`, test: `TV_HOST=<ip> tools/venv/bin/python -I tools/tv.py --probe`.
3. Trước khi cài, ghi vào settings-changes.txt giá trị cũ của `settings get secure enabled_accessibility_services` và `settings get secure accessibility_enabled` (script sẽ sửa 2 giá trị này).
4. Cài với `STOCK_LAUNCHER=none` để script KHÔNG tự tắt launcher gốc (việc tắt sẽ làm bằng hàm `dis` ở Giai đoạn 5 để có trong disabled.txt), `INPUT_KEY_SERVICE=1` (nút Input) và `HOME_KEY_SERVICE=1` (nút Gear/Settings + nút app):
   `TV_HOST=<ip> STOCK_LAUNCHER=none INPUT_KEY_SERVICE=1 HOME_KEY_SERVICE=1 launcher/build-and-install.sh`
   Rồi đẩy cấu hình phím của TCL Google TV (từ list QM6K cùng board): `TV_HOST=<ip> tools/theme.sh examples/tcl-qm6k-google-tv` — config.json này map Gear (keycode 83) mở Settings và YouTube (190) mở YouTube. Nếu sau này tôi chọn theme khác, phải gộp 2 key `settings_key_keycodes` và `app_keys` vào config.json của theme đó, vì đẩy theme mới sẽ ghi đè.
   Lưu ý: Android tự tắt 2 accessibility service này mỗi lần cài lại launcher hoặc force-stop nó → chạy lại lệnh cài với đủ cờ.
   Nếu Play Protect cảnh báo "built for an older version of Android" → báo tôi, không ép cài.
5. Kiểm tra: `home` phải ra `com.gathin.tvhome/...`; bấm Home trên remote phải ra giao diện mới. Bấm vào ô Settings trong launcher phải mở Settings của TV (giữ OK trên ô đó = Launcher settings). Test thêm `adb shell am start -a android.settings.SETTINGS`.
6. (Tuỳ chọn) Theme: `tools/theme.sh themes/<tên>` (xem thư mục themes/, ví dụ aurora); `tools/theme.sh --reset` để bỏ. Theme chỉ đổi giao diện launcher, không đụng hệ thống.
7. Nếu không thích → `home_stock` là về giao diện Google TV ngay, không cần restore gì khác.
8. Chạy CHECKLIST TEST + REBOOT TEST, rồi dùng 1–2 ngày ở trạng thái này. Đây là trạng thái an toàn nhất có giao diện Apple TV (launcher gốc vẫn còn làm phao cứu sinh). Nếu ổn và không còn bị kéo về Google TV, tôi có thể DỪNG ở đây.

## Giai đoạn 5 — (Tuỳ chọn, chỉ làm khi tôi gõ "TÔI ĐỒNG Ý GIAI ĐOẠN 5") Tắt launcher gốc
Lý do phổ biến khiến người khác bị treo logo / màn đen: tắt launcherx trước khi có launcher thay thế làm Home; hoặc Android xoá lựa chọn Home mặc định mỗi khi tập app HOME thay đổi, và trên Google TV 14 ứng viên kế tiếp là RecoveryActivity của setupwraith (màn đen, có thể crash-loop system_server). Vì vậy tắt setupwraith TRƯỚC, launcherx SAU, và đặt lại Home sau mỗi bước:
1. Điều kiện: Giai đoạn 4 đã chạy ổn ≥1 ngày; mở được Settings TV từ launcher mới; `dumpsys wifi | grep -o 'cname=[^ ]*'`. Nếu Wi-Fi thuộc com.google.android.tungsten.setupwraith → tôi vào Settings → Wi-Fi, Forget rồi kết nối lại (sau đó thuộc com.android.tv.settings), chạy lại lệnh kiểm tra, rồi `adb connect` lại.
2. `dis com.google.android.tungsten.setupwraith` → `home_new` → phải ra `com.gathin.tvhome`. Sai → `restore_last 1` + `home_new`.
3. Test cast từ điện thoại thật kỹ (repo chưa kiểm chứng cast trên TCL khi tắt setupwraith). Cast hỏng → `restore_last 1`, `home_new`, DỪNG Giai đoạn 5 (không tắt launcherx khi setupwraith còn bật).
4. `dis com.google.android.apps.tv.launcherx` → `home_new` ngay lập tức → phải ra `com.gathin.tvhome`. Bấm Home, Input, YouTube, Gear trên remote. Sai → `restore_last 1` + `home_new`.
5. REBOOT TEST. Trước khi reboot, nhắc tôi: sau reboot phải tự bật lại Wireless debugging trong Settings (mở từ ô Settings của launcher mới) rồi `adb tcpip 5555` lại để còn ADB.

## Bước cuối — Dọn dẹp & bảo mật
- In nội dung `~/tcl-debloat/disabled.txt` và `settings-changes.txt` cho tôi xem.
- Tuỳ chọn soundbar: `cmd hdmi_control cec_setting set system_audio_control 1` (ghi giá trị cũ trước).
- Tắt USB/Wireless debugging trong Developer options, reboot, kiểm tra cổng đã đóng: `nc -vz <ip TV> 5555` (chỉ "Connection refused" là OK).
- Nhắc: sau khi TCL cập nhật firmware, một số package có thể bật lại → so `pm list packages -e` với disabled.txt rồi `dis` lại.

# KẾ HOẠCH CỨU HỘ (giải thích cho tôi ngay từ đầu)
1. ADB còn kết nối → `restore_all` rồi `home_stock` (hoặc `~/tcl-debloat/restore.sh <ip>`), rồi `adb reboot`. Không dùng `tools/restore.sh` của repo (nó dựa trên record riêng của repo, không phải disabled.txt của tôi).
2. Mất ADB nhưng còn vào được Settings → Settings → Apps → See all apps → Show system apps → bật lại từng app theo disabled.txt (launcherx trước).
3. Treo logo / màn đen không vào được gì: vì chỉ disable chứ không xoá, Factory reset (qua menu recovery của TV: rút điện, giữ nút nguồn trên thân TV rồi cắm lại — hãy tra đúng cách cho TCL 65C6K) sẽ bật lại 100% app. Đây là phương án cuối, mất dữ liệu/đăng nhập.

Bắt đầu từ Bước 1. Trước tiên hãy tóm tắt lại kế hoạch trong 5 dòng và hỏi tôi IP của TV.
