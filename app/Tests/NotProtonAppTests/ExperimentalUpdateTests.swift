import Foundation
import Testing

@testable import NotProtonApp

// Only pure functions here: instantiating SPUStandardUpdaterController would start Sparkle.
@Suite("Experimental Sikarugir bundle")
struct ExperimentalUpdateTests {

    private static let repo = URL(filePath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    private static func infoPlist() throws -> [String: Any] {
        let data = try Data(contentsOf: repo.appending(path: "app/Info.plist"))
        return try #require(
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
    }

    private static func text(_ path: String) throws -> String {
        try String(contentsOf: repo.appending(path: path), encoding: .utf8)
    }

    @Test func testExperimentalBundleDoesNotStartUpstreamUpdater() {
        #expect(!AppUpdater.shouldStart(info: ["NPExperimental": true]))
    }

    @Test func testExistingBundleKeepsUpdaterBehavior() throws {
        #expect(AppUpdater.shouldStart(info: nil))
        #expect(AppUpdater.shouldStart(info: [:]))
        #expect(AppUpdater.shouldStart(info: ["NPExperimental": false]))

        // The checked-in plist is the upstream app: its feed stays and it is not experimental.
        let info = try Self.infoPlist()
        #expect(AppUpdater.shouldStart(info: info))
        #expect(info["SUFeedURL"] != nil)
        #expect(info["SUPublicEDKey"] != nil)
        #expect(info["NPExperimental"] == nil)
        #expect(info["CFBundleIdentifier"] as? String == "com.notproton.NotProton")
    }

    @Test("The experimental target stamps its own identity and leaves NotProton.app alone")
    func experimentalTargetIsDistinct() throws {
        let makefile = try Self.text("Makefile")
        #expect(makefile.contains("com.notproton.NotProton.sikarugir"))
        #expect(makefile.contains("NotProton Sikarugir.app"))
        #expect(makefile.contains(#"Delete :SUFeedURL"#))
        #expect(makefile.contains(#"Delete :SUPublicEDKey"#))
        #expect(makefile.contains("Add :NPExperimental bool true"))

        // deploy only looks at the upstream app names.
        let launchable = try #require(
            makefile.split(separator: "\n").first { $0.hasPrefix("LAUNCHABLE_BUNDLES") })
        #expect(!launchable.contains("Sikarugir"))
    }

    @Test("Every packaged Sikarugir file is checked before the experimental bundle builds")
    func experimentalTargetRequiresThePinnedBridge() throws {
        let makefile = try Self.text("Makefile")
        let start = try #require(makefile.range(of: "sikarugir-payload-check:"))
        let recipe = String(makefile[start.lowerBound...].prefix(600))
        for path in RunnerPatcher.sikarugirBridge.keys { #expect(recipe.contains(path)) }
        #expect(makefile.contains("app-sikarugir: sikarugir-payload-check app"))
    }

    @Test("Every detour resource on disk is declared by the package, Sikarugir ones included")
    func detoursAreDeclared() throws {
        let manifest = try Self.text("app/Package.swift")
        let resources = Self.repo.appending(path: "app/Sources/NotProtonApp/Resources")
        let bins = try FileManager.default.contentsOfDirectory(atPath: resources.path)
            .filter { $0.hasPrefix("detour") && $0.hasSuffix(".bin") }
        #expect(bins.contains("detour2-sikarugir.bin"))
        #expect(bins.contains("detour32-sikarugir.bin"))
        for bin in bins { #expect(manifest.contains(#".copy("Resources/\#(bin)")"#), "\(bin) is not packaged") }
    }
}
