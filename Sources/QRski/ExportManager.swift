import AppKit
import SwiftUI
import UniformTypeIdentifiers
import QRskiCore

enum ExportManager {
    @MainActor
    static func exportPNG(matrix: QRMatrix, moduleSize: Int, fg: Color, bg: Color?) {
        guard let data = ExportCore.generatePNG(matrix: matrix, moduleSize: moduleSize, fg: fg, bg: bg) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "qrcode.png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try data.write(to: url)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    @MainActor
    static func exportSVG(matrix: QRMatrix, fg: Color, bg: Color?) {
        let svg = ExportCore.generateSVG(matrix: matrix, fg: fg, bg: bg)
        let panel = NSSavePanel()
        if let svgType = UTType(filenameExtension: "svg") {
            panel.allowedContentTypes = [svgType]
        }
        panel.nameFieldStringValue = "qrcode.svg"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let svgData = svg.data(using: .utf8) {
            do {
                try svgData.write(to: url)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    @MainActor
    static func copySVGToClipboard(matrix: QRMatrix, fg: Color, bg: Color?) {
        let svg = ExportCore.generateSVG(matrix: matrix, fg: fg, bg: bg)
        NSPasteboard.general.clearContents()
        let success = NSPasteboard.general.setString(svg, forType: .string)
        if !success {
            let alert = NSAlert()
            alert.messageText = "Copy Failed"
            alert.informativeText = "Could not copy SVG to clipboard."
            alert.runModal()
        }
    }
}
