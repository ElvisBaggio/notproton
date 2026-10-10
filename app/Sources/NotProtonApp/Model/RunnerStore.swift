// Checks the copied Sikarugir runner for status display

import Foundation

enum RunnerState: Sendable, Equatable {
    case none
    case ready(builds: [String])
    case unpatched(builds: [String], problems: [String])

    var builds: [String] {
        switch self {
        case .none: []
        case .ready(let builds): builds
        case .unpatched(let builds, _): builds
        }
    }
}

enum RunnerStore {

    static func state(
        runners: URL = SupportPaths.runners,
        verify: @Sendable (RunnerBuild, URL) -> [String] = {
            RunnerPatcher.verify(build: $0, root: $1)
        }
    ) -> RunnerState {
        let installed = installedBuilds(in: runners)
        guard !installed.isEmpty else { return .none }

        var unpatched: [String] = []
        var problems: [String] = []
        for build in installed {
            let found = verify(build, SupportPaths.clonedRoot(forBuild: build.id, runners: runners))
            guard !found.isEmpty else { continue }
            unpatched.append(build.id)
            problems += found.map { "\(build.id): \($0)" }
        }
        if unpatched.isEmpty { return .ready(builds: installed.map(\.id)) }
        return .unpatched(builds: unpatched, problems: problems)
    }

    static func clonedBuilds(in runners: URL = SupportPaths.runners) -> [String] {
        let fm = FileManager.default
        let entries = (try? fm.contentsOfDirectory(at: runners, includingPropertiesForKeys: nil)) ?? []
        return entries
            .map(\.lastPathComponent)
            .filter { $0.hasPrefix("sikarugir-") }
            .sorted()
    }

    static func orphanedClones(in runners: URL = SupportPaths.runners) -> [String] {
        clonedBuilds(in: runners).filter { SupportedRunners.build(id: $0) == nil }
    }

    static func damagedClones(in runners: URL = SupportPaths.runners) -> [String] {
        clonedBuilds(in: runners).filter {
            SupportedRunners.build(id: $0) != nil
                && !RunnerInstaller.hasClone(forBuild: $0, runners: runners)
        }
    }

    static func cloneSize(forBuild build: String, runners: URL = SupportPaths.runners) -> Int64 {
        let root = SupportPaths.runnerRoot(forBuild: build, runners: runners)
        guard let walker = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let url as URL in walker {
            let values = try? url.resourceValues(
                forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
            )
            let bytes = values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? 0
            total += Int64(bytes)
        }
        return total
    }

    static func installedBuilds(in runners: URL = SupportPaths.runners) -> [RunnerBuild] {
        clonedBuilds(in: runners)
            .compactMap(SupportedRunners.build(id:))
            .filter { RunnerInstaller.hasClone(forBuild: $0.id, runners: runners) }
    }
}

enum CompatToolList {

    static func contents(_ tools: [InstalledTool]) -> String {
        tools.map { "\($0.name)\t\($0.build)\t\($0.tool.flavor.rawValue)\t\($0.display)\n" }.joined()
    }

    static func installed(
        runners: URL = SupportPaths.runners, file: URL = SupportPaths.toolList
    ) -> [InstalledTool] {
        resolved(runners: runners, file: file).tools
    }

    private static func resolved(
        runners: URL, file: URL
    ) -> (builds: [RunnerBuild], listed: String?, tools: [InstalledTool]) {
        let builds = RunnerStore.installedBuilds(in: runners)
        let listed = try? String(contentsOf: file, encoding: .utf8)
        return (builds, listed, SupportedRunners.tools(for: builds))
    }

    // Returns true when the list file changed.
    @discardableResult
    static func sync(
        runners: URL = SupportPaths.runners,
        bridge: URL = SupportPaths.bridge,
        file: URL = SupportPaths.toolList
    ) throws -> Bool {
        let (builds, listed, tools) = resolved(runners: runners, file: file)
        let text = contents(tools)
        let changed = !(listed == text || (listed == nil && text.isEmpty))
        if changed {
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try atomicReplace(file, with: Data(text.utf8), step: "Update compatibility tools")
        }
        prune(keeping: Set(builds.map(\.id)), bridge: bridge)
        return changed
    }

    private static func prune(keeping ids: Set<String>, bridge: URL) {
        NtdllPatcher.pruneBuilds(keeping: ids, in: bridge)
    }
}
