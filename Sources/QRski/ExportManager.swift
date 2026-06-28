import AppKit
import SwiftUI
import UniformTypeIdentifiers
import QRskiCore

enum ExportManager {
    static func exportPNG(matrix: QRMatrix, moduleSize: Int, fg: Color, bg: Color?) {
        guard let data = ExportCore.generatePNG(matrix: matrix, moduleSize: moduleSize, fg: fg, bg: bg) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "qrcode.png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url)
    }

    static func exportSVG(matrix: QRMatrix, fg: Color, bg: Color?) {
        let svg = ExportCore.generateSVG(matrix: matrix, fg: fg, bg: bg)
        let panel = NSSavePanel()
        if let svgType = UTType(filenameExtension: "svg") {
            panel.allowedContentTypes = [svgType]
        }
        panel.nameFieldStringValue = "qrcode.svg"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? svg.data(using: .utf8)?.write(to: url)
    }

    static func copySVGToClipboard(matrix: QRMatrix, fg: Color, bg: Color?) {
        let svg = ExportCore.generateSVG(matrix: matrix, fg: fg, bg: bg)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(svg, forType: .string)
    }
}
