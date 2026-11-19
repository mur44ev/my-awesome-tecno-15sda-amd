#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="$root/scripts/collect-hardware.sh"
sanitizer="$root/scripts/sanitize-dmidecode.sh"

test -x "$script"
test -x "$sanitizer"
bash -n "$script"

sample=$'Product Name: MEGABOOK K15S\nSerial Number: secret\nUUID: secret\nAsset Tag: secret\nService Tag: secret\nInventory Tag: secret\nSize: 8192 MB'
expected=$'Product Name: MEGABOOK K15S\nSerial Number: REDACTED\nUUID: REDACTED\nAsset Tag: REDACTED\nService Tag: REDACTED\nInventory Tag: REDACTED\nSize: 8192 MB'
test "$("$sanitizer" <<< "$sample")" = "$expected"

test ! -e "$root/hardware/acpi/raw/msdm.dat"
test ! -e "$root/hardware/acpi/raw/MSDM.dat"
! grep -Fqw -- 'SERIAL' "$root/hardware/storage.txt"
grep -Fq 'AMD Ryzen 5 7430U' "$root/hardware/cpu.txt"
grep -Fq '[1002:15e7]' "$root/hardware/pci.txt"
grep -Fq '[10ec:c822]' "$root/hardware/pci.txt"
grep -Fq 'ALC269VC' "$root/hardware/audio-analog.txt"
grep -Fq 'HTIX5288:00 093A:0255 Touchpad' "$root/hardware/input.txt"
test -s "$root/hardware/acpi/dsl/dsdt.dsl"
sensitive='^[[:space:]]*(Serial Number|UUID|Asset Tag|Service Tag|Inventory Tag):'
test "$(grep -Ec "$sensitive" "$root/hardware/system.txt")" -gt 0
test "$(grep -Ec "$sensitive REDACTED$" "$root/hardware/system.txt")" -eq "$(grep -Ec "$sensitive" "$root/hardware/system.txt")"
for retained in 'System Information' 'Base Board Information' 'Memory Device'; do
  grep -Fq -- "$retained" "$root/hardware/system.txt"
done
grep -Eq '^(BIOS Information|Platform Firmware Information)$' "$root/hardware/system.txt"
grep -Eq '^[[:space:]]+Size: [1-9]' "$root/hardware/system.txt"

failure_tmp="$(mktemp -d "/tmp/collect-hardware-test.XXXXXX")"
trap 'rm -rf -- "$failure_tmp"' EXIT
mkdir -p -- "$failure_tmp/repo/scripts" "$failure_tmp/repo/hardware" "$failure_tmp/bin"
cp -- "$script" "$sanitizer" "$failure_tmp/repo/scripts/"
touch -- "$failure_tmp/repo/hardware/original"
printf '#!/usr/bin/env bash\nexit 1\n' > "$failure_tmp/bin/lscpu"
chmod +x "$failure_tmp/bin/lscpu"
if PATH="$failure_tmp/bin:$PATH" "$failure_tmp/repo/scripts/collect-hardware.sh"; then
  exit 1
fi
test -e "$failure_tmp/repo/hardware/original"
test ! -e "$failure_tmp/repo/hardware/cpu.txt"

success_repo="$failure_tmp/success-repo"
success_bin="$failure_tmp/success-bin"
mkdir -p -- "$success_repo/scripts" "$success_repo/hardware" "$success_bin"
cp -- "$script" "$sanitizer" "$success_repo/scripts/"
touch -- "$success_repo/hardware/original"
cat > "$success_bin/fake-command" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$(/usr/bin/basename "$0")" in
  lscpu) /usr/bin/cat "$FIXTURE_HARDWARE/cpu.txt" ;;
  lspci) /usr/bin/cat "$FIXTURE_HARDWARE/pci.txt" ;;
  lsusb)
    if [[ "${1:-}" = -tv ]]; then
      /usr/bin/cat "$FIXTURE_HARDWARE/usb-tree.txt"
    else
      /usr/bin/cat "$FIXTURE_HARDWARE/usb.txt"
    fi
    ;;
  lsblk) /usr/bin/cat "$FIXTURE_HARDWARE/storage.txt" ;;
  cat)
    case "${2:-}" in
      /proc/bus/input/devices) /usr/bin/cat "${FIXTURE_INPUT:-$FIXTURE_HARDWARE/input.txt}" ;;
      /proc/asound/card0/codec#0) /usr/bin/cat "$FIXTURE_HARDWARE/audio-hdmi.txt" ;;
      /proc/asound/card1/codec#0) /usr/bin/cat "$FIXTURE_HARDWARE/audio-analog.txt" ;;
      *) exit 1 ;;
    esac
    ;;
  sudo) "$@" ;;
  dmidecode) /usr/bin/cat "$FIXTURE_HARDWARE/system.txt" ;;
  acpidump)
    /usr/bin/cp -- "$FIXTURE_HARDWARE"/acpi/raw/*.dat .
    /usr/bin/touch "msdm.dat"
    ;;
esac
EOF
chmod +x "$success_bin/fake-command"
for command in lscpu lspci lsusb lsblk cat sudo dmidecode acpidump; do
  ln -s -- "fake-command" "$success_bin/$command"
done
FIXTURE_HARDWARE="$root/hardware" PATH="$success_bin:$PATH" "$success_repo/scripts/collect-hardware.sh"
test ! -e "$success_repo/hardware/original"
test -s "$success_repo/hardware/cpu.txt"
test -s "$success_repo/hardware/acpi/dsl/dsdt.dsl"
test ! -e "$success_repo/hardware/acpi/raw/msdm.dat"
test -z "$(compgen -G "$success_repo/.hardware-stage.*" || true)"

mouse_repo="$failure_tmp/mouse-repo"
mkdir -p -- "$mouse_repo/scripts" "$mouse_repo/hardware"
cp -- "$script" "$sanitizer" "$mouse_repo/scripts/"
touch -- "$mouse_repo/hardware/original"
printf 'N: Name="HTIX5288:00 093A:0255 Mouse"\n' > "$failure_tmp/mouse-input.txt"
if FIXTURE_HARDWARE="$root/hardware" FIXTURE_INPUT="$failure_tmp/mouse-input.txt" PATH="$success_bin:$PATH" "$mouse_repo/scripts/collect-hardware.sh"; then
  exit 1
fi
test -e "$mouse_repo/hardware/original"
test ! -e "$mouse_repo/hardware/cpu.txt"

for required in \
  'set -euo pipefail' \
  'mktemp -d "/tmp/tecno-k15s-hardware.XXXXXX"' \
  'chmod 0700 "$tmp"' \
  'trap' \
  'lscpu' \
  'lspci -nnk' \
  'lsusb -tv' \
  'NAME,MODEL,SIZE,TYPE,FSTYPE,PARTTYPENAME,TRAN' \
  '/proc/bus/input/devices' \
  '/proc/asound/card0/codec#0' \
  '/proc/asound/card1/codec#0' \
  'dmidecode -t system -t baseboard -t bios -t memory' \
  '| "$root/scripts/sanitize-dmidecode.sh"' \
  'acpidump -b -z' \
  'sudo rm -f -- "msdm.dat" "MSDM.dat"' \
  'chown' \
  'cp -- "$raw/dsdt.dat" "$dsl/"' \
  'iasl -d "dsdt.dat"' \
  'mv --exchange --no-copy --no-target-directory' \
  'rm --'; do
  grep -Fq -- "$required" "$script"
done
