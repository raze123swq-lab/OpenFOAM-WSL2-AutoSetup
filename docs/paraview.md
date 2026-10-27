# ParaView / 结果查看

The normal path is the shortcut created by the installer. A local runtime JSON can also be passed to `scripts/windows/Open-ParaView.ps1 -Config <absolute-path>`. The template in `examples/` contains placeholders; never commit a filled-in private configuration.

Viewer setup selects `internalMesh`, maximum available time, Surface representation and cell U Magnitude. It resets a parallel camera facing the channel and enables the scalar bar. A PNG and JSON receipt are stored under the configured runtime reports directory. Existing sessions are reused without resetting their current view.

## Visual acceptance / 图形验收

- ParaView window visible on Windows desktop / Windows 桌面可见窗口。
- Pipeline contains pitzDailySteady and data are visible / 管线已加载、数据可见。
- Time equals final solved time / 时间为最后求解时刻。
- Color is U, component Magnitude / 着色为 U 的 Magnitude。
- Full channel and scalar bar visible / 流道完整、标尺可见。

The process/JSON receipt is API evidence only. Until a human or desktop tool checks the actual window, record **visual acceptance required / 需要图形确认**. The original machine's earlier viewer passed this check; that does not automatically validate a fresh launch using new code or another PC.

## Pressure / 压力

Select the source in Pipeline Browser. Change the top coloring selector from `U` to `p`, then use **Rescale to Data Range**. Keep the last time selected. Interpret p using its dimensions and solver model; do not assume all OpenFOAM p fields are pressure in Pa.

在管线中选择数据源，将顶部 U 下拉框改为 p，再重新缩放色标。保持最终时间步。物理单位以场文件 dimensions 为准。

## PNG export / 导出

Use **File > Save Screenshot**, choose PNG and desired resolution. In the Linux file dialog, `/mnt/d/OpenFOAM-Work/reports/` corresponds to `D:\OpenFOAM-Work\reports\`. Use a new name rather than overwriting a previous image.

通过 File > Save Screenshot 导出 PNG，设置分辨率。推荐带时间戳命名。自动生成的图片是渲染输出，不应伪装为 Windows 桌面验收截图。
