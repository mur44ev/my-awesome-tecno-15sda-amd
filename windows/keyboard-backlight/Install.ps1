param(
    [Parameter(Mandatory = $true)][string]$DependencyDirectory,
    [string]$PythonExecutable,
    [switch]$ValidateOnly
)
$ErrorActionPreference = 'Stop'
$expectedHash = '401DA4767C0DE662D59AA397EF699DE52FBFE8BBDBE4B41CD958EDD02510CD57'
$bios = Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS'
if ($bios.SystemProductName -cne 'MEGABOOK K15S AMD' -or $bios.SystemManufacturer -cne 'TECNO Mobile Limited') {
    throw 'This helper is restricted to the tested TECNO MEGABOOK K15S AMD.'
}
if ($bios.BIOSVersion -cne '1.10') { throw 'Only BIOS 1.10 has been tested.' }
$dependencies = (Resolve-Path -LiteralPath $DependencyDirectory).Path
foreach ($name in @('PCInformation.dll', 'inpoutx64.dll')) {
    $file = Join-Path $dependencies $name
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing dependency: $name" }
    if ((Get-AuthenticodeSignature -LiteralPath $file).Status -ne 'Valid') {
        throw "Dependency does not have a valid Authenticode signature: $name"
    }
}
if ((Get-FileHash -LiteralPath (Join-Path $dependencies 'PCInformation.dll') -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'Unsupported PCInformation.dll version. The internal function addresses require the documented SHA256.'
}
$driver = Get-CimInstance Win32_SystemDriver -Filter "Name='inpoutx64'"
if (!$driver -or $driver.State -ne 'Running') { throw 'The existing inpoutx64 driver must already be running. No driver will be installed.' }
if (!$PythonExecutable) {
    $pythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue
    if (!$pythonCommand) { throw 'Pass -PythonExecutable with the path to an x64 Python installation.' }
    $PythonExecutable = $pythonCommand.Source
}
$PythonExecutable = (Resolve-Path -LiteralPath $PythonExecutable).Path
$pythonw = Join-Path (Split-Path $PythonExecutable) 'pythonw.exe'
if (!(Test-Path -LiteralPath $pythonw -PathType Leaf)) { throw 'pythonw.exe must be next to python.exe.' }
& $PythonExecutable -c 'import struct,sys; sys.exit(0 if struct.calcsize("P")==8 and sys.version_info >= (3,8) else 1)'
if ($LASTEXITCODE -ne 0) { throw 'Python x64 3.8 or newer is required.' }
if ($ValidateOnly) { Write-Output 'Model, signed dependencies, DLL hash, running driver and Python validated. No changes made.'; return }
$destination = Join-Path $env:LOCALAPPDATA 'TecnoBacklightKeepAlive'
if (Test-Path -LiteralPath (Join-Path $destination 'backlight.py')) {
    throw 'Helper is already installed. Use Enable.ps1 / Disable.ps1; do not overwrite a running hardware helper.'
}
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'backlight.py') -Destination $destination
foreach ($name in @('PCInformation.dll', 'inpoutx64.dll')) {
    Copy-Item -LiteralPath (Join-Path $dependencies $name) -Destination $destination
}
@{ pythonw = $pythonw } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $destination 'install.json') -Encoding UTF8
$shell = New-Object -ComObject WScript.Shell
$shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) 'TECNO Keyboard Backlight.lnk'
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $pythonw
$shortcut.Arguments = '"' + (Join-Path $destination 'backlight.py') + '"'
$shortcut.WorkingDirectory = $destination
$shortcut.Description = 'TECNO K15S AMD keyboard backlight idle counter helper'
$shortcut.WindowStyle = 7
$shortcut.Save()
Start-Process -FilePath $pythonw -ArgumentList $shortcut.Arguments -WorkingDirectory $destination -WindowStyle Hidden
Write-Output "Installed to $destination; sign-in startup enabled."
