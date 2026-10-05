# QRski agent context

See README.md for full project docs and architecture.

## Key non-obvious decisions

- `QRcode_encodeMask` (mask control) is in `qrencode_inner.h`, not the public header. `STATIC_IN_RELEASE=""` in cSettings gives it external linkage so Swift can call it.
- `module.modulemap` exposes only `qrencode.h` + `qrencode_inner.h`. The other C headers use `size_t` without including `<stddef.h>` and fail when the Swift module system imports them directly.
- `@ObservationIgnored var isInitializing` in `AppState` prevents `didSet` side-effects from firing during `init()`, where `@Observable` calls setters even on first assignment.
- `QRCodeGenerator.generate` takes `ErrorCorrectionLevel` (the Swift enum), not the raw `QRecLevel` C type. Call sites must not add `.cValue`.
- SVG output omits the background (no `<rect fill="white">`) when `isTransparentBg` is true. The caller checks `effectiveBgColor`, which returns `nil` for transparent.
