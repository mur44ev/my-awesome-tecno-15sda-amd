# Windows USB mapping

Status: **BLOCKED** until this machine is mapped interactively in Windows.

Use USBToolBox 0.2 for Windows: <https://github.com/USBToolBox/tool/releases/download/0.2/Windows.zip>

1. Boot the TECNO K15SDA into its existing Windows installation and run `Windows.exe`.
2. Open **Discover Ports**.
3. Probe every physical port with both USB 2 and USB 3 devices, waiting for each device to appear before moving on.
4. Probe both orientations of every USB-C port with both devices.
5. Exercise the internal webcam while discovery is running and confirm its port appears.
6. Open **Select Ports and Build Kext** for `MacBookPro16,2`.
7. Select no more than 15 port personalities per controller and set the internal webcam port type to `255` (internal).
8. Build `UTBMap.kext` and place the real result at `hardware/usb/UTBMap.kext` in this worktree.

Do not substitute a generic map. `UTBMap.kext` must retain its `USBToolBox.kext` dependency; the validation script checks this and the 15-port limit when the map is present.
