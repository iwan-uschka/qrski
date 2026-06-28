import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum ExportManager {
    static let quietZone = 4

    static func exportPNG(matrix: QRMatrix, moduleSize: Int, fg: Color, bg: Color?) {
        guard let data = generatePNG(matrix: matrix, moduleSize: moduleSize, fg: fg, bg: bg) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "qrcode.png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url)
    }

    static func exportSVG(matrix: QRMatrix, fg: Color, bg: Color?) {
        let svg = generateSVG(matrix: matrix, fg: fg, bg: bg)
        let panel = NSSavePanel()
        if let svgType = UTType(filenameExtension: "svg") {
            panel.allowedContentTypes = [svgType]
        }
        panel.nameFieldStringValue = "qrcode.svg"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? svg.data(using: .utf8)?.write(to: url)
    }

    static func copySVGToClipboard(matrix: QRMatrix, fg: Color, bg: Color?) {
        let svg = generateSVG(matrix: matrix, fg: fg, bg: bg)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(svg, forType: .string)
    }

    static func generateSVG(matrix: QRMatrix, fg: Color, bg: Color?) -> String {
        let total = matrix.width + 2 * quietZone
        let fgHex = hexString(fg)

        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 \(total) \(total)\" shape-rendering=\"crispEdges\">"
        if let bg {
            svg += "<rect width=\"\(total)\" height=\"\(total)\" fill=\"\(hexString(bg))\"/>"
        }

        var path = ""
        for y in 0..<matrix.width {
            for x in 0..<matrix.width where matrix.modules[y][x] {
                path += "M\(x + quietZone) \(y + quietZone)h1v1h-1z"
            }
        }
        if !path.isEmpty {
            svg += "<path fill=\"\(fgHex)\" d=\"\(path)\"/>"
        }
        svg += "</svg>"
        return svg
    }

    static func generatePNG(matrix: QRMatrix, moduleSize: Int, fg: Color, bg: Color?) -> Data? {
        let total = (matrix.width + 2 * quietZone) * moduleSize
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: total, height: total,
            bitsPerComponent: 8, bytesPerRow: 0, space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        if let bg {
            ctx.setFillColor(cgColor(bg))
            ctx.fill(CGRect(x: 0, y: 0, width: total, height: total))
        }

        ctx.setFillColor(cgColor(fg))
        for y in 0..<matrix.width {
            for x in 0..<matrix.width where matrix.modules[y][x] {
                let px = (x + quietZone) * moduleSize
                let py = (y + quietZone) * moduleSize
                ctx.fill(CGRect(x: px, y: py, width: moduleSize, height: moduleSize))
            }
        }

        guard let cgImg = ctx.makeImage() else { return nil }
        return NSBitmapImageRep(cgImage: cgImg).representation(using: .png, properties: [:])
    }

    private static func hexString(_ color: Color) -> String {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        let r = Int((ns.redComponent * 255).rounded())
        let g = Int((ns.greenComponent * 255).rounded())
        let b = Int((ns.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    private static func cgColor(_ color: Color) -> CGColor {
        NSColor(color).cgColor
    }
}
