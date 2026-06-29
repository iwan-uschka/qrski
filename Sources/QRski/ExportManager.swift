import AppKit
import OSLog
import SwiftUI
import UniformTypeIdentifiers
import QRskiCore

enum ExportManager {
    @MainActor
    static func exportPNG(matrix: QRMatrix, moduleSize: Int, fg: Color, bg: Color?, quietZone: Int, onModuleSizeUsed: ((Int) -> Void)? = nil) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "qrcode.png"
        let accessory = PNGExportAccessory(matrix: matrix, initialModuleSize: moduleSize, quietZone: quietZone)
        panel.accessoryView = accessory.view
        guard panel.runModal() == .OK, let url = panel.url else {
            Logger.export.debug("PNG export cancelled")
            return
        }
        guard let data = ExportCore.generatePNG(matrix: matrix, moduleSize: accessory.moduleSize, fg: fg, bg: bg, quietZone: quietZone) else {
            Logger.export.error("PNG generation failed (CGContext or bitmap allocation)")
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = "Could not generate the PNG image. Try a smaller module size."
            alert.runModal()
            return
        }
        onModuleSizeUsed?(accessory.moduleSize)
        do {
            try data.write(to: url)
            Logger.export.info("PNG exported: path=\(url.path) moduleSize=\(accessory.moduleSize) bytes=\(data.count)")
        } catch {
            Logger.export.error("PNG export failed: \(error)")
            NSAlert(error: error).runModal()
        }
    }

    @MainActor
    static func exportSVG(matrix: QRMatrix, fg: Color, bg: Color?, quietZone: Int) {
        let panel = NSSavePanel()
        if let svgType = UTType(filenameExtension: "svg") {
            panel.allowedContentTypes = [svgType]
        }
        panel.nameFieldStringValue = "qrcode.svg"
        guard panel.runModal() == .OK, let url = panel.url else {
            Logger.export.debug("SVG export cancelled")
            return
        }
        let svg = ExportCore.generateSVG(matrix: matrix, fg: fg, bg: bg, quietZone: quietZone)
        guard let svgData = svg.data(using: .utf8) else {
            Logger.export.error("SVG encoding failed")
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = "Could not encode SVG data."
            alert.runModal()
            return
        }
        do {
            try svgData.write(to: url)
            Logger.export.info("SVG exported: path=\(url.path) bytes=\(svgData.count)")
        } catch {
            Logger.export.error("SVG export failed: \(error)")
            NSAlert(error: error).runModal()
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

private final class PNGExportAccessory: NSObject {
    let view: NSView
    private let slider: NSSlider
    private let moduleSizeValueLabel: NSTextField
    private let outputSizeLabel: NSTextField
    private let totalModules: Int

    var moduleSize: Int { Int(slider.doubleValue.rounded()) }

    init(matrix: QRMatrix, initialModuleSize: Int, quietZone: Int) {
        totalModules = matrix.width + 2 * quietZone

        slider = NSSlider()
        moduleSizeValueLabel = NSTextField(labelWithString: "")
        outputSizeLabel = NSTextField(labelWithString: "")

        let container = NSView()
        view = container

        super.init()

        slider.minValue = 1
        slider.maxValue = 32
        slider.numberOfTickMarks = 32
        slider.allowsTickMarkValuesOnly = true
        slider.doubleValue = Double(min(max(initialModuleSize, 1), 32))
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(sliderChanged)

        let moduleLabel = NSTextField(labelWithString: "Module size")
        moduleLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        moduleSizeValueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        moduleSizeValueLabel.alignment = .right
        outputSizeLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        outputSizeLabel.textColor = .secondaryLabelColor

        let row = NSStackView(views: [moduleLabel, slider, moduleSizeValueLabel])
        row.spacing = 8
        row.orientation = .horizontal

        let stack = NSStackView(views: [row, outputSizeLabel])
        stack.orientation = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 320),
            moduleSizeValueLabel.widthAnchor.constraint(equalToConstant: 44),
        ])

        update()
    }

    @objc private func sliderChanged() { update() }

    private func update() {
        let ms = moduleSize
        let side = totalModules * ms
        moduleSizeValueLabel.stringValue = "\(ms) px"
        outputSizeLabel.stringValue = "Output: \(side) × \(side) px"
    }
}
