# Code review hints — qrski

## Verify all focused value consumers before flagging removal

Before flagging removal of a `.focusedValue` modifier as a breaking change, grep for all usages of the corresponding `@FocusedValue` key across the entire codebase — not just the file being changed. In this project, `AppCommands.swift` was simultaneously migrated from `@FocusedValue(\.appState)` to a constructor-injected `let appState: AppState`, eliminating the only consumer. If zero files contain `@FocusedValue(\.appState)` after the change, removing the modifier is safe and intentional.
_Source: feature/NOTICKET-templates, finding [1], 2026-06-30_

## FileMenuDelegate installation pattern is intentional — do not simplify

`AppDelegate` in `QRski.swift` installs a `FileMenuDelegate` on the File submenu in two ways:

1. **Startup retry loop** (`installFileMenuDelegate`) — defers via `DispatchQueue.main.async` and retries until `NSApp.mainMenu?.item(withTitle: "File")?.submenu` is non-nil. This is necessary because SwiftUI builds the menu asynchronously.
2. **Recovery observer** (`menuBarDidBeginTracking`) — observes `NSMenu.didBeginTrackingNotification` and reinstalls the delegate if SwiftUI dropped it. This is essential: `AppCommands.body` reads `appState.blocks`, so any template load (which changes `blocks`) triggers a SwiftUI commands rebuild that silently clears the File submenu's delegate property. Without the recovery observer, the Close/Close All menu items stop being reordered after the first template load.

Do NOT flag either mechanism as redundant, fragile, or a candidate for simplification to a single one-shot `DispatchQueue.main.async`. Both are load-bearing. The dual-mechanism design was reached after the single-shot approach was confirmed broken in manual testing.
_Source: feature/NOTICKET-templates, post-review fix, 2026-06-30_
