import AppKit
import Foundation
import OSLog
import UniformTypeIdentifiers
import QRskiCore

enum TemplateManager {
    @MainActor
    static func save(_ template: QRskiTemplate, suggestedName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        // The suggested name comes from a free-text block label; strip path and
        // filename separators so the panel gets a plain filename.
        let name = suggestedName
            .components(separatedBy: CharacterSet(charactersIn: "/:").union(.newlines))
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespaces)
        panel.nameFieldStringValue = "qrski-" + (name.isEmpty ? "template" : name) + ".json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(template)
            try data.write(to: url)
            Logger.export.info("Template saved: path=\(url.path(percentEncoded: false))")
        } catch {
            Logger.export.error("Template save failed: \(error)")
            NSAlert(error: error).runModal()
        }
    }

    @MainActor
    static func load() -> QRskiTemplate? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        switch TemplateLoader.load(from: url) {
        case .success(let template):
            Logger.export.info("Template loaded: path=\(url.path(percentEncoded: false))")
            return template
        case .failure(.tooLarge):
            Logger.export.error("Template load failed: file too large")
            showError("This file is too large to be a QRski template.")
            return nil
        case .failure(.unsupportedSchemaVersion):
            Logger.export.error("Template load failed: unsupported schema version")
            showError("This template was saved with a newer version of QRski and cannot be opened.")
            return nil
        case .failure(.unreadable), .failure(.corrupted):
            Logger.export.error("Template load failed: file unreadable or corrupted")
            showError("Could not load template — the file may be invalid or corrupted.")
            return nil
        }
    }

    @MainActor
    private static func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Could not Load Template"
        alert.informativeText = message
        alert.runModal()
    }
}
