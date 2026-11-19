# TECNO K15S AMD — Backlight Timeout Fix

Disable the stock **15-second keyboard backlight timeout** on Windows. Keep the light on until you turn it off with F1 / Fn+F1.

A small background helper resets the idle timer every four seconds. Brightness controls still work. It starts when you sign in; no BIOS flashing is involved.

**Tested:** TECNO MEGABOOK K15SDA AMD, BIOS 1.10, Windows x64. Other models and BIOS versions are blocked.

## Install

You need Python x64 3.8+, the original `PCInformation.dll` and `inpoutx64.dll` from [TECNO PC Manager](https://www.tecno-mobile.com/support/support-detail-laptops/pcmanager/), and an already running `inpoutx64` driver. The helper does not install drivers.

The supported DLL comes from `TECNOPCManagerInstaller_1.0.1.27.exe`. Vendor binaries are not included.

Run PowerShell from this folder:

```powershell
.\Install.ps1 -DependencyDirectory 'C:\path\to\original-dlls'
```

Optional: add `-ValidateOnly` to check requirements without installing, or `-PythonExecutable 'C:\path\to\python.exe'` to select Python.

## Controls

- **F1 / Fn+F1:** change brightness or turn the light off.
- **Disable the helper:** run `.\Disable.ps1`.
- **Enable it again:** run `.\Enable.ps1`.

Installed files and status: `%LOCALAPPDATA%\TecnoBacklightKeepAlive`.

## Details

The fix was physically tested: the light stays on when idle, and manual off still works. Sign-in startup is configured; a reboot test has not been performed.

Read [how it works](docs/how-it-works.md) for the EC register, DLL hash and compatibility checks. The helper only works during your Windows session.

MIT license for this project's source code. TECNO software is not included or covered by that license.
