import Foundation

public struct QRskiTemplate: Codable {
    // Bump this and add migration logic in init(from:) when the schema changes
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public var blocks: [PayloadBlock]
    public var version: Int
    // maskPattern: valid domain is -1 (auto) or 0–7; QRCodeGenerator.generate enforces this at call time
    public var maskPattern: Int
    public var ecl: ErrorCorrectionLevel
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
        ecl: .M,
        fgColor: [0, 0, 0, 1],
        bgColor: [1, 1, 1, 1],
        isTransparentBg: false,
        matchViewportBackground: false,
        moduleSize: 10,
        quietZone: ExportCore.defaultQuietZone
    )

    public init(
        schemaVersion: Int,
        blocks: [PayloadBlock],
        version: Int,
        maskPattern: Int,
        ecl: ErrorCorrectionLevel,
        fgColor: [Double],
        bgColor: [Double],
        isTransparentBg: Bool,
        matchViewportBackground: Bool,
        moduleSize: Int,
        quietZone: Int
    ) {
        precondition(fgColor.count == 4, "fgColor must have exactly 4 RGBA components")
        precondition(bgColor.count == 4, "bgColor must have exactly 4 RGBA components")
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

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, blocks, version, maskPattern, ecl
        case fgColor, bgColor, isTransparentBg, matchViewportBackground
        case moduleSize, quietZone
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        guard schemaVersion <= QRskiTemplate.currentSchemaVersion else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Template was saved with schema version \(schemaVersion), but this build only supports up to \(QRskiTemplate.currentSchemaVersion)"
            ))
        }
        blocks = try c.decode([PayloadBlock].self, forKey: .blocks)
        version = try c.decode(Int.self, forKey: .version)
        maskPattern = try c.decode(Int.self, forKey: .maskPattern)
        ecl = try c.decode(ErrorCorrectionLevel.self, forKey: .ecl)
        fgColor = try c.decode([Double].self, forKey: .fgColor)
        bgColor = try c.decode([Double].self, forKey: .bgColor)
        guard fgColor.count == 4, bgColor.count == 4 else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Color arrays must have exactly 4 RGBA components"
            ))
        }
        isTransparentBg = try c.decode(Bool.self, forKey: .isTransparentBg)
        matchViewportBackground = try c.decode(Bool.self, forKey: .matchViewportBackground)
        moduleSize = try c.decode(Int.self, forKey: .moduleSize)
        quietZone = try c.decode(Int.self, forKey: .quietZone)
    }
}
