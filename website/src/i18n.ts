export type Lang = "zh" | "en";

const zh = {
  lang: "zh" as Lang,
  htmlLang: "zh-CN",
  title: "Keymit — 隐私优先的键盘敲击统计",
  description:
    "Keymit 是一款隐私优先的 macOS 菜单栏应用，按天、按应用统计键盘敲击次数，数据只保存在本机。",
  nav: {
    github: "GitHub",
    switch: "EN",
    switchHref: "/en/",
  },
  hero: {
    tagline: "你的键盘，只有你知道",
    subtitle:
      "Keymit 是一款隐私优先的 macOS 菜单栏应用，按天、按应用统计你的键盘敲击次数，用年度热力图呈现你的输入节奏。所有数据只保存在本机。",
    download: "下载 macOS 版",
    source: "查看源码",
    requirement: "需要 macOS 13 或更高版本 · 当前版本 v1.0.0",
  },
  features: {
    heading: "功能",
    sub: "只做一件事，并把它做好。",
    items: [
      {
        icon: "⌨️",
        title: "每日按键总量",
        desc: "在菜单栏实时查看今天敲了多少次键盘，按天积累你的输入记录。",
      },
      {
        icon: "🗓️",
        title: "年度活动热力图",
        desc: "以 GitHub 贡献图风格的热力图回顾一整年的输入节奏，哪天高产一目了然。",
      },
      {
        icon: "🧩",
        title: "按应用分布",
        desc: "看看你的键盘时间都花在了哪些应用里，按应用查看每日敲击分布。",
      },
      {
        icon: "⌫",
        title: "Backspace 减计",
        desc: "可选开启：按退格键时减一次计数，让总量与每日数据保持一致。",
      },
      {
        icon: "🔁",
        title: "自动恢复",
        desc: "辅助功能授权完成后，或 event tap 被系统禁用后，Keymit 会自动恢复监听。",
      },
      {
        icon: "🌐",
        title: "中英双语界面",
        desc: "界面支持简体中文和英文，可选开机自启，也可在确认后重置本地数据。",
      },
    ],
  },
  privacy: {
    heading: "隐私承诺",
    sub: "只听声音，不读内容。",
    points: [
      {
        title: "不记录按键内容",
        desc: 'Keymit 的 event tap 是只听的：它只统计"敲了一次"，从不记录你按了哪个键、输入了什么文本。',
      },
      {
        title: "数据不出本机",
        desc: "只有聚合计数和应用名，保存在本机的 UserDefaults 里。没有账号、没有上传、没有分析SDK。",
      },
      {
        title: "随时可以清空",
        desc: "在应用内确认后即可重置全部本地数据，一切由你掌控。",
      },
    ],
  },
  heatmap: {
    heading: "一年的输入，一眼看完",
    sub: "演示数据 — 应用内的热力图由你的真实敲击生成。",
    less: "少",
    more: "多",
  },
  install: {
    heading: "安装",
    sub: "Keymit 是 ad-hoc 签名、未经过苹果公证，首次打开需要一次手动确认。",
    steps: [
      "从 GitHub Releases 下载 DMG，打开后将 Keymit 拖入「应用程序」。",
      '首次打开会被 Gatekeeper 拦截，看到"无法打开"的警告，属正常现象。',
      "前往 系统设置 → 隐私与安全性 → 安全性，点击「仍要打开」。",
      "再在 系统设置 → 隐私与安全性 → 辅助功能 中允许 Keymit。",
      "菜单栏出现 Keymit 图标，即开始统计。",
    ],
    warning:
      "请只在 DMG 来自官方 GitHub Release、且 SHA-256 校验值与下方一致时，才绕过 Gatekeeper 打开应用。",
  },
  download: {
    heading: "下载",
    versionLabel: "版本",
    platformLabel: "平台",
    platform: "macOS 13+（Apple Silicon / Intel）",
    shaLabel: "SHA-256",
    verifyLabel: "下载后在终端验证：",
    verifyCmd: "shasum -a 256 Keymit-1.0.0.dmg",
    button: "前往 GitHub Releases 下载",
  },
  footer: {
    copyright: "© {year} Keymit. 保留所有权利。",
    github: "GitHub",
  },
};

const en: typeof zh = {
  lang: "en",
  htmlLang: "en",
  title: "Keymit — Privacy-first Keystroke Counter",
  description:
    "Keymit is a privacy-first macOS menu bar app that counts your keystrokes per day and per app. All data stays on your Mac.",
  nav: {
    github: "GitHub",
    switch: "中文",
    switchHref: "/",
  },
  hero: {
    tagline: "Your keyboard. Only you know.",
    subtitle:
      "Keymit is a privacy-first macOS menu bar app that counts your keystrokes per day and per app, and renders your typing rhythm as a yearly heatmap. All data stays on your Mac.",
    download: "Download for macOS",
    source: "View Source",
    requirement: "Requires macOS 13 or later · Current version v1.0.0",
  },
  features: {
    heading: "Features",
    sub: "Does one thing, and does it well.",
    items: [
      {
        icon: "⌨️",
        title: "Daily Keystroke Totals",
        desc: "See today’s keystroke count right in the menu bar, accumulated day by day.",
      },
      {
        icon: "🗓️",
        title: "Yearly Activity Heatmap",
        desc: "Review a whole year of typing rhythm in a GitHub-style contribution heatmap.",
      },
      {
        icon: "🧩",
        title: "Per-App Breakdown",
        desc: "See which apps your keyboard time goes to, with a daily breakdown per app.",
      },
      {
        icon: "⌫",
        title: "Backspace Deduction",
        desc: "Optional: pressing Backspace subtracts one from the count, keeping totals consistent with daily data.",
      },
      {
        icon: "🔁",
        title: "Automatic Recovery",
        desc: "Keymit resumes listening automatically after Accessibility permission is granted, or after macOS disables the event tap.",
      },
      {
        icon: "🌐",
        title: "Bilingual UI",
        desc: "Interface in Simplified Chinese and English, with optional launch at login and a confirmed reset of local data.",
      },
    ],
  },
  privacy: {
    heading: "Privacy Promise",
    sub: "It listens. It never reads.",
    points: [
      {
        title: "No key content recorded",
        desc: "Keymit’s event tap is listen-only: it counts “one keystroke” and never records which key you pressed or what you typed.",
      },
      {
        title: "Data never leaves your Mac",
        desc: "Only aggregate counts and app names, stored locally in UserDefaults. No account, no uploads, no analytics SDKs.",
      },
      {
        title: "Erase anytime",
        desc: "Reset all local data in the app after a confirmation. You stay in control.",
      },
    ],
  },
  heatmap: {
    heading: "A year of typing at a glance",
    sub: "Demo data — the heatmap in the app is generated from your real keystrokes.",
    less: "Less",
    more: "More",
  },
  install: {
    heading: "Installation",
    sub: "Keymit is ad-hoc signed and not notarized, so the first launch needs one manual confirmation.",
    steps: [
      "Download the DMG from GitHub Releases, open it, and drag Keymit into Applications.",
      'The first launch is blocked by Gatekeeper with a "cannot be opened" warning — this is expected.',
      'Go to System Settings → Privacy & Security → Security, and click "Open Anyway".',
      "Then allow Keymit under System Settings → Privacy & Security → Accessibility.",
      "The Keymit icon appears in the menu bar and counting begins.",
    ],
    warning:
      "Only bypass Gatekeeper when the DMG comes from the official GitHub Release and its SHA-256 matches the checksum below.",
  },
  download: {
    heading: "Download",
    versionLabel: "Version",
    platformLabel: "Platform",
    platform: "macOS 13+ (Apple Silicon / Intel)",
    shaLabel: "SHA-256",
    verifyLabel: "Verify after downloading in Terminal:",
    verifyCmd: "shasum -a 256 Keymit-1.0.0.dmg",
    button: "Download from GitHub Releases",
  },
  footer: {
    copyright: "© {year} Keymit. All rights reserved.",
    github: "GitHub",
  },
};

export const dict = { zh, en };
export type Dict = typeof zh;
