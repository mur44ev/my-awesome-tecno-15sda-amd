# Components and licensing

This repository combines two existing projects owned by the same GitHub account:

- [tecno-k15s-hackintosh](https://github.com/mur44ev/tecno-k15s-hackintosh): imported with its history under `hackintosh/`.
- [tecno-k15s-backlight](https://github.com/mur44ev/tecno-k15s-backlight): imported with its history under `windows/keyboard-backlight/`.

The Windows helper source is covered by its [MIT license](windows/keyboard-backlight/LICENSE).

The original Hackintosh repository did not declare a repository-wide license. This combined repository does not relicense its EFI binaries, kexts, drivers, or other third-party components. Their respective upstream terms continue to apply.

TECNO PC Manager DLLs and the `inpoutx64` driver are external prerequisites for the Windows helper. They are not included here and are not covered by the helper's license.
