import Foundation

public struct PayloadBlock: Identifiable, Codable {
    public var id: UUID
    public var label: String
    public var text: String

    public init(id: UUID = UUID(), label: String = "", text: String = "") {
        self.id = id
        self.label = label
        self.text = text
    }
}
