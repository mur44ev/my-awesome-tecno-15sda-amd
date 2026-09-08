# TECNO MEGABOOK K15S AMD Hackintosh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, validate, and boot a custom OpenCore 1.0.7 macOS Ventura EFI for the TECNO MEGABOOK K15S AMD, then install to a separately approved internal APFS partition and tune all realistically supported hardware.

**Architecture:** Keep OpenCore and Recovery on the approved 64 GB USB throughout testing so the internal EFI remains untouched. Build from this laptop's Linux hardware/ACPI dump, AMD Vanilla patches, NootedRed, and a Windows-generated USB map; validate every EFI revision before booting and change one setting per failed attempt.

**Tech Stack:** OpenCore 1.0.7 DEBUG/RELEASE, macOS Ventura Recovery, AMD Vanilla kernel patches, NootedRed 0.8.10, ACPI/iasl, SSDTTime, ProperTree, USBToolBox, release kexts, Bash, Python 3 stdlib plist tools.

---

## File Map

- `.gitignore`: excludes downloaded archives, Apple Recovery files, logs, backups, and temporary build output.
- `README.md`: records target hardware, exact component versions, known unsupported devices, and boot instructions.
- `scripts/collect-hardware.sh`: reproducibly captures DMI, PCI, USB, input, audio, storage, and ACPI data.
- `hardware/`: tracked machine inventory, decompiled ACPI, USB map, and dependency hashes.
- `acpi/`: tracked source DSL and compiled AML files selected for this laptop.
- `EFI/`: the validated OpenCore deliverable; DEBUG remains in Git until the machine is stable.
- `recovery/`: ignored Apple-hosted Ventura Recovery files.
- `downloads/`: ignored upstream release archives and tools.
- `logs/`: ignored per-attempt OpenCore logs and boot photos.
- `docs/acceptance-checklist.md`: one post-install hardware test checklist.

### Task 1: Capture The Exact Laptop Hardware

**Files:**
- Create: `.gitignore`
- Create: `scripts/collect-hardware.sh`
- Create: `hardware/system.txt`
- Create: `hardware/pci.txt`
- Create: `hardware/usb.txt`
- Create: `hardware/usb-tree.txt`
- Create: `hardware/storage.txt`
- Create: `hardware/input-devices.txt`
- Create: `hardware/audio-codec-hdmi.txt`
- Create: `hardware/audio-codec-analog.txt`
- Create: `hardware/acpi/raw/*`
- Create: `hardware/acpi/dsl/*`

- [ ] **Step 1: Install only the missing inventory tools**

Run:

```bash
sudo pacman -S --needed acpica dmidecode gptfdisk
```

Expected: `acpidump`, `iasl`, `dmidecode`, and `sgdisk` are available; no unrelated packages are installed.

- [ ] **Step 2: Add repository exclusions**

Create `.gitignore` with:

```gitignore
downloads/
recovery/
logs/
backups/
build/
*.log
```

- [ ] **Step 3: Write the collection script**

Create `scripts/collect-hardware.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
hardware="$root/hardware"
raw="$hardware/acpi/raw"
dsl="$hardware/acpi/dsl"

mkdir -p "$raw" "$dsl"
lscpu > "$hardware/cpu.txt"
lspci -nnk > "$hardware/pci.txt"
lsusb > "$hardware/usb.txt"
lsusb -tv > "$hardware/usb-tree.txt"
lsblk -o NAME,MODEL,SERIAL,SIZE,TYPE,FSTYPE,PARTTYPENAME,TRAN > "$hardware/storage.txt"
cp /proc/bus/input/devices "$hardware/input-devices.txt"
cp /proc/asound/card0/codec#0 "$hardware/audio-codec-hdmi.txt"
cp /proc/asound/card1/codec#0 "$hardware/audio-codec-analog.txt"
sudo dmidecode -t system -t baseboard -t bios -t memory > "$hardware/system.txt"

rm -f "$raw"/*.dat "$dsl"/*.dat "$dsl"/*.dsl
pushd "$raw" >/dev/null
sudo acpidump -b -z
popd >/dev/null
sudo chown -R "$(id -u):$(id -g)" "$raw"
cp "$raw"/*.dat "$dsl"/
pushd "$dsl" >/dev/null
iasl -da ./*.dat
rm ./*.dat
popd >/dev/null
```

- [ ] **Step 4: Check the script before running it**

Run:

```bash
bash -n scripts/collect-hardware.sh
```

Expected: exit code `0` and no output.

- [ ] **Step 5: Capture and assert the known hardware**

Run:

```bash
chmod +x scripts/collect-hardware.sh
./scripts/collect-hardware.sh
grep -Fq "AMD Ryzen 5 7430U" hardware/cpu.txt
grep -Fq "[1002:15e7]" hardware/pci.txt
grep -Fq "[10ec:c822]" hardware/pci.txt
grep -Fq "Realtek ALC269VC" hardware/audio-codec-analog.txt
grep -Fq "HTIX5288:00 093A:0255 Touchpad" hardware/input-devices.txt
test -s hardware/acpi/dsl/dsdt.dsl
```

Expected: every command exits `0`. This confirms Barcelo graphics, unsupported RTL8822CE wireless, ALC269VC revision `0x100203`, and the I2C HID touchpad.

- [ ] **Step 6: Commit the inventory**

Run:

```bash
export GIT_AUTHOR_NAME=OpenCode GIT_AUTHOR_EMAIL=opencode@localhost
export GIT_COMMITTER_NAME=OpenCode GIT_COMMITTER_EMAIL=opencode@localhost
git add .gitignore scripts hardware
git commit -m "Capture TECNO K15S hardware"
```

### Task 2: Build The Machine-Specific USB And ACPI Inputs

**Files:**
- Create: `hardware/usb/UTBMap.kext/**`
- Create: `hardware/acpi/ssdt-time/*`
- Create if SSDTTime reports it is required: `acpi/SSDT-EC.aml`
- Create: `acpi/SSDT-USBX.aml`
- Create: `acpi/SSDT-XOSI.aml`
- Create: `acpi/SSDT-PNLF.aml`
- Create: `acpi/SSDT-ALS0.aml`

- [ ] **Step 1: Generate ACPI fixes from this laptop's DSDT**

Run:

```bash
git clone https://github.com/corpnewt/SSDTTime.git downloads/SSDTTime
git -C downloads/SSDTTime checkout 16c359215b09464382753a2a0bb737ff68269881
cp hardware/acpi/raw/dsdt.dat downloads/SSDTTime/DSDT.aml
python3 downloads/SSDTTime/SSDTTime.py
```

In SSDTTime, select the existing `DSDT.aml`, then run the labelled actions `FakeEC`, `USBX`, and `XOSI`. Do not run desktop-only AWAC, PMC, PLUG, or CPUR fixes. Copy the resulting AML files and `patches_OC.plist` to `hardware/acpi/ssdt-time/`.

Expected: SSDTTime identifies a laptop EC and creates only machine-derived EC/USBX/XOSI output. If FakeEC reports that no fake EC is needed, omit `SSDT-EC.aml` rather than forcing it.

- [ ] **Step 2: Add NootedRed's laptop backlight tables**

Run:

```bash
curl -fL https://chefkiss.dev/Extras/SSDTs/SSDT-PNLF.aml -o acpi/SSDT-PNLF.aml
curl -fL https://chefkiss.dev/Extras/SSDTs/SSDT-ALS0.aml -o acpi/SSDT-ALS0.aml
cp hardware/acpi/ssdt-time/SSDT-USBX.aml acpi/SSDT-USBX.aml
cp hardware/acpi/ssdt-time/SSDT-XOSI.aml acpi/SSDT-XOSI.aml
test ! -e hardware/acpi/ssdt-time/SSDT-EC.aml || cp hardware/acpi/ssdt-time/SSDT-EC.aml acpi/SSDT-EC.aml
```

Expected: each selected AML is non-empty and compiles/decompiles with `iasl` without an error.

- [ ] **Step 3: Build the USB map in Windows**

Boot the existing Windows installation. Download and run `Windows.exe` from USBToolBox 0.2 as Administrator:

```text
https://github.com/USBToolBox/tool/releases/download/0.2/Windows.exe
```

Choose `Discover Ports`. Probe every physical port once with a USB 2 device and once with a USB 3 device, including both orientations of any USB-C port. Exercise the internal webcam. Return to `Select Ports and Build Kext`, keep only observed ports, set external connectors to their physical type, and build `UTBMap.kext` for `MacBookPro16,2`.

Expected: no controller exposes more than 15 mapped personalities and the webcam's internal port is type `255`.

- [ ] **Step 4: Import and inspect the USB map**

Copy `UTBMap.kext` from Windows to `hardware/usb/UTBMap.kext`, then run:

```bash
python3 - <<'PY'
import plistlib
from pathlib import Path

p = Path("hardware/usb/UTBMap.kext/Contents/Info.plist")
with p.open("rb") as f:
    data = plistlib.load(f)
assert data["CFBundleIdentifier"] == "com.dhinakg.USBToolBox.kext"
print("UTBMap plist valid")
PY
```

Expected: `UTBMap plist valid`.

- [ ] **Step 5: Commit the machine-specific inputs**

Run:

```bash
git add hardware/usb hardware/acpi/ssdt-time acpi
git commit -m "Add K15S ACPI and USB map"
```

### Task 3: Lock And Download OpenCore Components

**Files:**
- Create: `hardware/components.txt`
- Create: `hardware/dependency-sha256.txt`
- Create: `downloads/*`

- [ ] **Step 1: Record the selected versions**

Create `hardware/components.txt` with:

```text
OpenCorePkg 1.0.7 DEBUG initially, RELEASE after stabilization
AMD_Vanilla commit eaf52ef292abf4ebec899df6d48626569ba50cc6
SSDTTime commit 16c359215b09464382753a2a0bb737ff68269881
ProperTree commit 51ed53dbe3c96a81686ae1fc47f6d2a92f668159
NootedRed 0.8.10 RELEASE
Lilu 1.7.2 RELEASE
VirtualSMC 1.3.7 RELEASE
AppleALC 1.9.7 RELEASE
NVMeFix 1.1.3 RELEASE
RealtekRTL8111 3.0.0
VoodooI2C 2.9.1 RELEASE
VoodooPS2Controller 2.3.7 RELEASE
BrightnessKeys 1.0.3 RELEASE
ECEnabler 1.0.6 RELEASE
USBToolBox 1.2.0 RELEASE
AppleMCEReporterDisabler from Dortania OpenCore Install Guide
```

- [ ] **Step 2: Download only official release artifacts**

Run:

```bash
mkdir -p downloads
curl -fL https://github.com/acidanthera/OpenCorePkg/releases/download/1.0.7/OpenCore-1.0.7-DEBUG.zip -o downloads/OpenCore-1.0.7-DEBUG.zip
curl -fL https://github.com/acidanthera/OpenCorePkg/releases/download/1.0.7/OpenCore-1.0.7-RELEASE.zip -o downloads/OpenCore-1.0.7-RELEASE.zip
curl -fL https://raw.githubusercontent.com/AMD-OSX/AMD_Vanilla/eaf52ef292abf4ebec899df6d48626569ba50cc6/patches.plist -o downloads/AMD-Vanilla-patches.plist
curl -fL https://github.com/ChefKissInc/NootedRed/releases/download/v0.8.10/NootedRed-0.8.10-RELEASE.zip -o downloads/NootedRed-0.8.10-RELEASE.zip
curl -fL https://github.com/acidanthera/Lilu/releases/download/1.7.2/Lilu-1.7.2-RELEASE.zip -o downloads/Lilu-1.7.2-RELEASE.zip
curl -fL https://github.com/acidanthera/VirtualSMC/releases/download/1.3.7/VirtualSMC-1.3.7-RELEASE.zip -o downloads/VirtualSMC-1.3.7-RELEASE.zip
curl -fL https://github.com/acidanthera/AppleALC/releases/download/1.9.7/AppleALC-1.9.7-RELEASE.zip -o downloads/AppleALC-1.9.7-RELEASE.zip
curl -fL https://github.com/acidanthera/NVMeFix/releases/download/1.1.3/NVMeFix-1.1.3-RELEASE.zip -o downloads/NVMeFix-1.1.3-RELEASE.zip
curl -fL https://github.com/Mieze/RTL8111_driver_for_OS_X/releases/download/v3.0.0/RealtekRTL8111-V3.0.0.zip -o downloads/RealtekRTL8111-3.0.0.zip
curl -fL https://github.com/VoodooI2C/VoodooI2C/releases/download/v2.9.1/VoodooI2C-2.9.1-RELEASE.zip -o downloads/VoodooI2C-2.9.1-RELEASE.zip
curl -fL https://github.com/acidanthera/VoodooPS2/releases/download/2.3.7/VoodooPS2Controller-2.3.7-RELEASE.zip -o downloads/VoodooPS2Controller-2.3.7-RELEASE.zip
curl -fL https://github.com/acidanthera/BrightnessKeys/releases/download/1.0.3/BrightnessKeys-1.0.3-RELEASE.zip -o downloads/BrightnessKeys-1.0.3-RELEASE.zip
curl -fL https://github.com/averycblack/ECEnabler/releases/download/1.0.6/ECEnabler-1.0.6-RELEASE.zip -o downloads/ECEnabler-1.0.6-RELEASE.zip
curl -fL https://github.com/USBToolBox/kext/releases/download/1.2.0/USBToolBox-1.2.0-RELEASE.zip -o downloads/USBToolBox-1.2.0-RELEASE.zip
curl -fL https://github.com/dortania/OpenCore-Install-Guide/raw/master/extra-files/AppleMCEReporterDisabler.kext.zip -o downloads/AppleMCEReporterDisabler.kext.zip
curl -fL https://github.com/acidanthera/OcBinaryData/raw/master/Drivers/HfsPlus.efi -o downloads/HfsPlus.efi
sha256sum downloads/* > hardware/dependency-sha256.txt
```

Expected: all downloads complete without HTTP errors. Confirm these published hashes before continuing:

```text
OpenCore-1.0.7-DEBUG.zip 3644db831dd18344896d7a86077b8c338c0eaa01b1579d7fa00785598cac1f2b
OpenCore-1.0.7-RELEASE.zip 2ffab6ebf58c7aefb0bcb3a1a385d207746823d6dd87d44bd666e1286939943e
NootedRed-0.8.10-RELEASE.zip 28767001f2bbe12d648313e0e3b0c5adb1ac2c2d1f844e4212ee2f88d486da66
Lilu-1.7.2-RELEASE.zip 53967d7dcfaab01023a33df2e969a89522f13d6654a6a56ac4711b62dabf3ab8
VirtualSMC-1.3.7-RELEASE.zip 12f1d379969f926306fa92d94ddbf33b32b31176589dc42089d864a26b31b700
AppleALC-1.9.7-RELEASE.zip 81a8ba79986130e8c845fff595950226cbc30e588f8d37089e467f776469c29d
NVMeFix-1.1.3-RELEASE.zip e1d5657ab7ac31f69771708f7b80bf218ab9aa0b8e4c4fe6ff943983037e3dfb
RealtekRTL8111-3.0.0.zip a0f2e64ac3c76e2d416ff88f35a197ce229e74ea78e968631a736a43b4d8231c
ECEnabler-1.0.6-RELEASE.zip e21149519856308c6c4c06e0917aef9e3423ff3e23b6ea77989099f4f2cf0f0a
USBToolBox-1.2.0-RELEASE.zip c315a3a5acfd496dd97d0d19b4fbd1d487103d2fd541c5651583d4c9cebcfe07
```

- [ ] **Step 3: Commit the lock data, not downloaded binaries**

Run:

```bash
git add hardware/components.txt hardware/dependency-sha256.txt
git commit -m "Lock OpenCore component versions"
```

### Task 4: Assemble The DEBUG EFI

**Files:**
- Create: `EFI/BOOT/BOOTx64.efi`
- Create: `EFI/OC/OpenCore.efi`
- Create: `EFI/OC/Drivers/HfsPlus.efi`
- Create: `EFI/OC/Drivers/OpenRuntime.efi`
- Create: `EFI/OC/ACPI/*.aml`
- Create: `EFI/OC/Kexts/*.kext/**`
- Create: `EFI/OC/Resources/**`

- [ ] **Step 1: Extract upstream packages to temporary build directories**

Run:

```bash
rm -rf build EFI
mkdir -p build EFI/BOOT EFI/OC/{ACPI,Drivers,Kexts,Resources,Tools}
for archive in downloads/*.zip; do unzip -q "$archive" -d "build/$(basename "$archive" .zip)"; done
```

Expected: no archive reports CRC errors.

- [ ] **Step 2: Copy the minimal OpenCore boot chain**

Copy from the OpenCore 1.0.7 DEBUG archive:

```text
X64/EFI/BOOT/BOOTx64.efi -> EFI/BOOT/BOOTx64.efi
X64/EFI/OC/OpenCore.efi -> EFI/OC/OpenCore.efi
X64/EFI/OC/Drivers/OpenRuntime.efi -> EFI/OC/Drivers/OpenRuntime.efi
Docs/Sample.plist -> EFI/OC/config.plist
Utilities/ocvalidate/ocvalidate -> build/ocvalidate
Utilities/macserial/macserial -> build/macserial
Utilities/macrecovery/ -> build/macrecovery/
```

Copy `downloads/HfsPlus.efi` to `EFI/OC/Drivers/HfsPlus.efi`. Do not add OpenCanopy, audio, shell, legacy, or filesystem drivers.

- [ ] **Step 3: Copy ACPI and the required kexts**

Copy all selected files from `acpi/` into `EFI/OC/ACPI/`. Copy these release bundles into `EFI/OC/Kexts/`:

```text
Lilu.kext
NootedRed.kext
VirtualSMC.kext
SMCBatteryManager.kext
SMCLightSensor.kext
AppleMCEReporterDisabler.kext
AppleALC.kext
NVMeFix.kext
RealtekRTL8111.kext
VoodooPS2Controller.kext
VoodooI2C.kext
VoodooI2CHID.kext
BrightnessKeys.kext
ECEnabler.kext
USBToolBox.kext
UTBMap.kext
```

Use only one `VoodooInput.kext` plugin: retain the copy embedded in VoodooI2C. Remove the VoodooPS2Controller copies of `VoodooInput`, `VoodooPS2Mouse`, and `VoodooPS2Trackpad`; retain `VoodooPS2Keyboard` because the keyboard is PS/2 while the touchpad is I2C HID. Never add WhateverGreen because it conflicts with NootedRed.

- [ ] **Step 4: Assert the minimal file set**

Run:

```bash
test -s EFI/BOOT/BOOTx64.efi
test -s EFI/OC/OpenCore.efi
test -s EFI/OC/Drivers/HfsPlus.efi
test -s EFI/OC/Drivers/OpenRuntime.efi
test -d EFI/OC/Kexts/NootedRed.kext
test -d EFI/OC/Kexts/UTBMap.kext
test ! -e EFI/OC/Kexts/WhateverGreen.kext
```

Expected: every assertion exits `0`.

### Task 5: Configure OpenCore For The 7430U

**Files:**
- Modify: `EFI/OC/config.plist`
- Read: `hardware/acpi/ssdt-time/patches_OC.plist`
- Read: `downloads/AMD-Vanilla-patches.plist`

- [ ] **Step 1: Snapshot the assembled EFI, then import ACPI and kernel patches**

Run:

```bash
git clone https://github.com/corpnewt/ProperTree.git downloads/ProperTree
git -C downloads/ProperTree checkout 51ed53dbe3c96a81686ae1fc47f6d2a92f668159
python3 downloads/ProperTree/ProperTree.py EFI/OC/config.plist
```

Start from OpenCore 1.0.7 `Docs/Sample.plist`. In ProperTree run `File -> OC Clean Snapshot` and select `EFI/OC`; this creates exact executable, plist, and embedded-plugin paths from the assembled files. Merge only the SSDTTime ACPI patches that correspond to retained AML files. Replace `Kernel -> Patch` with the pinned AMD Vanilla `Kernel -> Patch` array.

For each of the four comments containing `Force cpuid_cores_per_package`, change only `Replace` for six physical cores:

```text
B8 06 0000 0000
BA 06 0000 0000
BA 06 0000 0090
BA 06 0000 00
```

- [ ] **Step 2: Set the initial AMD boot quirks**

Set these exact non-default or important values:

```text
Booter/Quirks/AvoidRuntimeDefrag = true
Booter/Quirks/EnableSafeModeSlide = true
Booter/Quirks/EnableWriteUnprotector = false
Booter/Quirks/ProvideCustomSlide = true
Booter/Quirks/RebuildAppleMemoryMap = true
Booter/Quirks/ResizeAppleGpuBars = -1
Booter/Quirks/SetupVirtualMap = true
Booter/Quirks/SyncRuntimePermissions = true
Kernel/Emulate/DummyPowerManagement = true
Kernel/Quirks/DisableLinkeditJettison = true
Kernel/Quirks/PanicNoKextDump = true
Kernel/Quirks/PowerTimeoutKernelPanic = true
Kernel/Quirks/ProvideCurrentCpuInfo = true
Kernel/Quirks/XhciPortLimit = false
UEFI/Quirks/RequestBootVarRouting = true
```

Do not add `npci=0x3000`; it is a diagnostic fallback only if boot stops at PCI configuration.

- [ ] **Step 3: Set kext load order**

Keep ProperTree's dependency order. Confirm the required top-level order and constraints are:

```text
Lilu.kext
NootedRed.kext
VirtualSMC.kext
SMCBatteryManager.kext
SMCLightSensor.kext
AppleMCEReporterDisabler.kext
AppleALC.kext
NVMeFix.kext
RealtekRTL8111.kext
VoodooPS2Controller.kext
VoodooI2C.kext
VoodooI2CHID.kext
BrightnessKeys.kext
ECEnabler.kext
USBToolBox.kext
UTBMap.kext
```

NootedRed must remain before AppleALC to avoid their documented Lilu conflict. Parent kexts must precede embedded plugins, `VoodooPS2Keyboard` must remain enabled under VoodooPS2Controller, and the single enabled `VoodooInput` must be the copy embedded under VoodooI2C.

- [ ] **Step 4: Configure debug, security, and NVRAM**

Set:

```text
Misc/Boot/HideAuxiliary = false
Misc/Debug/AppleDebug = true
Misc/Debug/ApplePanic = true
Misc/Debug/DisableWatchDog = true
Misc/Debug/DisplayLevel = 2147483650
Misc/Debug/SysReport = true
Misc/Debug/Target = 67
Misc/Security/AllowSetDefault = true
Misc/Security/BlacklistAppleUpdate = true
Misc/Security/DmgLoading = Signed
Misc/Security/ScanPolicy = 0
Misc/Security/SecureBootModel = Disabled
Misc/Security/Vault = Optional
NVRAM/Add/7C436110-AB2A-4BBB-A880-FE41995C9F82/boot-args = -v debug=0x100 keepsyms=1 alcid=21
NVRAM/Add/7C436110-AB2A-4BBB-A880-FE41995C9F82/csr-active-config = 00000000
NVRAM/Add/7C436110-AB2A-4BBB-A880-FE41995C9F82/run-efi-updater = No
```

SIP remains enabled. Layout `21` is only the first ALC269VC candidate and is changed one value at a time after installation if an audio path is missing.

- [ ] **Step 5: Generate local MacBookPro16,2 identity**

Run:

```bash
build/macserial -m MacBookPro16,2 -n 1
uuidgen
python3 - <<'PY'
import secrets
print(secrets.token_hex(6).upper())
PY
```

Put the generated serial/MLB, UUID, and six-byte ROM into `PlatformInfo -> Generic`; set `SystemProductName` to `MacBookPro16,2`, `Automatic` to `true`, and `UpdateSMBIOSMode` to `Create`. Do not publish these values in README or documentation.

- [ ] **Step 6: Configure UEFI drivers and validate the plist**

Enable only `HfsPlus.efi` and `OpenRuntime.efi` in `UEFI -> Drivers`. Run:

```bash
chmod +x build/ocvalidate
build/ocvalidate EFI/OC/config.plist
python3 - <<'PY'
import plistlib
from pathlib import Path

root = Path("EFI/OC")
with (root / "config.plist").open("rb") as f:
    c = plistlib.load(f)
checks = [
    ("ACPI", "Add", "Path"),
    ("Kernel", "Add", "BundlePath"),
    ("UEFI", "Drivers", "Path"),
]
folders = {"ACPI": "ACPI", "Kernel": "Kexts", "UEFI": "Drivers"}
for section, group, key in checks:
    for item in c[section][group]:
        if item.get("Enabled", True):
            path = root / folders[section] / item[key]
            assert path.exists(), path
names = [x["BundlePath"] for x in c["Kernel"]["Add"] if x["Enabled"]]
assert names.index("NootedRed.kext") < names.index("AppleALC.kext")
assert not any("WhateverGreen" in x for x in names)
ids = []
for name in names:
    with (root / "Kexts" / name / "Contents/Info.plist").open("rb") as f:
        ids.append(plistlib.load(f)["CFBundleIdentifier"])
assert len(ids) == len(set(ids)), "duplicate enabled kext identifiers"
print("EFI references and load order valid")
PY
```

Expected: `ocvalidate` prints `No issues found.` and Python prints `EFI references and load order valid`.

- [ ] **Step 7: Commit the first validated EFI**

Run:

```bash
git add EFI
git commit -m "Build initial K15S OpenCore EFI"
```

### Task 6: Download Ventura Recovery And Write The USB

**Files:**
- Create: `recovery/com.apple.recovery.boot/BaseSystem.dmg`
- Create: `recovery/com.apple.recovery.boot/BaseSystem.chunklist`
- Modify destructively after identity checks: the approved removable 64 GB USB only

- [ ] **Step 1: Download official Ventura Recovery**

Run:

```bash
mkdir -p recovery/com.apple.recovery.boot
(
  cd build/macrecovery
  python3 ./macrecovery.py -b Mac-B4831CEBD52A0C4C -m 00000000000000000 download
)
cp build/macrecovery/com.apple.recovery.boot/BaseSystem.dmg recovery/com.apple.recovery.boot/
cp build/macrecovery/com.apple.recovery.boot/BaseSystem.chunklist recovery/com.apple.recovery.boot/
test -s recovery/com.apple.recovery.boot/BaseSystem.dmg
test -s recovery/com.apple.recovery.boot/BaseSystem.chunklist
```

Expected: both files download from Apple and are non-empty.

- [ ] **Step 2: Identify the USB without guessing its device name**

Plug in only the approved 64 GB USB, then run:

```bash
lsblk -dpno NAME,SIZE,MODEL,SERIAL,TRAN,RM,TYPE
read -r -p "Exact 64 GB USB disk path: " USB_DISK
test "$(lsblk -dnro TRAN "$USB_DISK")" = usb
test "$(lsblk -dnro RM "$USB_DISK")" = 1
test "$(lsblk -dnro TYPE "$USB_DISK")" = disk
bytes=$(sudo blockdev --getsize64 "$USB_DISK")
test "$bytes" -ge 60000000000
test "$bytes" -le 70000000000
lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN "$USB_DISK"
```

Expected: the printed model, serial, transport, and 60-70 billion byte size match the approved flash drive. Stop if any assertion fails.

- [ ] **Step 3: Erase and format only the validated USB**

Run with the same shell variable:

```bash
sudo umount "${USB_DISK}"?* 2>/dev/null || true
sudo sgdisk --zap-all "$USB_DISK"
sudo sgdisk -n 1:0:0 -t 1:0700 -c 1:OPENCORE "$USB_DISK"
sudo partprobe "$USB_DISK"
USB_PART="${USB_DISK}1"
test -b "$USB_PART" || USB_PART="${USB_DISK}p1"
sudo mkfs.vfat -F 32 -n OPENCORE "$USB_PART"
udisksctl mount -b "$USB_PART"
```

Expected: one GPT Microsoft basic data partition labelled `OPENCORE` is mounted.

- [ ] **Step 4: Copy and verify EFI plus Recovery**

Run:

```bash
MOUNTPOINT=$(lsblk -dnro MOUNTPOINTS "$USB_PART")
test -n "$MOUNTPOINT"
cp -a EFI "$MOUNTPOINT/"
cp -a recovery/com.apple.recovery.boot "$MOUNTPOINT/"
sync
test -s "$MOUNTPOINT/EFI/BOOT/BOOTx64.efi"
test -s "$MOUNTPOINT/EFI/OC/config.plist"
test -s "$MOUNTPOINT/com.apple.recovery.boot/BaseSystem.dmg"
udisksctl unmount -b "$USB_PART"
```

Expected: all assertions pass and the partition unmounts cleanly.

### Task 7: Perform The First Recovery Boot Loop

**Files:**
- Create as needed: `logs/attempt-001/`, `logs/attempt-002/`, and subsequent numbered attempt directories
- Modify between attempts: `EFI/OC/config.plist`
- Modify after each validated change: the USB copy of `EFI/`

- [ ] **Step 1: Set conservative firmware options**

In BIOS 1.10, disable Secure Boot and Fast Boot. Disable CSM and IOMMU if exposed. Enable UEFI mode and XHCI hand-off if exposed. Leave UMA VRAM at its detected 512 MiB unless NootedRed reaches a black screen; prefer 1 GiB if the firmware offers it. Record every changed option in `README.md`.

- [ ] **Step 2: Boot OpenCore and Recovery**

Boot the USB from the firmware one-time menu. At OpenCore, run `Reset NVRAM` once, reboot to the USB, then select `macOS Recovery`. Connect wired Ethernet before Recovery requests a network.

Expected: OpenCore picker appears, verbose macOS boot completes, keyboard/trackpad work, and Ventura Recovery opens without touching the internal partitions.

- [ ] **Step 3: Preserve evidence after each failed attempt**

If boot fails, power off, boot Linux, mount the USB, and copy its `opencore-*.txt` plus the final-screen photo into `logs/attempt-001/`. Use `attempt-002`, `attempt-003`, and so on for later failures. Record one hypothesis and one proposed config change in that attempt directory's `notes.txt`.

Use this order and never combine changes:

```text
No OpenCore picker: recheck BOOTx64.efi path and firmware Secure Boot.
OCB/driver error: re-run ocvalidate and file-reference assertions.
[EB|#LOG:EXITBS:START]: toggle RebuildAppleMemoryMap first; restore it before testing SetupVirtualMap.
[PCI configuration begin]: add npci=0x3000 for one test only.
Kernel panic: preserve the full panic and identify the named kext before changing anything.
Black screen after graphics starts: verify NootedRed, no WhateverGreen, PNLF, and then raise UMA VRAM if BIOS permits.
Recovery opens without Ethernet: confirm RealtekRTL8111 loaded before changing its version.
```

- [ ] **Step 4: Commit the Recovery-booting EFI**

After Recovery opens twice from cold boot, copy the proven USB EFI back to the repository, run `ocvalidate` again, and commit:

```bash
git add EFI README.md
git commit -m "Boot Ventura Recovery on K15S"
```

### Task 8: Create The Internal macOS Space Safely

**Files:**
- Create: `backups/nvme0n1-before-macos.gpt`
- Create: `backups/nvme0n1-before-macos.sha256`
- Modify only after a fresh explicit approval: `/dev/nvme0n1` partition table

- [ ] **Step 1: Back up the current GPT before any resize**

Run from Linux:

```bash
mkdir -p backups
sudo sgdisk --backup=backups/nvme0n1-before-macos.gpt /dev/nvme0n1
sudo chown "$(id -u):$(id -g)" backups/nvme0n1-before-macos.gpt
sha256sum backups/nvme0n1-before-macos.gpt > backups/nvme0n1-before-macos.sha256
sudo sgdisk --verify /dev/nvme0n1
lsblk -o NAME,MODEL,SIZE,FSTYPE,PARTTYPENAME,MOUNTPOINTS /dev/nvme0n1
```

Expected: GPT verification reports no problems and the backup hash is recorded outside Git.

- [ ] **Step 2: Obtain a separate resize approval**

Present the current partition table and free-space report to the user. The recommended operation is to boot Windows, suspend BitLocker if enabled, disable Fast Startup, and shrink the large NTFS system partition by `102400 MB` in Disk Management. Leave the result unallocated. Do not resize Btrfs and do not create or format the macOS partition from Linux.

Expected: Windows still boots and Disk Management shows about 100 GB unallocated.

- [ ] **Step 3: Verify unallocated space without writing**

Boot Linux and run:

```bash
sudo sgdisk --print /dev/nvme0n1
sudo sgdisk --verify /dev/nvme0n1
```

Expected: a contiguous unallocated region of at least 80 GB exists and GPT verification still reports no problems. Stop if it does not.

- [ ] **Step 4: Install Ventura only into the free space**

Boot USB Recovery. In Disk Utility choose `View -> Show All Devices`, select only the new free-space region, create a GUID/APFS partition named `macOS`, and install Ventura there. During reboots, keep booting OpenCore from USB and choose `macOS Installer` until it disappears, then choose `macOS`.

Expected: Setup Assistant opens and Windows/Linux partitions retain their original names and sizes except for the approved NTFS shrink.

### Task 9: Tune And Test Supported Laptop Hardware

**Files:**
- Create: `docs/acceptance-checklist.md`
- Modify as evidence requires: `EFI/OC/config.plist`
- Modify as evidence requires: `acpi/*.aml`

- [ ] **Step 1: Add the single acceptance checklist**

Create `docs/acceptance-checklist.md` with unchecked rows for:

```text
Two cold boots and two warm reboots
Vega reports Metal support and correct display resolution
Brightness slider and brightness keys
PS/2 keyboard and all expected function keys
I2C touchpad pointer, click, two-finger scroll, and three-finger gesture
Battery percentage, charging state, and lid state
Speakers, internal microphone, headphone output, and jack switching
Webcam video
Every physical USB port at USB 2 and USB 3 speed
RTS5129 card reader recorded as working or unsupported; not a success gate
RTL8111 Ethernet DHCP and sustained transfer
Sleep/wake from menu and lid, tested on battery and AC
HDMI video; HDMI audio marked pass or known NootedRed limitation
Windows and Linux still boot from their firmware entries
```

- [ ] **Step 2: Verify graphics before tuning other devices**

Run in macOS:

```bash
system_profiler SPDisplaysDataType
```

Expected: AMD Vega is listed with display acceleration and `Metal Support: Metal 3`. If Chromium artifacts occur, record the documented NootedRed workaround rather than replacing the graphics stack.

- [ ] **Step 3: Select the working ALC269VC layout one at a time**

Test `alcid=21` first. If any required analog path is absent, test this sequence, one cold boot per value:

```text
11, 13, 28, 29, 35, 66, 69, 77
```

After each boot inspect `system_profiler SPAudioDataType` and test speakers, microphone, headphones, and jack switching. Keep the first layout that passes all four; do not test HDMI audio until analog audio is stable. NootedRed must stay before AppleALC in the config.

- [ ] **Step 4: Verify input, battery, brightness, camera, and USB**

Use System Settings and IORegistry to confirm VoodooI2CHID attaches to `HTIX5288`, SMCBatteryManager publishes battery data, PNLF exposes brightness, the webcam appears, and only UTBMap ports are present. If a device is absent, change only its corresponding kext/SSDT, re-run `iasl` and `ocvalidate`, then cold boot and retest.

- [ ] **Step 5: Test sleep and external display last**

Run:

```bash
pmset -g
pmset -g assertions
sudo pmset sleepnow
```

Test wake on AC and battery, then lid sleep/wake. Connect HDMI after internal sleep is stable. HDMI video is required; HDMI audio may remain marked as the upstream NootedRed limitation if it enumerates but produces no sound.

- [ ] **Step 6: Commit each proven peripheral fix separately**

For each change that converts one checklist item from fail to pass:

```bash
build/ocvalidate EFI/OC/config.plist
git add EFI acpi docs/acceptance-checklist.md
git commit -m "Fix K15S touchpad"
```

The command shows the touchpad case. For a battery-only revision use `git commit -m "Fix K15S battery"`; for audio use `git commit -m "Fix K15S audio"`; for brightness use `git commit -m "Fix K15S brightness"`; for sleep use `git commit -m "Fix K15S sleep"`. Do not combine unrelated fixes.

### Task 10: Produce The Stable EFI And Final Evidence

**Files:**
- Modify: `EFI/BOOT/BOOTx64.efi`
- Modify: `EFI/OC/OpenCore.efi`
- Modify: `EFI/OC/Drivers/OpenRuntime.efi`
- Modify: `EFI/OC/config.plist`
- Modify: `README.md`
- Modify: `docs/acceptance-checklist.md`

- [ ] **Step 1: Replace only OpenCore DEBUG binaries with 1.0.7 RELEASE**

Copy `BOOTx64.efi`, `OpenCore.efi`, and `OpenRuntime.efi` from the 1.0.7 RELEASE archive. Keep the known-good DEBUG EFI as a Git revision, not a second live configuration.

- [ ] **Step 2: Remove temporary debugging settings**

Set:

```text
Misc/Debug/AppleDebug = false
Misc/Debug/ApplePanic = true
Misc/Debug/DisplayLevel = 0
Misc/Debug/SysReport = false
Misc/Debug/Target = 0
NVRAM boot-args = the already-tested alcid value recorded as passing in docs/acceptance-checklist.md
Misc/Security/SecureBootModel = Default
```

Remove `-v debug=0x100 keepsyms=1` and any temporary `npci` argument. Keep SIP enabled, `DmgLoading=Signed`, and `Vault=Optional`. If `SecureBootModel=Default` alone prevents boot, restore `Disabled` and document that exact exception.

- [ ] **Step 3: Run final static verification**

Run:

```bash
build/ocvalidate EFI/OC/config.plist
git diff --check
test ! -e EFI/OC/Kexts/WhateverGreen.kext
test -d EFI/OC/Kexts/NootedRed.kext
```

Expected: `No issues found.`, no whitespace errors, no WhateverGreen, and NootedRed present.

- [ ] **Step 4: Re-copy EFI and run final boot verification**

Copy the validated EFI to the USB, unmount cleanly, then complete every row in `docs/acceptance-checklist.md`. Perform two cold boots, two warm reboots, one sleep/wake on battery, one on AC, and verify Windows and Linux from their original firmware entries.

- [ ] **Step 5: Document known limits and commit**

Update `README.md` with exact working versions, BIOS settings, the selected audio layout, supported/unsupported hardware, USB boot instructions, and recovery steps. State explicitly that RTL8822CE Wi-Fi/Bluetooth and fingerprint are unsupported, Android RNDIS tethering is not relied upon, and OpenCore remains on USB.

Run:

```bash
git add EFI README.md docs/acceptance-checklist.md
git commit -m "Finalize TECNO K15S Ventura EFI"
git status --short
```

Expected: final commit succeeds and `git status --short` is empty.
