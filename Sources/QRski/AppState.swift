import SwiftUI
import AppKit
import QRskiCore

@Observable
final class AppState {
    @ObservationIgnored private var isInitializing = true

    var inputText: String = "" {
        didSet { guard !isInitializing else { return }; ud.set(inputText, forKey: "inputText"); regenerate() }
    }
    var version: Int = 0 {
        didSet { guard !isInitializing else { return }; ud.set(version, forKey: "version"); regenerate() }
    }
    var maskPattern: Int = -1 {
        didSet {
            guard !isInitializing else { return }
            ud.set(maskPattern, forKey: "maskPattern"); ud.set(true, forKey: "maskSet"); regenerate()
        }
    }
    var ecl: ErrorCorrectionLevel = .M {
        didSet { guard !isInitializing else { return }; ud.set(ecl.rawValue, forKey: "ecl"); regenerate() }
    }
    var fgColor: Color = .black {
        didSet { guard !isInitializing else { return }; saveColor(fgColor, key: "fgColor") }
    }
    var bgColor: Color = .white {
        didSet { guard !isInitializing else { return }; saveColor(bgColor, key: "bgColor") }
    }
    var isTransparentBg: Bool = false {
        didSet { guard !isInitializing else { return }; ud.set(isTransparentBg, forKey: "transparentBg") }
    }
    var moduleSize: Int = 10 {
        didSet { guard !isInitializing else { return }; ud.set(moduleSize, forKey: "moduleSize") }
    }

    private(set) var matrix: QRMatrix? = nil
    private(set) var actualVersion: Int? = nil
    var generationError: String? = nil

    private let ud = UserDefaults.standard

    var effectiveBgColor: Color? { isTransparentBg ? nil : bgColor }

    init() {
        inputText = ud.string(forKey: "inputText") ?? ""
        version = ud.integer(forKey: "version")
        maskPattern = ud.object(forKey: "maskSet") != nil ? ud.integer(forKey: "maskPattern") : -1
        if let rawEcl = ud.object(forKey: "ecl") as? Int,
           let eclVal = ErrorCorrectionLevel(rawValue: rawEcl) { ecl = eclVal }
        if let fg = loadColor(key: "fgColor") { fgColor = fg }
        if let bg = loadColor(key: "bgColor") { bgColor = bg }
        isTransparentBg = ud.bool(forKey: "transparentBg")
        let ms = ud.integer(forKey: "moduleSize"); if ms > 0 { moduleSize = ms }

        isInitializing = false
        regenerate()
    }

    func regenerate() {
        guard !inputText.isEmpty else {
            matrix = nil; actualVersion = nil; generationError = nil
            return
        }
        if let result = QRCodeGenerator.generate(
            text: inputText, version: version,
            maskPattern: maskPattern, ecl: ecl
        ) {
            matrix = result.matrix
            actualVersion = result.version
            generationError = nil
        } else {
            matrix = nil; actualVersion = nil
            generationError = "Could not encode — text may be too long for version \(version == 0 ? "auto" : "\(version)")."
        }
    }

    private func saveColor(_ color: Color, key: String) {
        guard let ns = NSColor(color).usingColorSpace(.sRGB) else { return }
        ud.set([ns.redComponent, ns.greenComponent, ns.blueComponent, ns.alphaComponent], forKey: key)
    }

    private func loadColor(key: String) -> Color? {
        guard let c = ud.array(forKey: key) as? [Double], c.count == 4 else { return nil }
        return Color(red: c[0], green: c[1], blue: c[2], opacity: c[3])
    }
}
