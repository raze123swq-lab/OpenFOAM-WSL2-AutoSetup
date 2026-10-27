import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import uuid


def find_existing(case, proc_root=Path('/proc')):
    unknown = []
    for proc in proc_root.iterdir():
        if not proc.name.isdigit():
            continue
        try:
            if proc.stat().st_uid != os.getuid():
                continue
            args = (proc / 'cmdline').read_bytes().split(b'\0')
            if not args or Path(os.fsdecode(args[0])).name != 'paraview':
                continue
            if (proc / 'cwd').resolve() == case or str(case).encode() in b' '.join(args):
                return proc.name, unknown
            unknown.append(proc.name)
        except (OSError, ProcessLookupError):
            continue
    return None, unknown


def main(config_path):
    config = json.loads(Path(config_path).read_text())
    case = Path(config['case']).resolve(strict=True)
    reports = Path(config['reports'])
    reports.mkdir(parents=True, exist_ok=True)
    executable = shutil.which('paraview')
    if not executable:
        raise RuntimeError('ParaView missing')
    if not os.environ.get('DISPLAY') or not Path('/tmp/.X11-unix/X0').exists():
        raise RuntimeError('WSLg display missing; GUI not verified')
    digest = hashlib.sha256(str(case).encode()).hexdigest()[:16]
    # Private lock location; no world-writable predictable lock file.
    locks = Path.home() / '.cache/openfoam-autosetup'
    locks.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (locks / (digest + '.lock')).open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        existing, unknown = find_existing(case)
        if existing:
            print('EXISTING PID=' + existing + '; activate it from the taskbar. Current view preserved.')
            return
        # Unknown instances could have loaded this case after startup; do not guess.
        if unknown:
            raise RuntimeError('Other ParaView instances have unknown loaded cases. Inspect/close them before retrying: ' + ','.join(unknown))
        from benchmark import latest_time
        final = latest_time(case)
        for field in ('U', 'p'):
            if not (final / field).is_file():
                raise RuntimeError('Missing final field ' + field)
        try:
            with (case / 'benchmark.foam').open('x'):
                pass
        except FileExistsError:
            pass
        token = uuid.uuid4().hex
        result = reports / ('display-' + token + '.json')
        env = os.environ.copy()
        env.update(QT_QPA_PLATFORM='xcb', OF_AUTOCONFIG=str(Path(config_path).resolve()), OF_AUTORESULT=str(result))
        with (reports / ('paraview-' + token + '.log')).open('xb') as log:
            proc = subprocess.Popen([executable, '--script=' + config['viewer']], cwd=case, env=env, stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        for _ in range(60):
            if result.exists():
                data = json.loads(result.read_text())
                if data['status'] != 'success':
                    raise RuntimeError('Viewer configuration failed; see ' + str(result))
                print('CONFIGURED PID=' + str(proc.pid) + '; desktop visual acceptance still required. ' + str(result))
                return
            if proc.poll() is not None:
                raise RuntimeError('ParaView exited; see reports')
            time.sleep(1)
        raise RuntimeError('ParaView may still be running; configuration timed out. Inspect it before retrying.')


if __name__ == '__main__':
    try:
        main(sys.argv[1])
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
