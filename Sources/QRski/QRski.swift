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
        installFileMenuDelegate()
        // Recovery: reinstall the delegate each time the user activates the menu bar,
        // in case SwiftUI dropped it during an AppCommands rebuild (e.g. after template load).
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuBarDidBeginTracking(_:)),
            name: NSMenu.didBeginTrackingNotification,
            object: nil
        )
    }

    @objc private func menuBarDidBeginTracking(_ notification: Notification) {
        guard notification.object as? NSMenu === NSApp.mainMenu,
              let fileMenu = NSApp.mainMenu?.item(withTitle: "File")?.submenu,
              !(fileMenu.delegate is FileMenuDelegate) else { return }
        let delegate = FileMenuDelegate()
        fileMenuDelegate = delegate
        fileMenu.delegate = delegate
    }

    private func installFileMenuDelegate(attempt: Int = 0) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.fileMenuDelegate == nil else { return }
            if let fileMenu = NSApp.mainMenu?.item(withTitle: "File")?.submenu {
                let delegate = FileMenuDelegate()
                self.fileMenuDelegate = delegate
                fileMenu.delegate = delegate
            } else if attempt < 60 {
                // Cap the retries: if the "File" title ever stops matching (e.g.
                // localization), an uncapped loop would busy-schedule on the main
                // queue forever. The menu-tracking observer above remains as the
                // long-term recovery path.
                self.installFileMenuDelegate(attempt: attempt + 1)
            }
        }
    }
}

private class FileMenuDelegate: NSObject, NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        guard let closeIndex = menu.items.firstIndex(where: {
            $0.keyEquivalent == "w" && $0.keyEquivalentModifierMask == .command
        }) else { return }
        let lastNonSep = menu.items.lastIndex(where: { !$0.isSeparatorItem }) ?? 0
        let closeAllIdx = (closeIndex + 1 < menu.items.count && menu.items[closeIndex + 1].isAlternate)
            ? closeIndex + 1
            : nil
        let expectedLastNonSep = closeAllIdx ?? closeIndex
        guard expectedLastNonSep != lastNonSep else { return }

        // Move Close and its Close All alternate (the immediately-following isAlternate item)
        // together — moving Close alone orphans Close All and makes it invisible.
        var toMove: [NSMenuItem] = [menu.items[closeIndex]]
        let nextIdx = closeIndex + 1
        if nextIdx < menu.items.count, menu.items[nextIdx].isAlternate {
            toMove.append(menu.items[nextIdx])
        }
        toMove.reversed().forEach { menu.removeItem($0) }
        if menu.items.last?.isSeparatorItem == false { menu.addItem(.separator()) }
        toMove.forEach { menu.addItem($0) }
    }
}
