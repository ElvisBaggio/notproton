import Foundation
import Testing

@testable import NotProtonApp

// Scratch directories rather than the live runner, so these say the same thing on a
// machine that has never had a clone made on it.

@Suite("Clean copy resolution")
struct CleanTests {

    @Test("The backup beside a file is preferred when it exists")
    func backupWins() throws {
        let dir = try scratchDirectory("setup")
        defer { try? FileManager.default.removeItem(at: dir) }

        let live = dir.appending(path: "ntdll.dll")
        let backup = dir.appending(path: "ntdll.dll.notproton-orig")
        try Data([1]).write(to: live)
        try Data([2]).write(to: backup)

        #expect(Clean.copy(of: live) == backup)
    }

    @Test("A file with no backup resolves to itself")
    func noBackupResolvesToSelf() throws {
        let dir = try scratchDirectory("setup")
        defer { try? FileManager.default.removeItem(at: dir) }

        let live = dir.appending(path: "wine")
        try Data([1]).write(to: live)

        #expect(Clean.copy(of: live) == live)
    }

    @Test("The suffix is appended, not substituted for the extension")
    func suffixIsAppended() throws {
        let dir = try scratchDirectory("setup")
        defer { try? FileManager.default.removeItem(at: dir) }

        let live = dir.appending(path: "ntdll.dll")
        let backup = dir.appending(path: "ntdll.dll.notproton-orig")
        try Data([1]).write(to: live)
        try Data([2]).write(to: backup)

        // A rule built on deletingPathExtension would look for ntdll.notproton-orig
        // and silently fall through to the patched file.
        #expect(Clean.copy(of: live).lastPathComponent == "ntdll.dll.notproton-orig")
    }
}

@Suite("Cloned payload resolution")
struct ClonedPayloadTests {

    @Test("An intact clone is recognised by the payload inside it")
    func findsPayload() throws {
        let runners = try scratchDirectory("setup")
        defer { try? FileManager.default.removeItem(at: runners) }

        let payload = SupportPaths.clonedRoot(forBuild: "1.2.3.4", runners: runners)
        try FileManager.default.createDirectory(
            at: payload.appending(path: "lib/wine"), withIntermediateDirectories: true
        )

        #expect(RunnerInstaller.hasClone(forBuild: "1.2.3.4", runners: runners))
    }

    @Test("A clone still shaped as an .app does not count as cloned")
    func refusesBundleShapedClone() throws {
        let runners = try scratchDirectory("setup")
        defer { try? FileManager.default.removeItem(at: runners) }

        let clone = SupportPaths.runnerRoot(forBuild: "1.2.3.4", runners: runners)
        try FileManager.default.createDirectory(
            at: clone.appending(path: "Sikarugir.app/Contents/SharedSupport/wine/lib/wine"),
            withIntermediateDirectories: true
        )

        #expect(!RunnerInstaller.hasClone(forBuild: "1.2.3.4", runners: runners))
    }

    @Test("A clone with no payload in it does not count as cloned")
    func refusesCloneWithoutPayload() throws {
        let runners = try scratchDirectory("setup")
        defer { try? FileManager.default.removeItem(at: runners) }

        let clone = SupportPaths.runnerRoot(forBuild: "1.2.3.4", runners: runners)
        try FileManager.default.createDirectory(at: clone, withIntermediateDirectories: true)

        #expect(!RunnerInstaller.hasClone(forBuild: "1.2.3.4", runners: runners))
    }
}
