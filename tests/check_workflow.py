"""Requires PyYAML; local configuration check, not a remote Actions run."""
from pathlib import Path
import yaml

root = Path(__file__).resolve().parents[1]
# BaseLoader avoids YAML 1.1 treating GitHub's `on` key as boolean True.
data = yaml.load((root / '.github/workflows/validate.yml').read_text(), Loader=yaml.BaseLoader)
assert set(data['on']) == {'push', 'pull_request', 'workflow_dispatch'}
assert data['permissions'] == {'contents': 'read'}
assert set(data['jobs']) == {'windows', 'linux'}
assert data['jobs']['windows']['steps'][1]['shell'] == 'powershell'
assert data['jobs']['linux']['runs-on'] == 'ubuntu-22.04'
print('PASS workflow YAML and intended permissions/jobs; remote execution not performed')
