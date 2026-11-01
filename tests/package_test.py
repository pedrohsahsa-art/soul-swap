"""Distribution regressions: allowlist, checksums, reproducibility and clean extraction."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('release_package', ROOT / 'scripts/package.py')
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class DistributionTests(unittest.TestCase):
    def setUp(self):
        preferred = Path(os.environ.get('LOCALAPPDATA', tempfile.gettempdir())) / 'Temp' / 'opencode'
        # The CI and other users use their own OS temporary directory.
        self.temp = tempfile.TemporaryDirectory(prefix='soul-swap-package-', dir=preferred if preferred.is_dir() else None)
        self.root = Path(self.temp.name)
        for p in release.release_files():
            dest = self.root / p.relative_to(ROOT)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(p, dest)

    def tearDown(self):
        self.temp.cleanup()

    def test_allowlist_excludes_installed_game_tools_and_private_files(self):
        for name in ['play-v0.8.0/data.win', 'build/patched.win', 'tools/runner.exe',
                     'assets/reference/sprite.png', '.logs/private.log', '.env', 'gml/secret.exe']:
            p = self.root / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(b'DO NOT DISTRIBUTE')
        archive = release.package(self.root)
        with zipfile.ZipFile(archive) as z:
            names = z.namelist()
            for name in names:
                self.assertNotIn('..', Path(name).parts)
                self.assertNotIn(Path(name).suffix, ['.win', '.exe', '.dll', '.ogg', '.dat', '.png', '.log'])
                self.assertNotEqual(b'DO NOT DISTRIBUTE', z.read(name))
            for required in ['Install.cmd', 'scripts/install.ps1', '.github/workflows/checks.yml',
                             'gml/network.gml', 'README.md', 'PACKAGE-MANIFEST.json']:
                self.assertTrue(any(n.endswith('/' + required) for n in names), required)

    def test_hash_manifest_and_zip_checksum_are_reproducible(self):
        archive = release.package(self.root)
        first = archive.read_bytes()
        with zipfile.ZipFile(archive) as z:
            manifest_path = next(n for n in z.namelist() if n.endswith('/PACKAGE-MANIFEST.json'))
            prefix = manifest_path.rsplit('/', 1)[0] + '/'
            manifest = json.loads(z.read(manifest_path))
            self.assertEqual(len(z.namelist()), len(manifest['files']) + 1)
            for name, digest in manifest['files'].items():
                self.assertEqual(hashlib.sha256(z.read(prefix + name)).hexdigest(), digest)
        release.package(self.root)
        self.assertEqual(first, archive.read_bytes())
        self.assertEqual(archive.with_suffix('.zip.sha256').read_text().split()[0], hashlib.sha256(first).hexdigest())

    def test_missing_installer_and_version_mismatch_fail(self):
        (self.root / 'Install.cmd').unlink()
        with self.assertRaises(ValueError):
            release.package(self.root)
        shutil.copyfile(ROOT / 'Install.cmd', self.root / 'Install.cmd')
        rules = json.loads((self.root / 'rules.json').read_text())
        rules['version'] = '99.0.0'
        (self.root / 'rules.json').write_text(json.dumps(rules))
        with self.assertRaises(ValueError):
            release.package(self.root)

    def test_compatibility_matches_compiler_and_test_sources(self):
        compatibility = json.loads((ROOT / 'release/compatibility.json').read_text())
        source = (ROOT / 'build.py').read_text()
        for file in ['chapter2_windows/data.win', 'DELTARUNE.exe']:
            self.assertIn(compatibility['files'][file], source)
        self.assertEqual(compatibility['game_version'], json.loads((ROOT / 'rules.json').read_text())['version'])
        for p in release.release_files():
            if p.suffix in ('.ps1', '.py', '.cmd') and p.name != 'package_test.py':
                self.assertNotIn('E:\\IA stuff', p.read_text(encoding='utf-8'), str(p))


if __name__ == '__main__':
    unittest.main()
