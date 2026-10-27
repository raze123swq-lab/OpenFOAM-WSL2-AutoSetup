import ast
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
count = 0
for path in root.rglob('*'):
    if '.git' in path.parts or not path.is_file():
        continue
    if path.suffix in ('.ps1', '.sh', '.py'):
        raw = path.read_bytes()
        assert not raw.startswith(b'\xef\xbb\xbf'), path
        if path.suffix == '.sh':
            assert b'\r' not in raw, path
            subprocess.run(['bash', '-n', str(path)], check=True)
        if path.suffix == '.py':
            ast.parse(raw.decode('utf-8'), filename=str(path))
        count += 1
print('PASS source syntax/encoding:', count, 'scripts')
