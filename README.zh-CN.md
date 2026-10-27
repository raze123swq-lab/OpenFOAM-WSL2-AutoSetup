# OpenFOAM-WSL2-AutoSetup

[English](README.md) · **预发布候选版** · [MIT 许可证](LICENSE)

为 Windows 11 x64 用户整理 WSL2 + Ubuntu 22.04 + OpenFOAM Foundation 14 的部署流程，在独立 Linux 目录运行官方 `pitzDailySteady` 算例，并通过 WSLg 在 Windows 桌面显示最终速度云图。

## 真实验证范围

| 项目 | 状态 |
|---|---|
| 原始电脑：已安装环境、原算例、原 ParaView 桌面显示 | 已验证，2026-10-27 |
| 新代码：统一入口只读检测、独立官方算例、成功结果重复复用 | 本机已验证 |
| 新代码：PowerShell 5.1、失败停止、故障恢复测试 | 本机已验证；恢复测试使用合成夹具 |
| 新代码：已有窗口识别、ParaView Python 渲染 | 本机已验证 |
| 新代码：首次创建 GUI 窗口的完整链路 | 尚未验证；保留了原窗口 |
| 新安装器：全新系统安装、管理员/密码交接、重启后恢复 | 尚未验证 |
| 第二台电脑 | **尚未验证** |
| GitHub Actions | Windows 与 Linux 验证已在 GitHub 运行通过；以最新提交的 Actions 状态为准 |
| CFD 质量守恒和工程物理可信度 | **尚未验收** |

该算例前后边界为 `empty`，属于薄层网格表示的二维流动，不应称为完整三维物理仿真。

## 一键入口

将仓库放在运行工程目录之外，在仓库根目录打开普通 PowerShell。将 `cfd` 换成实际 Ubuntu 用户名：

```powershell
.\Install-OpenFOAM.ps1 -LinuxUser cfd -ProjectDirectory D:\OpenFOAM-Work -VerifyOnly
.\Install-OpenFOAM.ps1 -LinuxUser cfd -ProjectDirectory D:\OpenFOAM-Work -AllowInstall
```

第二条是统一部署命令。需要管理员、重启、首次创建 Linux 用户或输入 sudo 密码时，脚本会提示用户操作；完成后重新执行同一命令。已装好环境时可省略 `-AllowInstall`。使用 `-SkipGui` 只准备结果和快捷方式。

不会自动重启、注销 Ubuntu、改变脚本执行策略、静默提权或保存密码。下载脚本应先审阅；执行受限时按组织的签名和安全要求处理，不使用执行策略绕过参数。

成功后双击桌面 **OpenFOAM CFD Results**。若已存在同名快捷方式，保留原文件，在工程目录创建带算例标识的新快捷方式。不要移动仓库目录，快捷方式依赖其中的启动器。

成功算例经文件哈希复核后复用；失败日志和结果保留在独立尝试目录，恢复时新建尝试目录。此恢复机制不是从中间求解时间继续计算。软件包安装完成后另行验收，不能只凭 apt 成功判定全部通过。

## 文档与测试

- [中英文安装教程及手动流程](docs/install.md)
- [结构与架构图](docs/architecture.md)
- [排错及 FAQ](docs/troubleshooting.md)
- [ParaView、压力场与 PNG 导出](docs/paraview.md)
- [历史脚本分类审计](docs/source-audit.md)
- [实际验收和测试矩阵](docs/acceptance.md)
- [发布清单及风险](docs/release-checklist.md)
- [许可证建议](docs/license-decision.md)

```powershell
.\tests\Test-Static.ps1
.\tests\Test-Host.ps1 -LinuxUser cfd -ProjectDirectory D:\OpenFOAM-Validation
```

Linux 单元测试与语法检查见英文 README。GitHub Actions 只执行静态和夹具测试，WSL2、真实求解器和图形验收需要真实 Windows 主机。

## 发布范围

只准备新编写的通用脚本、文档、测试与 CI 配置。原始日志、私人用户名、工程配置、求解结果、安装包、WSL 虚拟磁盘均不进入仓库。运行目录必须留在仓库之外。

新编写的代码、测试与文档经所有者确认采用 MIT，版权署名为 raze123swq-lab。OpenFOAM、ParaView 等上游软件保留各自许可，仓库不再分发它们。
