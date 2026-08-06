# TuringRiff-bucket

[![CI Tests](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/ci.yml/badge.svg)](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/ci.yml)
[![Excavator](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/excavator.yml/badge.svg)](https://github.com/TuringRiff/TuringRiff-bucket/actions/workflows/excavator.yml)

A personal [Scoop](https://scoop.sh) bucket for custom or hard-to-find Windows applications and tools.

[中文说明](README-zh.md)

## Usage

Add the bucket:

```powershell
scoop bucket add TuringRiff-bucket https://github.com/TuringRiff/TuringRiff-bucket.git
```

Install an app:

```powershell
scoop install TuringRiff-bucket/<app-name>
```

## Maintenance

Manifests are kept up to date by [Excavator](.github/workflows/excavator.yml). Residual outdated manifests are tracked through `manifest-outdated` issues; hard failures use `excavator-failure`.

Local checks (requires Scoop):

```powershell
.\bin\lint.ps1                  # validate manifest format
.\bin\checkver.ps1 -SkipUpdated # should print nothing if all apps are current
```

## Contributing

Contributions are welcome. Submit a pull request to add or update a manifest.

## License

Released into the public domain under the [Unlicense](LICENSE).
