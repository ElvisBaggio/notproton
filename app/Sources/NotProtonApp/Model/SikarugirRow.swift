// The single Sikarugir line on the Status pane

import Foundation

struct SikarugirRow: Equatable {
    static let title = "Sikarugir 11.0 (experimental)"

    enum Copy: Equatable {
        case none
        case ready
        case unpatched
        case damaged
    }

    let install: SikarugirInstall?
    let copy: Copy

    var buildID: String { SupportedRunners.sikarugir.id }
    var canSetUp: Bool { install != nil }

    static func == (a: SikarugirRow, b: SikarugirRow) -> Bool {
        a.install?.root == b.install?.root && a.copy == b.copy
    }

    static func row(
        installs: [SikarugirInstall], installed: [RunnerBuild], damaged: [String], unpatched: [String]
    ) -> SikarugirRow {
        let id = SupportedRunners.sikarugir.id
        let copy: Copy
        if unpatched.contains(id) {
            copy = .unpatched
        } else if installed.contains(where: { $0.id == id }) {
            copy = .ready
        } else if damaged.contains(id) {
            copy = .damaged
        } else {
            copy = .none
        }
        return SikarugirRow(install: installs.first, copy: copy)
    }
}
