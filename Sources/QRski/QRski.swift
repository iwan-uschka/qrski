import SwiftUI
import AppKit

@main
struct QRskiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) fileprivate var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup("QRski") {
            ContentView()
                .environment(appState)
                .frame(minWidth: 700, minHeight: 450)
                .task { UpdateChecker.shared.check(silent: true) }
        }
        .windowResizability(.contentMinSize)
        .commands {
            AppCommands(appState: appState)
        }
    }
}

private class AppDelegate: NSObject, NSApplicationDelegate {
    private var fileMenuDelegate: FileMenuDelegate?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate()
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async {
            guard let fileMenu = NSApp.mainMenu?.item(withTitle: "File")?.submenu else { return }
            let delegate = FileMenuDelegate()
            self.fileMenuDelegate = delegate
            fileMenu.delegate = delegate
        }
    }
}

private class FileMenuDelegate: NSObject, NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        guard let closeIndex = menu.items.firstIndex(where: {
            $0.keyEquivalent == "w" && $0.keyEquivalentModifierMask == .command
        }) else { return }
        let lastNonSep = menu.items.lastIndex(where: { !$0.isSeparatorItem }) ?? 0
        guard closeIndex != lastNonSep else { return }
        let closeItem = menu.items[closeIndex]
        menu.removeItem(at: closeIndex)
        if menu.items.last?.isSeparatorItem == false { menu.addItem(.separator()) }
        menu.addItem(closeItem)
    }
}
