# T08 — launcher, prefixos e ferramentas Wine (Sikarugir 11.0 r0)

Agente: claude, modelo efetivo `sonnet` (Claude Sonnet 5.5). Base: Codex Sol (gpt-6.1-sol) iniciou o diff e parou por limite sem commit; o diff foi revisado, mantido e completado aqui.

## Mudanças

- `dylib/feats/compat_run.sh`: `np_origin` derivado de `build` (`sikarugir-*`). Ramo Sikarugir remove `CX_*`, `DYLD_*`, `WINEDLLPATH*`, `WINELOADER`, `WINESERVER`, `WINELOADERNOEXEC`, `WINEPATH`, `WINEPREFIX`, `WINEDLLOVERRIDES` herdados, não exporta `CX_HOME`/`CX_ROOT` e usa só `runners/<build>/wine` (engine copiada pelo T07). Exporta o ambiente provado no T05: `SikarugirAppWine11=1`, `WINEARCH=win64`, `WINELOADER/WINESERVER` da cópia, e `DYLD_FALLBACK_LIBRARY_PATH=<cópia>/Frameworks:/usr/lib` aplicado depois de `/usr/bin/arch -x86_64 /usr/bin/env` (`wine_exec`, `without_lock_fds`, `in_template_env`). Perfil A: `WINEDLLPATH=<cópia>/Frameworks/renderer/d3dmetal/wine` e `CX_APPLEGPTK_LIBD3DSHARED_PATH` (única exceção `CX_*`, sempre na cópia). Ponte Sikarugir: só `steamclient64.dll`, `lsteamclient.{dll,so}` x86_64 e `steam.exe` em `bridge/<build>/`; sem trigger/legacycompat/syswow64; `WINEPATH` aponta para a pasta Steam do prefixo. Encerramento por `wineserver -k`/`-w`. Ramo CrossOver mantém o fluxo original.
- `PrefixTools.swift`/`PrefixRebuild.swift`: `isSikarugir(runner:)`, `layout` (bin/wine, bin/wineserver, lib/wine/x86_64-unix), `command(...)` (arch antes de DYLD), ambiente isolado, usuário do perfil = usuário do macOS no rebuild. Wineboot, ferramentas (winecfg etc.) e executáveis usam o mesmo wrapper. Nenhum caminho do wrapper original.
- Testes: `dylib/tests/sikarugircheck.sh` (executa o setup real do script; chamado por `envcheck.sh`), ajustes em seed/route/settingscheck para extrair `wine_exec`; `app/Tests/NotProtonAppTests/SikarugirPrefixTests.swift` (4 testes Swift Testing).

## Renderer e ordem de tentativa (para T11)

1. Perfil A (D3DMetal, padrão): ambiente acima; jogo com `-force-d3d11` primeiro (confirmar `Forcing GfxDevice: Direct3D 11` em `Player.log`), depois DX12 pela janela do jogo, depois Vulkan só se ambos falharem.
2. Perfil B (DXMT) só como controle de D3D11; nunca misturar tradutores na mesma execução. Não habilitado pelo launcher; requer `WINEDLLPATH` apontando `$R/dxmt/wine` em tentativa explícita (T11).

## Provas

| Prova | Resultado |
|---|---|
| `make seedcheck envcheck buildcheck settingscheck routecheck bridgecheck gamedrivecheck` (ramo CrossOver inalterado) | PASS (0 falhas) |
| `sikarugircheck.sh` | PASS |
| `sh -n` em compat_run.sh e dylib/tests/*.sh | PASS |
| runcheck/scriptcheck | SKIP (shellcheck ausente), não contado como PASS |
| Harness swiftc (`scratch/t08-checks`, DEVELOPER_DIR=CommandLineTools, arquivos reais PrefixTools/PrefixRebuild/PrefixStore/RunnerStore etc.; boundaries apenas AppLog/RunnerPatcher/RunnerInstaller/NtdllPatcher) | 11 asserts PASS |
| Suíte Swift completa | NOT RUN (sem Xcode/SwiftUIMacros; licença Xcode não aceita) |

## Ensaio integrado (condição Astra)

Em `scratch/t08-runtime` (engine copiada pelo T07/T05, HOME e prefixo descartáveis, `run` = `compat_run.sh` atual), Steam do Mac fechado. `run.sh waitforexitandrun` com `steam-api-probe.exe --appid 3527290` e variáveis CX_*/WINE* estranhas exportadas:

- Prefixo claimado, template `sikarugir-11.0-r0-x86_64-unix` construído por wineboot via `arch -x86_64`, clone do prefixo, drive S:, ponte staged (`steamclient64.dll`, `lsteamclient`, `steam.exe`): OK.
- Lançamento via `steam.exe` da ponte e Wine 11.0 sikarugir da cópia: o probe carrega `lsteamclient`, que carrega `steamclient.dylib` do Steam do Mac (`STEAM_COMPAT_CLIENT_INSTALL_PATH`) e falha em `CreateSteamPipe`. Saída: `STEAM_INIT=fail`, `APP_ID=0`, `AUTHENTICATED=no`. Falha esperada por falta de sessão Steam (cliente fechado); não é prova de AUTHENTICATED=yes no launcher integrado.
- Sem processos wine residuais. Aviso: `no patched ntdll for build ... in the bridge` (payload ntdll de T04 não instalado neste HOME descartável); os patches em memória não foram observados aqui.

Comando para a prova com sessão real (Elvis, com o Steam do Mac aberto e logado, a partir da raiz do worktree):

    sh scratch/t08-runtime/run.sh waitforexitandrun

Esperado: `STEAM_INIT=ok`, `APP_ID=3527290`, `AUTHENTICATED=yes` (o log completo fica em `scratch/t08-runtime/compatdata/3527290/notproton-run.log`, privado, não commitar).

## Pendências

- T09: suíte Swift completa em Xcode/CI; UI/pacote; instalar o `run` novo via `SteamInstaller` (o `run` só é atualizado pelo deployment).
- T10/T11: prova de sessão real e renderer; `-force-d3d11` primeiro.
- Revisão Claude Code Opus 5.5 pendente (modelo efetivo do revisor a registrar).
