import AppKit
import Foundation
import OSLog
import UniformTypeIdentifiers
import QRskiCore

enum TemplateManager {
    private struct SchemaProbe: Decodable { let schemaVersion: Int }

    @MainActor
    static func save(_ template: QRskiTemplate, suggestedName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        let name = suggestedName.trimmingCharacters(in: .whitespaces)
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
        do {
            let data = try Data(contentsOf: url)
            // QRskiTemplate.init(from:) throws on a future schemaVersion, so probe it first to
            // distinguish that case and show the specific message instead of the generic one.
            let probe = try JSONDecoder().decode(SchemaProbe.self, from: data)
            guard probe.schemaVersion <= QRskiTemplate.currentSchemaVersion else {
                showError("This template was saved with a newer version of QRski and cannot be opened.")
                return nil
            }
            let template = try JSONDecoder().decode(QRskiTemplate.self, from: data)
            Logger.export.info("Template loaded: path=\(url.path(percentEncoded: false))")
            return template
        } catch {
            Logger.export.error("Template load failed: \(error)")
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
