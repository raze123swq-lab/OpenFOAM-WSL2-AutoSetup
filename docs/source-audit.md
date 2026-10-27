# Source audit / 原工程审计

Reviewed 2026-10-27. Original project was read only; runtime validation uses separate directories. The source project, raw logs, desktop shortcut and local usernames are not copied into this repository.

| Source group | Evidence / classification | Publication decision |
|---|---|---|
| `42_verify_openfoam.sh`, `43_run_openfoam_verify.ps1` | Final 21:08 run: 22 PASS, 0 FAIL; executable help and interactive/explicit environment checks succeeded | Reimplement minimal explicit acceptance, no raw logs or private paths |
| `44_setup_bashrc.sh`, `45_run_bashrc_setup.ps1` | 21:07 interactive initialization succeeded | Learn separation of interactive and non-interactive loading; new project leaves `.bashrc` untouched |
| `50_run_benchmark.sh`, `51_run_benchmark.ps1` | blockMesh/checkMesh/foamRun exit 0, 12,225 cells, convergence at 285; mass balance unverified | Reimplement isolated runs and hash-based reuse; do not reuse unsafe existing-directory rerun behavior |
| `Open-OpenFOAM-ParaView.ps1`, `launch_paraview.py`, `benchmark_pitzDailySteady_view.py` | Prior desktop visual acceptance passed; repeated launcher reused PID | Generalize user/case/report paths and retain guarded instance detection |
| `40_install_openfoam14.sh`, `41_run_openfoam_install.ps1` | apt installation succeeded but original acceptance failed at undefined ZSH_NAME; final edited installer not clean-installed again | Historical installation evidence only; do not label edited installer end-to-end verified |
| `30_ubuntu_init.sh`, `31_run_ubuntu_init.ps1` | Earlier username parameter propagation defect; validation added later | Do not republish original account mutation code; interactive account handoff |
| `20_install_wsl_ubuntu.ps1`, `21_verify_wsl.ps1` | WSL2 eventually accepted, earlier false positive/negative capture defects | New separate stdout/stderr and exact distro/version parsing |
| `22_diag_kernel.ps1`, `23_diag_network.*`, `24_confirm_wsl_basics.ps1`, `10_detect_env.ps1` | Diagnostics only; contain machine-specific facts and logs | Summarize defects, exclude raw diagnostics |
| `90_run_all_stages.ps1` | Return-value pollution from Write-Output caused false failure | Excluded; helper returns exactly one result object |
| `91_run_with_network_waiver.ps1` | Historical workaround, not release baseline | Excluded; no network/security waiver mode |
| `02*`, `03*`, `04*`, `Start-OpenFOAM-Setup.ps1`, `_backup_*` | Legacy or failed intermediate versions | Excluded |
| `execution_state.json` | Stale stage flags conflict with later successful logs; includes unrelated private project details | Excluded; later concrete evidence takes precedence |
| `06_results`, `00_environment`, `07_reports` | Solver output, full paths, identities, diagnostics and rendered assets | Excluded; publish only sanitized factual summaries |
| Desktop `.lnk` | Absolute local script path | Excluded; generate on target host |

No old script is copied unchanged or represented as a validated generic installer. This repository's code is a new implementation informed by observed failure modes. A success in the source project is not inherited as a pass for newly written code. Source names are retained only as provenance references.

Specific safeguards: ASCII PowerShell; LF Bash; explicit OpenFOAM source in a child Bash; no `.bashrc` dependence; no source-status suppression; validated Linux username; no shell-built command strings for normal WSL calls; failure propagation; separate apt and acceptance stages; no automatic reboot, system policy changes or security bypass.
