import Foundation
import AppKit
import QRskiCore

@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()

    private let apiURL = URL(string: "https://api.github.com/repos/iwan-uschka/qrski/releases/latest")!

    private init() {}

    func check(silent: Bool) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: apiURL)
                guard
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let tag = json["tag_name"] as? String,
                    let releaseURL = json["html_url"] as? String
                else { return }

                let remote = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                let local = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

                if isVersionNewer(remote, than: local) {
                    presentUpdateAvailable(version: remote, url: releaseURL)
                } else if !silent {
                    presentUpToDate(version: local)
                }
            } catch {
                if !silent {
                    presentError(error)
                }
            }
        }
    }

    // MARK: - Alerts

    private func presentUpdateAvailable(version: String, url: String) {
        let local = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "QRski \(version) is available. You have \(local)."
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn, let releaseURL = URL(string: url) {
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
