"""Produce an allowlisted, deterministic source/tester ZIP. Never package game files."""
import hashlib
import json
from pathlib import Path
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
FILES = ['README.md', 'Install.cmd', 'Start_LAN.cmd', 'Start_Local_PvP.cmd',
         '.gitignore', '.gitattributes', 'THIRD_PARTY.md', 'build.py', 'patch.csx', 'verify.csx',
         'rules.json', 'assets/manifest.json', 'assets/game-assets.json', 'release/compatibility.json']
TREES = {'gml': {'.gml'}, 'docs': {'.md'}, 'scripts': {'.ps1', '.py'},
         'tests': {'.cjs', '.py', '.ps1', '.gml', '.md'}, '.github': {'.yml', '.md'}}


def release_files(root=ROOT):
    paths = [root / name for name in FILES]
    for directory, extensions in TREES.items():
        paths.extend(p for p in (root / directory).rglob('*')
                     if p.is_file() and p.suffix in extensions and '__pycache__' not in p.parts)
    for p in paths:
        if not p.is_file() or p.is_symlink() or not p.resolve().is_relative_to(root.resolve()):
            raise ValueError(f'Missing or unsafe release source: {p}')
    return sorted(set(paths), key=lambda p: p.relative_to(root).as_posix())


def package(root=ROOT):
    config = json.loads((root / 'release/compatibility.json').read_text(encoding='utf-8'))
    version = config['package_version']
    import re
    if not re.fullmatch(r'\d+\.\d+\.\d+-test\.\d+', version):
        raise ValueError('Invalid package version')
    if json.loads((root / 'rules.json').read_text())['version'] != config['game_version']:
        raise ValueError('Gameplay/package version mismatch')
    for launcher in ['Start_LAN.cmd', 'Start_Local_PvP.cmd']:
        if f"play-v{config['game_version']}" not in (root / launcher).read_text():
            raise ValueError(f'Outdated launcher: {launcher}')
    prefix = f'SOUL-SWAP-{version}'
    files = release_files(root)
    content = {}
    for file in files:
        name = file.relative_to(root).as_posix()
        data = file.read_bytes()
        # Batch entry points work consistently when extracted on Windows.
        if file.suffix == '.cmd':
            data = data.replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
        content[name] = data
    manifest = {name: hashlib.sha256(data).hexdigest() for name, data in content.items()}
    content['PACKAGE-MANIFEST.json'] = json.dumps({'version': version, 'files': manifest}, indent=2).encode()
    output = root / 'dist'
    output.mkdir(exist_ok=True)
    archive = output / f'{prefix}.zip'
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for name, data in sorted(content.items()):
            info = zipfile.ZipInfo(f'{prefix}/{name}', date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, data)
    checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix('.zip.sha256').write_text(f'{checksum}  {archive.name}\n', encoding='ascii')
    print(f'{archive}\n{len(content)} files; {archive.stat().st_size:,} bytes\nSHA256 {checksum}')
    return archive


if __name__ == '__main__':
    try:
        package()
    except (OSError, ValueError) as error:
        print(f'PACKAGE FAILED: {error}', file=sys.stderr)
        raise SystemExit(1)
