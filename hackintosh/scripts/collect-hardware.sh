#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
final="$root/hardware"
tmp="$(mktemp -d "/tmp/tecno-k15s-hardware.XXXXXX")"
chmod 0700 "$tmp"
stage=""
trap 'rm -rf -- "$tmp"; test -z "$stage" || rm -rf -- "$stage"' EXIT

hardware="$tmp/hardware"
raw="$hardware/acpi/raw"
dsl="$hardware/acpi/dsl"

mkdir -p -- "$raw" "$dsl"

lscpu > "$hardware/cpu.txt"
lspci -nnk > "$hardware/pci.txt"
lsusb > "$hardware/usb.txt"
lsusb -tv > "$hardware/usb-tree.txt"
lsblk -o NAME,MODEL,SIZE,TYPE,FSTYPE,PARTTYPENAME,TRAN > "$hardware/storage.txt"
cat -- /proc/bus/input/devices > "$hardware/input.txt"
cat -- /proc/asound/card0/codec#0 > "$hardware/audio-hdmi.txt"
cat -- /proc/asound/card1/codec#0 > "$hardware/audio-analog.txt"
sudo dmidecode -t system -t baseboard -t bios -t memory | "$root/scripts/sanitize-dmidecode.sh" > "$hardware/system.txt"

owner_uid="${SUDO_UID:-$(id -u)}"
owner_gid="${SUDO_GID:-$(id -g)}"
(
  cd -- "$raw"
  sudo acpidump -b -z
  sudo rm -f -- "msdm.dat" "MSDM.dat"
)

shopt -s nullglob
raw_output=("$raw"/*)
test "${#raw_output[@]}" -gt 0
sudo chown -- "$owner_uid:$owner_gid" "${raw_output[@]}"

cp -- "$raw/dsdt.dat" "$dsl/"
(
  cd -- "$dsl"
  trap 'rm -- "dsdt.dat"' EXIT
  iasl -d "dsdt.dat"
)

for output in cpu.txt pci.txt usb.txt usb-tree.txt storage.txt input.txt audio-hdmi.txt audio-analog.txt system.txt; do
  test -s "$hardware/$output"
done
test ! -e "$raw/msdm.dat"
test ! -e "$raw/MSDM.dat"
! grep -Fqw -- 'SERIAL' "$hardware/storage.txt"
sensitive='^[[:space:]]*(Serial Number|UUID|Asset Tag|Service Tag|Inventory Tag):'
test "$(grep -Ec "$sensitive" "$hardware/system.txt")" -gt 0
test "$(grep -Ec "$sensitive REDACTED$" "$hardware/system.txt")" -eq "$(grep -Ec "$sensitive" "$hardware/system.txt")"
grep -Fq 'AMD Ryzen 5 7430U' "$hardware/cpu.txt"
grep -Fq '[1002:15e7]' "$hardware/pci.txt"
grep -Fq '[10ec:c822]' "$hardware/pci.txt"
grep -Fq 'ALC269VC' "$hardware/audio-analog.txt"
grep -Fq 'HTIX5288:00 093A:0255 Touchpad' "$hardware/input.txt"
test -s "$dsl/dsdt.dsl"

stage="$(mktemp -d "$root/.hardware-stage.XXXXXX")"
chmod 0700 "$stage"
cp -a -- "$hardware/." "$stage/"
if [[ -e "$final" ]]; then
  mv --exchange --no-copy --no-target-directory -- "$stage" "$final"
else
  mv --no-copy --no-target-directory -- "$stage" "$final"
  stage=""
fi
