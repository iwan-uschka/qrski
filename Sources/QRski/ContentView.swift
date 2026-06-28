import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HSplitView {
            ControlsView(appState: appState)
                .frame(minWidth: 260, idealWidth: 280, maxWidth: 320)
            QRPreviewView(appState: appState)
                .frame(minWidth: 300, minHeight: 300)
        }
        .focusedValue(\.appState, appState)
    }
}
