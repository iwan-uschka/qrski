import Foundation
import AppKit
import OSLog
import QRskiCore

@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()

    private let apiURL = URL(string: "https://api.github.com/repos/iwan-uschka/qrski/releases/latest")!

    private var didRunSilentCheck = false

    private init() {}

    func check(silent: Bool) {
        // Every window's .task fires a silent check, and File → New Window can spawn many —
        // only the first silent check runs so a new window doesn't re-prompt. Explicit checks always run.
        if silent {
            guard !didRunSilentCheck else { return }
            didRunSilentCheck = true
        }
        guard let local = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            Logger.update.debug("skipping update check: no bundle version (development build)")
            return
        }
        Logger.update.info("checking for updates (silent=\(silent))")
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: apiURL)
                guard
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let tag = json["tag_name"] as? String,
                    let releaseURL = json["html_url"] as? String
                else {
                    Logger.update.error("unexpected API response format")
                    return
                }

                let remote = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

                if isVersionNewer(remote, than: local) {
                    Logger.update.info("update available: local=\(local) remote=\(remote)")
                    presentUpdateAvailable(version: remote, localVersion: local, url: releaseURL)
                } else {
                    Logger.update.info("up to date: local=\(local) remote=\(remote)")
                    if !silent { presentUpToDate(version: local) }
                }
            } catch {
                Logger.update.error("update check failed: \(error)")
                if !silent { presentError(error) }
            }
        }
    }

    // MARK: - Alerts

    private func presentUpdateAvailable(version: String, localVersion: String, url: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "QRski \(version) is available. You have \(localVersion)."
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            // url comes straight from the GitHub API JSON — only open it if it's an https
            // github.com URL, never an arbitrary scheme/host from a tampered response.
            guard let releaseURL = URL(string: url),
                  releaseURL.scheme == "https",
                  let host = releaseURL.host,
                  host == "github.com" || host.hasSuffix(".github.com")
            else {
                Logger.update.error("refusing to open untrusted release URL: \(url)")
                return
            }
            NSWorkspace.shared.open(releaseURL)
        }
    }

    private func presentUpToDate(version: String) {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date"
        alert.informativeText = "QRski \(version) is the latest version."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }


}
