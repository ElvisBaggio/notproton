import Foundation

struct SikarugirInstall: Sendable {
    let root: URL
    let build: RunnerBuild
}

enum SikarugirSource {
    static let version = "wine sikarugir 11.0 (revision 0)"
    // Exact hashes also pin the Mach-O x86_64 and PE x86_64/i386 architectures.
    static let files: [String: String] = [
        "bin/wine": SupportedRunners.sikarugir.loaderSHA256,
        "bin/wineserver": "2cd179014ba76e2dfe5748a5debb40eeff0ff7e93a35948d9e1c2ca0ef4ad235",
        "lib/wine/x86_64-unix/ntdll.so": "c9948aab11b674b182c8dd41e212cb0be10568adeb47a28721151561456f5b6c",
        "lib/wine/x86_64-windows/ntdll.dll": SupportedRunners.sikarugir.cleanNtdll[.x86_64Windows]!,
        "lib/wine/i386-windows/ntdll.dll": SupportedRunners.sikarugir.cleanNtdll[.i386Windows]!,
    ]

    static func unixLoader(inRoot root: URL) -> URL { root.appending(path: "bin/wine") }

    static func frameworks(inRoot root: URL) -> URL {
        // Source wrappers keep Frameworks in Contents; isolated clones keep it inside wine.
        if root.deletingLastPathComponent().lastPathComponent == "SharedSupport" {
            return root.deletingLastPathComponent().deletingLastPathComponent().appending(path: "Frameworks")
        }
        return root.appending(path: "Frameworks")
    }

    static func inspect(
        root: URL, hash: (URL) -> String? = Digest.sha256IfPresent
    ) throws -> SikarugirInstall {
        guard let text = try? String(contentsOf: root.appending(path: "version"), encoding: .utf8),
              text.trimmingCharacters(in: .whitespacesAndNewlines) == version else {
            throw StepFailure(step: "Verify Sikarugir", detail: "Unknown or missing engine version.")
        }
        let resolved = root.resolvingSymlinksInPath().path + "/"
        for (path, expected) in files.sorted(by: { $0.key < $1.key }) {
            let file = root.appending(path: path)
            guard file.resolvingSymlinksInPath().path.hasPrefix(resolved), hash(file) == expected else {
                throw StepFailure(step: "Verify Sikarugir", detail: "\(path) is missing or is not Sikarugir 11.0 r0 x86_64/Rosetta.")
            }
        }
        var directory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: frameworks(inRoot: root).path, isDirectory: &directory),
              directory.boolValue else {
            throw StepFailure(step: "Verify Sikarugir", detail: "Required Frameworks directory is missing.")
        }
        return SikarugirInstall(root: root, build: SupportedRunners.sikarugir)
    }

    static let unsupportedAdvice =
        "NotProton supports only Sikarugir 11.0 revision 0 (x86_64/Rosetta). Select that Sikarugir app, or its wine folder."

    // A picked Sikarugir app holds the engine at Contents/SharedSupport/wine; the wine
    // folder itself is accepted too.
    static func engineRoot(forPicked url: URL) -> URL {
        if FileManager.default.fileExists(atPath: url.appending(path: "version").path(percentEncoded: false)) {
            return url
        }
        return url.appending(path: "Contents/SharedSupport/wine")
    }

    static func pick(_ url: URL) throws -> SikarugirInstall {
        do {
            return try inspect(root: engineRoot(forPicked: url))
        } catch let failure as StepFailure {
            throw StepFailure(
                step: failure.step,
                detail: "\(url.lastPathComponent) cannot be used. \(failure.detail) \(unsupportedAdvice)")
        }
    }

    static func discover(searchRoots: [URL] = [
        URL(filePath: "/Applications"), SupportPaths.home.appending(path: "Applications"),
        SupportPaths.home.appending(path: "Applications/Sikarugir"),
    ]) -> [SikarugirInstall] {
        let candidates = searchRoots.flatMap {
            (try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)) ?? []
        }.filter { $0.pathExtension == "app" }
        var seen = Set<String>()
        return candidates.sorted { $0.path < $1.path }.compactMap {
            let root = $0.appending(path: "Contents/SharedSupport/wine")
            guard seen.insert(root.resolvingSymlinksInPath().path).inserted else { return nil }
            return try? inspect(root: root)
        }
    }
}
