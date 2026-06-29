import SwiftUI
import AppKit

public enum ExportCore {
    public static let defaultQuietZone = 4

    public static func generateSVG(matrix: QRMatrix, fg: Color, bg: Color?, quietZone: Int = defaultQuietZone) -> String {
        let total = matrix.width + 2 * quietZone
        let fgHex = hexString(fg)

        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 \(total) \(total)\" shape-rendering=\"crispEdges\">"
        if let bg {
            svg += "<rect width=\"\(total)\" height=\"\(total)\" fill=\"\(hexString(bg))\"/>"
        }

        var segments: [String] = []
        segments.reserveCapacity(matrix.width * matrix.width)
        for y in 0..<matrix.width {
            for x in 0..<matrix.width where matrix.modules[y][x] {
                segments.append("M\(x + quietZone) \(y + quietZone)h1v1h-1z")
            }
        }
        if !segments.isEmpty {
            svg += "<path fill=\"\(fgHex)\" d=\"\(segments.joined())\"/>"
        }
        svg += "</svg>"
        return svg
    }

    public static func generatePNG(matrix: QRMatrix, moduleSize: Int, fg: Color, bg: Color?, quietZone: Int = defaultQuietZone) -> Data? {
        let total = (matrix.width + 2 * quietZone) * moduleSize
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil, width: total, height: total,
            bitsPerComponent: 8, bytesPerRow: 0, space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // CGContext origin is bottom-left (Y-up); flip to match QR matrix row order (Y-down)
        ctx.translateBy(x: 0, y: CGFloat(total))
        ctx.scaleBy(x: 1, y: -1)

        if let bg {
            ctx.setFillColor(cgColor(bg))
            ctx.fill(CGRect(x: 0, y: 0, width: total, height: total))
        }

        ctx.setFillColor(cgColor(fg))
        var rects: [CGRect] = []
        rects.reserveCapacity(matrix.width * matrix.width)
        for y in 0..<matrix.width {
            for x in 0..<matrix.width where matrix.modules[y][x] {
                let px = CGFloat((x + quietZone) * moduleSize)
                let py = CGFloat((y + quietZone) * moduleSize)
                rects.append(CGRect(x: px, y: py, width: CGFloat(moduleSize), height: CGFloat(moduleSize)))
            }
        }
        ctx.fill(rects)

        guard let cgImg = ctx.makeImage() else { return nil }
        return NSBitmapImageRep(cgImage: cgImg).representation(using: .png, properties: [:])
    }

    static func hexString(_ color: Color) -> String {
        let ns = NSColor(color).usingColorSpace(.sRGB)
               ?? NSColor(color).usingColorSpace(.genericRGB)
               ?? NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        let r = Int((ns.redComponent * 255).rounded())
        let g = Int((ns.greenComponent * 255).rounded())
        let b = Int((ns.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    static func cgColor(_ color: Color) -> CGColor {
        NSColor(color).cgColor
    }
}
