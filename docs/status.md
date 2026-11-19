# Test status

## Windows keyboard backlight

| Check | Result |
| --- | --- |
| Prevent the stock 15-second timeout during inactivity | Confirmed by physical observation |
| Turn the light off using the keyboard shortcut | Confirmed by physical observation |
| Keep brightness controls available | Existing level selection is preserved; the helper does not write brightness |
| Run in the background | Process and status file checked |
| Sign-in startup | Shortcut configured and inspected |
| Operation after restarting Windows | Not physically tested |
| Operation after sleep/resume | Not physically tested |
| Other laptop models or BIOS versions | Not tested; blocked by runtime checks |

Test setup: MEGABOOK K15SDA AMD, BIOS 1.10, Windows x64, Python 3.13, and the supported original vendor DLLs.

## Hackintosh

The existing OpenCore EFI, ACPI sources, hardware captures, scripts, and research were imported with their history. EFI contents are preserved from the original repository.

This consolidation does not include a new macOS boot or device validation run. The historical design and build plan describe intended tests, not confirmed results for every device.
