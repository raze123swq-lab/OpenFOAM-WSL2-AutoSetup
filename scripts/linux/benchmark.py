"""Run an isolated official tutorial. Never reuse or overwrite foreign cases."""
import argparse
import datetime
import fcntl
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid

HERE = Path(__file__).resolve().parent
TUTORIAL = Path('/opt/openfoam14/tutorials/incompressibleFluid/pitzDailySteady')


def latest_time(case):
    times = []
    for item in Path(case).iterdir():
        try:
            value = float(item.name)
        except ValueError:
            continue
        if item.is_dir() and math.isfinite(value) and value > 0:
            times.append((value, item))
    if not times:
        raise RuntimeError('No positive result time directory')
    return max(times, key=lambda pair: pair[0])[1]


def validate(case):
    case = Path(case)
    final = latest_time(case)
    for name in ('U', 'p'):
        if not (final / name).is_file() or (final / name).stat().st_size == 0:
            raise RuntimeError('Missing final field: ' + name)
    meshlog = (case / 'log.checkMesh').read_text(errors='replace')
    solverlog = (case / 'log.foamRun').read_text(errors='replace')
    if 'Mesh OK.' not in meshlog:
        raise RuntimeError('checkMesh did not report Mesh OK.')
    if not re.search(r'^End\s*$', solverlog, re.M) or 'SIMPLE solution converged' not in solverlog:
        raise RuntimeError('Solver did not finish with a convergence message')
    # Do not match legitimate sigFpe trap configuration or substrings such as "info".
    if re.search(r'FOAM FATAL|^Floating point exception|Segmentation fault|(?<!\w)(?:nan|[+-]?inf)(?!\w)', solverlog, re.I | re.M):
        raise RuntimeError('Solver log contains a fatal/non-finite marker')
    files = [final / 'U', final / 'p', case / 'log.blockMesh', case / 'log.checkMesh', case / 'log.foamRun']
    files += [case / 'constant/polyMesh' / n for n in ('points', 'faces', 'owner', 'neighbour', 'boundary')]
    hashes = {str(p.relative_to(case)): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
    return {'time': float(final.name), 'hashes': hashes, 'physical_validation': 'not_assessed'}


def run_benchmark(root, source=TUTORIAL, runner=None):
    root = Path(root).expanduser().resolve()
    if root.exists() and not (root / '.autosetup-owned').is_file():
        raise RuntimeError('Refusing existing unowned benchmark directory')
    root.mkdir(parents=True, exist_ok=True)
    (root / '.autosetup-owned').touch(exist_ok=True)
    with (root / '.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        for record in sorted(root.glob('attempt-*/success.json'), reverse=True):
            case = record.parent / 'case'
            try:
                old = json.loads(record.read_text())
                current = validate(case)
                if current['hashes'] == old['hashes']:
                    return {'case': str(case), 'reused': True, 'time': current['time']}
            except (OSError, RuntimeError, ValueError, KeyError):
                pass
        attempt = root / ('attempt-' + datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S') + '-' + uuid.uuid4().hex[:8])
        attempt.mkdir()
        case = attempt / 'case'
        try:
            shutil.copytree(source, case)
            for command in ('blockMesh', 'checkMesh', 'foamRun'):
                with (case / ('log.' + command)).open('xb') as log:
                    if runner is None:
                        completed = subprocess.run(['bash', str(HERE / 'foam-exec.sh'), command], cwd=case, stdout=log, stderr=subprocess.STDOUT)
                        code = completed.returncode
                    else:
                        code = runner(command, case, log)
                if code != 0:
                    raise RuntimeError(command + ' failed: ' + str(code))
                if command == 'checkMesh' and 'Mesh OK.' not in (case / 'log.checkMesh').read_text(errors='replace'):
                    raise RuntimeError('checkMesh failed quality checks; solver not started')
            result = validate(case)
            (attempt / 'success.json').write_text(json.dumps(result, indent=2))
            return {'case': str(case), 'reused': False, 'time': result['time']}
        except Exception as exc:
            (attempt / 'failure.txt').write_text(str(exc))
            raise


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default=str(Path.home() / 'OpenFOAM/autosetup14/pitzDailySteady'))
    args = parser.parse_args()
    try:
        print(json.dumps(run_benchmark(args.root)))
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
