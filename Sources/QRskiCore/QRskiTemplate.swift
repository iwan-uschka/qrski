import Foundation

public struct QRskiTemplate: Codable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var blocks: [PayloadBlock]
    public var version: Int
    public var maskPattern: Int
    public var ecl: Int
    public var fgColor: [Double]
    public var bgColor: [Double]
    public var isTransparentBg: Bool
    public var matchViewportBackground: Bool
    public var moduleSize: Int
    public var quietZone: Int

    public static let `default` = QRskiTemplate(
        schemaVersion: currentSchemaVersion,
        blocks: [PayloadBlock()],
        version: 0,
        maskPattern: -1,
        ecl: 1,
        fgColor: [0, 0, 0, 1],
        bgColor: [1, 1, 1, 1],
        isTransparentBg: false,
        matchViewportBackground: false,
        moduleSize: 10,
        quietZone: 4
    )

    public init(
        schemaVersion: Int,
        blocks: [PayloadBlock],
        version: Int,
        maskPattern: Int,
        ecl: Int,
        fgColor: [Double],
        bgColor: [Double],
        isTransparentBg: Bool,
        matchViewportBackground: Bool,
        moduleSize: Int,
        quietZone: Int
    ) {
        self.schemaVersion = schemaVersion
        self.blocks = blocks
        self.version = version
        self.maskPattern = maskPattern
        self.ecl = ecl
        self.fgColor = fgColor
        self.bgColor = bgColor
        self.isTransparentBg = isTransparentBg
        self.matchViewportBackground = matchViewportBackground
        self.moduleSize = moduleSize
        self.quietZone = quietZone
    }
}
