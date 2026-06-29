import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(before: .appTermination) {
            Button("Check for Updates…") {
                UpdateChecker.shared.check(silent: false)
            }
            Divider()
        }
    }
}
