import SwiftUI

struct AppStateFocusedKey: FocusedValueKey {
    typealias Value = AppState
}

extension FocusedValues {
    var appState: AppState? {
        get { self[AppStateFocusedKey.self] }
        set { self[AppStateFocusedKey.self] = newValue }
    }
}

struct AppCommands: Commands {
    @FocusedValue(\.appState) var appState

    var body: some Commands {
        CommandGroup(after: .saveItem) {
            Button("Export PNG…") {
                guard let s = appState, let matrix = s.matrix else { return }
                ExportManager.exportPNG(
                    matrix: matrix, moduleSize: s.moduleSize,
                    fg: s.fgColor, bg: s.effectiveBgColor, quietZone: s.quietZone,
                    onModuleSizeUsed: { s.moduleSize = $0 }
                )
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(appState?.matrix == nil)

            Button("Export SVG…") {
                guard let s = appState, let matrix = s.matrix else { return }
                ExportManager.exportSVG(
                    matrix: matrix, fg: s.fgColor, bg: s.effectiveBgColor, quietZone: s.quietZone
                )
            }
            .disabled(appState?.matrix == nil)
        }

        CommandGroup(before: .appTermination) {
            Button("Check for Updates…") {
                UpdateChecker.shared.check(silent: false)
            }
            Divider()
        }

        CommandGroup(after: .pasteboard) {
            Button("Copy SVG") {
                guard let s = appState, let matrix = s.matrix else { return }
                ExportManager.copySVGToClipboard(
                    matrix: matrix, fg: s.fgColor, bg: s.effectiveBgColor, quietZone: s.quietZone
                )
            }
            .keyboardShortcut("k", modifiers: .command)
            .disabled(appState?.matrix == nil)
        }
    }
}
