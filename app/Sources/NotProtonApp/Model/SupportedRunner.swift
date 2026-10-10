// The Sikarugir build the runner clones from. The ntdll hook sites are hardcoded RVAs, so
// only a build pinned here (loader, clean and patched ntdll hashes) can be patched.

import Foundation

enum WineArch: String, Sendable, CaseIterable {
    case x86_64Windows = "x86_64-windows"
    case i386Windows = "i386-windows"
}

struct RunnerBuild: Sendable, Equatable, Identifiable {
    // Names the directory under runners/ and keys the ntdll hash tables. Changing it orphans
    // an installed runner.
    let bundleVersion: String

    // Display only, never identity.
    let releaseVersion: String

    let loaderSHA256: String

    let cleanNtdll: [WineArch: String]
    let patchedNtdll: [WineArch: String]

    var tools: [CompatTool] = []

    var id: String { bundleVersion }

    var displayVersion: String { "\(releaseVersion) Rosetta" }
}

struct CompatTool: Sendable, Hashable, Identifiable {
    // The Sikarugir engine is x86_64 Wine running under Rosetta, so this is the only flavor.
    // It stays in the tool list and template names the dylib and the run script read.
    enum Flavor: String, Sendable, CaseIterable {
        case rosetta

        var name: String { "Rosetta" }
        var unixDir: String { "x86_64-unix" }
    }

    let name: String
    let flavor: Flavor
    let display: String

    var id: String { name }

    var prefixArch: PrefixArch { .x86_64 }
}

struct InstalledTool: Sendable, Hashable, Identifiable {
    let tool: CompatTool
    let build: String

    var id: String { tool.name }
    var name: String { tool.name }
    var display: String { tool.display }
}

enum SupportedRunners {

    static func tools(for builds: [RunnerBuild]) -> [InstalledTool] {
        let installed = Set(builds.map(\.id))
        return all.filter { installed.contains($0.id) }.flatMap { build in
            build.tools.map { InstalledTool(tool: $0, build: build.id) }
        }
    }

    static let sikarugir = RunnerBuild(
        bundleVersion: "sikarugir-11.0-r0", releaseVersion: "11.0",
        loaderSHA256: "874d068ebd42114388e77edffc526d85460350f9d599d074acd951a2f0a32e2c",
        cleanNtdll: [
            .x86_64Windows: "da7e1ea5d7e6bca3192ff5aa4a603302a9572233a1dbe02c9c8d85505101f676",
            .i386Windows: "e1ce5ae37f57cee3c4fea80b681fbf64e3f0611b36d5c9125851c03dea985589",
        ],
        patchedNtdll: [
            .x86_64Windows: "ef8e99712f845f5c4e7ee01a0475d3ccaf84114d54a0a6c962808fee34b68b29",
            .i386Windows: "60c6a031ea679833d6f8a81e4873cb60d98815ed9f7220c2046ed58443cfcc03",
        ],
        tools: [CompatTool(name: "notproton-sikarugir-11.0-r0", flavor: .rosetta,
            display: "Sikarugir 11.0 (experimental)")]
    )

    static let all: [RunnerBuild] = [sikarugir]

    static func build(id: String) -> RunnerBuild? {
        all.first { $0.id == id }
    }

    static func displayVersion(forID id: String) -> String {
        build(id: id)?.displayVersion ?? id
    }

    static var versionList: String { sikarugir.releaseVersion }
}
