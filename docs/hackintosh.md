# Hackintosh

OpenCore EFI and research for the TECNO MEGABOOK K15SDA AMD, imported from [tecno-k15s-hackintosh](https://github.com/mur44ev/tecno-k15s-hackintosh).

## Files

| Path | Contents |
| --- | --- |
| [`hackintosh/EFI`](../hackintosh/EFI) | OpenCore, configuration, ACPI tables, kexts, and drivers |
| [`hackintosh/acpi`](../hackintosh/acpi) | SSDT sources and build notes |
| [`hackintosh/hardware`](../hackintosh/hardware) | Original hardware and ACPI captures |
| [`hackintosh/scripts`](../hackintosh/scripts) | Collection and ACPI helper scripts |
| [`hackintosh/docs`](../hackintosh/docs) | Original design and build plan |

## Before booting

The published `config.plist` has empty machine identifiers. Generate your own values for `PlatformInfo → Generic`:

- `SystemSerialNumber`
- `MLB`
- `SystemUUID`
- `ROM`

The original configuration uses **MacBookPro16,2**. Review the hardware-specific configuration and enabled components before use.

## Start from USB

1. Prepare a macOS recovery or installer USB using the appropriate OpenCore tools.
2. Copy **`hackintosh/EFI/`** to the USB's EFI partition as **`EFI/`**.
3. Fill in your generated SMBIOS identifiers and review `EFI/OC/config.plist`.
4. Boot the USB from the firmware boot menu and validate Recovery before changing internal partitions.

The original [usage notes](../hackintosh/README.md) are retained with the EFI. Original plans describe intended device support; this repository merge does not verify macOS boot, acceleration, or peripheral compatibility. See [test status](status.md).
