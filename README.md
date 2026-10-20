# PCL2 下载恢复补丁

> ⚠️ **非官方补丁**，基于开源项目 [PCL2](https://github.com/Hex-Dragon/PCL2) 修改，仅解除官方自行加入的「原版 Minecraft 下载限制」。**与 PCL 官方无关**，请勿混淆。

PCL2 官方版因「遵守相关法律法规」关闭了原版 Minecraft 下载功能（打开下载页会提示 *"为遵守相关法律法规，PCL 暂时不再提供 MC 下载功能"*）。本补丁解除该限制，恢复原版下载 / 原版安装 / Forge / Fabric / NeoForge 安装。

## 下载

从右侧 **Releases** 下载最新版的补丁文件（`Plain Craft Launcher 2.exe`）。

## 使用方法（约 1 分钟）

1. 完全关闭 PCL2（启动器不要运行）。
2. 【建议】备份：把你原来的 `Plain Craft Launcher 2.exe` 复制一份到别处。
3. 把补丁的 `Plain Craft Launcher 2.exe` 复制到你的 PCL2 所在文件夹，**覆盖**原来的。
4. 重新启动 PCL2。
5. 进「设置 → 下载」，把下载源改成「**官方源优先**」或「仅使用官方源」
   （BMCLAPI 镜像已停止提供原版文件，必须用官方源才能下载）。

## 验证是否成功

打开「下载」页，能看到原版游戏版本列表（1.21.x / 26.x 等）即成功。

## 适用范围与已知限制

- 仅适用于 **PCL 2.99.0**（`Plain Craft Launcher 2.exe`，原版约 5.98MB）。
- ✅ 已恢复：原版下载、原版安装、Forge / Fabric / NeoForge 安装。
- ❌ 整合包下载安装：仍不可用（PCL 编译时已删除整合包安装逻辑，无法通过补丁恢复；需要装整合包请使用 HMCL 等其他启动器）。
- 其他非原版下载（Mod 下载、光影下载等）不受影响。

## 工作原理

PCL 源码 `Modules/ModSecret.vb` 中存在编译时常量 `RestrictMcDownload = True`，编译器将 `If RestrictMcDownload Then ...` 内联为 `If True Then ...` 并做分支消除：

- **原版下载**：下载页入口 `PageDownloadInstall.LoaderInit` 的正常分支（`DlClientListLoader`）仍在程序集中，只是被判断切走——补丁用 [dnlib](https://github.com/0xd4d/dnlib) 修改 IL，把「关闭下载 + 抛法律异常」的路径改回正常加载版本列表，即可恢复。
- **整合包安装**：正常逻辑在编译时已被删除，不存在于程序集中，无法通过 IL 补丁恢复。

补丁脚本见 `patch-download-fix.ps1`（透明化，可自行审查）。

## 回滚

想恢复官方原版：把你备份的原 exe 复制回来覆盖即可。

## 致谢与版权

- 基于 [PCL2](https://github.com/Hex-Dragon/PCL2) 修改，PCL2 版权归原作者所有，许可证见 PCL2 仓库的《PCL 分发有限许可》。
- 本补丁仅为解除下载限制，不包含 PCL 源码；按《PCL 存储库合理使用指南》重度使用要求，特此署名并声明与 PCL 官方无关联。
- 本仓库仅用于技术交流，请遵守 PCL 分发的相关条款。
