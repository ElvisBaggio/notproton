import Foundation
import Sparkle

@MainActor
final class AppUpdater {

    private let controller: SPUStandardUpdaterController?

    // The experimental Sikarugir bundle declares NPExperimental in its Info.plist and must
    // never follow the upstream appcast, which would replace it with the upstream app.
    nonisolated static func shouldStart(info: [String: Any]?) -> Bool {
        (info?["NPExperimental"] as? Bool) != true
    }

    var isEnabled: Bool { controller != nil }

    init(info: [String: Any]? = Bundle.main.infoDictionary) {
        guard Self.shouldStart(info: info) else {
            controller = nil
            return
        }
        #if DEBUG
        let scheduling = false
        #else
        let scheduling = true
        #endif
        controller = SPUStandardUpdaterController(
            startingUpdater: scheduling,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func check() {
        #if !DEBUG
        controller?.checkForUpdates(nil)
        #endif
    }
}
