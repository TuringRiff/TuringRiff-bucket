# TuringRiff-bucket

[![CI Tests](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/ci.yml/badge.svg)](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/ci.yml)
[![Excavator](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/excavator.yml/badge.svg)](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/excavator.yml)

这是个人的 [Scoop](https://scoop.sh) 软件仓库（Bucket），主要用于收录一些自定义的、或者在官方仓库中找不到的 Windows 应用程序和工具。

[English README](README.md)

## 已收录应用

| 应用 | 描述 | 主页 |
|:----|:----|:----|
| [antigravity-manager](bucket/antigravity-manager.json) | Antigravity 账号管理器与切换工具 | [GitHub](https://github.com/lbjlaq/Antigravity-Manager) |
| [bili23-downloader](bucket/bili23-downloader.json) | 跨平台的 B 站视频下载工具 (Bilibili Video Downloader) | [GitHub](https://github.com/ScottSloan/Bili23-Downloader) |
| [ccx](bucket/ccx.json) | Claude / Codex / Gemini API 代理与网关 | [GitHub](https://github.com/BenedictKing/ccx) |
| [chatwise](bucket/chatwise.json) | 支持多种大语言模型的 AI 聊天客户端 | [ChatWise](https://chatwise.app/) |
| [cockpit-tools](bucket/cockpit-tools.json) | 通用 AI IDE 账号管理与切换工具，支持多账号切换和额度监控 | [GitHub](https://github.com/jlcodes99/cockpit-tools) |
| [dashplayer](bucket/dashplayer.json) | 为英语学习者量身打造的视频播放器 | [GitHub](https://github.com/solidSpoon/DashPlayer) |
| [drop-icons](bucket/drop-icons.json) | 拖拽式图像到图标 (.ico) 转换器，支持批量处理与现代样式 | [GitHub](https://github.com/genesistoxical/drop-icons) |
| [flix](bucket/flix.json) | Flix - 像聊天一样传文件。跨平台局域网设备间快速分享与文件传输工具 | [Flix](https://flix.center) |
| [helium](bucket/helium.json) | 基于 Chromium 的网页浏览器，默认提供极佳的隐私保护、无偏见广告拦截与无臃肿体验 | [Helium](https://helium.computer) |
| [lx-music-desktop](bucket/lx-music-desktop.json) | 基于 Electron 的洛雪音乐助手桌面版 | [GitHub](https://github.com/lyswhut/lx-music-desktop) |
| [mpv-lazy](bucket/mpv-lazy.json) | mpv-lazy 懒人包，整合了着色器与滤镜方案的 mpv 播放器中文配置 | [GitHub](https://github.com/hooke007/mpv_PlayKit) |
| [pilinara](bucket/pilinara.json) | 基于 PiliPlus 的 BiliBili Flutter 第三方桌面客户端，支持离线缓存 | [GitHub](https://github.com/Starfallan/PiliNara) |
| [readest](bucket/readest.json) | 开源电子书阅读器，专注沉浸式深度阅读体验 | [Readest](https://readest.com/) |
| [recordly](bucket/recordly.json) | 开源屏幕录制与编辑工具，适合演示、教程与产品视频 | [Recordly](https://recordly.dev/) |
| [sumatrapdf-plus](bucket/sumatrapdf-plus.json) | SumatraPDF 非官方增强版，针对中文电子书、离线查词、主题与 PDF 智能暗黑模式等做了增强 | [GitHub](https://github.com/dengxibo/sumatrapdf-plus) |
| [zedg](bucket/zedg.json) | Zed Editor 汉化版本 (Localized / 汉化版) | [GitHub](https://github.com/x6nux/zed-globalization) |

## 如何使用

在使用本仓库之前，请确保你已经安装了 [Scoop](https://scoop.sh)。

### 添加仓库

```powershell
scoop bucket add TuringRiff-bucket https://github.com/TuringRiff/TuringRiff-bucket.git
```

### 安装应用

```powershell
scoop install TuringRiff-bucket/<应用名称>
```

## 维护说明（自动更新监控）

本仓库通过 **Excavator**（`.github/workflows/excavator.yml`）定时更新：

1. **Excavate** — 运行 Scoop `checkver -Update`（单 app 失败为软错误，整次 job 仍可能是绿色）。
2. **Detect outdated** — 再跑 `checkver -SkipUpdated`（只读）。若仍有滞后，创建/更新带 **`manifest-outdated`** 标签的 Issue。
3. 滞后消除后，该 Issue 会自动关闭。

整次流水线硬失败使用 **`excavator-failure`** 标签。

本地自检（需已安装 Scoop）：

```powershell
.\bin\checkver.ps1 -SkipUpdated    # 全部最新时应无输出
.\bin\detect-outdated.ps1          # 生成滞后报告
.\bin\checkver.ps1 <app> -u        # 强制更新某个 manifest
```

多 app 的 bucket **不要**给 Excavator 开 `THROW_ERROR=1`：一个包失败会拖死整仓库更新。

## 贡献指南

欢迎提交 Pull Request 来添加或更新应用配置 (Manifest)。

## 许可证

本项目基于 [Unlicense](LICENSE) 发布至公共领域。
