# TECNO Megabook K15S (AMD) — Hackintosh EFI

OpenCore EFI and research notes for running macOS on a TECNO Megabook K15S AMD (model K15SDA, AMD APU, iGPU accelerated via NootedRed).

```
EFI/          Bootable OpenCore EFI folder (copy to your EFI partition)
  OC/
    config.plist
    ACPI/     Prebuilt SSDTs (EC, USBX, XOSI, PNLF, ALS0, HPET, CPUR, ...)
    Kexts/    All required kexts
    Drivers/  OpenRuntime, HfsPlus, OpenCanopy, ...
acpi/         SSDT sources (.dsl) and build notes
docs/         Design docs and step-by-step build plans
hardware/     Sanitized hardware dumps (dmidecode, lspci, USB tree, audio paths)
scripts/      Hardware collection / ACPI helper scripts
```

## ⚠️ Sanitized before publishing

`EFI/OC/config.plist` has been stripped of machine-unique data. The following are **empty** and must be generated for your own machine before booting:

- `PlatformInfo → Generic → SystemSerialNumber`
- `PlatformInfo → Generic → MLB`
- `PlatformInfo → Generic → SystemUUID`
- `PlatformInfo → Generic → ROM`

SMBIOS model used: **MacBookPro16,2**. Generate serials with [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) or `macserial`. OC boot logs and old config snapshots were removed as well.

## Usage (fresh install)

1. Get a macOS recovery/installer image — e.g. with OpenCore's `macrecovery` (in `Utilities/macrecovery/`) written to a FAT32 USB stick.
2. Copy this repo's `EFI/` onto that USB's ESP.
3. Generate and fill in your own SMBIOS serials (see above).
4. Review `config.plist` — it was tuned for this specific laptop (audio layout, Wi-Fi, USB mapping).
5. Boot from USB (`EFI/Boot/BOOTX64.EFI` is a copy of `OpenCore.efi`, so firmware picks it up without a boot entry), install macOS, then copy `EFI/` to the internal ESP.

After a Linux+OC dual boot the ESP may hold other loaders (Limine/GRUB/systemd) — that is fine, boot through the firmware boot menu if needed.

## Disclaimer

Provided as-is, for personal reference. No guarantees — read the OpenCore docs before touching anything.
