#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
dsdt="$root/hardware/acpi/dsl/dsdt.dsl"
source_dir="$root/hardware/acpi/ssdt-time"

for name in SSDT-EC SSDT-USBX SSDT-XOSI; do
  test -s "$source_dir/$name.aml"
  cmp -s "$source_dir/$name.aml" "$root/acpi/$name.aml"
done
for name in SSDT-PNLF SSDT-ALS0; do
  test -s "$root/acpi/$name.aml"
done

python3 - "$source_dir/patches_OC.plist" <<'PY'
import plistlib
import sys

with open(sys.argv[1], "rb") as stream:
    acpi = plistlib.load(stream)["ACPI"]

assert {item["Path"] for item in acpi["Add"]} == {
    "SSDT-EC.aml", "SSDT-USBX.aml", "SSDT-XOSI.aml"
}
patches = {item["Comment"]: item for item in acpi["Patch"]}
assert not patches["EC0 _STA to XSTA Rename"]["Enabled"]
assert patches["_OSI to XOSI rename - requires SSDT-XOSI.aml"]["Enabled"]
PY

tmp="$(mktemp -d "/tmp/tecno-k15s-acpi-test.XXXXXX")"
trap 'rm -rf -- "$tmp"' EXIT
cp -- "$root"/acpi/*.aml "$tmp/"
for aml in "$tmp"/*.aml; do
  iasl -d "$aml" >/dev/null
  if [[ "$(basename -- "$aml")" = SSDT-EC.aml ]]; then
    # iasl drops this CondRefOf-only external while disassembling SSDT-EC.
    python3 - "${aml%.aml}.dsl" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
needle = "    External (_SB_.PCI0.SBRG.EC0_.XSTA"
assert needle in text
path.write_text(text.replace(
    needle,
    "    External (_SB_.PCI0.SBRG.EC0_._STA, MethodObj)\n" + needle,
    1,
))
PY
  fi
  iasl "${aml%.aml}.dsl" >/dev/null
done

grep -Fq 'Scope (_SB.PCI0.SBRG)' "$dsdt"
grep -Fq 'Device (EC0)' "$dsdt"
grep -Fq 'EisaId ("PNP0C09")' "$dsdt"
grep -Fq 'External (\_SB.PCI0.SBRG, DeviceObj)' "$tmp/SSDT-EC.dsl"
grep -Fq 'Scope (\_SB)' "$tmp/SSDT-USBX.dsl"
grep -Fq '"Windows 2015"' "$tmp/SSDT-XOSI.dsl"
grep -Fq 'Device (PNLF)' "$tmp/SSDT-PNLF.dsl"
grep -Fq 'Scope (_SB)' "$tmp/SSDT-ALS0.dsl"
! grep -Fq 'Device (PNLF)' "$dsdt"
! grep -Fq 'Device (ALS0)' "$dsdt"

map="$root/hardware/usb/UTBMap.kext/Contents/Info.plist"
if [[ -f "$map" ]]; then
  python3 - "$map" <<'PY'
import plistlib
import sys

with open(sys.argv[1], "rb") as stream:
    info = plistlib.load(stream)

assert "com.dhinakg.USBToolBox.kext" in info["OSBundleLibraries"]
personalities = info["IOKitPersonalities"]
assert personalities
for personality in personalities.values():
    assert personality["CFBundleIdentifier"] == "com.dhinakg.USBToolBox.kext"
    assert len(personality["IOProviderMergeProperties"]["ports"]) <= 15
PY
fi
