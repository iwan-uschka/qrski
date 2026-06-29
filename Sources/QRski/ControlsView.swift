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
                pngSizeSection
                Divider()
                colorsSection
            }
            .padding()
        }
    }

    // MARK: - Sections

    private var qrParametersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("QR Parameters", systemImage: "qrcode")
                .font(.headline)

            HStack {
                Text("Error Correction")
                Spacer()
                Picker("", selection: $appState.ecl) {
                    ForEach(ErrorCorrectionLevel.allCases) { ecl in
                        Text(ecl.label).tag(ecl)
                    }
                }
                .labelsHidden()
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

            HStack {
                Text("Mask Pattern")
                Spacer()
                Picker("", selection: $appState.maskPattern) {
                    Text("Auto").tag(-1)
                    ForEach(0..<8) { i in Text("\(i)").tag(i) }
                }
                .labelsHidden()
            }

            HStack {
                Text("Quiet Zone")
                Spacer()
                Text("\(appState.quietZone) modules")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { Double(appState.quietZone) },
                    set: { appState.quietZone = Int($0.rounded()) }
                ),
                in: 0...8, step: 1
            )
            .accessibilityLabel("Quiet Zone")

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
            .accessibilityLabel("Module size")
            if let matrix = appState.matrix {
                let px = (matrix.width + 2 * appState.quietZone) * appState.moduleSize
                Text("Output: \(px)×\(px) px")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Colors", systemImage: "paintpalette")
                .font(.headline)

            HStack {
                Text("Foreground")
                Spacer()
                ColorPicker("", selection: $appState.fgColor, supportsOpacity: false)
                    .labelsHidden()
                    .accessibilityLabel("Foreground")
            }

            HStack {
                Text("Transparent Background")
                Spacer()
                Toggle("", isOn: $appState.isTransparentBg)
                    .labelsHidden()
                    .toggleStyle(.checkbox)
                    .accessibilityLabel("Transparent Background")
            }

            if !appState.isTransparentBg {
                HStack {
                    Text("Background")
                    Spacer()
                    ColorPicker("", selection: $appState.bgColor, supportsOpacity: false)
                        .labelsHidden()
                        .accessibilityLabel("Background")
                }
            }
        }
    }


}
