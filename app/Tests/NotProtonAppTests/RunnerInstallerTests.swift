import Foundation
import Testing

@testable import NotProtonApp

@Suite("Copying the runner")
struct RunnerInstallerTests {

    private func makeRunners() throws -> URL {
        let runners = FileManager.default.temporaryDirectory
            .appending(path: "np-point-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: runners, withIntermediateDirectories: true)
        return runners
    }

    // The clone is found afterwards at a fixed name inside the build directory, so the tree
    // has to land where clonedRoot looks for it.
    @Test("The copy lands where the clone is looked for")
    func copyLandsWhereTheCloneIsLookedFor() throws {
        let runners = try makeRunners()
        defer { try? FileManager.default.removeItem(at: runners) }

        let source = runners.appending(path: "source/wine")
        try FileManager.default.createDirectory(
            at: source.appending(path: "lib/wine"), withIntermediateDirectories: true
        )
        try Data("loader".utf8).write(to: source.appending(path: "bin-wine"))

        let build = SupportedRunners.sikarugir.id
        let target = SupportPaths.clonedRoot(forBuild: build, runners: runners)
        try FileManager.default.createDirectory(
            at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try RunnerInstaller.cloneTree(from: source, to: target)

        #expect(FileManager.default.fileExists(atPath: target.appending(path: "lib/wine").path(percentEncoded: false)))
        #expect(try Data(contentsOf: target.appending(path: "bin-wine")) == Data("loader".utf8))
        #expect(RunnerInstaller.hasClone(forBuild: build, runners: runners))
    }

    @Test("A folder that never finished copying does not count as a clone")
    func partialCloneIsNotAClone() throws {
        let runners = try makeRunners()
        defer { try? FileManager.default.removeItem(at: runners) }

        let build = SupportedRunners.sikarugir.id
        let stale = SupportPaths.clonedRoot(forBuild: build, runners: runners)
        try FileManager.default.createDirectory(at: stale, withIntermediateDirectories: true)
        try Data("junk".utf8).write(to: stale.appending(path: "leftover"))

        #expect(!RunnerInstaller.hasClone(forBuild: build, runners: runners))
    }

    @Test("Cloning is APFS only: an existing destination is not silently merged")
    func cloneTreeRefusesWhatCpRefuses() throws {
        let runners = try makeRunners()
        defer { try? FileManager.default.removeItem(at: runners) }

        let source = runners.appending(path: "missing-source")
        #expect(throws: (any Error).self) {
            try RunnerInstaller.cloneTree(from: source, to: runners.appending(path: "destination"))
        }
        #expect(!FileManager.default.fileExists(atPath: runners.appending(path: "destination").path(percentEncoded: false)))
    }

    @Test("The state reader agrees with what the installer writes")
    func stateAgreesWithInstaller() throws {
        let runners = try makeRunners()
        defer { try? FileManager.default.removeItem(at: runners) }

        let build = SupportedRunners.sikarugir.id
        try FileManager.default.createDirectory(
            at: SupportPaths.clonedRoot(forBuild: build, runners: runners).appending(path: "lib/wine"),
            withIntermediateDirectories: true
        )

        #expect(RunnerStore.state(runners: runners, verify: { _, _ in [] }) == .ready(builds: [build]))
    }
}
