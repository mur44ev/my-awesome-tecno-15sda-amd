# Disable the 15-second backlight timeout

The stock keyboard backlight turns off after about 15 seconds of inactivity. This Windows helper keeps it on until you switch it off with F1 / Fn+F1.

It runs in the background and resets the idle counter. Brightness controls still work. No BIOS or EC firmware flashing is required.

## Requirements

- TECNO MEGABOOK K15SDA AMD, BIOS **1.10**. The helper blocks other model and BIOS values.
- Windows x64 and Python x64 **3.8+**, including `pythonw.exe`.
- Original `PCInformation.dll` and `inpoutx64.dll` from the supported TECNO PC Manager installer.
- An already installed and running `inpoutx64` driver. The project does not install drivers.

The supported DLL comes from `TECNOPCManagerInstaller_1.0.1.27.exe`, linked from the [official TECNO PC Manager page](https://www.tecno-mobile.com/support/support-detail-laptops/pcmanager/). Its exact hash is checked; vendor binaries are not bundled.

## Install

Put the two original DLLs in a folder, then open PowerShell at the root of this repository:

```powershell
.\windows\keyboard-backlight\Install.ps1 -DependencyDirectory 'C:\path\to\original-dlls'
```

Add `-ValidateOnly` for a check without installation. If Python is not found automatically, add `-PythonExecutable 'C:\path\to\python.exe'`.

The installer creates a background helper in `%LOCALAPPDATA%\TecnoBacklightKeepAlive` and a shortcut in the current user's Startup folder.

## Controls

| Action | Control |
| --- | --- |
| Change brightness or switch the light off | F1 / Fn+F1 |
| Disable the helper, including future sign-ins | `.\windows\keyboard-backlight\Disable.ps1` |
| Enable the helper again | `.\windows\keyboard-backlight\Enable.ps1` |
| Read diagnostic status | `%LOCALAPPDATA%\TecnoBacklightKeepAlive\status.json` |

The fix only runs during the Windows user session. Restart and resume behavior have not been physically verified. See [test status](status.md) and [implementation details](../windows/keyboard-backlight/docs/how-it-works.md).
