// Patcher logic

import Foundation

enum RunnerPatcher {

    static let step = "Patch the compatibility tool"

    static let sikarugirBridge: [String: String] = [
        "steam.exe": "56979db411cb12b48610c09b8fc01db3c34bb3c7e31ea53f1b17dafaf7f98b70",
        "x86_64-windows/lsteamclient.dll": "2933ac86d886f1264fabfbb97f21f53967452fca2397f29ecdbd29f83616c7ac",
        "x86_64-unix/lsteamclient.so": "d71f954cf1c1a2355e9dfd7e8de593d8a4d1274117d42626394d4e95c7379a9c",
    ]

    static func builtins(for build: RunnerBuild, in root: URL) -> [(arch: String, name: String)] {
        [("", "steam.exe"), ("x86_64-windows", "lsteamclient.dll"), ("x86_64-unix", "lsteamclient.so")]
    }

    static func bridgeRoot(for build: RunnerBuild, in bridge: URL) -> URL {
        bridge.appending(path: build.id)
    }

    static func builtinPath(_ builtin: (arch: String, name: String)) -> String {
        builtin.arch.isEmpty ? builtin.name : "\(builtin.arch)/\(builtin.name)"
    }

    static func builtinDestination(_ builtin: (arch: String, name: String), in root: URL) -> URL {
        root.appending(path: builtin.arch.isEmpty ? "bin/\(builtin.name)" : "lib/wine/\(builtinPath(builtin))")
    }

    struct Outcome: Sendable {
        var ntdll: [WineArch] = []
        var builtins: [String] = []

        var wroteNothing: Bool { ntdll.isEmpty && builtins.isEmpty }
    }

    static func install(
        build: RunnerBuild, root: URL, bridge: URL = SupportPaths.bridge
    ) throws -> Outcome {
        let sources = bridgeRoot(for: build, in: bridge)
        for builtin in builtins(for: build, in: root) {
            let path = builtinPath(builtin)
            guard let hash = Digest.sha256IfPresent(sources.appending(path: path)),
                  hash == sikarugirBridge[path] else {
                throw StepFailure(step: step, detail: "Missing or unknown bridge file: \(path).")
            }
        }
        for (arch, hash) in build.patchedNtdll {
            guard Digest.sha256IfPresent(NtdllPatcher.stagedCopy(of: arch, build: build.id, in: bridge)) == hash else {
                throw StepFailure(step: step, detail: "Missing or unknown staged ntdll: \(arch.rawValue).")
            }
        }
        if verify(build: build, root: root, bridge: bridge).isEmpty { return Outcome() }
        let staging = root.deletingLastPathComponent().appending(path: ".patch-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: staging) }
        try RunnerInstaller.cloneTree(from: root, to: staging)
        var outcome = Outcome()
        outcome.ntdll = try installNtdll(build: build, root: staging, bridge: bridge)
        outcome.builtins = try installBuiltins(build: build, root: staging, bridge: sources)
        let wrong = verify(build: build, root: staging, bridge: bridge)
        guard wrong.isEmpty else { throw StepFailure(step: step, detail: wrong.joined(separator: "\n")) }
        try RunnerInstaller.publish(staging, at: root, occupied: true)
        return outcome
    }

    static func verify(
        build: RunnerBuild, root: URL, bridge: URL = SupportPaths.bridge
    ) -> [String] {
        var wrong: [String] = []
        for arch in WineArch.allCases {
            guard let expected = build.patchedNtdll[arch] else { continue }
            let live = root.appending(path: "lib/wine/\(arch.rawValue)/ntdll.dll")
            guard let actual = Digest.sha256IfPresent(live) else {
                wrong.append("\(arch.rawValue)/ntdll.dll is missing")
                continue
            }
            if actual != expected {
                wrong.append("\(arch.rawValue)/ntdll.dll is not the patched copy")
            }
        }
        for builtin in builtins(for: build, in: root) {
            let installed = Digest.sha256IfPresent(
                builtinDestination(builtin, in: root))
            guard let installed else {
                wrong.append("\(builtin.arch)/\(builtin.name) is missing")
                continue
            }

            let staged = sikarugirBridge[builtinPath(builtin)]
            if let staged, staged != installed {
                wrong.append("\(builtin.arch)/\(builtin.name) is out of date")
            }
        }

        if Digest.sha256IfPresent(SikarugirSource.unixLoader(inRoot: root)) != build.loaderSHA256 {
            wrong.append("bin/wine is missing or does not match the pinned loader")
        }
        do { try RunnerInstaller.verifyClone(build: build, root: root) }
        catch { wrong.append(error.localizedDescription) }
        return wrong
    }

    private static func installNtdll(
        build: RunnerBuild, root: URL, bridge: URL
    ) throws -> [WineArch] {
        var installed: [WineArch] = []

        for arch in WineArch.allCases {
            guard let expected = build.patchedNtdll[arch] else { continue }
            let staged = NtdllPatcher.stagedCopy(of: arch, build: build.id, in: bridge)

            guard Digest.sha256IfPresent(staged) == expected else {
                throw StepFailure(
                    step: step,
                    detail: "The patched \(arch.rawValue) ntdll has not been copied into place."
                )
            }

            let live = root.appending(path: "lib/wine/\(arch.rawValue)/ntdll.dll")
            if Digest.sha256IfPresent(live) == expected { continue }

            try keepClean(live)
            try atomicReplace(live, with: Data(contentsOf: staged), step: step)
            installed.append(arch)
        }

        return installed
    }

    private static func installBuiltins(build: RunnerBuild, root: URL, bridge: URL) throws -> [String] {
        var installed: [String] = []

        for builtin in builtins(for: build, in: root) {
            let source = bridge.appending(path: builtinPath(builtin))
            guard FileManager.default.fileExists(atPath: source.path(percentEncoded: false)) else {
                throw StepFailure(
                    step: step,
                    detail: "\(builtin.arch)/\(builtin.name) is not in the bridge. "
                            + "Install NotProton first."
                )
            }

            let destination = builtinDestination(builtin, in: root)
            if Digest.sha256IfPresent(source) == Digest.sha256IfPresent(destination) { continue }

            try atomicReplace(destination, with: Data(contentsOf: source), step: step)
            installed.append("\(builtin.arch)/\(builtin.name)")
        }

        return installed
    }

    private static func keepClean(_ file: URL) throws {
        let backup = Clean.copy(of: file)
        guard backup == file else { return }

        let destination = file.appendingPathExtension(Clean.backupSuffix)
        let result = try Shell.run("/bin/cp", [
            "-p", file.path(percentEncoded: false), destination.path(percentEncoded: false),
        ])
        guard result.status == 0 else {
            throw StepFailure(
                step: step,
                detail: "Keeping the shipped \(file.lastPathComponent) failed. "
                    + result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }
}
