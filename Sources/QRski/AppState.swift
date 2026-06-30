import SwiftUI
import AppKit
import OSLog
import QRskiCore

@Observable
final class AppState {
    @ObservationIgnored private var isInitializing = true
    @ObservationIgnored private var isApplyingTemplate = false

    var blocks: [PayloadBlock] = [] {
        didSet {
            guard !isInitializing else { return }
            if let data = try? JSONEncoder().encode(blocks) { ud.set(data, forKey: "blocks") }
            Logger.blocks.debug("blocks changed: count=\(self.blocks.count)")
            guard !isApplyingTemplate else { return }
            regenerate()
        }
    }
    var version: Int = 0 {
        didSet {
            guard !isInitializing else { return }
            ud.set(version, forKey: "version")
            guard !isApplyingTemplate else { return }
            regenerate()
        }
    }
    var maskPattern: Int = -1 {
        didSet {
            guard !isInitializing else { return }
            ud.set(maskPattern, forKey: "maskPattern"); ud.set(true, forKey: "maskSet")
            guard !isApplyingTemplate else { return }
            regenerate()
        }
    }
    var ecl: ErrorCorrectionLevel = .M {
        didSet {
            guard !isInitializing else { return }
            ud.set(ecl.rawValue, forKey: "ecl")
            guard !isApplyingTemplate else { return }
            regenerate()
        }
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
    var matchViewportBackground: Bool = false {
        didSet { guard !isInitializing else { return }; ud.set(matchViewportBackground, forKey: "matchViewportBg") }
    }
    var moduleSize: Int = 10 {
        didSet { guard !isInitializing else { return }; ud.set(moduleSize, forKey: "moduleSize") }
    }
    var quietZone: Int = ExportCore.defaultQuietZone {
        didSet {
            guard !isInitializing else { return }
            if quietZone == ExportCore.defaultQuietZone {
                ud.removeObject(forKey: "quietZone")
            } else {
                ud.set(quietZone, forKey: "quietZone")
            }
        }
    }

    private(set) var matrix: QRMatrix? = nil
    private(set) var actualVersion: Int? = nil
    var generationError: String? = nil

    private let ud = UserDefaults.standard

    var inputText: String { blocks.map(\.text).joined() }
    var effectiveBgColor: Color? { isTransparentBg ? nil : bgColor }

    init() {
        if let data = ud.data(forKey: "blocks"),
           let saved = try? JSONDecoder().decode([PayloadBlock].self, from: data) {
            blocks = saved
        } else if let legacy = ud.string(forKey: "inputText"), !legacy.isEmpty {
            blocks = [PayloadBlock(text: legacy)]
        } else {
            blocks = [PayloadBlock()]
        }

        version = ud.integer(forKey: "version")
        maskPattern = ud.object(forKey: "maskSet") != nil ? ud.integer(forKey: "maskPattern") : -1
        if let rawEcl = ud.object(forKey: "ecl") as? Int,
           let eclVal = ErrorCorrectionLevel(rawValue: rawEcl) { ecl = eclVal }
        if let fg = loadColor(key: "fgColor") { fgColor = fg }
        if let bg = loadColor(key: "bgColor") { bgColor = bg }
        isTransparentBg = ud.bool(forKey: "transparentBg")
        matchViewportBackground = ud.bool(forKey: "matchViewportBg")
        let ms = ud.integer(forKey: "moduleSize"); if ms > 0 { moduleSize = ms }
        if let qz = ud.object(forKey: "quietZone") as? Int { quietZone = qz }

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
            Logger.generation.info("encoded: version=\(result.version) size=\(result.matrix.width)x\(result.matrix.height) ecl=\(self.ecl.rawValue) mask=\(self.maskPattern) textLen=\(self.inputText.utf8.count)")
        } else {
            matrix = nil; actualVersion = nil
            generationError = "Could not encode — text may be too long for version \(version == 0 ? "auto" : "\(version)")."
            Logger.generation.error("encode failed: version=\(self.version) ecl=\(self.ecl.rawValue) textLen=\(self.inputText.utf8.count)")
        }
    }

    func makeTemplate() -> QRskiTemplate {
        QRskiTemplate(
            schemaVersion: QRskiTemplate.currentSchemaVersion,
            blocks: blocks,
            version: version,
            maskPattern: maskPattern,
            ecl: ecl,
            fgColor: colorAsComponents(fgColor) ?? [0, 0, 0, 1],
            bgColor: colorAsComponents(bgColor) ?? [1, 1, 1, 1],
            isTransparentBg: isTransparentBg,
            matchViewportBackground: matchViewportBackground,
            moduleSize: moduleSize,
            quietZone: quietZone
        )
    }

    func applyTemplate(_ template: QRskiTemplate) {
        guard
            let fg = colorFromComponents(template.fgColor),
            let bg = colorFromComponents(template.bgColor)
        else {
            generationError = "Template contains invalid values and was not applied."
            return
        }
        isApplyingTemplate = true
        defer { isApplyingTemplate = false }
        blocks = template.blocks
        version = template.version
        maskPattern = template.maskPattern
        ecl = template.ecl
        fgColor = fg
        bgColor = bg
        isTransparentBg = template.isTransparentBg
        matchViewportBackground = template.matchViewportBackground
        moduleSize = template.moduleSize
        quietZone = template.quietZone
        regenerate()
    }

    private func saveColor(_ color: Color, key: String) {
        if let c = colorAsComponents(color) { ud.set(c, forKey: key) }
    }

    private func loadColor(key: String) -> Color? {
        guard let c = ud.array(forKey: key) as? [Double] else { return nil }
        return colorFromComponents(c)
    }

    private func colorAsComponents(_ color: Color) -> [Double]? {
        guard let ns = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        return [ns.redComponent, ns.greenComponent, ns.blueComponent, ns.alphaComponent]
    }

    private func colorFromComponents(_ c: [Double]) -> Color? {
        guard c.count == 4 else { return nil }
        return Color(red: c[0], green: c[1], blue: c[2], opacity: c[3])
    }
}
