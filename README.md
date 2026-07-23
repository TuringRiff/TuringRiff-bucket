# TuringRiff-bucket

[![CI Tests](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/ci.yml/badge.svg)](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/ci.yml)
[![Excavator](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/excavator.yml/badge.svg)](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/excavator.yml)

A personal [Scoop](https://scoop.sh) bucket for custom or hard-to-find Windows applications and tools.

[中文说明](README-zh.md)

## Available Apps

| App | Description | Homepage |
|:----|:-----------|:---------|
| [antigravity-manager](bucket/antigravity-manager.json) | Antigravity account manager and switching tool | [GitHub](https://github.com/lbjlaq/Antigravity-Manager) |
| [bili23-downloader](bucket/bili23-downloader.json) | Cross-platform Bilibili video downloader | [GitHub](https://github.com/ScottSloan/Bili23-Downloader) |
| [ccx](bucket/ccx.json) | Claude / Codex / Gemini API Proxy and Gateway | [GitHub](https://github.com/BenedictKing/ccx) |
| [chatwise](bucket/chatwise.json) | AI chatbot for many LLMs | [ChatWise](https://chatwise.app/) |
| [cockpit-tools](bucket/cockpit-tools.json) | Universal AI IDE account manager with multi-account switching and quota monitoring | [GitHub](https://github.com/jlcodes99/cockpit-tools) |
| [dashplayer](bucket/dashplayer.json) | A video player tailored for English learners | [GitHub](https://github.com/solidSpoon/DashPlayer) |
| [drop-icons](bucket/drop-icons.json) | Drag and drop image to icon (.ico) converter, with batch processing and adaptive corners | [GitHub](https://github.com/genesistoxical/drop-icons) |
| [flix](bucket/flix.json) | Chat-like cross-platform file transfer tool for fast sharing within local networks | [Flix](https://flix.center) |
| [helium](bucket/helium.json) | Chromium-based web browser focused on privacy, unbiased ad-blocking, and simplicity | [Helium](https://helium.computer) |
| [lx-music-desktop](bucket/lx-music-desktop.json) | Electron-based music player (LX Music Desktop) | [GitHub](https://github.com/lyswhut/lx-music-desktop) |
| [mpv-lazy](bucket/mpv-lazy.json) | Modern mpv player configurations, Chinese-localized setup, shaders, and filter integration | [GitHub](https://github.com/hooke007/mpv_PlayKit) |
| [pilinara](bucket/pilinara.json) | Flutter BiliBili desktop client forked from PiliPlus, with offline cache support | [GitHub](https://github.com/Starfallan/PiliNara) |
| [readest](bucket/readest.json) | Open-source ebook reader for immersive and deep reading experiences | [Readest](https://readest.com/) |
| [recordly](bucket/recordly.json) | Open-source screen recorder and editor for walkthroughs, demos, and product videos | [Recordly](https://recordly.dev/) |
| [sumatrapdf-plus](bucket/sumatrapdf-plus.json) | Unofficial SumatraPDF fork with Chinese ebook, offline lookup, themes, and smart PDF dark mode | [GitHub](https://github.com/dengxibo/sumatrapdf-plus) |
| [zedg](bucket/zedg.json) | Zed Editor (Localized / Chinese Translation) | [GitHub](https://github.com/x6nux/zed-globalization) |

## Usage

To use this bucket, you must have [Scoop](https://scoop.sh) installed.

### Add the bucket

```powershell
scoop bucket add TuringRiff-bucket https://github.com/TuringRiff/TuringRiff-bucket.git
```

### Install an application

```powershell
scoop install TuringRiff-bucket/<app-name>
```

## Maintenance (auto-update monitoring)

This bucket uses **Excavator** (`.github/workflows/excavator.yml`) on a schedule:

1. **Excavate** — Scoop `checkver -Update` (per-app failures are soft; the job can stay green).
2. **Detect outdated** — re-run `checkver -SkipUpdated` (read-only). Residual lag opens/updates a GitHub issue labeled **`manifest-outdated`**.
3. When lag is gone, that issue is closed automatically.

Hard workflow failures use the **`excavator-failure`** label.

Local checks (requires Scoop):

```powershell
.\bin\checkver.ps1 -SkipUpdated    # should print nothing if all apps are current
.\bin\detect-outdated.ps1          # markdown drift report
.\bin\checkver.ps1 <app> -u        # force-update one manifest
```

Do **not** set `THROW_ERROR=1` on Excavator for multi-app buckets: one broken app would block updates for all others.

## Contributing

Contributions are welcome! Please submit a Pull Request if you'd like to add or update an application manifest.

## License

This project is released into the public domain under the [Unlicense](LICENSE).
