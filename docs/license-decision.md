# License decision pending / 许可证待确认

**Proposal:** MIT for the newly authored automation scripts, tests and documentation. It is concise and permits broad reuse with attribution and the license notice. Apache-2.0 is an alternative if an explicit patent grant is desired; choose based on the owner's distribution goals.

No LICENSE file is included until the owner confirms the license and copyright holder. This is a release blocker, not an assertion that the current repository is already open-source licensed.

OpenFOAM and ParaView are separate upstream projects with their own licenses. This repository does not include their source, binaries, installers or official tutorial files. Installing them or copying a tutorial locally does not relicense those works. Any future redistribution of upstream assets requires a separate license review.

建议新编写的自动化代码采用 MIT，最终由所有者确认，同时确认版权署名。尚未放入 LICENSE，公开发布前必须补齐。不会将 MIT 标记套用到 OpenFOAM、ParaView 或其他上游软件。

Pending approval fields:

- Repository name: `OpenFOAM-WSL2-AutoSetup`
- License and copyright holder: undecided
- Public scope: generic source/docs/tests only; no raw logs, private config or solver results
- Visibility: local only until approved
