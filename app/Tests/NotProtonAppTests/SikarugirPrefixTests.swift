import Foundation
import Testing
@testable import NotProtonApp

@Suite("Sikarugir prefix commands")
struct SikarugirPrefixTests {
    static let prefix = WinePrefix(appID: "480", name: nil, library: SteamLibrary(root: URL(filePath: "/isolated/lib")), lastUsed: nil)
    let runner = URL(filePath: "/isolated/runners/sikarugir-11.0-r0/wine")

    @Test func copiedLayoutUsesBinWineEvenForFEX() {
        let layout = PrefixTools.layout(runner: runner, flavor: .fex)
        #expect(layout.loader == runner.appending(path: "bin/wine"))
        #expect(layout.server == runner.appending(path: "bin/wineserver"))
        #expect(layout.unixDir == runner.appending(path: "lib/wine/x86_64-unix"))
    }

    @Test func archPrecedesFrameworkEnvironmentAndPreservesArguments() {
        let layout = PrefixTools.layout(runner: runner)
        let command = PrefixTools.command(loader: layout.loader, arguments: ["wineboot", "--init"], runner: runner)
        #expect(command.executable == "/usr/bin/arch")
        #expect(command.arguments == ["-x86_64", "/usr/bin/env", "DYLD_FALLBACK_LIBRARY_PATH=\(runner.path)/Frameworks:/usr/lib", layout.loader.path, "wineboot", "--init"])
        let crossOver = URL(filePath: "/isolated/runners/crossover-123/CrossOver")
        let original = PrefixTools.loader(runner: crossOver)
        let direct = PrefixTools.command(loader: original, arguments: ["winecfg"], runner: crossOver)
        #expect(direct.executable == original.path)
        #expect(direct.arguments == ["winecfg"])
    }

    @Test func sikarugirEnvironmentIsIsolatedAndProven() {
        setenv("CX_HOME", "/foreign", 1); setenv("DYLD_LIBRARY_PATH", "/foreign", 1)
        setenv("WINEDLLOVERRIDES", "bad", 1); setenv("WINEPATH", "/foreign", 1)
        defer { for k in ["CX_HOME", "DYLD_LIBRARY_PATH", "WINEDLLOVERRIDES", "WINEPATH"] { unsetenv(k) } }
        let prefix = Self.prefix
        let env = PrefixTools.environment(prefix: prefix, runner: runner)
        #expect(env["CX_HOME"] == nil && env["CX_ROOT"] == nil)
        #expect(env["DYLD_LIBRARY_PATH"] == nil && env["WINEDLLOVERRIDES"] == nil && env["WINEPATH"] == nil)
        #expect(env["SikarugirAppWine11"] == "1" && env["WINEARCH"] == "win64")
        #expect(env["WINELOADER"] == runner.path + "/bin/wine")
        #expect(env["WINESERVER"] == runner.path + "/bin/wineserver")
        #expect(env["WINEDLLPATH"] == runner.path + "/Frameworks/renderer/d3dmetal/wine")
        #expect(env["CX_APPLEGPTK_LIBD3DSHARED_PATH"] == runner.path + "/Frameworks/renderer/d3dmetal/external/libd3dshared.dylib")
        #expect(env["WINEPREFIX"] == prefix.pfx.path)
        #expect(!env.keys.contains { $0.hasPrefix("CX_") && $0 != "CX_APPLEGPTK_LIBD3DSHARED_PATH" })
    }

    @Test func crossOverEnvironmentKeepsCrossOverRoot() {
        let crossOver = URL(filePath: "/isolated/runners/crossover-123/CrossOver")
        let env = PrefixTools.environment(prefix: Self.prefix, runner: crossOver)
        #expect(env["CX_ROOT"] == crossOver.path)
        #expect(env["SikarugirAppWine11"] == nil)
    }
}
