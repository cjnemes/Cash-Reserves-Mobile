# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_all

datas = [('assets', 'assets'), ('*.md', '.')]
binaries = []
hiddenimports = []
tmp_ret = collect_all('matplotlib')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]


a = Analysis(
    ['reserve_manager_pro_v3.py'],
    pathex=[],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['ttkbootstrap', 'PyQt5', 'PyQt6', 'PySide2', 'PySide6', 'scipy', 'pandas', 'IPython', 'jupyter', 'requests', 'urllib3', 'cryptography'],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='Reserve Manager',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['assets/app.icns'],
)
coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='Reserve Manager',
)
app = BUNDLE(
    coll,
    name='Reserve Manager.app',
    icon='assets/app.icns',
    bundle_identifier='com.reservemanager.app',
)
