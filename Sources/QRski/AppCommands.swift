import SwiftUI

struct AppCommands: Commands {
    let appState: AppState

    var body: some Commands {
        CommandGroup(after: .saveItem) {
            Menu("Templates") {
                Button("Save") {
                    let template = appState.makeTemplate()
                    let name = appState.blocks.first?.label ?? ""
                    Task { @MainActor in TemplateManager.save(template, suggestedName: name) }
                }
                Button("Load") {
                    Task { @MainActor in
                        if let template = TemplateManager.load() { appState.applyTemplate(template) }
                    }
                }
                Divider()
                Button("Reset to Default") {
                    appState.applyTemplate(.default)
                }
            }
        }

        CommandGroup(before: .appTermination) {
            Button("Check for Updates…") {
                UpdateChecker.shared.check(silent: false)
            }
            Divider()
        }

        CommandGroup(after: .pasteboard) {
            Button("Copy SVG") {
                guard let matrix = appState.matrix else { return }
                ExportManager.copySVGToClipboard(
                    matrix: matrix, fg: appState.fgColor, bg: appState.effectiveBgColor, quietZone: appState.quietZone
                )
            }
            .keyboardShortcut("c", modifiers: [.command, .option])
            .disabled(appState.matrix == nil)
        }
    }
}
