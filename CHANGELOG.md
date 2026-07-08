# Changelog

## [Unreleased]

## [1.2.4] - 2026-07-08

### Added
- License files: the app source is now MIT-licensed (`LICENSE`), and the vendored libqrencode 4.1.1 ships its GNU LGPL 2.1 text (`LICENSE.libqrencode`). Both are documented in the README and bundled into `QRski.app/Contents/Resources` so binary-only downloads carry them.

## [1.2.3] - 2026-07-08

### Fixed
- Pinch-zoom in the preview no longer compounds exponentially (the gesture baseline was resynced mid-gesture)
- "Check for Updates…" now shows an error dialog on HTTP errors (e.g. GitHub rate limiting) and unreadable responses instead of silently doing nothing
- `moduleSize` from templates and preferences is now clamped to 1–32, matching the export slider
- Template colors with out-of-range, non-finite, or transparent components are now clamped to the 0–1 range and full opacity instead of silently rendering an invisible QR
- Out-of-range `version`/`maskPattern` values restored from preferences are now clamped instead of causing a misleading encode error
- Duplicate block ids in a hand-edited template no longer break block editing and deletion (ids are regenerated on collision)
- A failed PNG export no longer persists the chosen module size

### Security
- Release-URL validation moved to `QRskiCore` (`isTrustedReleaseURL`) with tests; subdomains of github.com are now rejected (release pages live on github.com itself)
- Template files larger than 1 MB are rejected before being read into memory
- `ExportCore.generatePNG`/`generateSVG` now validate their inputs (module size, quiet zone) instead of relying on callers

### Internal
- `make_release.sh` now validates the version format, refuses to run on a dirty working tree or an existing tag, passes the version to `make_app.sh` explicitly, and publishes a SHA-256 checksum alongside the zip
- Both build scripts use `set -euo pipefail`; `make_app.sh` no longer depends on the caller's working directory and warns instead of silently ignoring a failed Info.plist merge
- File-menu delegate installation retries are capped instead of unbounded
- Template save-panel filenames are sanitized (path separators stripped from block labels)
- New regression tests for export input guards, release-URL trust, version-comparison edge cases, and PNG pixel colors

## [1.2.2] - 2026-07-07

### Fixed
- Loading a template saved by a newer QRski now shows the specific "newer version" message instead of the generic corrupt-file error
- Applying a template with an empty `blocks` array no longer leaves the editor without any content block
- Out-of-range `maskPattern` values in templates are now clamped to the valid -1…7 range instead of causing a misleading encode error
- Quiet zone restored from preferences is now clamped to 0–8, matching template loading
- Version comparison for update checks now treats non-numeric components (e.g. pre-release suffixes) as zero instead of dropping them, which previously misaligned later components

### Changed
- Automatic update check now runs once per launch instead of once per window

### Security
- Update dialog now only opens release URLs that are `https` and on `github.com`

### Internal
- C encoder boundary now guards against >2 GiB input instead of trapping on `Int32` overflow
- `AppState` is now `@MainActor`
- `make_app.sh` uses a random temp directory for the partial Info.plist instead of a fixed `/tmp` path
- `make_release.sh` restores `CHANGELOG.md` from backup if the release build fails partway through
- New regression tests for mask-pattern validation and version parsing

## [1.2.1] - 2026-07-06

### Fixed
- Loading a template file with an out-of-range `version` value crashed the app instead of showing an error
- Loading a template with an extreme `quietZone` value could freeze the preview; `version` and `quietZone` are now clamped to their valid ranges when a template is applied
- Typing in a content block no longer re-encodes the QR code on every keystroke — regeneration is now debounced

## [1.2.0] - 2026-06-30

### Added
- **Templates**: save and load the full app state (blocks, QR parameters, colors, viewport settings) as `.json` files via `File → Templates → Save / Load`. A built-in `Reset to Default` option restores all settings to their initial values.

### Changed
- `File → Close` moved to the very bottom of the File menu

### Fixed
- `File → Close` and `Close All` now stay paired when the File menu is reordered — previously loading a template could separate them, making `Close All` disappear
- `make_release.sh` no longer duplicates `[Unreleased]` and version headers when a same-date release already exists in the changelog — replaced two `sed` substitutions with a single `awk` script that only matches the first occurrence

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
