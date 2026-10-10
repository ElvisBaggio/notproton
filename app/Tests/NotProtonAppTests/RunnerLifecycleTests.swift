import Foundation
import Testing

@testable import NotProtonApp

@Suite("Runner lifecycle by origin")
struct RunnerLifecycleTests {
    private func temporary() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appending(path: "t07-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func write(_ text: String, at file: URL) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: file)
    }

    private func refuses(_ body: () throws -> Void) -> Bool {
        do { try body(); return false } catch { return true }
    }

    private func prepare(_ build: RunnerBuild, in work: URL, license: (URL) -> CrossOverLicense.Status) throws {
        let runners = work.appending(path: "runners")
        let root = SupportPaths.clonedRoot(forBuild: build.id, runners: runners)
        try FileManager.default.createDirectory(at: root.appending(path: "lib/wine"), withIntermediateDirectories: true)
        let run = work.appending(path: "payload-run")
        try write("#!/bin/sh\n", at: run)
        _ = try RunnerSetup.prepare(build, runners: runners, bridge: work.appending(path: "bridge"),
            toolList: work.appending(path: "tools"), compatTools: work.appending(path: "compatibilitytools.d"),
            runScript: { run }, license: license, verify: { _, _ in }, stage: { _, _, _ in [] },
            patch: { _, _, _ in RunnerPatcher.Outcome() })
    }

    @Test func testSikarugirSetupDoesNotCallCrossOverLicense() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        var called = false
        try prepare(SupportedRunners.sikarugir, in: work) { _ in
            called = true
            return CrossOverLicense.Status(licensed: false, detail: "unlicensed", diagnostic: "test")
        }
        #expect(!called)
        // The same entry point repairs an existing clone, still without a CrossOver license.
        try prepare(SupportedRunners.sikarugir, in: work) { _ in
            called = true
            return CrossOverLicense.Status(licensed: false, detail: "unlicensed", diagnostic: "test")
        }
        #expect(!called)
    }

    @Test func testCrossOverStillRequiresLicense() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        var called = false
        #expect(refuses {
            try prepare(SupportedRunners.all[0], in: work) { _ in
                called = true
                return CrossOverLicense.Status(licensed: false, detail: "unlicensed", diagnostic: "test")
            }
        })
        #expect(called)
    }

    @Test func testRepairVerifiesSikarugirLoader() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        let wrong = RunnerPatcher.verify(build: SupportedRunners.sikarugir, root: work, bridge: work)
        #expect(wrong.contains { $0.hasPrefix("bin/wine") })
    }

    @Test func testZeroCrossOverLoadersRefused() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        #expect(RunnerPatcher.verify(build: SupportedRunners.all[0], root: work).contains("No Wine loaders found"))
    }

    @Test func testFailedPatchPreservesExistingClone() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        let root = work.appending(path: "runner")
        let bridge = work.appending(path: "bridge")
        let build = RunnerBuild(bundleVersion: "test", releaseVersion: "test", flavor: nil,
                                loaderSHA256: "", cleanNtdll: [:], patchedNtdll: [:])
        try write("unsigned loader", at: root.appending(path: "lib/wine/x86_64-unix/wine"))
        for builtin in RunnerPatcher.builtins(in: root) {
            try write("new builtin", at: bridge.appending(path: RunnerPatcher.builtinPath(builtin)))
            try write("previous builtin", at: RunnerPatcher.builtinDestination(builtin, in: root))
        }
        #expect(refuses { _ = try RunnerPatcher.install(build: build, root: root, bridge: bridge) })
        for builtin in RunnerPatcher.builtins(in: root) {
            #expect(try String(contentsOf: RunnerPatcher.builtinDestination(builtin, in: root), encoding: .utf8) == "previous builtin")
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: work.path).sorted() == ["bridge", "runner"])
    }

    @Test func testPublicationFailurePreservesDestination() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        let target = work.appending(path: "target")
        try write("old", at: target.appending(path: "marker"))
        #expect(refuses { try RunnerInstaller.publish(work.appending(path: "absent"), at: target, occupied: true) })
        #expect(try String(contentsOf: target.appending(path: "marker"), encoding: .utf8) == "old")
        let staging = work.appending(path: "staging")
        try write("new", at: staging.appending(path: "marker"))
        try RunnerInstaller.publish(staging, at: target, occupied: true)
        #expect(try String(contentsOf: target.appending(path: "marker"), encoding: .utf8) == "new")
        #expect(try String(contentsOf: staging.appending(path: "marker"), encoding: .utf8) == "old")
    }

    @Test func testSikarugirBridgeDoesNotReplaceCrossOverPayload() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        let build = SupportedRunners.sikarugir
        #expect(RunnerPatcher.bridgeRoot(for: build, in: work) == work.appending(path: build.id))
        #expect(RunnerPatcher.bridgeRoot(for: SupportedRunners.all[0], in: work) == work)
        #expect(RunnerPatcher.builtins(for: build, in: work).map { RunnerPatcher.builtinPath($0) }.sorted() == RunnerPatcher.sikarugirBridge.keys.sorted())
        #expect(RunnerPatcher.builtins(for: build, in: work).allSatisfy { !$0.arch.hasPrefix("i386") && !$0.arch.hasPrefix("aarch64") })
        let shared = work.appending(path: "x86_64-windows/lsteamclient.dll")
        try write("CrossOver unchanged", at: shared)
        #expect(refuses { _ = try RunnerPatcher.install(build: build, root: work.appending(path: "runner"), bridge: work) })
        #expect(try String(contentsOf: shared, encoding: .utf8) == "CrossOver unchanged")
    }

    @Test func testCorrectedPayloadPins() throws {
        let build = SupportedRunners.sikarugir
        let patches = NtdllPatcher.patches(for: build)
        #expect(patches.count == 2)
        #expect(build.patchedNtdll[.x86_64Windows] == "ef8e99712f845f5c4e7ee01a0475d3ccaf84114d54a0a6c962808fee34b68b29")
        #expect(build.patchedNtdll[.i386Windows] == "60c6a031ea679833d6f8a81e4873cb60d98815ed9f7220c2046ed58443cfcc03")
        for patch in patches { #expect(Digest.sha256(of: try NtdllPatcher.payload(for: patch)) == patch.payloadSHA256) }
    }

    @Test func testUnknownHashRefusesInstall() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        let source = work.appending(path: "unknown.dll")
        let target = work.appending(path: "target.dll")
        try write("unknown", at: source)
        try write("previous", at: target)
        #expect(refuses { _ = try NtdllPatcher.write(NtdllPatcher.patches(for: SupportedRunners.sikarugir)[0],
            build: SupportedRunners.sikarugir, from: source, to: target) })
        #expect(try String(contentsOf: target, encoding: .utf8) == "previous")
    }

    @Test func testFrameworkMapAndEscapingSymlink() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        let frameworks = work.appending(path: "Frameworks")
        try write("dylib", at: frameworks.appending(path: "nested/library"))
        try FileManager.default.createSymbolicLink(atPath: frameworks.appending(path: "internal").path,
                                                   withDestinationPath: "nested/library")
        let before = try RunnerInstaller.frameworkMap(frameworks)
        #expect(before["internal"] == "link:nested/library")
        try write("changed", at: frameworks.appending(path: "nested/library"))
        #expect(try before != RunnerInstaller.frameworkMap(frameworks))
        try FileManager.default.createSymbolicLink(atPath: frameworks.appending(path: "escape").path,
                                                   withDestinationPath: "../../outside")
        #expect(refuses { _ = try RunnerInstaller.frameworkMap(frameworks) })
    }

    @Test func testLeftoverRemovalsByOrigin() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        for name in [".crossover-test.removing", ".sikarugir-11.0-r0.removing", ".other.removing"] {
            try write("marker", at: work.appending(path: "\(name)/marker"))
        }
        RunnerInstaller.removeLeftoverRemovals(runners: work)
        #expect(try FileManager.default.contentsOfDirectory(atPath: work.path) == [".other.removing"])
    }

    @Test func testPrefixTemplatesByOrigin() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        let library = SteamLibrary(root: work, volume: nil)
        let folder = library.compatdata.appending(path: SupportPaths.prefixTemplateFolder)
        for name in ["crossover-test-x86_64-unix", "sikarugir-11.0-r0-x86_64-unix", "keep"] {
            try write("marker", at: folder.appending(path: "\(name)/marker"))
        }
        #expect(RunnerInstaller.removePrefixTemplates(keeping: [], libraries: [library]).isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path) == ["keep"])
    }

    @Test func testSteamBuildUsesInstalledChannelManifest() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        try write("\"version\" \"100\"", at: work.appending(path: "package/steam_client_osx.manifest"))
        #expect(try SteamInstaller.activeClientBuild(in: work) == 100)
        try write("publicbeta", at: work.appending(path: "package/beta"))
        try write("\"version\" \"200\"", at: work.appending(path: "package/steam_client_publicbeta_signed-2_osx.manifest"))
        try write("\"version\" \"300\"", at: work.appending(path: "package/steam_client_publicbeta_signed-2_osx"))
        #expect(try SteamInstaller.activeClientBuild(in: work) == 200)
        try write("unknown", at: work.appending(path: "package/beta"))
        #expect(refuses { _ = try SteamInstaller.activeClientBuild(in: work) })
    }

    @Test func testSignatureBuildContract() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        let profile = work.appending(path: "100.json")
        try write("{\"steam_build\":100}", at: profile)
        try SteamInstaller.requireSignatureProfile(activeBuild: 100, profiles: [profile])
        #expect(refuses { try SteamInstaller.requireSignatureProfile(activeBuild: 200, profiles: [profile]) })
        #expect(refuses { try SteamInstaller.requireSignatureProfile(activeBuild: 100, profiles: [profile, profile]) })
        try write("{\"steam_build\":200}", at: profile)
        #expect(refuses { try SteamInstaller.requireSignatureProfile(activeBuild: 200, profiles: [profile]) })
        #expect(refuses { try SteamInstaller.requireSignatureProfile(activeBuild: 100, profiles: []) })
    }

    @Test func testSteamMismatchRefusedBeforeHooks() throws {
        let work = try temporary()
        defer { try? FileManager.default.removeItem(at: work) }
        let app = work.appending(path: "Steam.app")
        try write("original", at: app.appending(path: "Contents/Info.plist"))
        let profile = work.appending(path: "100.json")
        try write("{\"steam_build\":100}", at: profile)
        let client = work.appending(path: "client")
        try write("\"version\" \"200\"", at: client.appending(path: "package/steam_client_osx.manifest"))
        let payload = InstallPayload.Located(dylib: work, overlayShim: work, iconmaker: work,
            appinfo: work, run: work, builtAt: 1, signatures: [profile])
        #expect(refuses {
            _ = try SteamInstaller.run(payload: payload, bridgePayload: BridgePayload.Located(sources: []),
                app: app, deployedVersion: work.appending(path: "support/version"), clientRoot: client,
                patchRunner: { _, _, _ in preconditionFailure("guard must precede runner patch") },
                stopClient: { _, _ in preconditionFailure("guard must precede Steam control") },
                register: { _ in preconditionFailure("guard must precede registration") })
        })
        #expect(try String(contentsOf: app.appending(path: "Contents/Info.plist"), encoding: .utf8) == "original")
        #expect(!FileManager.default.fileExists(atPath: work.appending(path: "support").path))
    }
}
