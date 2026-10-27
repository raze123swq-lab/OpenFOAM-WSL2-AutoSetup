# Architecture / 项目结构

```mermaid
flowchart TD
    A[PowerShell entry: user and runtime directory] --> B[Detect Windows / restart / WSL2 / Ubuntu]
    B --> C{Packages verified?}
    C -->|No, explicit install consent| D[Interactive sudo and apt]
    D --> E[Separate OpenFOAM acceptance]
    C -->|Yes| E
    E --> F[Isolated tutorial attempt with file lock]
    F --> G[blockMesh then checkMesh then foamRun]
    G --> H[Convergence / fields / hashes]
    H --> I[Local JSON and non-overwriting shortcut]
    I --> J[Existing-instance check / WSLg ParaView]
    J --> K[Python display receipt and PNG]
    K --> L[Human or desktop-tool visual acceptance]
```

| Path | Responsibility |
|---|---|
| `Install-OpenFOAM.ps1` | Windows orchestration and explicit human handoffs |
| `scripts/windows/Common.ps1` | Native argv quoting, separate stdout/stderr, scalar result, WSL state parsing |
| `scripts/windows/Open-ParaView.ps1` | Reusable launcher using private runtime JSON |
| `scripts/linux/check-ubuntu.sh` | Exact OS/architecture check |
| `scripts/linux/install-packages.sh` | Missing package installation; no blanket upgrade |
| `scripts/linux/foam-exec.sh` | Isolated explicit environment load; restores strict script options |
| `scripts/linux/verify.sh` | Independent installed-environment acceptance |
| `scripts/linux/benchmark.py` | Locks, attempts, solver exit checks, quality checks, result hashes |
| `scripts/linux/launch-viewer.py` | Case/WSLg validation, duplicate detection, launch result wait |
| `scripts/linux/view.py` | Final time, U Magnitude, camera, scalar bar, PNG and JSON receipt |
| `tests/` | Static, fixture and real-host checks |
| `examples/` | Placeholder configuration only; no upstream tutorial copies |
| `.github/workflows/` | Unprivileged static/fixture CI |
| `docs/` | Instructions, provenance, validation boundaries and release gates |

Runtime state belongs outside Git. Windows runtime contains timestamped logs, local configuration, PNG/JSON receipts and possibly a fallback shortcut. Linux runtime contains untouched failed attempts and successful cases. No global state file can override current environment verification.

Recovery means rerunning completed checks and reusing verified outputs. It does not mean continuing an interrupted solver from a partial time directory. A failing step stops subsequent stages. Package-manager interrupted transactions may require a manual `dpkg` repair; scripts never assume permission to change unrelated package state.
