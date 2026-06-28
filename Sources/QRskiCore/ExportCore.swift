import SwiftUI
import AppKit

public enum ExportCore {
    public static let quietZone = 4

    public static func generateSVG(matrix: QRMatrix, fg: Color, bg: Color?) -> String {
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

    public static func generatePNG(matrix: QRMatrix, moduleSize: Int, fg: Color, bg: Color?) -> Data? {
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

    public static func hexString(_ color: Color) -> String {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        let r = Int((ns.redComponent * 255).rounded())
        let g = Int((ns.greenComponent * 255).rounded())
        let b = Int((ns.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    public static func cgColor(_ color: Color) -> CGColor {
        NSColor(color).cgColor
    }
}
