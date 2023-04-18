import Foundation
import XcodeProj

extension PBXFileElement {
    private static var cache: [String: String] = [:]
    private static let cacheLock = NSRecursiveLock()

    var namePathSortString: String {
        Self.cacheLock.lock()
        defer {
            Self.cacheLock.unlock()
        }
        if let cached = Self.cache[uuid] {
            return cached
        }

        let ret = """
\(name ?? path ?? "")\t\(name ?? "")\t\(path ?? "")
"""
        Self.cache[uuid] = ret
        return ret
    }
}

extension PBXBuildFile {
    private static var cache: [String: String] = [:]
    private static let cacheLock = NSRecursiveLock()

    var namePathSortString: String {
        Self.cacheLock.lock()
        defer {
            Self.cacheLock.unlock()
        }
        if let cached = Self.cache[uuid] {
            return cached
        }

        let name = file!.name
        let path = file!.path
        let parent = file!.parent

        let parentNamePathSortString = parent?.namePathSortString ?? ""
        let ret = """
\(name ?? path ?? "")\t\(name ?? "")\t\(path ?? "")\t\(parentNamePathSortString)
"""
        Self.cache[uuid] = ret
        return ret
    }
}

extension Sequence {
    static func sortByLocalizedStandard(
        _ keyPath: KeyPath<Element, String>
    ) -> (
        _ lhs: Element,
        _ rhs: Element
    ) -> Bool {
        return { lhs, rhs in
            let l = lhs[keyPath: keyPath]
            let r = rhs[keyPath: keyPath]
            return l.localizedStandardCompare(r) == .orderedAscending
        }
    }

    func sortedLocalizedStandard(
        _ keyPath: KeyPath<Element, String>
    ) -> [Element] {
        return sorted(by: Self.sortByLocalizedStandard(keyPath))
    }
}

extension Array where Element == PBXFileElement {
    mutating func sortLocalizedStandard(
        _ keyPath: KeyPath<Element, String>
    ) {
        sort(by: Self.sortByLocalizedStandard(keyPath))
    }

    mutating func sortLocalizedStandard() {
        sortLocalizedStandard(\.namePathSortString)
    }

    func sortedLocalizedStandard() -> [Element] {
        return sortedLocalizedStandard(\.namePathSortString)
    }
}

extension Sequence where Element == PBXBuildFile {
    func sortedLocalizedStandard() -> [Element] {
        return sortedLocalizedStandard(\.namePathSortString)
    }
}

private struct PBXFileReferenceByTargetKey {
    let file: PBXFileReference
    let sortString: String

    init(_ element: (key: ConsolidatedTarget.Key, value: PBXFileReference)) {
        file = element.value
        sortString = "\(file.namePathSortString)\t\(element.key)"
    }
}

extension Dictionary
where Key == ConsolidatedTarget.Key, Value: PBXFileReference {
    func sortedLocalizedStandard() -> [PBXFileReference] {
        let sort = [PBXFileReferenceByTargetKey]
            .sortByLocalizedStandard(\.sortString)
        return map(PBXFileReferenceByTargetKey.init)
            .sorted(by: sort)
            .map(\.file)
    }
}
