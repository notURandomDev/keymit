# KeyCadence

[English](README.md) | **[简体中文](README.zh-CN.md)**

KeyCadence 是一个 macOS 菜单栏应用，用于统计每日键盘敲击次数，并按应用维度展示分布。项目同时支持中英文本地化，并遵循原生玻璃材质的界面风格。

## 快速开始

### 从源码构建

```bash
# 构建应用
./build.sh

# 启动应用
open KeyCadence.app
```

### 权限设置

首次运行需在 **系统设置 → 隐私与安全 → 辅助功能** 中授权。重构建后（路径或签名变化）可能需要重新授权。

### 图标配置

在 `Assets` 目录下提供以下任一格式：

- `AppIcon.icns`
- `AppIcon.iconset`
- `AppIcon.png`（1024x1024）

## 功能特性

- 菜单栏窗口展示总敲击数与各应用占比
- 忽略修饰键、功能键、Backspace/Forward Delete 等非打字输入
- 按应用聚合统计，显示对应应用图标
- 设置页支持清空数据、切换语言（跟随系统/英文/中文简体）
- 切换语言时提供"需要重启"提示并可一键重启
- 原生 NSVisualEffectView 玻璃材质背景

## 架构总览

- 事件采集与数据层：全局键盘事件监听、过滤、聚合与持久化
- 展示层：SwiftUI 仪表盘与设置页
- 系统集成：菜单栏窗口、原生玻璃材质、可访问性权限、代码签名
- 本地化：基于 Localizable.strings 的多语言文案

## 模块说明

### KeyTracker（核心逻辑）

- 文件：[KeyTracker.swift](Sources/KeyTracker.swift)
- 职责：
  - 创建 CGEventTap 捕获全局按键，处理在主 RunLoop 中
  - 过滤规则：
    - 忽略 Backspace(51)、Forward Delete(117)、Caps Lock(57)、F1–F12(122–135)
    - 忽略含 Command/Control/Option 的组合键，忽略空字符事件
  - 应用识别：监听前台应用激活，记录 localizedName 与 bundleIdentifier 映射
  - 应用图标：优先通过 bundleIdentifier → URL 获取；退化到运行进程 bundleURL 或系统路径；最终兜底为系统应用图标
  - 持久化：UserDefaults 存储总数与分布；引入脏标记、定时器与计数器进行节流（100 次或每 2 秒保存），退出时强制保存

### DashboardView（仪表盘）

- 文件：[DashboardView.swift](Sources/DashboardView.swift)
- 职责：
  - 展示今日敲击总数与应用列表（进度条显示占比）
  - 打开设置窗口、退出应用按钮
  - 使用原生玻璃背景：根视图使用 underWindowBackground，列表项使用 contentBackground

### SettingsView（设置页）

- 文件：[SettingsView.swift](Sources/SettingsView.swift)
- 职责：
  - 切换语言（跟随系统/英文/中文简体）；选择后先弹窗说明需重启，取消不应用，确认写入并重启
  - 清空数据操作与确认弹窗
  - 使用原生玻璃背景

### SettingsWindowManager（设置窗口管理）

- 文件：[SettingsWindowManager.swift](Sources/SettingsWindowManager.swift)
- 职责：
  - 以 NSWindow 实现单实例设置窗口，避免多开
  - 注入语言环境与标题本地化；语言变更后更新窗口标题

### App 入口与场景

- 文件：[App.swift](Sources/App.swift)
- 职责：
  - 使用 MenuBarExtra 的 window 风格提供仪表盘窗口
  - 注册 Settings 场景并注入语言环境
  - 在菜单栏标签中实时显示总敲击数

### 偏好与重启

- **AppPreferences**：[AppPreferences.swift](Sources/AppPreferences.swift)
  - 存储语言选择（\_system/en/zh-Hans），提供 SwiftUI locale 环境
- **RestartHelper**：[RestartHelper.swift](Sources/RestartHelper.swift)
  - 通过 open 重新拉起应用并优雅退出当前进程

### 原生玻璃材质封装

- **GlassBackground**：[GlassBackground.swift](Sources/GlassBackground.swift)
  - 将 NSVisualEffectView 封装为 SwiftUI 背景，可配置 material 和 blendingMode

### 构建与资源

- **构建脚本**：[build.sh](build.sh)
  - 负责编译 Swift 源码、拷贝 Info.plist、复制本地化资源
  - 图标处理：支持 Assets/AppIcon.icns、AppIcon.iconset 或 1024x1024 PNG 自动打包
  - 执行 ad-hoc 签名，改善系统权限关联的稳定性
- **Info.plist**：[Info.plist](Info.plist)
  - 声明 LSUIElement 菜单栏应用、Bundle 图标与本地化区域
- **本地化资源**：
  - 英文：[en.lproj/Localizable.strings](Localization/en.lproj/Localizable.strings)
  - 中文（简体）：[zh-Hans.lproj/Localizable.strings](Localization/zh-Hans.lproj/Localizable.strings)
- **图标 Assets**：
  - 说明文档：[Assets/README.md](Assets/README.md)

## 本地化与语言切换

- 应用默认跟随系统语言；可在设置页手动选择语言
- 选择新语言后会弹窗提示需要重启；取消不生效，确认立即重启并应用

## 过滤规则说明

- **被统计的按键**：常规输入字符（包含 Shift 组合形成的大写或符号）
- **被忽略的按键**：
  - Backspace(⌫)、Forward Delete(⌦)
  - Caps Lock、F1–F12 功能键
  - 含 Command/Control/Option 修饰键的组合
  - 无字符的事件（例如部分系统键）

## 性能优化

- **写入节流**：每 2 秒或累计 100 次触发保存，退出时强制保存
- **图标缓存**：以 bundle identifier 优先作为键；缓存超过 128 项时做简单淘汰

## 贡献

- 欢迎提交 PR 与 Issue；建议在提交前运行构建脚本验证
- 如需添加更多本地化或配置项，可在 SettingsView 与 Localizable.strings 扩展

## 许可证

- 待补充（MIT/Apache-2.0 等）
