import Foundation

/// Returns true if `remote` is a strictly higher semantic version than `local`.
/// Ignores a leading "v" or "V". Missing components are treated as zero.
/// Pre-release suffixes (e.g. "-rc1") are not handled and compare as zero for that component.
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
    var trimmed = version
    if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") { trimmed.removeFirst() }
    return trimmed
        .split(separator: ".")
        .compactMap { Int($0) }
}
