# Changelog

## [Unreleased]

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
