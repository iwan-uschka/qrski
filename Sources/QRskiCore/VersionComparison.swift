import Foundation

/// Returns true if `remote` is a strictly higher semantic version than `local`.
/// Ignores a leading "v" or "V". Missing components are treated as zero.
public func isVersionNewer(_ remote: String, than local: String) -> Bool {
    let r = versionComponents(remote)
    let l = versionComponents(local)
    for i in 0..<max(r.count, l.count) {
        let rv = i < r.count ? r[i] : 0
        let lv = i < l.count ? l[i] : 0
        if rv != lv { return rv > lv }
    }
    return false
}

private func versionComponents(_ version: String) -> [Int] {
    version
        .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        .split(separator: ".")
        .compactMap { Int($0) }
}
