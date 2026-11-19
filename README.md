# TECNO MEGABOOK K15SDA AMD

Hackintosh EFI, Windows fixes, and hardware notes for this laptop.

| Project | What it does | Start here |
| --- | --- | --- |
| **Hackintosh** | OpenCore EFI, ACPI sources, and setup notes | [Hackintosh guide](docs/hackintosh.md) |
| **Windows backlight fix** | Disables the stock **15-second keyboard backlight timeout** while the helper is running | [Backlight guide](docs/windows-backlight.md) |
| **Hardware & research** | Laptop details, captured hardware data, and technical notes | [Hardware](docs/hardware.md) · [Test status](docs/status.md) |

## What's inside

```text
docs/                         Guides, hardware overview, and test status
hackintosh/
  EFI/                        OpenCore EFI folder
  acpi/                       SSDT source files
  hardware/                   Original hardware captures
  scripts/                    Hardware and ACPI tools
  docs/                       Original build plans and research
windows/
  keyboard-backlight/          Backlight timeout fix and install scripts
```

## Keep the keyboard light on

The Windows helper stops the backlight from turning off after 15 seconds. The keyboard shortcut still changes brightness and turns the light off manually.

From PowerShell in this repository:

```powershell
.\windows\keyboard-backlight\Install.ps1 -DependencyDirectory 'C:\path\to\original-dlls'
```

Requires Python x64, the supported original TECNO DLLs, and an already running `inpoutx64` driver. Tested on **K15SDA AMD, BIOS 1.10**. [Requirements and controls →](docs/windows-backlight.md)

## Set up Hackintosh

The EFI is in [`hackintosh/EFI`](hackintosh/EFI). Read the [setup guide](docs/hackintosh.md) before copying it to a USB EFI partition. Generate your own SMBIOS identifiers first; the published values are empty.

The EFI and research were imported from the existing laptop project. This merge does not establish a new macOS compatibility or boot result. [What has been tested →](docs/status.md)

## About this repository

This brings together [tecno-k15s-hackintosh](https://github.com/mur44ev/tecno-k15s-hackintosh) and [tecno-k15s-backlight](https://github.com/mur44ev/tecno-k15s-backlight), with both Git histories preserved.

See [the docs](docs/README.md) for navigation and [NOTICE](NOTICE.md) for component licensing. This is a personal project, unaffiliated with TECNO.
