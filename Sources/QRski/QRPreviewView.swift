import SwiftUI
import QRskiCore

struct QRPreviewView: View {
    var appState: AppState

    @State private var zoomScale: Double = 1.0
    @State private var gestureStartScale: Double = 1.0

    private let quietZone = ExportCore.quietZone

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                previewArea(geo: geo)
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

            ScrollView([.horizontal, .vertical]) {
                Canvas { ctx, _ in
                    drawQR(ctx: ctx, matrix: matrix, modulePx: modulePx)
                }
                .frame(width: canvasSize, height: canvasSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                MagnificationGesture()
                    .onChanged { delta in
                        zoomScale = (gestureStartScale * delta).clamped(to: 0.2...20.0)
                    }
                    .onEnded { _ in
                        gestureStartScale = zoomScale
                    }
            )
        } else {
            placeholderView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var zoomBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "minus.magnifyingglass")
                .foregroundStyle(.secondary)
            Slider(value: $zoomScale, in: 0.2...20.0)
                .onChange(of: zoomScale) { _, newVal in gestureStartScale = newVal }
            Image(systemName: "plus.magnifyingglass")
                .foregroundStyle(.secondary)
            Button("Fit") {
                zoomScale = 1.0
                gestureStartScale = 1.0
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
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

    // MARK: - Drawing

    private func baseModulePx(matrix: QRMatrix, viewSize: CGSize) -> Double {
        let totalModules = Double(matrix.width + 2 * quietZone)
        let availableSize = min(viewSize.width, viewSize.height - 44)
        return max(1.0, availableSize / totalModules * 0.9)
    }

    private func drawQR(ctx: GraphicsContext, matrix: QRMatrix, modulePx: Double) {
        let totalPx = Double(matrix.width + 2 * quietZone) * modulePx

        if appState.isTransparentBg {
            drawCheckerboard(ctx: ctx, size: totalPx)
        } else {
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
