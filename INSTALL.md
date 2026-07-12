# Installing Keymit / 安装 Keymit

Keymit is ad-hoc signed because it is an independent project without an
Apple Developer account. Apple has not notarized this app.

1. Drag `Keymit.app` to `Applications`.
2. Try to open it once. macOS will display a security warning.
3. Open **System Settings → Privacy & Security**, scroll to **Security**, and
   click **Open Anyway** for Keymit. Confirm **Open** when prompted.
4. Keymit appears in the menu bar. Follow its prompt to enable Keymit
   under **Privacy & Security → Accessibility** so it can count keystrokes.

Only override macOS security when the DMG came from the official Keymit
GitHub release and its SHA-256 checksum matches the checksum published there.

---

Keymit 是一个没有 Apple Developer 账号的独立项目，因此使用 Ad Hoc 签名，
并未经过 Apple 公证。

1. 将 `Keymit.app` 拖入“应用程序”文件夹。
2. 尝试打开一次，macOS 会显示安全警告。
3. 打开 **系统设置 → 隐私与安全性**，滚动到“安全性”，找到 Keymit 并点击
   **仍要打开**，然后在弹窗中确认打开。
4. Keymit 会出现在菜单栏。按照应用提示，在 **隐私与安全性 → 辅助功能** 中
   允许 Keymit，以便统计按键次数。

只有在 DMG 来自 Keymit 官方 GitHub Release，且 SHA-256 与 Release 页面公布的
校验值一致时，才应绕过 macOS 的安全限制。
