import SwiftUI
import QRskiCore

struct QRPreviewView: View {
    @Bindable var appState: AppState

    @State private var zoomScale: Double = 1.0
    // Baseline captured at pinch start; nil outside a gesture. MagnificationGesture
    // deltas are cumulative since gesture start, so the baseline must stay fixed for
    // the whole gesture — resyncing it mid-gesture compounds the zoom exponentially.
    @State private var gestureStartScale: Double? = nil

    private let zoomBarHeight: Double = 44
    private var quietZone: Int { appState.quietZone }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                previewArea(geo: geo)
                    .overlay(alignment: .topTrailing) {
                        exportMenu.padding(8)
                    }
                Divider()
                zoomBar
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func previewArea(geo: GeometryProxy) -> some View {
        if let matrix = appState.matrix {
            let modulePx = baseModulePx(matrix: matrix, viewSize: geo.size) * zoomScale
            let canvasSize = Double(matrix.width + 2 * quietZone) * modulePx

            Canvas { ctx, _ in
                drawQR(ctx: ctx, matrix: matrix, modulePx: modulePx)
            }
            .frame(width: canvasSize, height: canvasSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if appState.matchViewportBackground {
                    if appState.isTransparentBg {
                        Canvas { ctx, size in
                            drawCheckerboard(ctx: ctx, size: max(size.width, size.height))
                        }
                    } else {
                        appState.bgColor
                    }
                }
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { delta in
                        let base = gestureStartScale ?? zoomScale
                        gestureStartScale = base
                        zoomScale = (base * delta).clamped(to: 0.2...1.0)
                    }
                    .onEnded { _ in
                        gestureStartScale = nil
                    }
            )
        } else {
            placeholderView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var zoomBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                matchBackgroundToggle
                Divider().frame(height: 16)
                zoomControls
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            VStack(spacing: 4) {
                HStack(spacing: 8) { zoomControls }
                HStack(spacing: 8) { matchBackgroundToggle; Spacer() }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private var matchBackgroundToggle: some View {
        Toggle("Match Background", isOn: $appState.matchViewportBackground)
            .toggleStyle(.checkbox)
    }

    private var zoomControls: some View {
        HStack(spacing: 8) {
            Image(systemName: "minus.magnifyingglass")
                .foregroundStyle(.secondary)
            Slider(value: $zoomScale, in: 0.2...1.0)
            Image(systemName: "plus.magnifyingglass")
                .foregroundStyle(.secondary)
            Button("Fit") {
                zoomScale = 1.0
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "qrcode")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.25))
            if appState.generationError != nil {
                Text("Generation failed")
                    .foregroundStyle(.red.opacity(0.6))
                    .font(.subheadline)
            } else {
                Text("Enter text to generate a QR code")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Export menu

    private var exportMenu: some View {
        Menu {
            Section("Export") {
                Button("PNG") {
                    guard let matrix = appState.matrix else { return }
                    ExportManager.exportPNG(
                        matrix: matrix, moduleSize: appState.moduleSize,
                        fg: appState.fgColor, bg: appState.effectiveBgColor,
                        quietZone: appState.quietZone,
                        onModuleSizeUsed: { appState.moduleSize = $0 }
                    )
                }
                Button("SVG") {
                    guard let matrix = appState.matrix else { return }
                    ExportManager.exportSVG(
                        matrix: matrix, fg: appState.fgColor,
                        bg: appState.effectiveBgColor, quietZone: appState.quietZone
                    )
                }
            }
            Section("Copy") {
                Button("SVG") {
                    guard let matrix = appState.matrix else { return }
                    ExportManager.copySVGToClipboard(
                        matrix: matrix, fg: appState.fgColor,
                        bg: appState.effectiveBgColor, quietZone: appState.quietZone
                    )
                }
            }
        } label: {
            Image(systemName: "arrow.down.to.line")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(8)
                .background(Color.accentColor)
                .clipShape(.circle)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .disabled(appState.matrix == nil)
        .accessibilityLabel("Export")
    }

    // MARK: - Drawing

    private func baseModulePx(matrix: QRMatrix, viewSize: CGSize) -> Double {
        let totalModules = Double(matrix.width + 2 * quietZone)
        let availableSize = min(viewSize.width, viewSize.height - zoomBarHeight)
        return max(1.0, availableSize / totalModules * 0.9)
    }

    private func drawQR(ctx: GraphicsContext, matrix: QRMatrix, modulePx: Double) {
        let totalPx = Double(matrix.width + 2 * quietZone) * modulePx

        if appState.isTransparentBg && !appState.matchViewportBackground {
            drawCheckerboard(ctx: ctx, size: totalPx)
        } else if !appState.isTransparentBg {
            ctx.fill(
                Path(CGRect(x: 0, y: 0, width: totalPx, height: totalPx)),
                with: .color(appState.bgColor)
            )
        }

        var path = Path()
        for y in 0..<matrix.width {
            for x in 0..<matrix.width where matrix.modules[y][x] {
                let px = Double(x + quietZone) * modulePx
                let py = Double(y + quietZone) * modulePx
                path.addRect(CGRect(x: px, y: py, width: modulePx, height: modulePx))
            }
        }
        ctx.fill(path, with: .color(appState.fgColor))
    }

    private func drawCheckerboard(ctx: GraphicsContext, size: Double) {
        let sq: Double = 8
        let tiles = Int(ceil(size / sq))
        for row in 0..<tiles {
            for col in 0..<tiles {
                let color: Color = (row + col) % 2 == 0 ? .white : Color(white: 0.85)
                ctx.fill(
                    Path(CGRect(x: Double(col) * sq, y: Double(row) * sq, width: sq, height: sq)),
                    with: .color(color)
                )
            }
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
