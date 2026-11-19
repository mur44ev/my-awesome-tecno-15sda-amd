"""TECNO K15S AMD: preserve keyboard backlight until the hardware key disables it.
Tested EC: register 0x26 counts idle time in 100 ms units, saturating at 150.
Only that counter is written; the brightness register 0x1A is never written.
"""
import ctypes, hashlib, json, os, pathlib, time, traceback, winreg
ROOT = pathlib.Path(__file__).resolve().parent
STOP = ROOT / 'disabled.flag'
STATUS = ROOT / 'status.json'
EXPECTED = '401da4767c0de662d59aa397ef699de52fbfe8bbdbe4b41cd958edd02510cd57'
kernel = ctypes.WinDLL('kernel32', use_last_error=True)
kernel.CreateMutexW.argtypes = [ctypes.c_void_p, ctypes.c_bool, ctypes.c_wchar_p]
kernel.CreateMutexW.restype = ctypes.c_void_p
kernel.CloseHandle.argtypes = [ctypes.c_void_p]

def status(**data):
    data.update(pid=os.getpid(), updated=time.strftime('%Y-%m-%d %H:%M:%S'))
    STATUS.write_text(json.dumps(data, ensure_ascii=False), encoding='utf-8')

def main():
    mutex = kernel.CreateMutexW(None, False, 'Local\\TecnoK15SBacklightKeepAlive')
    if not mutex or ctypes.get_last_error() == 183:
        return
    dll_directory = None
    try:
        if STOP.exists():
            return
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r'HARDWARE\DESCRIPTION\System\BIOS') as bios:
            model = winreg.QueryValueEx(bios, 'SystemProductName')[0]
            maker = winreg.QueryValueEx(bios, 'SystemManufacturer')[0]
            bios_version = winreg.QueryValueEx(bios, 'BIOSVersion')[0]
        if model != 'MEGABOOK K15S AMD' or maker != 'TECNO Mobile Limited':
            raise RuntimeError('This helper is restricted to the tested TECNO K15S AMD.')
        if bios_version != '1.10':
            raise RuntimeError('Only BIOS 1.10 has been tested; refusing hardware access.')
        path = ROOT / 'PCInformation.dll'
        if hashlib.sha256(path.read_bytes()).hexdigest() != EXPECTED:
            raise RuntimeError('Vendor DLL checksum mismatch; refusing hardware access.')
        dll_directory = os.add_dll_directory(str(ROOT))
        d = ctypes.WinDLL(str(path))
        for name in ['IniTemp', 'IsECSupport', 'GetKeyLight']:
            f = getattr(d, name); f.argtypes = []; f.restype = ctypes.c_int
        d.IniTemp()
        if d.IsECSupport() != 0:
            raise RuntimeError('EC signature does not match.')
        # These are the vendor read/write routines, verified against the DLL hash.
        read = ctypes.CFUNCTYPE(ctypes.c_short, ctypes.c_short)(d._handle + 0x76fd0)
        write = ctypes.CFUNCTYPE(None, ctypes.c_short, ctypes.c_short)(d._handle + 0x77050)
        last_level = None
        last_report = 0
        resets = 0
        while not STOP.exists():
            level = d.GetKeyLight()
            counter = read(0x26) & 255
            if level not in range(5) or counter > 150:
                raise RuntimeError('Unexpected EC state; stopped without further writes.')
            if level:
                write(0x26, 0)
                if (read(0x26) & 255) > 3:
                    raise RuntimeError('Idle counter reset verification failed.')
                resets += 1
            if level != last_level or time.monotonic() - last_report > 20:
                status(state='running', level=level, idle_counter=counter, resets=resets)
                last_report = time.monotonic()
            last_level = level
            for _ in range(40):
                if STOP.exists(): break
                time.sleep(0.1)
        status(state='disabled', level=last_level, resets=resets)
    except Exception:
        status(state='error', error=traceback.format_exc())
    finally:
        if dll_directory: dll_directory.close()
        kernel.CloseHandle(mutex)

if __name__ == '__main__':
    main()
