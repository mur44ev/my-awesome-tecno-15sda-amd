# SSDTTime results

- Commit: `16c359215b09464382753a2a0bb737ff68269881`
- Selected table: `hardware/acpi/raw/dsdt.dat`
- `FakeEC Laptop`: found a valid `PNP0C09` EC at `\_SB.PCI0.SBRG.EC0`. Because it is named `EC0`, SSDTTime created a macOS-only `EC` device. The existing `_STA` returns `0x0F` from both branches; SSDTTime emitted its conservative `EC0 _STA to XSTA Rename` patch disabled, and it remains disabled.
- `USBX`: generated with SSDTTime's defaults (`0x13EC`, `0x0834`, `0x13EC`, `0x0834`).
- `XOSI`: auto-detected `Windows 10 (Windows 2015)`, found no `OSID` method, and generated only the enabled `_OSI` to `XOSI` rename.
- Not run: AWAC/RTCAWAC, PMC, PluginType/PLUG/CPUR, or other desktop-only actions.

`SSDT-PNLF.aml` and `SSDT-ALS0.aml` in `acpi/` are the official NootedRed laptop tables from:

- <https://chefkiss.dev/Extras/SSDTs/SSDT-PNLF.aml>
- <https://chefkiss.dev/Extras/SSDTs/SSDT-ALS0.aml>
