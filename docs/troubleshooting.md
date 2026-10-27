# Troubleshooting / 故障排查与 FAQ

| Symptom / 现象 | Action / 处理 |
|---|---|
| `ADMIN_REQUIRED` | Reopen PowerShell as administrator for WSL provisioning only; no silent elevation. / 按提示人工提权。 |
| `RESTART_REQUIRED` | Save work and restart manually, then repeat the command. Do not clear registry flags. / 不自动重启或清理注册表标志。 |
| Linux account missing | Create the selected account interactively; enter password yourself. / 不把 `-LinuxUser` 参数名当成用户名。 |
| `ZSH_NAME: unbound variable` | Use `foam-exec.sh`; it defines ZSH_NAME and temporarily relaxes errexit/nounset/pipefail while sourcing. / 不修改 OpenFOAM 原文件。 |
| Source returns nonzero | Preserve the error and stop; installed package status is not environment acceptance. / 先查源加载日志，不直接重装。 |
| Interactive works but automation fails | Non-interactive Bash does not reliably read `.bashrc`; explicit loading is mandatory. / 本项目不修改 `.bashrc`。 |
| WSL localhost proxy warning | Read `.stderr.log`; judge command success by exit code and validated stdout, never by warning text. / 不自动修改代理。 |
| Garbled WSL diagnostic text | WSL may emit UTF-16 diagnostic bytes beside UTF-8 child stderr. Raw decoded logs may contain NULs; it does not contaminate stdout or change exit status. / 发行版列表单独按 UTF-16 解码。 |
| `apt` failure / key conflict | Keep logs; inspect existing repository/key configuration. No key-verification disabling, package-source deletion or automatic proxy change. / 自定义源需人工检查。 |
| Partially created repository files | Inspect the named key/list, then finish or repair manually. Existing files are preserved. / 不覆盖用户文件。 |
| Installer says verification failed although installed | Check `verify-before` and `verify-after` logs. Broken environment is separate from missing packages. / 不以 apt 退出 0 代替验收。 |
| `Mesh OK.` missing | Solver is not started even if checkMesh exits zero. / 需要网格检查证据。 |
| Duplicate/unknown ParaView | Same case cwd/command-line is reused. Other instances may have loaded the case through UI, so inspect or close them manually. / 不盲目开重复窗口。 |
| No WSLg display | Check DISPLAY, X11 socket, WAYLAND_DISPLAY and XDG_RUNTIME_DIR. Use a real unlocked Windows desktop. / 无图形时标记未验收。 |
| `pvpython` cannot import paraview | Ubuntu package can omit dist-packages from embedded Python's path; `view.py` adds the installed system package directory only when needed. / 本机实测此兼容处理，不全局修改 PYTHONPATH。 |
| Old shortcut after moving repo | Re-create a project-local shortcut pointing to the new launcher; existing shortcuts are intentionally not overwritten. / 仓库位置应保持固定。 |
| Restricted PowerShell execution | Review code and use organization-approved signing/execution procedures. Do not add Bypass or disable policy. |

## FAQ

**Is this OpenFOAM Foundation or OpenCFD?** Foundation 14 only. Package name `openfoam14`, environment `/opt/openfoam14/etc/bashrc`.

**Does a successful CFD run prove engineering accuracy?** No. The automated gates check successful tools, mesh-quality message, solver convergence message and result availability. Conservation, boundary conditions, model suitability and mesh independence require separate engineering review.

**Why does the original log report one fatal-marker match despite success?** A broad substring search matched normal `sigFpe` trap setup. New validation avoids that substring false positive and tests it explicitly. It still does not constitute a complete numerical stability audit.

**Can I use a different Ubuntu version, ARM64 or WSL1?** Not supported by this project's current acceptance scope. It stops instead of assuming compatibility.

**Does repeat execution rerun CFD?** A hash-verified successful case is reused. Missing or changed artifacts lead to a new attempt; previous files stay intact. Fixture tests cover failure recovery, but clean-PC interruption/reboot recovery is not yet tested.

**Why no bundled tutorial or results?** The official tutorial is obtained from the user's installed OpenFOAM package at runtime. This keeps release size small and avoids redistributing upstream content or private datasets.

**Is a private GitHub repository already created?** No. Current delivery is a local Git repository. The connected account search returned no visible matching repository; the direct lookup returned 404, which can also mean inaccessible. Recheck immediately before future creation.
