import Foundation
import Testing
@testable import NotProtonApp

@Suite("Sikarugir source")
struct SikarugirSourceTests {
    struct Fixture: ~Copyable {
        let root: URL
        let directory: URL
        init(wrapper: Bool = false) throws {
            directory = FileManager.default.temporaryDirectory.appending(path: "np-sikarugir-\(UUID())")
            root = directory.appending(path: wrapper ? "Wrapper.app/Contents/SharedSupport/wine" : "wine")
            for path in SikarugirSource.files.keys {
                let file = root.appending(path: path)
                try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
                try Data(path.utf8).write(to: file)
            }
            try SikarugirSource.version.write(to: root.appending(path: "version"), atomically: true, encoding: .utf8)
            try FileManager.default.createDirectory(at: SikarugirSource.frameworks(inRoot: root), withIntermediateDirectories: true)
        }
        func baselineHash(_ file: URL) -> String? {
            let path = String(file.path.dropFirst(root.path.count + 1))
            guard (try? Data(contentsOf: file)) == Data(path.utf8) else { return nil }
            return SikarugirSource.files[path]
        }
        deinit { try? FileManager.default.removeItem(at: directory) }
    }

    @Test func testExactHashesIdentifySource() throws {
        let fixture = try Fixture()
        let install = try SikarugirSource.inspect(root: fixture.root, hash: { fixture.baselineHash($0) })
        #expect(install.build.origin == .sikarugir)
        #expect(install.root == fixture.root)
        #expect(SikarugirSource.files.count == 5)
    }
    @Test func testChangedLoaderIsRejected() throws {
        let fixture = try Fixture()
        try Data("changed".utf8).write(to: SikarugirSource.unixLoader(inRoot: fixture.root))
        #expect(throws: StepFailure.self) { try SikarugirSource.inspect(root: fixture.root, hash: { fixture.baselineHash($0) }) }
    }
    @Test func testEveryKeyFileIsRequired() throws {
        for path in SikarugirSource.files.keys {
            let fixture = try Fixture()
            try FileManager.default.removeItem(at: fixture.root.appending(path: path))
            #expect(throws: StepFailure.self) { try SikarugirSource.inspect(root: fixture.root, hash: { fixture.baselineHash($0) }) }
        }
    }
    @Test func testWrongArchitectureIsRejected() throws {
        let fixture = try Fixture()
        #expect(throws: StepFailure.self) {
            try SikarugirSource.inspect(root: fixture.root, hash: { file in
                file.lastPathComponent == "wine" ? SupportedRunners.all.first { $0.flavor == "fex" }!.loaderSHA256
                    : fixture.baselineHash(file)
            })
        }
    }
    @Test func testWrongOriginVersionIsRejected() throws {
        let fixture = try Fixture()
        try "CrossOver 27".write(to: fixture.root.appending(path: "version"), atomically: true, encoding: .utf8)
        #expect(throws: StepFailure.self) { try SikarugirSource.inspect(root: fixture.root, hash: { fixture.baselineHash($0) }) }
    }
    @Test func testWrapperFrameworksAndMissingFrameworks() throws {
        let fixture = try Fixture(wrapper: true)
        #expect(SikarugirSource.frameworks(inRoot: fixture.root).path.hasSuffix("Wrapper.app/Contents/Frameworks"))
        _ = try SikarugirSource.inspect(root: fixture.root, hash: { fixture.baselineHash($0) })
        try FileManager.default.removeItem(at: SikarugirSource.frameworks(inRoot: fixture.root))
        #expect(throws: StepFailure.self) { try SikarugirSource.inspect(root: fixture.root, hash: { fixture.baselineHash($0) }) }
    }
    @Test func testEscapingSymlinkIsRejected() throws {
        let fixture = try Fixture()
        let file = SikarugirSource.unixLoader(inRoot: fixture.root)
        try FileManager.default.removeItem(at: file)
        try FileManager.default.createSymbolicLink(at: file, withDestinationURL: URL(filePath: "/bin/sh"))
        #expect(throws: StepFailure.self) { try SikarugirSource.inspect(root: fixture.root, hash: { _ in SupportedRunners.sikarugir.loaderSHA256 }) }
    }
    @Test func testDiscoveryRejectsUnknownEngine() throws {
        let fixture = try Fixture(wrapper: true)
        let search = fixture.root.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        #expect(SikarugirSource.discover(searchRoots: [search]).isEmpty)
    }
}
