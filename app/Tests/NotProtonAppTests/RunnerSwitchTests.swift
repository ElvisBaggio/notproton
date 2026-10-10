import Foundation
import Testing

@testable import NotProtonApp

@Suite("Preparing an installed build")
struct RunnerPrepareTests {

    private static let build = SupportedRunners.sikarugir

    private static let runScript = Data("#!/bin/sh\n".utf8)

    private final class Calls: @unchecked Sendable {
        var staged: [String] = []
        var patched: [String] = []
    }

    private func makeRunners(cloning builds: [RunnerBuild]) throws -> URL {
        let runners = FileManager.default.temporaryDirectory
            .appending(path: "np-prepare-\(UUID().uuidString)")
        for build in builds {
            try FileManager.default.createDirectory(
                at: SupportPaths.clonedRoot(forBuild: build.id, runners: runners)
                    .appending(path: "lib/wine"),
                withIntermediateDirectories: true
            )
        }
        return runners
    }

    private static func writeStaged(for build: RunnerBuild, into bridge: URL) throws {
        for arch in build.patchedNtdll.keys {
            try atomicReplace(
                NtdllPatcher.stagedCopy(of: arch, build: build.id, in: bridge),
                with: Data("\(build.id) \(arch.rawValue)".utf8), step: "test"
            )
        }
    }

    private func prepare(
        _ build: RunnerBuild,
        runners: URL,
        calls: Calls,
        failPatch: Bool = false
    ) throws -> RunnerSetup.Outcome {
        try RunnerSetup.prepare(
            build,
            runners: runners,
            bridge: runners.appending(path: "bridge"),
            toolList: runners.appending(path: "tools"),
            compatTools: runners.appending(path: "compatibilitytools.d"),
            runScript: {
                let script = runners.appending(path: "payload-run")
                try Self.runScript.write(to: script)
                return script
            },
            verify: { _, _ in },
            stage: { build, _, bridge in
                calls.staged.append(build.id)
                try Self.writeStaged(for: build, into: bridge)
                return []
            },
            patch: { build, _, _ in
                calls.patched.append(build.id)
                if failPatch { throw StepFailure(step: "test", detail: "patch failed") }
                return RunnerPatcher.Outcome()
            }
        )
    }

    private func toolList(_ runners: URL) -> String? {
        try? String(contentsOf: runners.appending(path: "tools"), encoding: .utf8)
    }

    @Test("A set-up build is listed as its tool")
    func listsTheBuild() throws {
        let runners = try makeRunners(cloning: [Self.build])
        defer { try? FileManager.default.removeItem(at: runners) }

        let calls = Calls()
        let outcome = try prepare(Self.build, runners: runners, calls: calls)

        #expect(outcome.toolsChanged)
        #expect(calls.staged == [Self.build.id])
        #expect(calls.patched == [Self.build.id])
        #expect(toolList(runners) == CompatToolList.contents(SupportedRunners.tools(for: [Self.build])))
        #expect(toolList(runners)?.hasPrefix("notproton-sikarugir-11.0-r0\tsikarugir-11.0-r0\trosetta\t") == true)

        let again = try prepare(Self.build, runners: runners, calls: calls)
        #expect(!again.toolsChanged)
    }

    @Test("Every listed tool gets a run script")
    func writesMissingRunScripts() throws {
        let runners = try makeRunners(cloning: [Self.build])
        defer { try? FileManager.default.removeItem(at: runners) }

        _ = try prepare(Self.build, runners: runners, calls: Calls())

        let tools = CompatToolList.installed(runners: runners, file: runners.appending(path: "tools"))
        #expect(tools.count == 1)
        for tool in tools {
            let run = runners.appending(path: "compatibilitytools.d/\(tool.name)/run")
            #expect(try Data(contentsOf: run) == Self.runScript)
            #expect(FileManager.default.isExecutableFile(atPath: run.path))
        }
    }

    @Test("A tool's existing run script is left alone")
    func keepsExistingRunScript() throws {
        let runners = try makeRunners(cloning: [Self.build])
        defer { try? FileManager.default.removeItem(at: runners) }
        let tool = SupportedRunners.tools(for: [Self.build])[0].name
        let run = runners.appending(path: "compatibilitytools.d/\(tool)/run")
        let old = Data("#!/bin/sh\nexec something-older\n".utf8)
        try atomicReplace(run, with: old, step: "test")

        _ = try prepare(Self.build, runners: runners, calls: Calls())

        #expect(try Data(contentsOf: run) == old)
    }

    @Test("Preparing leaves staged copies of folders it does not own alone")
    func keepsForeignStagedCopies() throws {
        let runners = try makeRunners(cloning: [Self.build])
        defer { try? FileManager.default.removeItem(at: runners) }
        let bridge = runners.appending(path: "bridge")
        let foreign = bridge.appending(path: "wine/27.0.0.40921/x86_64-windows/ntdll.dll")
        let legacy = bridge.appending(path: "wine/x86_64-windows/ntdll.dll")
        for file in [foreign, legacy] { try atomicReplace(file, with: Data("old".utf8), step: "test") }

        _ = try prepare(Self.build, runners: runners, calls: Calls())

        #expect(try Data(contentsOf: foreign) == Data("old".utf8))
        #expect(try Data(contentsOf: legacy) == Data("old".utf8))
        for arch in Self.build.patchedNtdll.keys {
            #expect(FileManager.default.fileExists(atPath: NtdllPatcher.stagedCopy(
                of: arch, build: Self.build.id, in: bridge).path(percentEncoded: false)))
        }
    }

    @Test("A failed patch leaves the tool list as it was")
    func failedPatchKeepsList() throws {
        let runners = try makeRunners(cloning: [Self.build])
        defer { try? FileManager.default.removeItem(at: runners) }

        #expect(throws: StepFailure.self) {
            try prepare(Self.build, runners: runners, calls: Calls(), failPatch: true)
        }
        #expect(toolList(runners) == nil)
    }

    @Test("With nothing set up and no list yet, no list is written")
    func writesNoEmptyList() throws {
        let runners = try makeRunners(cloning: [])
        defer { try? FileManager.default.removeItem(at: runners) }
        let file = runners.appending(path: "support/tools")

        let changed = try CompatToolList.sync(
            runners: runners, bridge: runners.appending(path: "bridge"), file: file
        )

        #expect(!changed)
        #expect(!FileManager.default.fileExists(
            atPath: file.deletingLastPathComponent().path(percentEncoded: false)))
    }

    @Test("A build with no clone is refused without touching anything")
    func refusesMissingClone() throws {
        let runners = try makeRunners(cloning: [])
        defer { try? FileManager.default.removeItem(at: runners) }

        let calls = Calls()
        let failure = try #require(throws: StepFailure.self) {
            try prepare(Self.build, runners: runners, calls: calls)
        }

        #expect(failure.detail.contains("has not been set up"))
        #expect(calls.staged.isEmpty)
        #expect(toolList(runners) == nil)
    }

    @Test("Installed builds are supported clones that still have their payload")
    func installedBuildsListing() throws {
        let runners = try makeRunners(cloning: [Self.build])
        defer { try? FileManager.default.removeItem(at: runners) }

        try FileManager.default.createDirectory(
            at: SupportPaths.clonedRoot(forBuild: "sikarugir-1.0-r1", runners: runners)
                .appending(path: "lib/wine"),
            withIntermediateDirectories: true
        )
        #expect(RunnerStore.installedBuilds(in: runners) == [Self.build])

        try FileManager.default.removeItem(
            at: SupportPaths.clonedRoot(forBuild: Self.build.id, runners: runners)
        )
        #expect(RunnerStore.installedBuilds(in: runners).isEmpty)
    }
}

@MainActor
@Suite("Choosing which Sikarugir to set up from")
struct SetupSourceTests {

    private func install(_ name: String) -> SikarugirInstall {
        SikarugirInstall(
            root: URL(filePath: "/Applications/\(name).app/Contents/SharedSupport/wine"),
            build: SupportedRunners.sikarugir
        )
    }

    private func status(runner: RunnerState, installs: [SikarugirInstall]) -> SystemStatus {
        let status = SystemStatus()
        status.snapshot = StatusSnapshot(
            steam: .steamMissing,
            steamRunning: false,
            updateBlocked: false,
            sikarugir: installs,
            runner: runner,
            payload: PayloadInspector.inspect(bridge: FileManager.default.temporaryDirectory, builds: [])
        )
        return status
    }

    @Test("The first Sikarugir app found is the setup source")
    func firstFoundIsTheSource() {
        let first = install("Sikarugir A")
        let second = install("Sikarugir B")
        let status = status(runner: .none, installs: [first, second])

        #expect(status.setupSource?.root == first.root)
    }

    @Test("With no Sikarugir app there is no setup source")
    func noSourceWithoutAnApp() {
        #expect(status(runner: .none, installs: []).setupSource == nil)
    }

    @Test("The row offers Set Up for a found app and Repair state follows the copy")
    func rowFollowsTheCopy() {
        let found = install("Sikarugir")
        let id = SupportedRunners.sikarugir.id

        let notSetUp = SikarugirRow.row(installs: [found], installed: [], damaged: [], unpatched: [])
        #expect(notSetUp.copy == .none && notSetUp.canSetUp)

        let ready = SikarugirRow.row(
            installs: [found], installed: [SupportedRunners.sikarugir], damaged: [], unpatched: [])
        #expect(ready.copy == .ready)

        let unpatched = SikarugirRow.row(
            installs: [], installed: [SupportedRunners.sikarugir], damaged: [], unpatched: [id])
        #expect(unpatched.copy == .unpatched && !unpatched.canSetUp)

        let damaged = SikarugirRow.row(installs: [found], installed: [], damaged: [id], unpatched: [])
        #expect(damaged.copy == .damaged)
    }
}

@Suite("Removing an installed build")
struct RunnerRemovalTests {

    private static let main = SupportedRunners.sikarugir.id
    private static let other = "sikarugir-10.0-r3"

    private func makeRunners(cloning builds: [String]) throws -> URL {
        let runners = FileManager.default.temporaryDirectory
            .appending(path: "np-remove-\(UUID().uuidString)")
        for build in builds {
            try FileManager.default.createDirectory(
                at: SupportPaths.clonedRoot(forBuild: build, runners: runners)
                    .appending(path: "lib/wine"),
                withIntermediateDirectories: true
            )
        }
        return runners
    }

    private func remove(
        _ build: String, runners: URL, libraries: [SteamLibrary] = [], running: Bool = false
    ) throws -> Bool {
        try RunnerInstaller.removeClone(
            forBuild: build, runners: runners,
            bridge: runners.appending(path: "bridge"), toolList: runners.appending(path: "tools"),
            libraries: libraries,
            running: { _ in running }
        )
    }

    @Test("Removing a build leaves nothing of it in the runners folder")
    func removalLeavesNothing() throws {
        let runners = try makeRunners(cloning: [Self.main, Self.other])
        defer { try? FileManager.default.removeItem(at: runners) }
        let fm = FileManager.default
        let leftover = runners.appending(path: ".\(Self.main).removing/wine")
        try fm.createDirectory(at: leftover, withIntermediateDirectories: true)

        _ = try remove(Self.main, runners: runners)

        let left = try fm.contentsOfDirectory(atPath: runners.path(percentEncoded: false))
            .filter { $0.contains(Self.main) }
        #expect(left.isEmpty)
        #expect(RunnerStore.clonedBuilds(in: runners) == [Self.other])
    }

    @Test("Removing a build also clears what an earlier failed removal of another build left")
    func removalClearsOtherLeftovers() throws {
        let runners = try makeRunners(cloning: [Self.main])
        defer { try? FileManager.default.removeItem(at: runners) }
        let fm = FileManager.default
        let leftover = runners.appending(path: ".\(Self.other).removing/wine")
        try fm.createDirectory(at: leftover, withIntermediateDirectories: true)

        _ = try remove(Self.main, runners: runners)

        #expect(try fm.contentsOfDirectory(atPath: runners.path(percentEncoded: false))
            .filter { $0.hasSuffix(".removing") }.isEmpty)
    }

    @Test("A removal whose tool list cannot be written puts the build back")
    func failedSyncRestoresBuild() throws {
        let runners = try makeRunners(cloning: [Self.main, Self.other])
        defer { try? FileManager.default.removeItem(at: runners) }
        let fm = FileManager.default
        // The list is still non-empty after the removal (main stays), so it has to be written,
        // and a directory in its place makes that fail.
        try fm.createDirectory(at: runners.appending(path: "tools/blocked"), withIntermediateDirectories: true)
        let staged = runners.appending(path: "bridge/wine/\(Self.other)/x86_64-windows/ntdll.dll")
        try fm.createDirectory(at: staged.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("patched".utf8).write(to: staged)

        #expect(throws: (any Error).self) { try remove(Self.other, runners: runners) }
        #expect(fm.fileExists(atPath: staged.path(percentEncoded: false)))

        #expect(RunnerStore.clonedBuilds(in: runners) == [Self.other, Self.main].sorted())
        #expect(RunnerInstaller.hasClone(forBuild: Self.other, runners: runners))
        #expect(try fm.contentsOfDirectory(atPath: runners.path(percentEncoded: false))
            .filter { $0.hasSuffix(".removing") }.isEmpty)
    }

    @Test("Removing a build deletes its prefix templates in every library and keeps the others")
    func removesThatBuildsTemplates() throws {
        let runners = try makeRunners(cloning: [Self.main, Self.other])
        defer { try? FileManager.default.removeItem(at: runners) }
        let fm = FileManager.default
        let libraries = ["internal", "external"].map {
            SteamLibrary(root: runners.appending(path: "libraries/\($0)"))
        }
        for library in libraries {
            for build in [Self.main, Self.other] {
                for template in SupportPaths.prefixTemplates(forBuild: build, in: library) {
                    try fm.createDirectory(
                        at: template.appending(path: "pfx/drive_c"), withIntermediateDirectories: true)
                }
            }
        }

        _ = try remove(Self.main, runners: runners, libraries: libraries)

        for library in libraries {
            let left = try fm.contentsOfDirectory(
                atPath: library.compatdata.appending(path: SupportPaths.prefixTemplateFolder)
                    .path(percentEncoded: false)
            ).sorted()
            #expect(left == SupportPaths.prefixTemplates(forBuild: Self.other, in: library)
                .map(\.lastPathComponent).sorted())
        }
    }

    @Test("Removing a build also clears templates left by builds removed while their drive was away")
    func removesTemplatesOfBuildsAlreadyGone() throws {
        let runners = try makeRunners(cloning: [Self.main, Self.other])
        defer { try? FileManager.default.removeItem(at: runners) }
        let fm = FileManager.default
        let library = SteamLibrary(root: runners.appending(path: "libraries/external"))
        let gone = SupportPaths.prefixTemplates(forBuild: "sikarugir-9.0-r1", in: library)
        for template in gone {
            try fm.createDirectory(at: template.appending(path: "pfx"), withIntermediateDirectories: true)
        }

        _ = try remove(Self.main, runners: runners, libraries: [library])

        for template in gone { #expect(!fm.fileExists(atPath: template.path(percentEncoded: false))) }
    }

    @Test("A template is named by the build and the unix arch, under notproton-template")
    func templateNamesMatchTheScript() throws {
        let library = SteamLibrary(root: URL(filePath: "/L"))
        let repo = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let script = try String(contentsOf: repo.appending(path: "dylib/feats/compat_run.sh"), encoding: .utf8)
        let expression = try #require(script.firstMatch(of: #/runner_id="([^"]+)"/#)).1
        let cache = script.split(separator: "\n").first { $0.contains("template_cache=\"") }
        #expect(cache?.contains("$(dirname \"$STEAM_COMPAT_DATA_PATH\")/\(SupportPaths.prefixTemplateFolder)\"") == true)
        let template = script.split(separator: "\n").first { $0.contains("template_dir=\"") }
        #expect(template?.contains("template_dir=\"$template_cache/$runner_id\"") == true)
        let name = expression.replacingOccurrences(of: "$np_build", with: Self.main)
            .replacingOccurrences(of: "${wine_unix##*/}", with: "x86_64-unix")
        #expect(SupportPaths.prefixTemplates(forBuild: Self.main, in: library).map(\.path)
            == [library.compatdata.appending(path: SupportPaths.prefixTemplateFolder).appending(path: name).path])
    }

    @Test("A build with a game still running on it is not removed")
    func keepsRunningBuild() throws {
        let runners = try makeRunners(cloning: [Self.main])
        defer { try? FileManager.default.removeItem(at: runners) }

        #expect(throws: StepFailure.self) { try remove(Self.main, runners: runners, running: true) }
        #expect(RunnerInstaller.hasClone(forBuild: Self.main, runners: runners))
    }

    @Test("A process runs from a clone only when its executable sits inside it")
    func readsRunningExecutables() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "np-ps-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let ps = dir.appending(path: "ps")
        try """
            #!/bin/sh
            echo "/launchd"
            echo "/R/sikarugir-11.0-r0/wine/bin/wineserver"
            """.write(to: ps, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: ps.path(percentEncoded: false))
        let path = ps.path(percentEncoded: false)

        #expect(RunnerInstaller.isRunning(from: URL(filePath: "/R/sikarugir-11.0-r0"), ps: path))
        #expect(!RunnerInstaller.isRunning(from: URL(filePath: "/R/sikarugir-11.0"), ps: path))
        #expect(!RunnerInstaller.isRunning(from: URL(filePath: "/R/sikarugir-10.0-r3"), ps: path))
        #expect(RunnerInstaller.isRunning(from: URL(filePath: "/R/x"), ps: "/nonexistent/ps"))
    }

    @Test("A build can be removed, and its staged copies and tool go with it")
    func removesBuild() throws {
        let runners = try makeRunners(cloning: [Self.main, Self.other])
        defer { try? FileManager.default.removeItem(at: runners) }
        let bridge = runners.appending(path: "bridge")
        let staged = NtdllPatcher.stagedCopy(of: .x86_64Windows, build: Self.other, in: bridge)
        try atomicReplace(staged, with: Data("patched".utf8), step: "test")

        #expect(try remove(Self.other, runners: runners))

        #expect(!RunnerInstaller.hasClone(forBuild: Self.other, runners: runners))
        #expect(RunnerInstaller.hasClone(forBuild: Self.main, runners: runners))
        #expect(!FileManager.default.fileExists(atPath: staged.path(percentEncoded: false)))
        let list = try String(contentsOf: runners.appending(path: "tools"), encoding: .utf8)
        #expect(list == CompatToolList.contents(SupportedRunners.tools(for: [SupportedRunners.sikarugir])))

        #expect(try remove(Self.main, runners: runners))
        #expect(try String(contentsOf: runners.appending(path: "tools"), encoding: .utf8).isEmpty)
    }

    @Test("A build with no clone reports rather than succeeding quietly")
    func refusesMissingBuild() throws {
        let runners = try makeRunners(cloning: [Self.main])
        defer { try? FileManager.default.removeItem(at: runners) }

        #expect(throws: StepFailure.self) {
            try remove(Self.other, runners: runners)
        }
    }

    @Test("A supported build whose payload never finished copying is listed as damaged")
    func damagedCloneIsListed() throws {
        let runners = try makeRunners(cloning: [])
        defer { try? FileManager.default.removeItem(at: runners) }

        try FileManager.default.createDirectory(
            at: SupportPaths.clonedRoot(forBuild: Self.main, runners: runners),
            withIntermediateDirectories: true
        )

        #expect(RunnerStore.damagedClones(in: runners) == [Self.main])
        #expect(RunnerStore.orphanedClones(in: runners).isEmpty)
        #expect(RunnerStore.installedBuilds(in: runners).isEmpty)
    }

    @Test("Every clone on disk lands in exactly one of the three lists")
    func cloneListsPartition() throws {
        let runners = try makeRunners(cloning: [Self.main, Self.other])
        defer { try? FileManager.default.removeItem(at: runners) }

        try FileManager.default.createDirectory(
            at: SupportPaths.clonedRoot(forBuild: "sikarugir-9.0-r1", runners: runners),
            withIntermediateDirectories: true
        )

        let installed = RunnerStore.installedBuilds(in: runners).map(\.id)
        let damaged   = RunnerStore.damagedClones(in: runners)
        let orphaned  = RunnerStore.orphanedClones(in: runners)
        let all       = installed + damaged + orphaned

        #expect(Set(all) == Set(RunnerStore.clonedBuilds(in: runners)))
        #expect(all.count == Set(all).count)
    }

    @Test("Clones of unsupported versions are listed apart from installed builds")
    func orphanedClonesAreFound() throws {
        let runners = try makeRunners(cloning: [Self.main, Self.other])
        defer { try? FileManager.default.removeItem(at: runners) }

        #expect(RunnerStore.orphanedClones(in: runners) == [Self.other])
        #expect(RunnerStore.installedBuilds(in: runners).map(\.id) == [Self.main])
    }

    @Test("An orphaned clone can be removed")
    func removesOrphanedClone() throws {
        let runners = try makeRunners(cloning: [Self.main, Self.other])
        defer { try? FileManager.default.removeItem(at: runners) }

        _ = try remove(Self.other, runners: runners)

        #expect(RunnerStore.orphanedClones(in: runners).isEmpty)
        #expect(RunnerInstaller.hasClone(forBuild: Self.main, runners: runners))
    }

    @Test("A clone's size counts the bytes it occupies")
    func measuresCloneSize() throws {
        let runners = try makeRunners(cloning: [Self.main])
        defer { try? FileManager.default.removeItem(at: runners) }
        let file = SupportPaths.clonedRoot(forBuild: Self.main, runners: runners)
            .appending(path: "lib/wine/blob")
        try Data(repeating: 0, count: 64 * 1024).write(to: file)

        #expect(RunnerStore.cloneSize(forBuild: Self.main, runners: runners) >= 64 * 1024)
    }
}
