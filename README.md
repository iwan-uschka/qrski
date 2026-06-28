# QRski

macOS native QR code generator. Built with Swift + SwiftUI, no external dependencies.

## Features

- QR code generation with full parameter control: version (1–40), mask pattern (auto/0–7), error correction (L/M/Q/H)
- Real-time preview with zoom slider and pinch-to-zoom
- Foreground/background color pickers; transparent background with checkerboard preview
- Export to PNG (configurable module size) and SVG
- Copy SVG to clipboard
- All settings persisted between launches

## Running (development)

Open `Package.swift` in Xcode (double-click or `open Package.swift`), then Build & Run (⌘R).

Or from the terminal: `swift build && .build/debug/QRski`

## Building a release app

```bash
bash make_app.sh
```

This produces `QRski.app` in the project root — a release binary assembled into a proper macOS app bundle, compiled asset catalog (icon), and ad-hoc signed.

**To share with colleagues:**
```bash
zip -r QRski.zip QRski.app
```

Recipients right-click → Open once to bypass Gatekeeper, then it runs normally.

## Menu bar

| Menu | Item | Shortcut |
|---|---|---|
| File | Export PNG… | ⌘⇧E |
| File | Export SVG… | — |
| Edit | Copy SVG | ⌘K |

## Architecture

| File | Role |
|---|---|
| `QRski.swift` | `@main` App entry, WindowGroup scene, menu commands |
| `AppState.swift` | `@Observable` model; UserDefaults persistence; triggers regeneration on change |
| `QRCodeGenerator.swift` | Thin Swift wrapper over libqrencode C API → `QRMatrix` |
| `ExportManager.swift` | PNG via CoreGraphics, SVG hand-rolled single `<path>`, NSSavePanel |
| `ContentView.swift` | `HSplitView` — controls left, preview right |
| `ControlsView.swift` | All parameters + export buttons |
| `QRPreviewView.swift` | `Canvas` rendering with zoom slider + `MagnificationGesture` |
| `AppCommands.swift` | `@FocusedValue` pattern for menu bar ↔ AppState bridge |
| **QRskiCore target** | |
| `QRskiCore/QRCodeGenerator.swift` | Core QR generation logic (shared library target) |
| `QRskiCore/ExportCore.swift` | Core export logic (shared library target) |

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
