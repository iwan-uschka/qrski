import AppKit
import OSLog
import SwiftUI
import UniformTypeIdentifiers
import QRskiCore

enum ExportManager {
    @MainActor
    static func exportPNG(matrix: QRMatrix, moduleSize: Int, fg: Color, bg: Color?, quietZone: Int) {
        guard let data = ExportCore.generatePNG(matrix: matrix, moduleSize: moduleSize, fg: fg, bg: bg, quietZone: quietZone) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "qrcode.png"
        guard panel.runModal() == .OK, let url = panel.url else {
            Logger.export.debug("PNG export cancelled")
            return
        }
        do {
            try data.write(to: url)
            Logger.export.info("PNG exported: path=\(url.path) bytes=\(data.count)")
        } catch {
            Logger.export.error("PNG export failed: \(error)")
            NSAlert(error: error).runModal()
        }
    }

    @MainActor
    static func exportSVG(matrix: QRMatrix, fg: Color, bg: Color?, quietZone: Int) {
        let svg = ExportCore.generateSVG(matrix: matrix, fg: fg, bg: bg, quietZone: quietZone)
        let panel = NSSavePanel()
        if let svgType = UTType(filenameExtension: "svg") {
            panel.allowedContentTypes = [svgType]
        }
        panel.nameFieldStringValue = "qrcode.svg"
        guard panel.runModal() == .OK, let url = panel.url else {
            Logger.export.debug("SVG export cancelled")
            return
        }
        if let svgData = svg.data(using: .utf8) {
            do {
                try svgData.write(to: url)
                Logger.export.info("SVG exported: path=\(url.path) bytes=\(svgData.count)")
            } catch {
                Logger.export.error("SVG export failed: \(error)")
                NSAlert(error: error).runModal()
            }
        }
    }

    @MainActor
    static func copySVGToClipboard(matrix: QRMatrix, fg: Color, bg: Color?, quietZone: Int) {
        let svg = ExportCore.generateSVG(matrix: matrix, fg: fg, bg: bg, quietZone: quietZone)
        NSPasteboard.general.clearContents()
        let success = NSPasteboard.general.setString(svg, forType: .string)
        if success {
            Logger.export.info("SVG copied to clipboard: bytes=\(svg.utf8.count)")
        } else {
            Logger.export.error("SVG copy to clipboard failed")
            let alert = NSAlert()
            alert.messageText = "Copy Failed"
            alert.informativeText = "Could not copy SVG to clipboard."
            alert.runModal()
        }
    }
}
