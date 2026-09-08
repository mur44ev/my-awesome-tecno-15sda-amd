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

## Usage

1. Copy `EFI/` to your EFI (ESP) partition.
2. Generate and fill in your own SMBIOS serials (see above).
3. Review `config.plist` — it was tuned for this specific laptop (audio layout, Wi-Fi, USB mapping).
4. Boot.

## Disclaimer

Provided as-is, for personal reference. No guarantees — read the OpenCore docs before touching anything.
