import Darwin
import Foundation
import Testing

@testable import NotProtonApp

@Suite("Bridge payload")
struct BridgePayloadTests {

    private static let layout = [
        "steam.exe", "x86_64-windows/lsteamclient.dll", "x86_64-unix/lsteamclient.so",
        "i386-windows/lsteamclient.dll",
    ]

    // Stand-in files for the pinned Sikarugir bridge, with pins computed from their content.
    private func fakeResources(in work: URL) throws -> (root: URL, pins: [String: String]) {
        let root = work.appending(path: "bridge")
        var pins: [String: String] = [:]
        for path in Self.layout {
            let file = root.appending(path: "\(SupportedRunners.sikarugir.id)/\(path)")
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = Data(repeating: UInt8(path.count % 256), count: path.count * 100)
            try data.write(to: file)
            pins[path] = Digest.sha256(of: data)
        }
        return (root, pins)
    }

    private var stagedPaths: [String] { Self.layout.map { "\(SupportedRunners.sikarugir.id)/\($0)" } }

    @Test("Locate finds every pinned Sikarugir file when present")
    func locateFindsAll() throws {
        let work = try scratchDirectory("bridge")
        defer { try? FileManager.default.removeItem(at: work) }

        let (root, pins) = try fakeResources(in: work)
        let located = try BridgePayload.locate(root: root, pins: pins)
        #expect(located.sources.count == Self.layout.count)
        #expect(located.sources.flatMap(\.bridgePaths).sorted() == stagedPaths.sorted())
    }

    @Test("Locate refuses a Sikarugir file whose hash is not the pinned one")
    func locateRefusesUnknownFile() throws {
        let work = try scratchDirectory("bridge")
        defer { try? FileManager.default.removeItem(at: work) }

        let (root, pins) = try fakeResources(in: work)
        try Data("tampered".utf8).write(to: root.appending(path: "\(SupportedRunners.sikarugir.id)/steam.exe"))
        #expect(throws: StepFailure.self) { try BridgePayload.locate(root: root, pins: pins) }
    }

    @Test("Locate reports missing resources rather than silently staging nothing")
    func locateReportsMissing() throws {
        let work = try scratchDirectory("bridge")
        defer { try? FileManager.default.removeItem(at: work) }

        let root = work.appending(path: "empty-bridge")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        #expect(throws: StepFailure.self) { try BridgePayload.locate(root: root) }
    }

    @Test("Stage writes every Sikarugir bridge path")
    func stageWritesAll() throws {
        let work = try scratchDirectory("bridge")
        defer { try? FileManager.default.removeItem(at: work) }

        let (root, pins) = try fakeResources(in: work)
        let located = try BridgePayload.locate(root: root, pins: pins)
        let bridge = work.appending(path: "staged")
        let result = try BridgePayload.stage(located: located, bridge: bridge)

        let allPaths = stagedPaths
        #expect(result.staged.count == allPaths.count)
        #expect(result.unchanged.isEmpty)

        for path in allPaths {
            #expect(
                FileManager.default.fileExists(atPath: bridge.appending(path: path).path(percentEncoded: false)),
                "\(path) was not staged"
            )
        }
    }

    @Test("Matching contents are left untouched on a second run")
    func skipsMatchingContents() throws {
        let work = try scratchDirectory("bridge")
        defer { try? FileManager.default.removeItem(at: work) }

        let (root, pins) = try fakeResources(in: work)
        let located = try BridgePayload.locate(root: root, pins: pins)
        let bridge = work.appending(path: "staged")

        let first = try BridgePayload.stage(located: located, bridge: bridge)
        let allPaths = stagedPaths
        let untouchedDate = Date(timeIntervalSince1970: 1_000_000)
        let before = try allPaths.map { path in
            let destination = bridge.appending(path: path).path(percentEncoded: false)
            try FileManager.default.setAttributes([.modificationDate: untouchedDate], ofItemAtPath: destination)
            return try FileManager.default.attributesOfItem(atPath: destination)
        }
        let second = try BridgePayload.stage(located: located, bridge: bridge)

        #expect(!first.staged.isEmpty)
        #expect(second.staged.isEmpty, "files were re-staged despite matching contents")
        #expect(second.unchanged.count == allPaths.count)
        for (path, original) in zip(allPaths, before) {
            let after = try FileManager.default.attributesOfItem(
                atPath: bridge.appending(path: path).path(percentEncoded: false)
            )
            #expect(after[.systemFileNumber] as? NSNumber == original[.systemFileNumber] as? NSNumber)
            #expect(after[.modificationDate] as? Date == original[.modificationDate] as? Date)
        }
    }

    @Test("Changed contents replace the copy even when byte counts match")
    func replacesSameSizeContents() throws {
        let work = try scratchDirectory("bridge")
        defer { try? FileManager.default.removeItem(at: work) }

        let (root, pins) = try fakeResources(in: work)
        let located = try BridgePayload.locate(root: root, pins: pins)
        let bridge = work.appending(path: "staged")
        _ = try BridgePayload.stage(located: located, bridge: bridge)

        let entry = try #require(located.sources.first)
        let previous = try Data(contentsOf: entry.source)
        let changed = Data(repeating: 0xff, count: previous.count)
        try changed.write(to: entry.source)
        let result = try BridgePayload.stage(located: located, bridge: bridge)

        #expect(result.staged == entry.bridgePaths)
        #expect(Set(result.unchanged).isDisjoint(with: entry.bridgePaths))
        for path in entry.bridgePaths {
            #expect(try Data(contentsOf: bridge.appending(path: path)) == changed)
        }
    }

    @Test("An unavailable source fails without changing the previous destination", arguments: [false, true])
    func unavailableSourcePreservesDestination(missing: Bool) throws {
        let work = try scratchDirectory("bridge")
        defer { try? FileManager.default.removeItem(at: work) }
        let source = work.appending(path: "source")
        let destination = work.appending(path: "staged/steam.exe")
        try Data("old".utf8).write(to: source)
        let located = BridgePayload.Located(sources: [(source: source, bridgePaths: ["steam.exe"])])
        _ = try BridgePayload.stage(located: located, bridge: destination.deletingLastPathComponent())

        try Data("new".utf8).write(to: source)
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o644], ofItemAtPath: source.path(percentEncoded: false)
            )
        }
        if missing {
            try FileManager.default.removeItem(at: source)
        } else {
            try FileManager.default.setAttributes(
                [.posixPermissions: 0], ofItemAtPath: source.path(percentEncoded: false)
            )
        }

        #expect(throws: (any Error).self) {
            try BridgePayload.stage(located: located, bridge: destination.deletingLastPathComponent())
        }
        #expect(try Data(contentsOf: destination) == Data("old".utf8))
        #expect(try FileManager.default.contentsOfDirectory(
            atPath: destination.deletingLastPathComponent().path(percentEncoded: false)
        ) == ["steam.exe"])
    }

    @Test("Replacement preserves source permissions and extended attributes")
    func replacementPreservesMetadata() throws {
        let work = try scratchDirectory("bridge")
        defer { try? FileManager.default.removeItem(at: work) }
        let source = work.appending(path: "source")
        let bridge = work.appending(path: "staged")
        let destination = bridge.appending(path: "steam.exe")
        try FileManager.default.createDirectory(at: bridge, withIntermediateDirectories: true)
        try Data("old".utf8).write(to: destination)
        try Data("new".utf8).write(to: source)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o751], ofItemAtPath: source.path(percentEncoded: false)
        )
        let attribute = Data("metadata".utf8)
        let setResult = attribute.withUnsafeBytes {
            setxattr(source.path(percentEncoded: false), "com.notproton.test", $0.baseAddress, $0.count, 0, 0)
        }
        #expect(setResult == 0)

        let located = BridgePayload.Located(sources: [(source: source, bridgePaths: ["steam.exe"])])
        let result = try BridgePayload.stage(located: located, bridge: bridge)

        #expect(result.staged == ["steam.exe"])
        #expect(try Data(contentsOf: destination) == Data("new".utf8))
        let attributes = try FileManager.default.attributesOfItem(atPath: destination.path(percentEncoded: false))
        #expect(attributes[.posixPermissions] as? Int == 0o751)
        var copiedAttribute = Data(count: attribute.count)
        let readCount = copiedAttribute.withUnsafeMutableBytes {
            getxattr(destination.path(percentEncoded: false), "com.notproton.test", $0.baseAddress, $0.count, 0, 0)
        }
        #expect(readCount == attribute.count)
        #expect(copiedAttribute == attribute)
        #expect(try FileManager.default.contentsOfDirectory(atPath: bridge.path(percentEncoded: false)) == ["steam.exe"])
    }

    @Test("An atomic copy failure preserves the destination and removes staging files", arguments: [false, true])
    func atomicCopyFailurePreservesDestination(missing: Bool) throws {
        let work = try scratchDirectory("bridge")
        defer { try? FileManager.default.removeItem(at: work) }
        let source = work.appending(path: "source")
        let bridge = work.appending(path: "staged")
        let destination = bridge.appending(path: "steam.exe")
        try FileManager.default.createDirectory(at: bridge, withIntermediateDirectories: true)
        try Data("old".utf8).write(to: destination)
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o644], ofItemAtPath: source.path(percentEncoded: false)
            )
        }
        if !missing {
            try Data("new".utf8).write(to: source)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0], ofItemAtPath: source.path(percentEncoded: false)
            )
        }

        #expect(throws: (any Error).self) {
            try atomicReplace(destination, from: source, step: BridgePayload.step)
        }
        #expect(try Data(contentsOf: destination) == Data("old".utf8))
        #expect(try FileManager.default.contentsOfDirectory(atPath: bridge.path(percentEncoded: false)) == ["steam.exe"])
    }

    @Test("An atomic rename failure preserves the destination and removes staging files")
    func atomicRenameFailurePreservesDestination() throws {
        let work = try scratchDirectory("bridge")
        defer { try? FileManager.default.removeItem(at: work) }
        let source = work.appending(path: "source")
        let bridge = work.appending(path: "staged")
        let destination = bridge.appending(path: "steam.exe")
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let previous = destination.appending(path: "previous")
        try Data("old".utf8).write(to: previous)
        try Data("new".utf8).write(to: source)

        #expect(throws: StepFailure.self) {
            try atomicReplace(destination, from: source, step: BridgePayload.step)
        }
        #expect(try Data(contentsOf: previous) == Data("old".utf8))
        #expect(try FileManager.default.contentsOfDirectory(atPath: bridge.path(percentEncoded: false)) == ["steam.exe"])
    }

    @Test("The pinned Sikarugir paths cover every built path in payload.manifest")
    func coversPayloadManifest() throws {
        let manifest = try PayloadManifest.bundled()
        let builtPaths = Set(manifest.paths(origin: .built))
        #expect(builtPaths == Set(RunnerPatcher.sikarugirBridge.keys.map { "\(SupportedRunners.sikarugir.id)/\($0)" }))
    }
}
