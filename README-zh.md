# TuringRiff-bucket

[![CI Tests](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/ci.yml/badge.svg)](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/ci.yml)
[![Excavator](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/excavator.yml/badge.svg)](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/excavator.yml)

这是个人的 [Scoop](https://scoop.sh) 软件仓库，收录自定义的或官方仓库中没有的 Windows 应用与工具。

[English README](README.md)

## 使用方法

添加仓库：

```powershell
scoop bucket add TuringRiff-bucket https://github.com/TuringRiff/TuringRiff-bucket.git
```

安装应用：

```powershell
scoop install TuringRiff-bucket/<应用名称>
```

## 维护

清单由 [Excavator](.github/workflows/excavator.yml) 自动更新。仍有滞后的清单会通过带 `manifest-outdated` 标签的 Issue 跟踪，流水线硬失败使用 `excavator-failure` 标签。

本地检查（需已安装 Scoop）：

```powershell
.\bin\lint.ps1                  # 校验清单格式
.\bin\checkver.ps1 -SkipUpdated # 全部最新时应无输出
```

## 贡献

欢迎提交 Pull Request 添加或更新清单。

## 许可证

基于 [Unlicense](LICENSE) 发布至公共领域。
