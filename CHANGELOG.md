# Changelog

## [Unreleased]

## [1.1.1] - 2026-06-29

### Added
- Export consolidated into a single overlay menu button (↓ icon) on the preview panel — replaces three separate export buttons; menu has Export (PNG, SVG) and Copy (SVG) sections
- PNG save dialog now includes a live module size slider with output dimensions label; chosen size is applied after the dialog closes
- Tab / Shift+Tab advances and retreats focus in payload text fields (custom `NSTextView` wrapper)
- README: screenshot and Download section linking to the Releases page

### Fixed
- Silent PNG export failure now surfaces an `NSAlert` instead of returning silently
- Module size chosen in the PNG dialog is written back to `AppState` via callback and persists across exports
- `NSSlider` in PNG export dialog snaps to integer positions (tick marks)
- Checkerboard preview now correctly scoped to the viewport background toggle state

### Changed
- `make_release.sh` now requires an explicit version argument, verifies `[Unreleased]` is non-empty, stamps it with the version and date, and restores a fresh `[Unreleased]` header automatically
- Export PNG/SVG and Copy SVG removed from the File/Edit menu bar — export is exclusively via the overlay button
- Quiet zone stepper replaced with a slider in the controls panel
- `QRMatrix.height` is now a computed property
- `NSApp.activate()` call updated for deprecation
- `VersionComparison` strips only the leading `v` prefix, not arbitrary non-numeric characters
- Accessibility labels added to payload block buttons and export menu items
- `ExportManager` SVG generation deferred; encoding failures guarded explicitly
- `import Foundation` removed from files that don't require it

### Internal
- C library (`libqrencode`): null/overflow guards and bounds checks on mode and version parameters; errno propagation on allocation failure; `#undef` guards before macro redefinitions; unused include removal; doc comment typo fixes
- `QuietZoneTests` setup migrated to `setUpWithError`
- Build scripts: `CFBundleVersion` now uses `VERSION`; `actool` plist merge fixed; `trap` cleanup added; zip guarded against missing app bundle; scripts `cd` to their own directory on startup

## [1.1.0] - 2026-06-29

### Added
- **Payload block system**: replace the single text input with multiple composable blocks, each with an optional label. Blocks are concatenated live to form the QR payload. Blocks can be added, deleted, and reordered. A copy button shows the assembled result when more than one block is present.
- **Configurable quiet zone**: stepper in QR Parameters (0–8 modules, default 4) affects both preview rendering and all exports (PNG, SVG).
- **Match viewport background**: checkbox in the preview toolbar fills the entire preview area with the QR background color (or checkerboard for transparent), avoiding contrast issues in dark mode.
- Structured `OSLog` logging with four categories: `generation`, `blocks`, `export`, `update`. Stream with: `log stream --predicate 'subsystem == "com.creativytool.qrski"' --level debug`

### Fixed
- Update check now skipped in development builds (no `CFBundleShortVersionString` in bundle)
- Update alert showed empty local version string when running without a built app bundle
- App window not brought to front on launch when run from Xcode
- Crash when deleting a block due to stale captured index in SwiftUI closure
- Move/delete button hit areas too small due to missing `contentShape`
- Concatenated result field expanded unexpectedly on click with no way to collapse

### Changed
- Bundle identifier changed from `de.bitgrip.qrski` to `com.creativytool.qrski`
- `make_app.sh` now reads the version from `CHANGELOG.md` automatically — no manual bump needed
- Zoom capped at fit-to-viewport (1×); scroll beyond viewport removed
- Preview toolbar zoom controls wrap gracefully when the panel is narrow (`ViewThatFits`)

## [1.0.1] - 2026-06-28

### Added
- Automatic update check on launch: shows an alert when a newer GitHub release is available
- "Check for Updates…" item in the application menu for manual checks
- `make_release.sh`: builds the app, zips it as `QRski-vX.Y.Z.zip`, and prints the `gh release create` command with release notes extracted from this changelog

### Fixed
- Test suite was passing `.cValue` (`QRecLevel`) to `QRCodeGenerator.generate`, which now accepts `ErrorCorrectionLevel` directly

## [1.0.0] - 2026-06-28

### Fixed
- FNC1 First mode was non-functional due to an inverted boolean guard in `QRinput_check`
- `QRinput_List_dup` could invoke `malloc(0)` / `memcpy` with a null source on zero-size entries
- `QRinput_insertFNC1Header` dereferenced `input->head` without a NULL check on empty inputs
- `MMask_makeMaskedFrame` (test path) indexed `maskMakers` without bounds-checking `mask`
- `RSECC_encode` lacked a lower-bound check on `ecc_length`, causing unsigned wraparound on zero
- `BitStream_writeNum` undefined behaviour when shift count ≥ 32
- Negative `version` passed to MQR encode entry points caused near-infinite loops
- `QRcode_APIVersionString` declaration and definition now consistently return `const char *`
- `QRcode_List_free` docs example freed `entry` (always NULL at loop exit) instead of `qrcodes`

### Changed
- `QRCodeGenerator.generate` now accepts `ErrorCorrectionLevel` instead of the raw C `QRecLevel`
- `ExportManager` methods annotated `@MainActor`; I/O errors surfaced via `NSAlert` instead of silently discarded
- `ExportCore.generateSVG` uses array-join instead of quadratic string concatenation
- `ExportCore.generatePNG` batches `CGRect` fills into a single `ctx.fill([CGRect])` call
- `ExportCore.hexString` falls back through `genericRGB` to avoid `NSException` on non-RGB colors
- `make_app.sh`: removed deprecated `--deep` flag from `codesign`

### Internal
- Added `#include <stddef.h>` to `bitstream.h` and `rsecc.h` so they compile standalone
- Added `#include "qrencode.h"` to `mask.h` and `mmask.h` for `QRecLevel`
- Added input bounds checks to all `MQRspec` public API functions
- Fixed reserved `__bstream__` macro identifiers; added argument parentheses
- Fixed `ln → la` mode-switch cost variable in `Split_eatAn`
