import SwiftUI
import QRskiCore

struct ControlsView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PayloadBlocksView(appState: appState)
                Divider()
                qrParametersSection
                Divider()
                colorsSection
                Divider()
                pngSizeSection
                Divider()
                exportSection
            }
            .padding()
        }
    }

    // MARK: - Sections

    private var qrParametersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("QR Parameters", systemImage: "qrcode")
                .font(.headline)

            Picker("Error Correction", selection: $appState.ecl) {
                ForEach(ErrorCorrectionLevel.allCases) { ecl in
                    Text(ecl.label).tag(ecl)
                }
            }

            HStack {
                Text("Version")
                Spacer()
                Text(appState.version == 0 ? "Auto" : "\(appState.version)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Stepper("", value: $appState.version, in: 0...40)
                    .labelsHidden()
            }

            Picker("Mask Pattern", selection: $appState.maskPattern) {
                Text("Auto").tag(-1)
                ForEach(0..<8) { i in Text("\(i)").tag(i) }
            }

            HStack {
                Text("Quiet Zone")
                Spacer()
                Text("\(appState.quietZone) modules")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Stepper("", value: $appState.quietZone, in: 0...8)
                    .labelsHidden()
            }

            if let v = appState.actualVersion {
                Text("Encoded at version \(v) (\((v * 4 + 21))×\((v * 4 + 21)) modules)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let err = appState.generationError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Colors", systemImage: "paintpalette")
                .font(.headline)

            ColorPicker("Foreground", selection: $appState.fgColor, supportsOpacity: false)

            Toggle("Transparent Background", isOn: $appState.isTransparentBg)

            if !appState.isTransparentBg {
                ColorPicker("Background", selection: $appState.bgColor, supportsOpacity: false)
            }
        }
    }

    private var pngSizeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("PNG Export", systemImage: "photo")
                .font(.headline)
            HStack {
                Text("Module size")
                Spacer()
                Text("\(appState.moduleSize) px")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { Double(appState.moduleSize) },
                    set: { appState.moduleSize = Int($0.rounded()) }
                ),
                in: 1...32, step: 1
            )
            if let matrix = appState.matrix {
                let px = (matrix.width + 2 * appState.quietZone) * appState.moduleSize
                Text("Output: \(px)×\(px) px")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Export PNG…") {
                guard let matrix = appState.matrix else { return }
                ExportManager.exportPNG(
                    matrix: matrix, moduleSize: appState.moduleSize,
                    fg: appState.fgColor, bg: appState.effectiveBgColor,
                    quietZone: appState.quietZone
                )
            }
            .disabled(appState.matrix == nil)
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)

            Button("Export SVG…") {
                guard let matrix = appState.matrix else { return }
                ExportManager.exportSVG(matrix: matrix, fg: appState.fgColor, bg: appState.effectiveBgColor, quietZone: appState.quietZone)
            }
            .disabled(appState.matrix == nil)
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)

            Button("Copy SVG") {
                guard let matrix = appState.matrix else { return }
                ExportManager.copySVGToClipboard(matrix: matrix, fg: appState.fgColor, bg: appState.effectiveBgColor, quietZone: appState.quietZone)
            }
            .disabled(appState.matrix == nil)
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
        }
    }
}
