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

## 贡献指南

欢迎提交 Pull Request 来添加或更新应用配置 (Manifest)。

## 许可证

本项目基于 [Unlicense](LICENSE) 发布至公共领域。
