// The Bridge Payload consists of the components Proton uses to 'bridge'
// communication between the game running under Wine and the native
// Steam client. This component of the app deploys the pinned Sikarugir ones.

import Foundation

enum BridgePayload {
    static let step = "Copy the built bridge files"

    struct Located: Sendable {
        let sources: [(source: URL, bridgePaths: [String])]
    }

    static func locate(
        root: URL? = nil, pins: [String: String] = RunnerPatcher.sikarugirBridge
    ) throws -> Located {
        let base: URL
        if let root {
            base = root
        } else {
            guard let payloadRoot = try? InstallPayload.root() else {
                throw StepFailure(
                    step: step,
                    detail: "NotProton carries no components."
                )
            }
            base = payloadRoot.appending(path: "bridge")
        }

        let sikarugir = base.appending(path: SupportedRunners.sikarugir.id)
        guard FileManager.default.fileExists(atPath: sikarugir.path(percentEncoded: false)) else {
            throw StepFailure(
                step: step,
                detail: "Missing components: \(SupportedRunners.sikarugir.id). "
                    + "Run make bridge-sikarugir and make app-payload, then build the app again."
            )
        }
        var sources: [(source: URL, bridgePaths: [String])] = []
        for (path, expected) in pins.sorted(by: { $0.key < $1.key }) {
            let source = sikarugir.appending(path: path)
            guard Digest.sha256IfPresent(source) == expected else {
                throw StepFailure(step: step, detail: "Unknown Sikarugir bridge file: \(path).")
            }
            sources.append((source: source, bridgePaths: ["\(SupportedRunners.sikarugir.id)/\(path)"]))
        }
        return Located(sources: sources)
    }

    struct Outcome: Sendable {
        let staged: [String]
        let unchanged: [String]
    }

    static func stage(
        located: Located,
        bridge: URL = SupportPaths.bridge
    ) throws -> Outcome {
        var staged: [String] = []
        var unchanged: [String] = []

        for entry in located.sources {
            let sourceHash = try Digest.sha256(of: entry.source)
            for bridgePath in entry.bridgePaths {
                let destination = bridge.appending(path: bridgePath)
                if Digest.sha256IfPresent(destination) == sourceHash {
                    unchanged.append(bridgePath)
                    continue
                }

                try WriteRefused.catching(destination) {
                    try atomicReplace(destination, from: entry.source, step: step)
                }
                staged.append(bridgePath)
            }
        }

        return Outcome(staged: staged, unchanged: unchanged)
    }
}
