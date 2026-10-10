// Patcher logic

import Foundation

enum RunnerPatcher {

    static let step = "Patch the compatibility tool"

    private static let dyldEntitlement = "com.apple.security.cs.allow-dyld-environment-variables"

    static let windowsBuiltins = [
        (arch: "i386-windows", name: "lsteamclient.dll"),
        (arch: "x86_64-windows", name: "lsteamclient.dll"),
    ]

    static func builtins(in root: URL) -> [(arch: String, name: String)] {
        windowsBuiltins + unixArches(in: root).map { (arch: $0, name: "lsteamclient.so") }
    }

    static let sikarugirBridge: [String: String] = [
        "steam.exe": "56979db411cb12b48610c09b8fc01db3c34bb3c7e31ea53f1b17dafaf7f98b70",
        "x86_64-windows/lsteamclient.dll": "2933ac86d886f1264fabfbb97f21f53967452fca2397f29ecdbd29f83616c7ac",
        "x86_64-unix/lsteamclient.so": "d71f954cf1c1a2355e9dfd7e8de593d8a4d1274117d42626394d4e95c7379a9c",
    ]

    static func builtins(for build: RunnerBuild, in root: URL) -> [(arch: String, name: String)] {
        if build.origin == .sikarugir {
            return [("", "steam.exe"), ("x86_64-windows", "lsteamclient.dll"), ("x86_64-unix", "lsteamclient.so")]
        }
        return builtins(in: root)
    }

    static func bridgeRoot(for build: RunnerBuild, in bridge: URL) -> URL {
        build.origin == .sikarugir ? bridge.appending(path: build.id) : bridge
    }

    static func builtinPath(_ builtin: (arch: String, name: String)) -> String {
        builtin.arch.isEmpty ? builtin.name : "\(builtin.arch)/\(builtin.name)"
    }

    static func builtinDestination(_ builtin: (arch: String, name: String), in root: URL) -> URL {
        root.appending(path: builtin.arch.isEmpty ? "bin/\(builtin.name)" : "lib/wine/\(builtinPath(builtin))")
    }

    static func unixArches(in root: URL) -> [String] {
        let arches = unixLoaders(in: root).compactMap { loader in
            loader.pathComponents.last { $0.hasSuffix("-unix") }
        }
        let present = ["aarch64-unix", "x86_64-unix"].filter { arches.contains($0) }
        return present.isEmpty ? ["x86_64-unix"] : present
    }

    static func unixArch(in root: URL) -> String {
        unixArches(in: root)[0]
    }

    struct Outcome: Sendable {
        var ntdll: [WineArch] = []
        var builtins: [String] = []
        var loaders: [String] = []

        var wroteNothing: Bool { ntdll.isEmpty && builtins.isEmpty && loaders.isEmpty }
    }

    static func install(
        build: RunnerBuild, root: URL, bridge: URL = SupportPaths.bridge
    ) throws -> Outcome {
        let sources = bridgeRoot(for: build, in: bridge)
        for builtin in builtins(for: build, in: root) {
            let path = builtinPath(builtin)
            guard let hash = Digest.sha256IfPresent(sources.appending(path: path)),
                  build.origin != .sikarugir || hash == sikarugirBridge[path] else {
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
        if build.origin == .crossOver {
            outcome.loaders = try grantLoaderEntitlement(root: staging)
        }
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

            let staged = build.origin == .sikarugir ? sikarugirBridge[builtinPath(builtin)] : Digest.sha256IfPresent(
                bridge.appending(path: builtinPath(builtin)))
            if let staged, staged != installed {
                wrong.append("\(builtin.arch)/\(builtin.name) is out of date")
            }
        }

        if build.origin == .sikarugir {
            if Digest.sha256IfPresent(SikarugirSource.unixLoader(inRoot: root)) != build.loaderSHA256 {
                wrong.append("bin/wine is missing or does not match the pinned loader")
            }
            do { try RunnerInstaller.verifyClone(build: build, root: root) }
            catch { wrong.append(error.localizedDescription) }
            return wrong
        }
        let loaders = unixLoaders(in: root)
        if loaders.isEmpty { wrong.append("No Wine loaders found") }
        for loader in loaders {
            let granted = entitlements(of: loader)
            if granted?.contains(restrictedEntitlement) == true {
                if !signatureIsValid(signingTarget(for: loader)) {
                    wrong.append("\(name(of: loader)) has a broken signature")
                }
            } else if granted?.contains(dyldEntitlement) != true {
                wrong.append("\(name(of: loader)) is missing the dyld entitlement")
            }
        }

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

    private static func grantLoaderEntitlement(root: URL) throws -> [String] {
        var signed: [String] = []

        for loader in unixLoaders(in: root) {
            let existing = entitlements(of: loader)
            if existing?.contains(restrictedEntitlement) == true { continue }
            if existing?.contains(dyldEntitlement) == true,
               signatureIsValid(signingTarget(for: loader)) { continue }

            guard let existing, !existing.isEmpty else {
                throw StepFailure(
                    step: step,
                    detail: "\(name(of: loader)) carries no entitlements to extend."
                )
            }

            do {
                try sign(loader, addingTo: existing)
            } catch {
                restoreClean(loader)
                throw error
            }
            signed.append(name(of: loader))
        }

        return signed
    }

    static func unixLoaders(in root: URL) -> [URL] {
        let fm = FileManager.default
        let wine = root.appending(path: "lib/wine")
        let entries = (try? fm.contentsOfDirectory(at: wine, includingPropertiesForKeys: nil)) ?? []

        return entries
            .filter { $0.lastPathComponent.hasSuffix("-unix") }
            .flatMap { [$0.appending(path: "wine"), $0.appending(path: "wine.app/Contents/MacOS/wine")] }
            .filter { fm.fileExists(atPath: $0.path(percentEncoded: false)) }
            .sorted { $0.path < $1.path }
    }

    static func name(of loader: URL) -> String {
        let parts = loader.pathComponents
        guard let arch = parts.lastIndex(where: { $0.hasSuffix("-unix") }) else {
            return loader.lastPathComponent
        }
        return parts[arch...].joined(separator: "/")
    }

    private static func entitlements(of loader: URL) -> String? {
        guard let result = try? Shell.run(
            "/usr/bin/codesign", ["-d", "--entitlements", ":-", loader.path(percentEncoded: false)]
        ), result.status == 0 else { return nil }
        return result.stdout
    }

    private static func sign(_ loader: URL, addingTo existing: String) throws {
        let plist = FileManager.default.temporaryDirectory
            .appending(path: "np-entitlements-\(UUID().uuidString).plist")
        defer { try? FileManager.default.removeItem(at: plist) }

        try Data(existing.utf8).write(to: plist)
        _ = try Shell.run("/usr/libexec/PlistBuddy", [
            "-c", "Add :\(dyldEntitlement) bool true", plist.path(percentEncoded: false),
        ])

        try keepClean(loader)
        let target = signingTarget(for: loader)
        let result = try Shell.run("/usr/bin/codesign", [
            "-f", "-s", "-", "--options", "runtime",
            "--entitlements", plist.path(percentEncoded: false),
            target.path(percentEncoded: false),
        ])
        guard result.status == 0 else {
            throw StepFailure(
                step: step,
                detail: result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }


        guard entitlements(of: loader)?.contains(dyldEntitlement) == true else {
            throw StepFailure(
                step: step,
                detail: "\(name(of: loader)) was re-signed without the dyld entitlement."
            )
        }
    }

    private static func signingTarget(for loader: URL) -> URL {
        enclosingBundle(of: loader) ?? loader
    }

    private static func enclosingBundle(of loader: URL) -> URL? {
        var candidate = loader.deletingLastPathComponent()
        while candidate.pathComponents.count > 1 {
            if candidate.pathExtension == "app" { return candidate }
            candidate = candidate.deletingLastPathComponent()
        }
        return nil
    }

    static let restrictedEntitlement = "com.apple.developer.cross-architecture-support"

    private static func signatureIsValid(_ target: URL) -> Bool {
        guard let result = try? Shell.run(
            "/usr/bin/codesign", ["--verify", "--strict", target.path(percentEncoded: false)]
        ) else { return false }
        return result.status == 0
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

    private static func restoreClean(_ file: URL) {
        let backup = file.appendingPathExtension(Clean.backupSuffix)
        guard FileManager.default.fileExists(atPath: backup.path(percentEncoded: false)) else { return }
        _ = try? Shell.run("/bin/cp", [
            "-p", backup.path(percentEncoded: false), file.path(percentEncoded: false),
        ])
    }

}
