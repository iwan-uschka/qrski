import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HSplitView {
            ControlsView(appState: appState)
                .frame(minWidth: 260, idealWidth: 280)
            QRPreviewView(appState: appState)
                .frame(minWidth: 200, minHeight: 300)
        }
        .focusedValue(\.appState, appState)
    }
}
