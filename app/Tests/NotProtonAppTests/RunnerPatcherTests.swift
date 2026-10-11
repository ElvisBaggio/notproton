import Foundation
import Testing

@testable import NotProtonApp

@Suite("Runner patching")
struct RunnerPatcherTests {

    // Only real Sikarugir bytes can answer whether a repair works, since no tree a test builds
    // meets the pinned hashes. An APFS clone costs a second and leaves the real one alone.
    // Explicitly skipped (not passed) on a machine with no verified Sikarugir clone installed.
    static let hasHealthyClone: Bool = RunnerStore.installedBuilds().contains {
        RunnerPatcher.verify(build: $0, root: SupportPaths.clonedRoot(forBuild: $0.id)).isEmpty
    }

    private static func healthyClone() throws -> (root: URL, build: RunnerBuild)? {
        guard let build = RunnerStore.installedBuilds().first(where: {
            RunnerPatcher.verify(build: $0, root: SupportPaths.clonedRoot(forBuild: $0.id)).isEmpty
        }) else { return nil }
        let live = SupportPaths.clonedRoot(forBuild: build.id)

        let scratch = URL(filePath: NSTemporaryDirectory())
            .appending(path: "notproton-runner-\(UUID().uuidString)")
        let copied = try Shell.run("/bin/cp", [
            "-c", "-R", live.path(percentEncoded: false), scratch.path(percentEncoded: false),
        ])

        // Past the healthy check, a clone that cannot be read is this test breaking and
        // not a machine that cannot answer, so it fails rather than skipping.
        try #require(copied.status == 0)
        try #require(RunnerPatcher.verify(build: build, root: scratch).isEmpty)

        return (scratch, build)
    }

    // The launch path used to copy this on every run, so the button is now the only thing
    // that closes the gap after an app update replaces the bridge copy.
    @Test("A builtin the bridge has replaced is reported, then repaired by the install", .enabled(if: RunnerPatcherTests.hasHealthyClone))
    func repairsStaleBuiltin() throws {
        let (root, build) = try #require(try Self.healthyClone())
        defer { try? FileManager.default.removeItem(at: root) }

        let arch = "x86_64-unix"
        let builtin = root.appending(path: "lib/wine/\(arch)/lsteamclient.so")
        try Data("not the bridge copy".utf8).write(to: builtin)

        #expect(RunnerPatcher.verify(build: build, root: root)
            == ["\(arch)/lsteamclient.so is out of date"])

        let outcome = try RunnerPatcher.install(build: build, root: root)
        #expect(outcome.builtins == ["\(arch)/lsteamclient.so"])
        #expect(RunnerPatcher.verify(build: build, root: root).isEmpty)
    }

    @Test("A builtin that was never installed is reported, then repaired by the install", .enabled(if: RunnerPatcherTests.hasHealthyClone))
    func repairsMissingBuiltin() throws {
        let (root, build) = try #require(try Self.healthyClone())
        defer { try? FileManager.default.removeItem(at: root) }

        let builtin = root.appending(path: "lib/wine/x86_64-windows/lsteamclient.dll")
        try FileManager.default.removeItem(at: builtin)

        #expect(RunnerPatcher.verify(build: build, root: root)
            == ["x86_64-windows/lsteamclient.dll is missing"])

        _ = try RunnerPatcher.install(build: build, root: root)
        #expect(RunnerPatcher.verify(build: build, root: root).isEmpty)
    }

    // A runner back on stock ntdll runs games that fail their ownership check, which is
    // the failure this whole path exists to prevent.
    @Test("A runner back on stock ntdll is reported, then repaired by the install", .enabled(if: RunnerPatcherTests.hasHealthyClone))
    func repairsStockNtdll() throws {
        let (root, build) = try #require(try Self.healthyClone())
        defer { try? FileManager.default.removeItem(at: root) }

        let arch = WineArch.x86_64Windows
        let live = root.appending(path: "lib/wine/\(arch.rawValue)/ntdll.dll")
        let clean = NtdllPatcher.cleanSource(inRoot: root, arch: arch)
        guard clean != live else { return }

        try Data(contentsOf: clean).write(to: live)
        #expect(RunnerPatcher.verify(build: build, root: root)
            == ["\(arch.rawValue)/ntdll.dll is not the patched copy"])

        let outcome = try RunnerPatcher.install(build: build, root: root)
        #expect(outcome.ntdll == [arch])
        #expect(Digest.sha256IfPresent(live) == build.patchedNtdll[arch])
        #expect(RunnerPatcher.verify(build: build, root: root).isEmpty)
    }

    // Re-running has to be free, or the button cannot be the answer to every runner
    // problem the UI reports.
    @Test("Installing into a runner that is already right writes nothing", .enabled(if: RunnerPatcherTests.hasHealthyClone))
    func installIsIdempotent() throws {
        let (root, build) = try #require(try Self.healthyClone())
        defer { try? FileManager.default.removeItem(at: root) }

        let outcome = try RunnerPatcher.install(build: build, root: root)
        #expect(outcome.wroteNothing)
    }

    @Test("The Sikarugir builtins are the steam.exe launcher, the x86_64 lsteamclient pair and the i386 PE half")
    func builtinsAreThePinnedSet() {
        let root = URL(filePath: "/unused")
        let builtins = RunnerPatcher.builtins(for: SupportedRunners.sikarugir, in: root)
        #expect(builtins.map { RunnerPatcher.builtinPath($0) }.sorted()
            == ["i386-windows/lsteamclient.dll", "steam.exe", "x86_64-unix/lsteamclient.so",
                "x86_64-windows/lsteamclient.dll"])
        #expect(RunnerPatcher.builtinDestination(builtins[0], in: root).path == "/unused/bin/steam.exe")
        #expect(RunnerPatcher.builtinDestination(builtins[1], in: root).path == "/unused/lib/wine/x86_64-windows/lsteamclient.dll")
        #expect(RunnerPatcher.builtinDestination(builtins[3], in: root).path == "/unused/lib/wine/i386-windows/lsteamclient.dll")
    }
}
