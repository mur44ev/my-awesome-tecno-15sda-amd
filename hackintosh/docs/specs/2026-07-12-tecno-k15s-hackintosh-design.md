# TECNO MEGABOOK K15S AMD Hackintosh Design

## Goal

Build a custom OpenCore EFI and an official macOS Ventura Recovery USB for a
test installation. Boot and validate Recovery before changing the internal
disk, then install macOS to a dedicated APFS partition and enable every
realistically supported laptop device.

## Hardware

- Laptop: TECNO MEGABOOK K15S AMD, board K15SDA, BIOS 1.10
- CPU: AMD Ryzen 5 7430U, 6 cores / 12 threads, Cezanne/Barcelo
- iGPU: AMD Barcelo Vega, PCI ID 1002:15e7, 512 MiB reserved VRAM
- NVMe: KIOXIA BG5 512 GB, PCI ID 1e0f:000c
- Ethernet: Realtek RTL8111/8168, PCI ID 10ec:8168
- Wi-Fi/Bluetooth: Realtek RTL8822CE, PCI ID 10ec:c822
- USB devices: RTS5129 card reader, FocalTech fingerprint reader, USB camera
- Existing systems: Windows on NTFS and Linux on Btrfs

NootedRed officially supports the Vega Raven family through Ryzen 5xxx and
7x30 APUs, including this 7430U. Ventura is selected as a conservative target
for the first working build rather than a newer macOS release.

## Scope

The finished test build should provide:

- OpenCore boot from the USB without modifying the internal EFI
- macOS Recovery boot with verbose output and persistent OpenCore logs
- Vega graphics acceleration on the internal display
- Display brightness and brightness keys
- Keyboard and touchpad with gestures
- Speakers, microphone, and headphone output
- Battery status, lid state, and sleep/wake where firmware permits
- Webcam, mapped USB ports, and wired Ethernet
- HDMI video, with HDMI audio treated as best effort because NootedRed lists it
  as a known compatibility issue

The RTL8822CE Wi-Fi/Bluetooth and fingerprint reader are excluded because they
have no viable modern macOS driver. The RTS5129 card reader is best effort and
is not a success requirement. Installation networking will use wired Ethernet,
not Android USB tethering.

## EFI Design

Use current release builds of OpenCore and only the kexts required by detected
hardware. The EFI will contain:

- AMD Vanilla kernel patches for the 6-core Cezanne CPU
- NootedRed and its required dependencies for the Vega iGPU
- VirtualSMC and laptop sensor/battery support as applicable
- Drivers for the Realtek Ethernet, KIOXIA NVMe, audio, keyboard, and touchpad
- A machine-specific USB map
- ACPI tables and patches derived from this laptop's own firmware tables
- MacBookPro16,2 SMBIOS, as recommended by NootedRed

No ACPI tables or USB maps will be copied unchanged from another laptop EFI.
Unique SMBIOS values will be generated locally and kept out of documentation.
The current 512 MiB VRAM allocation meets NootedRed's minimum; it will only be
changed if graphics testing shows that it is necessary and firmware permits it.

## Delivery Flow

1. Capture ACPI tables, codec IDs, input devices, firmware settings, and USB
   topology from the running Linux installation.
2. Build the custom EFI and validate its plist and file references with the
   OpenCore release's `ocvalidate`.
3. Erase the approved 64 GB USB and place OpenCore plus official Ventura
   Recovery files on it.
4. Boot Recovery over wired Ethernet. Diagnose failures from the OpenCore log
   and a photo of the final verbose line, changing one variable per attempt.
5. After Recovery is stable, back up the NVMe partition table and obtain
   separate approval for the exact resize operation that creates 80-100 GB of
   unallocated space.
6. Install macOS only into the new APFS space. Keep OpenCore on USB during all
   testing so the existing internal EFI remains unchanged.
7. Test and tune supported peripherals against a single acceptance checklist.

## Safety And Recovery

- The 64 GB USB may be erased; this has been approved.
- No internal partition is resized or formatted during EFI construction or the
  initial Recovery boot test.
- Before repartitioning, save the GPT and verify that Windows and Linux backups
  are adequate. The exact source partition for the new space remains a later,
  explicit user decision.
- Never format by ambiguous disk name; identify targets by model, size, and
  partition table immediately before each destructive command.
- Keep a last-known-good EFI copy and preserve logs from each failed boot.

## Verification

Before writing the USB, `ocvalidate` must pass against the exact OpenCore
release and every enabled driver, kext, ACPI table, and tool must exist in the
EFI. Recovery boot is the first integration check. After installation, verify
graphics acceleration, brightness, input, each audio path, battery, lid,
sleep/wake, camera, every USB port, Ethernet, and HDMI, then confirm Windows and
Linux still boot unchanged.
