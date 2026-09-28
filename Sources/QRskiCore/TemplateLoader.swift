import Foundation

public enum TemplateLoadError: Error, Equatable {
    case tooLarge
    case unreadable
    case unsupportedSchemaVersion
    case corrupted
}

/// Validates and decodes a template file's bytes, kept separate from the app's
/// NSOpenPanel/NSAlert plumbing so the size cap and schema-version check are
/// testable without driving a modal panel.
public enum TemplateLoader {
    // Real templates are a few KB; the cap only exists so a mistakenly selected huge
    // file doesn't get slurped into memory and persisted to UserDefaults wholesale.
    public static let maxBytes = 1 << 20

    public static func load(from url: URL) -> Result<QRskiTemplate, TemplateLoadError> {
        let size: Int?
        do {
            size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        } catch {
            return .failure(.unreadable)
        }
        if let size, size > maxBytes {
            return .failure(.tooLarge)
        }
        guard let data = try? Data(contentsOf: url) else {
            return .failure(.unreadable)
        }
        return decode(data)
    }

    public static func decode(_ data: Data) -> Result<QRskiTemplate, TemplateLoadError> {
        struct SchemaProbe: Decodable { let schemaVersion: Int }
        // QRskiTemplate.init(from:) throws on a future schemaVersion too, but probing first
        // lets the caller show that specific message instead of a generic decode-failure one.
        guard let probe = try? JSONDecoder().decode(SchemaProbe.self, from: data) else {
            return .failure(.corrupted)
        }
        guard probe.schemaVersion <= QRskiTemplate.currentSchemaVersion else {
            return .failure(.unsupportedSchemaVersion)
        }
        guard let template = try? JSONDecoder().decode(QRskiTemplate.self, from: data) else {
            return .failure(.corrupted)
        }
        return .success(template)
    }
}
