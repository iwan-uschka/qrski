# QRski

macOS native QR code generator. Built with Swift + SwiftUI, no external dependencies.

![QRski screenshot](https://github.com/user-attachments/assets/aea83f18-af45-4024-90c3-a22ed328a32b)

## Download

Pre-built releases (macOS app bundle, zipped) are available on the [Releases page](https://github.com/iwan-uschka/qrski/releases).

> **Note:** the app is unsigned — right-click → Open on first launch to bypass Gatekeeper.

## Features

- **Payload block system**: compose the QR payload from multiple text blocks with optional labels — edit only the part that changes without touching the rest
- QR code generation with full parameter control: version (1–40), mask pattern (auto/0–7), error correction (L/M/Q/H), quiet zone (0–8 modules)
- Real-time preview with zoom slider and pinch-to-zoom; optional viewport background matching
- Foreground/background color pickers; transparent background with checkerboard preview
- Export to PNG (configurable module size) and SVG
- Copy SVG to clipboard
- Automatic update check against GitHub Releases on launch
- All settings persisted between launches

## Building a release app

```bash
bash make_app.sh
```

This produces `QRski.app` in the project root — a release binary assembled into a proper macOS app bundle, compiled asset catalog (icon), and ad-hoc signed. The version is read automatically from the latest `[x.y.z]` entry in `CHANGELOG.md`.

## Publishing a release

```bash
bash make_release.sh
```

Builds the app, zips it as `QRski-vX.Y.Z.zip`, and prints the `gh release create` command to run. Release notes are extracted automatically from `CHANGELOG.md`.

## Dependencies

**libqrencode 4.1.1** — vendored in `Sources/CQREncode/`, no brew required.

Key C API used:

```c
QRinput *QRinput_new2(int version, QRecLevel level);  // version 0 = auto
int QRinput_append(input, QR_MODE_8, len, utf8_bytes);
QRcode *QRcode_encodeMask(input, mask);  // mask -1 = auto, 0–7 = specific
// qrcode->data[y*w + x] & 0x01 == 1 → dark module
QRcode_free(qrcode); QRinput_free(input);
```

`QRcode_encodeMask` comes from `qrencode_inner.h`. `STATIC_IN_RELEASE` is defined as empty in `Package.swift` `cSettings` to give it external linkage. A custom `module.modulemap` limits the Swift-visible module to the two public headers only.
