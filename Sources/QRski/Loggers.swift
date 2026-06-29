import OSLog

extension Logger {
    static let generation = Logger(subsystem: "com.creativytool.qrski", category: "generation")
    static let blocks     = Logger(subsystem: "com.creativytool.qrski", category: "blocks")
    static let export     = Logger(subsystem: "com.creativytool.qrski", category: "export")
    static let update     = Logger(subsystem: "com.creativytool.qrski", category: "update")
}
