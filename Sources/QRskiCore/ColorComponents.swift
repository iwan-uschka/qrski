import SwiftUI
import AppKit

/// Converts between SwiftUI `Color` and the `[r, g, b, a]` arrays `QRskiTemplate`
/// persists, so templates stay plain Codable data on disk.
public enum ColorComponents {
    public static func encode(_ color: Color) -> [Double]? {
        // A pattern-backed NSColor (e.g. one wrapping an NSImage pattern) can't be
        // converted to sRGB and returns nil here instead of crashing on force-unwrap.
        guard let ns = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        return [ns.redComponent, ns.greenComponent, ns.blueComponent, ns.alphaComponent]
    }

    public static func decode(_ components: [Double]) -> Color? {
        // Hand-edited templates can carry out-of-range, non-finite, or wrong-length
        // component arrays. The in-app pickers can't produce alpha ≠ 1 (supportsOpacity
        // is false) and an alpha of 0 would silently export an invisible, unscannable
        // QR, so clamp to 0…1 and force full opacity; transparency is isTransparentBg's job.
        guard components.count == 4, components.allSatisfy(\.isFinite) else { return nil }
        let clamped = components.map { min(max($0, 0), 1) }
        return Color(red: clamped[0], green: clamped[1], blue: clamped[2], opacity: 1)
    }
}
