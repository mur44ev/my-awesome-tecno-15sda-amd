# How the backlight fix works

Test machine: TECNO MEGABOOK K15SDA AMD, BIOS 1.10. Runtime testing used Windows x64 and Python 3.13.

## EC interface

| Register | Observed meaning | Helper action |
| --- | --- | --- |
| `0x02` | Vendor interface signature: `0xAA` | Read through `IsECSupport` |
| `0x1A` | Selected backlight level, `0`–`4`; `0` is manual off | Read only |
| `0x26` | Idle counter; rises about 10 units/second and stops at `150` | Reset to `0` every four seconds when the level is nonzero |

The counter's behavior was observed while using the physical keyboard. Resetting it kept the backlight on beyond the stock timeout. The user also verified that manual off continued to work.

Repeating `SetKeyLight` and briefly changing brightness did not prevent the timeout. The working helper never writes the brightness register.

## Vendor library

The helper uses the original signed `PCInformation.dll` and its dependency `inpoutx64.dll` from TECNO PC Manager. Read and write routines are located at RVA `0x76FD0` and `0x77050` in this exact `PCInformation.dll`:

```text
SHA256: 401da4767c0de662d59aa397ef699de52fbfe8bbdbe4b41cd958edd02510cd57
```

The vendor protocol uses command `0x80` for reads and `0x81` for writes on port `0x6C`, with the register and data on port `0x68`.

The runtime checks the laptop model, BIOS version, DLL hash, interface signature, level range and counter range. Unexpected values stop the helper. A named mutex prevents duplicate instances.

## Limits

- This is a Windows helper, not a permanent firmware setting. It does not run before sign-in or while Windows is suspended.
- The existing `inpoutx64` driver was already running and configured for automatic start on the test machine. The installer does not install or configure it.
- The exact DLL hash and matching interface signature do not establish compatibility with another laptop. Do not bypass the model and BIOS checks to try another board.
- Internal DLL calls can fail outside Python's exception handling. A native crash may leave no diagnostic entry.
- Autostart was checked by inspecting the shortcut. Restart and resume behavior have not been physically verified.

Diagnostics are written to `status.json` in the installation folder. Proprietary vendor libraries and firmware dumps are not distributed here.
