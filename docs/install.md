# Installation / 安装教程

## English: supported target

Windows 11 x64, hardware virtualization available, WSL2, Ubuntu-22.04 x86_64. Allow disk space for Ubuntu, OpenFOAM and runtime cases. Internet is needed only for installing missing packages. The code deliberately rejects other Ubuntu versions/architectures; do not infer support from upstream's wider support matrix.

### Unified workflow

1. Keep the repository in a stable local-drive directory. Keep runtime data in a different directory, e.g. `D:\OpenFOAM-Work`. Spaces in local paths are supported by the native argument helper; UNC/network paths are rejected.
2. Run `Install-OpenFOAM.ps1 -LinuxUser cfd -ProjectDirectory D:\OpenFOAM-Work -AllowInstall` from PowerShell, using your intended Linux username.
3. If WSL is missing, follow the printed administrator command. If Ubuntu is missing and the terminal is elevated, type `INSTALL` at the explicit prompt. The installer runs `wsl --install -d Ubuntu-22.04 --no-launch`, then stops for first-run setup/restart.
4. Open Ubuntu, create the exact selected username and enter its password yourself. If using an existing distro and the requested account does not exist, create it interactively: `wsl -d Ubuntu-22.04 -u root -- adduser cfd`, then `wsl -d Ubuntu-22.04 -u root -- usermod -aG sudo cfd`. These commands require operator action, not a password embedded in a script.
5. Rerun the entry point. It verifies Ubuntu and the user. Missing packages require `-AllowInstall` plus an `INSTALL` confirmation and interactive sudo. An installed but broken OpenFOAM environment is not silently reinstalled.
6. It loads OpenFOAM explicitly, runs executable help checks, copies the official tutorial into `$HOME/OpenFOAM/autosetup14/pitzDailySteady/attempt-.../case`, checks mesh quality and solves. Each failed attempt is retained. A completed result is reused only after log/result/mesh hashes match.
7. It creates local ParaView JSON, a shortcut, and optionally launches the viewer. The selected time is the maximum available positive time, never hard-coded to 285.

`-VerifyOnly` permits read-only environment checks even if a pending restart flag exists; installation/benchmark orchestration stops at that flag. No automatic reboot. After reboot, rerun the same command. The generic pending-rename marker may originate from unrelated software; inspect it rather than clearing registry flags.

### Manual sequence

Windows, elevated only for WSL installation:

```powershell
wsl --install -d Ubuntu-22.04
# Save work and restart manually if requested; finish Ubuntu first-run setup.
wsl --list --verbose
```

In Ubuntu, change to the repository's `/mnt/<drive>/...` directory:

```bash
bash scripts/linux/check-ubuntu.sh
bash scripts/linux/install-packages.sh "$HOME/OpenFOAM-setup-logs"
bash scripts/linux/verify.sh
python3 scripts/linux/benchmark.py
```

Return to PowerShell and run the unified entry point without `-AllowInstall` to validate, reuse the case and create the launcher. For an existing arbitrary case use the JSON template in `examples/` and `scripts/windows/Open-ParaView.ps1 -Config <path>`. Keep real JSON outside the repo.

Interactive shell initialization is optional. The project does not alter `.bashrc`. In an interactive Ubuntu shell, `source /opt/openfoam14/etc/bashrc` enables manual CFD commands. For automated commands use `bash scripts/linux/foam-exec.sh blockMesh -help`; it handles shell options and does not depend on `.bashrc`.

## 中文流程

1. 目标平台限定 Windows 11 x64、Ubuntu 22.04 x86_64。先保证 BIOS/固件虚拟化可用。仓库与运行工程分开保存，避免把运行数据提交到 Git。
2. 执行统一入口，指定实际 Linux 用户名和 Windows 工程目录。用户名只接受小写字母、数字、下划线与短横线，且不能以数字或短横线开头，不允许 root。
3. 缺少 WSL/发行版时按提示以管理员身份操作。出现重启要求时保存工作并人工重启，脚本不会代为操作。
4. Ubuntu 首次打开时自行输入用户名和密码。已有发行版缺少指定用户时，使用上面的 `adduser` 和 `usermod` 命令人工创建；不要向聊天、脚本或日志提供密码。
5. 再执行同一入口。包安装阶段需要明确输入 `INSTALL`，sudo 密码只在本机终端输入。包安装成功后继续单独验证环境。
6. 官方算例来自已经安装的 OpenFOAM 教程目录，复制到独立尝试目录。失败立即停止，保留日志，下一次创建新尝试目录；成功结果经哈希复核后跳过重算。
7. 桌面快捷方式打开最终时刻 U Magnitude。已有同名快捷方式不会覆盖；新快捷方式会放在工程目录。

手动安装可按上面的 Windows 与 Linux 命令分阶段执行。非交互脚本显式加载 OpenFOAM 环境，不能依赖 `.bashrc` 是否自动执行。

## References

- [OpenFOAM Foundation 14 Ubuntu packages](https://openfoam.org/download/14-ubuntu/): signed apt packages, official key and repository.
- [Microsoft WSL installation](https://learn.microsoft.com/en-us/windows/wsl/install): first-run account setup and manual restart.

Checked 2026-10-27. The new installer uses a scoped `signed-by` keyring and the `main` repository only. It preserves existing repository files rather than applying upstream cleanup commands automatically. This new provisioning branch has not been tested on a clean host.
