"""Scan Git-tracked release files. Reports locations, never secret values."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--deny', action='append', default=[], help='Additional private text; not written to report')
parser.add_argument('--output', type=Path, help='Write scan outside repository')
args = parser.parse_args()
names = subprocess.check_output(['git', '-C', str(root), 'ls-files', '-z']).decode().split('\0')
patterns = {
    'private-key': re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'github-token': re.compile(r'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})\b'),
    'aws-key': re.compile(r'\bAKIA[0-9A-Z]{16}\b'),
    'windows-user-path': re.compile(r'[A-Za-z]:[\\/]Users[\\/][^\s/\\]+', re.I),
    'credential-url': re.compile(r'https?://[^\s/@:]+:[^\s/@]+@'),
}
manifest, findings = [], []
for name in filter(None, names):
    path = root / name
    raw = path.read_bytes()
    text = raw.decode('utf-8', errors='replace')
    manifest.append({'path': name, 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
    if len(raw) > 1024 * 1024:
        findings.append({'path': name, 'kind': 'over-1MiB'})
    if path.suffix.lower() in {'.vhdx', '.vhd', '.exe', '.msi', '.deb', '.iso', '.log', '.lnk', '.pem', '.key'}:
        findings.append({'path': name, 'kind': 'forbidden-release-type'})
    for label, pattern in patterns.items():
        if pattern.search(text):
            findings.append({'path': name, 'kind': label})
    for private in args.deny:
        boundary = r'(?<![A-Za-z0-9_-])' + re.escape(private) + r'(?![A-Za-z0-9_-])'
        if re.search(boundary, text, re.I):
            findings.append({'path': name, 'kind': 'private-denylist-match'})
result = {'files': manifest, 'file_count': len(manifest), 'total_bytes': sum(x['bytes'] for x in manifest), 'findings': findings, 'license_present': (root / 'LICENSE').exists(), 'license_status': 'MIT_owner_approved', 'remote_ci': 'not_run', 'second_pc': 'not_tested'}
serialized = json.dumps(result, indent=2)
if args.output:
    if args.output.resolve().is_relative_to(root):
        raise SystemExit('Scan output must stay outside the repository')
    args.output.write_text(serialized)
print(json.dumps({k: v for k, v in result.items() if k != 'files'}, indent=2))
sys.exit(1 if findings else 0)
