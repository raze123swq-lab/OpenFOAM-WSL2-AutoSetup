# OpenFOAM-WSL2-AutoSetup

[中文](README.zh-CN.md) · **Pre-release / license decision pending / local repository only**

Prepare Windows 11 x64 + WSL2 + Ubuntu 22.04 + OpenFOAM Foundation 14, run the official `incompressibleFluid/pitzDailySteady` tutorial in an isolated Linux directory, and view the final U Magnitude field in ParaView through WSLg.

## Validation status

| Scope | Status |
|---|---|
| Original PC: installed stack, original CFD run and desktop ParaView | Verified, 2026-10-27 |
| New project on original PC: read-only entry point, independent CFD run, repeat execution | Verified |
| New project: fixture failure recovery, PowerShell 5.1 syntax/native process handling | Verified locally |
| New project: ParaView existing-instance detection and Python rendering | Verified locally |
| New project: fresh GUI launch end to end | Not yet validated; original viewer left open |
| New installer on a clean PC, package install, restart and password handoffs | Not yet validated |
| Second PC | **Not tested** |
| GitHub Actions | Configuration prepared; no remote run yet |
| CFD mass balance / physical validation | **Not assessed** |

This is a reproducibility candidate, not a production-certified installer. The tutorial uses `empty` front/back boundaries: it is a two-dimensional flow represented by a thin mesh, not a full 3D flow validation.

## Quick start

Keep this repository outside your runtime project directory. Open normal Windows PowerShell in the repository folder. Replace `cfd` with your actual Ubuntu username:

```powershell
.\Install-OpenFOAM.ps1 -LinuxUser cfd -ProjectDirectory D:\OpenFOAM-Work -VerifyOnly
.\Install-OpenFOAM.ps1 -LinuxUser cfd -ProjectDirectory D:\OpenFOAM-Work -AllowInstall
```

The second command is the unified deployment entry point. It pauses for administrator access, manual restart, first-run Linux account/password setup, or interactive sudo when required. Rerun the same command after completing the requested action. It never changes execution policy, restarts Windows/WSL, stores passwords, or silently elevates. Existing verified packages are reused. Review downloaded scripts and follow your organization's script-signing policy if execution is restricted.

On an already installed machine omit `-AllowInstall`. Use `-SkipGui` to prepare results and a shortcut without launching a window. `-VerifyOnly` does not install, run CFD, or change shell initialization; it only creates local diagnostic logs.

Successful setup creates a desktop **OpenFOAM CFD Results** shortcut. An existing shortcut is preserved; a case-specific shortcut is created in the project directory instead. Keep the repository at its original location, since the shortcut references its launcher. Runtime JSON and logs contain local paths and must not be published.

## Guides

- [Installation: English and Chinese, automatic and manual](docs/install.md)
- [Architecture and file structure](docs/architecture.md)
- [Troubleshooting and FAQ](docs/troubleshooting.md)
- [ParaView usage and visual acceptance](docs/paraview.md)
- [Source audit and historical defects](docs/source-audit.md)
- [Actual acceptance record and test matrix](docs/acceptance.md)
- [Release checklist and disclosure risks](docs/release-checklist.md)
- [License proposal](docs/license-decision.md)

## Tests

```powershell
.\tests\Test-Static.ps1
.\tests\Test-Host.ps1 -LinuxUser cfd -ProjectDirectory D:\OpenFOAM-Validation
```

In Ubuntu, from the repository directory:

```bash
python3 tests/check_sources.py
python3 -m unittest discover -s tests -p 'test_*.py' -v
bash scripts/linux/verify.sh
python3 scripts/linux/benchmark.py
python3 scripts/linux/benchmark.py  # must reuse a valid successful result
```

Fixture tests do not run CFD. Host commands do. A successful process launch is not GUI acceptance: check the visible pipeline, final time, U Magnitude, full channel and scalar bar.

## Upstream and licensing

Installation follows the [OpenFOAM Foundation Ubuntu 14 instructions](https://openfoam.org/download/14-ubuntu/) and [Microsoft WSL installation instructions](https://learn.microsoft.com/en-us/windows/wsl/install), checked on 2026-10-27. This project does not redistribute OpenFOAM, ParaView, WSL, installers or tutorial files. The tutorial is copied from the locally installed OpenFOAM package at runtime. Upstream software retains its own licenses.

MIT is proposed for the newly authored automation code, subject to owner confirmation. **No LICENSE has been granted yet; do not publish or label this repository MIT-licensed until that decision is recorded.**
