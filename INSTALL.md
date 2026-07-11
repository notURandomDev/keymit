# Installing KeyCadence / 安装 KeyCadence

KeyCadence is ad-hoc signed because it is an independent project without an
Apple Developer account. Apple has not notarized this app.

1. Drag `KeyCadence.app` to `Applications`.
2. Try to open it once. macOS will display a security warning.
3. Open **System Settings → Privacy & Security**, scroll to **Security**, and
   click **Open Anyway** for KeyCadence. Confirm **Open** when prompted.
4. KeyCadence appears in the menu bar. Follow its prompt to enable KeyCadence
   under **Privacy & Security → Accessibility** so it can count keystrokes.

Only override macOS security when the DMG came from the official KeyCadence
GitHub release and its SHA-256 checksum matches the checksum published there.

---

KeyCadence 是一个没有 Apple Developer 账号的独立项目，因此使用 Ad Hoc 签名，
并未经过 Apple 公证。

1. 将 `KeyCadence.app` 拖入“应用程序”文件夹。
2. 尝试打开一次，macOS 会显示安全警告。
3. 打开 **系统设置 → 隐私与安全性**，滚动到“安全性”，找到 KeyCadence 并点击
   **仍要打开**，然后在弹窗中确认打开。
4. KeyCadence 会出现在菜单栏。按照应用提示，在 **隐私与安全性 → 辅助功能** 中
   允许 KeyCadence，以便统计按键次数。

只有在 DMG 来自 KeyCadence 官方 GitHub Release，且 SHA-256 与 Release 页面公布的
校验值一致时，才应绕过 macOS 的安全限制。
