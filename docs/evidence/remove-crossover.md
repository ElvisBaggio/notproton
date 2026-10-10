# T09b — remoção completa do CrossOver (issue #22)

Agente: claude, modelo efetivo `sonnet` (Claude Sonnet 5.5). Decisão do Elvis (2026-10-10): o fork passa a ser só Sikarugir 11.0 r0; melhorias do upstream serão portadas à mão, então não se preserva mesclabilidade. Branch `claude/t09b-remove-crossover`, base `codex/game-agnostic-scope` @ 8d7233c.

## O que saiu

| Área | Removido |
|---|---|
| App (Swift) | `CrossOverSource`, `CrossOverRow`, `CrossOverLicense` e a checagem de licença; `RunnerOrigin` (enum eliminado, os `if origin ==` sumiram); builds/pins CrossOver (26.3, 27.0.0.40921 rosetta/fex, 27.0.0.41069 rosetta/fex) de `SupportedRunner`; nome legado `notproton` e `runners/current`; `WineArch.aarch64Windows`; ramo FEX/ARM de `PrefixTools.layout`; concessão de entitlement ao loader (`grantLoaderEntitlement`, `unixLoaders`); cópia do bundle CrossOver (`copyPayload`); seção CrossOver, "Add CrossOver…" e diálogos de licença de `StatusView`/`SystemStatus`/`App` |
| Recursos | 12 `detour*.bin` CrossOver (cx26, rosetta, fex, 41069) e a entrada deles em `Package.swift`; `payload.manifest` agora lista só a ponte `sikarugir-11.0-r0/` e as ntdll x86_64/i386 |
| `dylib/feats/compat_run.sh` | ramo CrossOver inteiro, `np_origin`, `np_flavor`, `CX_ROOT/CX_HOME`, FEX/rosetta, ponte i386 e syswow64, legacycompat, bundle de lançamento (`.app`) e Game Mode: 1501 → 1063 linhas. Comportamento do ramo Sikarugir inalterado (provado abaixo) |
| dylib (C) | `np_compat_register_crossover` virou `np_compat_register_tools`; lista de ferramentas aceita só o sabor `rosetta`; textos de UI do Steam e comentários; marcador do `run` agora "Sikarugir compatibility tool shim" |
| `ntdll-patch/` | `build-ntdll.sh`, `build64.sh`, `shim64.S`, `link64.ld`; todo o caminho aarch64 e os pins CrossOver de `resolve.py`/`apply.py` |
| `lsteamclient/`, `bridge/`, `steam-shim/`, Makefile | `lsteamclient/build.sh --install` e a detecção de clone CrossOver; alvo `bridge` (build dual CrossOver) e `BRIDGE_FILES`; `ntdll-resolve` agora recebe `NTDLL=<ntdll.dll do Sikarugir>`; comentários |

Tamanho: 87 arquivos tocados, +896 / -5156 linhas (22 arquivos apagados, 1322 linhas só neles).

## O que ficou de propósito

- **Pasta de perfil `crossover` em prefixos antigos.** `PrefixRebuild.landing` ainda funde `users/crossover` em `steamuser`, e os testes de rebuild usam essa pasta como fixture. É proteção de saves dos prefixos criados pelo NotProton 1.1.0, não código de runtime CrossOver. As ocorrências de `crossover` em `app/Tests` (fixtures de perfil, a pasta `crossover-*` ignorada de propósito em `RunnerStateTests`/`TemplateCleanupTests`) seguem essa razão.
- `bridge/tests/sikarugir-buildcheck.sh` afirma que o binário não depende de CrossOver (guarda negativa).
- `CompatTool.Flavor` tem um único caso (`rosetta`) porque o formato do arquivo `tools` (coluna 3) e o sufixo `-x86_64-unix` dos templates são contrato com o dylib e o `run`. Simplificar exige mudar os dois lados; fica como possível limpeza.
- `ntdll-patch/detour.c` e `detour32.c` mantêm os `#ifdef NP_SIKARUGIR_WINE11`: os ramos else são do CrossOver, mas remover exige reconstruir e reconferir os hashes pinados dos payloads (`d73b0f84…`, `a1305ebe…`) com a toolchain llvm-mingw, que não foi refeita aqui.
- O app não mexe em `bridge/wine/<build>` nem em `runners/crossover-*` do 1.1.0 (só pastas `sikarugir-*` são podadas). Convivência com o 1.1.0 instalado é do T10.
- Comparador ABI do T01 (`abi_compare.py`) e seus testes não dependiam de binário CrossOver neste repositório: nenhuma troca de controle foi necessária; os 4+16 testes Python seguem passando e continuam capazes de falhar.

## App

Alvo único: `make app` (alias `make app-sikarugir`) gera `out/NotProton Sikarugir.app`, id `com.notproton.NotProton.sikarugir`, sem `SUFeedURL`/`SUPublicEDKey`, `NPExperimental=true` (Sparkle desligado). `app-payload` exige a ponte Sikarugir pinada.

## Provas (rodadas de verdade)

| Prova | Resultado |
|---|---|
| `rg -i crossover app dylib bridge ntdll-patch lsteamclient steam-shim Makefile` | só as exceções acima (fixtures/proteção de saves, guarda negativa) |
| `make dobby app-payload` | PASS |
| `make app` + `codesign --verify --deep --strict "out/NotProton Sikarugir.app"` | PASS; Info.plist conferido (id, nome, `NPExperimental`, sem feed); `run` do bundle idêntico a `compat_run.sh` |
| `cd app && touch Package.swift && swift test --no-parallel` (após `swift package purge-cache`) | **452 testes em 53 suítes: 446 PASS, 0 falhas, 6 SKIP explícitos** (4 de `RunnerPatcherTests` e 2 de staging ntdll por falta de clone Sikarugir instalado, mais a suíte `Real rebuild`). SKIP não conta como PASS |
| Antes (T09) | 518 testes, 517 PASS, 1 SKIP. A queda vem dos testes só-CrossOver apagados (licença, origem, linhas CrossOver, multi-build, FEX/rosetta); os compartilhados foram adaptados |
| Testes que antes "retornavam cedo" sem engine real | agora usam `.enabled(if:)` (SKIP explícito) ou `#require` |
| `make seedcheck envcheck buildcheck settingscheck routecheck bridgecheck gamedrivecheck compatcheck compatsvc-check sigcheck callscheck peicon-fixtures webpatch-fixtures panel-behavior launch-shell spawn-env overlay-shim-tests` | PASS |
| `make anchorcheck sigdb-fixtures` | FAIL, idêntico no worktree T09 sem as minhas mudanças (13 âncoras erradas contra o `steamclient.dylib` local); fora do escopo |
| `runcheck`/`scriptcheck` | SKIP (shellcheck ausente) |
| `sh -n` em compat_run.sh e todos os `.sh` | PASS |
| `ntdll-patch/tests` e `bridge/tests` (unittest) | PASS |

### Ensaio do launcher (como no T08)

Modelo: cópia APFS de `scratch/worktrees/t08/scratch/t08-runtime` para `scratch/t09b-runtime`, com `tool/run` trocado pelo novo `compat_run.sh`. Steam fechado: chega a `steamclient_init Loaded host steamclient`, `CreateSteamPipe`, e falha como esperado (`STEAM_INIT=fail`, `APP_ID=0`, `AUTHENTICATED=no`, status 1). Variáveis `CX_*`/`WINE*` herdadas foram descartadas. Para repetir com Steam logado:

```sh
cd /Users/elvisoliveira/_dev/notproton/scratch/worktrees/t09b/scratch/t09b-runtime && sh run.sh run
```

Esperado com a sessão: `STEAM_INIT=ok`, `APP_ID=3527290`, `AUTHENTICATED=yes`.

## Como portar melhorias do upstream

Upstream: `NotProtonNot/NotProton` (remote `upstream`). O fork manteve a árvore; o que mudou:

| Upstream | Fork | Como portar |
|---|---|---|
| `dylib/feats/compat_run.sh` | mesmo caminho, só ramo Sikarugir | Aplicar à mão só o que toca prefixo/saves/controles/ponte/template; ignorar tudo que usa `CX_ROOT`, `np_flavor`, FEX/rosetta, i386, legacycompat, bundle `.app` |
| `dylib/feats/compat.c`, `compat.h`, `hooks/hook_compat.c`, `feats/webpatch.c` | mesmos | Portar normalmente; `np_compat_register_crossover` = `np_compat_register_tools`; sabor `fex` não existe |
| `dylib/tests/*` | mesmos, adaptados | Fixtures CrossOver viraram `sikarugir-*`; `bridgecheck` usa `bridge/<build>/...` |
| `app/.../Model/SupportedRunner.swift` | mesmo | Upstream tem a tabela de builds CrossOver; aqui só `sikarugir`. Novos pins de CrossOver não se aplicam |
| `Model/CrossOver{Source,Row,License}.swift` | apagados | Mudanças upstream aqui são descartadas |
| `Model/RunnerInstaller/RunnerPatcher/RunnerSetup/RunnerStore/BridgePayload/NtdllPatcher.swift` | mesmos, sem ramos CrossOver | Portar o que for lógica comum (clone, publish, remoção, staging); ignorar entitlement, `copyPayload`, `runners/current`, legado |
| `Model/SikarugirSource/SikarugirRow.swift`, `bridge/build-sikarugir.sh`, `bridge/stage-sikarugir-payload.py`, `docs/evidence/*` | só no fork | Sem equivalente upstream |
| `SystemStatus.swift`, `Views/StatusView.swift`, `App.swift` | mesmos | Seção "CrossOver" e licença não existem; a seção Sikarugir é a única |
| `Resources/detour*.bin`, `ntdll-patch/*` | só `detour*-sikarugir.bin` e Python/shell sem aarch64 | Novos detours CrossOver não se aplicam |
| `Makefile` | mesmo | Alvo `app` é o app Sikarugir; sem `bridge` (CrossOver) |
| `app/Tests/*` | mesmos, muitos adaptados | Testes só-CrossOver foram apagados |

Dica: `git diff upstream/main...HEAD -- <arquivo>` mostra o delta do fork por arquivo; porte hunks, não o arquivo inteiro.

## Pendências para T10

Convivência com o 1.1.0 instalado (mesmo `tools`, `bridge/` e dylib no Steam.app: o mais novo vence); prova de sessão real do launcher e do app; decidir se `CompatTool.Flavor` e os `#ifdef` de `detour*.c` serão simplificados.

Revisão solicitada: Claude Code Opus 5.5 (registrar modelo efetivo do revisor).
