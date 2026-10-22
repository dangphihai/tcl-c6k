#!/bin/zsh
D=~/tcl-debloat
IP="${1:-192.168.50.103}"
echo "--- BẮT ĐẦU CỨU HỘ: Kết nối tới $IP:5555 ---"
adb connect "$IP:5555"
export ANDROID_SERIAL="$IP:5555"

if [[ -f "$D/disabled.txt" ]] && [[ -s "$D/disabled.txt" ]]; then
  echo "Khôi phục các package đã disable (thứ tự ngược)..."
  tail -r "$D/disabled.txt" | while read -r p; do
    [[ -z "$p" ]] && continue
    echo "Enabling $p..."
    adb shell pm enable --user 0 "$p" </dev/null | tr -d '\r'
  done
  TS=$(date +%Y%m%d-%H%M%S)
  mv "$D/disabled.txt" "$D/disabled.restored-$TS.txt"
  touch "$D/disabled.txt"
  echo "Đã đổi tên disabled.txt -> disabled.restored-$TS.txt"
else
  echo "Không có package nào cần khôi phục trong disabled.txt."
fi

echo "Khôi phục Home về Google TV launcher gốc..."
adb shell 'cmd package set-home-activity --user 0 $(cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME com.google.android.apps.tv.launcherx | tail -n 1)' </dev/null | tr -d '\r'

if [[ -f "$D/settings-changes.txt" ]] && [[ -s "$D/settings-changes.txt" ]]; then
  echo "Khôi phục lại các cài đặt hệ thống..."
  while read -r ns key val; do
    [[ -z "$ns" || -z "$key" ]] && continue
    echo "Khôi phục setting: $ns $key -> $val"
    adb shell settings put "$ns" "$key" "$val" </dev/null | tr -d '\r'
  done < "$D/settings-changes.txt"
fi

echo "--- HOÀN TẤT CỨU HỘ ---"
