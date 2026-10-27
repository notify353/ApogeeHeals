"""Keep the standalone validator strict about its shared UI source dependency."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('pwsh') and shutil.which('lua'), 'PowerShell and Lua required')
class LocalRunnerTests(unittest.TestCase):
    def test_invalid_dependency_contracts_stop_before_runtime_checks(self):
        toc = (ROOT / 'ApogeeHeals.toc').read_text(encoding='utf-8')
        dep = '## Dependencies: ApogeeUI'
        api = '## X-Apogee-UI-API: 1'
        cases = [
            ('missing', toc.replace(dep, ''), 'Expected exactly'),
            ('duplicate', toc.replace(dep, dep + '\n' + dep), 'Expected exactly'),
            ('dev-family', toc.replace(dep, dep + 'Dev'), 'Expected exactly'),
            ('extra', toc.replace(dep, dep + ', AnotherAddon'), 'Expected exactly'),
            ('optional', toc.replace(dep, '## OptionalDeps: ApogeeUI'), 'Unexpected dependency'),
            ('wrong-api', toc.replace(api, '## X-Apogee-UI-API: 2'), 'interface version 1'),
            ('missing-api', toc.replace(api, ''), 'interface version 1'),
            ('duplicate-api', toc.replace(api, api + '\n' + api), 'interface version 1'),
        ]
        for label, invalid, expected in cases:
            with self.subTest(label=label), tempfile.TemporaryDirectory() as directory:
                folder = Path(directory)
                (folder / 'scripts').mkdir()
                shutil.copyfile(ROOT / 'scripts/test-local.ps1', folder / 'scripts/test-local.ps1')
                (folder / 'ApogeeHeals.toc').write_text(invalid, encoding='utf-8')
                result = subprocess.run(
                    ['pwsh', '-NoProfile', '-File', str(folder / 'scripts/test-local.ps1')],
                    cwd=folder, capture_output=True, text=True, encoding='utf-8', errors='replace',
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(expected, result.stdout + result.stderr)
                self.assertNotIn('Missing TOC file:', result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
