D=~/tcl-debloat
export ANDROID_SERIAL="192.168.50.103:5555"

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
