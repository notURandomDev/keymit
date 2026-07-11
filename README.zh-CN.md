# KeyCadence

[English](README.md) | **简体中文**

KeyCadence 是一个隐私优先、数据仅存本机的 macOS 菜单栏应用。它按日期和应用统计
打字次数，并展示年度热力图和每日应用分布，但不会记录你按下的具体按键或输入的文字。

## 产品范围

- 今日打字次数、年度活跃热力图和应用分布
- 可选的 Backspace 删减统计，并保证累计与每日数据一致
- 英文和简体中文界面
- 可选开机自启动
- 带二次确认的本地统计清理
- 获得辅助功能授权后自动开始统计；监听被 macOS 暂停时自动恢复

KeyCadence 支持 macOS 13 及以上版本。全局按键计数需要辅助功能权限。事件监听为
只读模式，应用只会在本机 `UserDefaults` 中保存汇总次数和应用名称。

## 构建与测试

需要安装 Xcode Command Line Tools 或 Xcode。

```bash
swift test --disable-sandbox
./build.sh
open KeyCadence.app
```

`build.sh` 默认生成经过校验、使用临时签名的 arm64 + x86_64 通用应用。模块缓存和
中间产物均位于 `.build`，因此在受限环境和 CI 中也能稳定构建。

首次启动后，请在 **系统设置 → 隐私与安全性 → 辅助功能** 中允许 KeyCadence。
应用会自动识别授权并开始统计，无需重启。

由于 Release 使用 Ad Hoc 签名且未经过 Apple 公证，Gatekeeper 会阻止首次启动。
请按照 [INSTALL.md](INSTALL.md) 在系统设置中允许打开，并先核对 Release 页面公布的
SHA-256 校验值。

## 打包

生成仅供本地测试、不可公开分发的安装包：

```bash
./create-dmg.sh
```

使用 Ad Hoc 签名且经过本地校验的 DMG 和 SHA-256 文件会写入 `dist/`。GitHub
Release 流程和必须披露的限制见 [RELEASING.md](RELEASING.md)。

## 备份本地数据

退出 KeyCadence 后运行：

```bash
./backup-data.sh
```

脚本会生成一个私密的 `backups/KeyCadence-data-<时间戳>.tar.gz` 文件，其中包含
当前偏好域，以及在三个历史 Bundle ID 下找到的旧数据。也可以把目标 `.tar.gz`
路径作为第一个参数传入。

## 架构

- `Sources/Core/StatisticsStore.swift`：确定性的统计状态与数据约束，带单元测试
- `Sources/KeyTracker.swift`：权限生命周期、只读事件监听、应用归属、节流持久化和
  旧数据迁移
- `Sources/*View.swift`：SwiftUI 菜单面板、热力图和设置界面
- `Sources/AppPreferences.swift` / `LaunchManager.swift`：语言与 `SMAppService` 登录项
- `build.sh`、`create-dmg.sh`、`release.sh`：经过校验的 Ad Hoc 构建与 GitHub
  打包发布门禁
- `.github/workflows/ci.yml`：仅针对 PR 的核心测试和通用应用构建
- `.github/workflows/release.yml`：校验 `v*` 标签、生成 DMG 和校验文件，并自动创建
  GitHub Release

macOS 系统集成被限制在边界层，最容易造成用户数据损坏的状态变更则可独立测试。

## 数据兼容

已有的 `totalKey`、`appStats` 和 `dailyHistory` 偏好会继续保留。旧版每日总数会在
加载时迁移，异常负数会被修正；清空统计不会再误删语言或开机启动偏好。
