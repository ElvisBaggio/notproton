# T06 — Catálogo e origem Sikarugir

Data: 2026-10-09 · Cliente: `codex` · Papel: `runner_model` · Modelo efetivo: `gpt-6.1-sol`.
Branch: `codex/t06-sikarugir-source`; território exclusivo T06. Gate E2 aceito com ressalvas conforme `docs/reviews/astra-e2-gate.md`; mapa `docs/reviews/e3-codemap.md` conferido no código antes da mudança. Revisão Claude Code Opus 5.5 solicitada no fechamento da issue #10; modelo efetivo do revisor ainda pendente.

## Contratos implementados

- `RunnerOrigin` distingue `.crossOver` e `.sikarugir`; origem default de `RunnerBuild` permanece `.crossOver`.
- Identidade única `sikarugir-11.0-r0`, tool `notproton-sikarugir-11.0-r0`, somente flavor Rosetta/x86_64, display `Sikarugir 11.0 (experimental)`. Não declara ponte i386 funcional, FEX ou ARM Windows.
- Catálogo completo `SupportedRunners.catalog`, lookup por id e `tools(for:)` incluem Sikarugir. `all` permanece a lista dos builds com patches embarcados; isto preserva as invariantes dos testes Ntdll existentes sem antecipar recursos de T07. T07 deve incorporar Sikarugir em `all` junto com seus payloads e remover a duplicação em `catalog`. Lookup somente por loader continua CrossOver-only, pois `CrossOverSource.inspect` depende dele; Sikarugir só é aceito após conferir os cinco arquivos.
- Sikarugir não foi colocado em `toolPreference`; em catálogo misto permanece depois de CrossOver. Legado `notproton` e `current` continuam CrossOver-only.
- `SikarugirSource.inspect(root:)` exige `version = wine sikarugir 11.0 (revision 0)` e os cinco hashes exatos da tabela T01 em `engine-baseline.md` (loader, wineserver, ntdll Unix e duas ntdll PE). Esses hashes também fixam as arquiteturas observadas x86_64/i386. Recusa arquivo ausente, alterado, origem/versão diferente e symlink de arquivo que saia da engine. Nada é executado para detectar versão/arquitetura.
- Descoberta somente leitura inspeciona apps diretamente em `/Applications`, `~/Applications` e `~/Applications/Sikarugir`, deduplica raiz resolvida e descarta engines desconhecidas. Escolha manual/UI é T09.
- TSV continua exatamente quatro colunas `name/build/flavor/display`; a origem se infere do prefixo reservado `sikarugir-` do build id.

## Layout único por origem

```text
runners/crossover-<id>/CrossOver/        # inalterado
runners/sikarugir-11.0-r0/wine/
    bin/wine
    bin/wineserver
    lib/wine/...
    Frameworks/                        # dependências da cópia, T07
```

A fonte original fica em `<wrapper>.app/Contents/SharedSupport/wine`; ali Frameworks é `<wrapper>.app/Contents/Frameworks`. `SikarugirSource.frameworks(inRoot:)` distingue esse layout de leitura do layout instalado único `wine/Frameworks`. T06 exige que o diretório exista; a integridade/cópia completa de Frameworks fica para T07, com o inventário T05 (965 entradas) como referência. T06 não copia, instala ou modifica a fonte.

`SupportPaths.runnerFolder(forBuild:)` centraliza o nome da pasta, preservando assinaturas e caminhos CrossOver. `RunnerStore` reconhece ambos os prefixos, incluindo Sikarugir desconhecido como órfão e conhecido sem `lib/wine` como danificado. O estado do clone aceita o caminho `wine` correto; a verificação/instalação dos patches ainda depende de T07.

## Validação

| Prova | Resultado |
|---|---|
| TDD: assert do lookup Sikarugir contra o SupportedRunner anterior à implementação | RED: exit 133, `T06 RED: Sikarugir absent from catalog` |
| Mesmo assert após implementação | GREEN: exit 0 |
| Harness Swift 6 isolado, arquivos reais de catálogo/paths/store/source + Digest/StepFailure/AtomicReplace | PASS: 19 métodos com assert; includes five-file missing cases |
| Inspeção real default de `wrapper-steam.app`, somente leitura | PASS: versão + cinco SHA-256 + presença Frameworks; sem Wine/runtime |
| `make seedcheck envcheck buildcheck settingscheck routecheck bridgecheck gamedrivecheck` | PASS: sete targets exit 0; nenhum SKIP contado como PASS |
| `git diff --check` | PASS |
| Suíte Swift do app | **NOT RUN**: só Command Line Tools; falta `SwiftUIMacros.StateMacro` em App.swift |
| Swift Testing num pacote isolado sem UI | **NOT RUN**: falta `TestingMacros`; não substitui CI/Xcode |

O harness isolado reutiliza os corpos dos testes novos de catálogo/source e RunnerState, substituindo somente `@Suite/@Test/#expect/#require` por chamadas assert. Lifecycle fica nas fronteiras: `RunnerPatcher.verify`, `NtdllPatcher.pruneBuilds`, `SteamLibrary` e `PrefixArch` têm stubs; `hasClone` usa o mesmo corpo real, lendo `lib/wine`. Não prova patch, pruning ou runtime. A compilação real detectou um erro de borrow em fixtures `~Copyable`, corrigido com closures locais. Novos testes Swift Testing ficam versionados para CI/Xcode.

Comandos locais (logs e harness apenas em `scratch/t06-checks/`, ignorado):

```sh
rtk proxy xcode-select -p
rtk proxy swiftc -module-cache-path /tmp/t06-module-cache app/Sources/NotProtonApp/Model/SupportedRunner.swift /tmp/t06-red.swift -o /tmp/t06-red
rtk proxy /tmp/t06-red
rtk proxy sh scratch/t06-checks/run.sh
rtk proxy /tmp/t06-checks "$HOME/Applications/Sikarugir/wrapper-steam.app/Contents/SharedSupport/wine"
rtk proxy swift test --package-path app --disable-sandbox --cache-path /tmp/t06-spm-cache -Xswiftc -module-cache-path -Xswiftc /tmp/t06-module-cache --filter 'SikarugirSourceTests|DetectionTests|RunnerStateTests'
rtk proxy make seedcheck envcheck buildcheck settingscheck routecheck bridgecheck gamedrivecheck
rtk git diff --check
```

## Pendências explícitas

T07: cópia atômica de engine + Frameworks em `wine/Frameworks`; validação de mapa completo, pins/resources pós-correção, ponte isolada, licença somente CrossOver, verificação/reparo por origem e build Steam/perfil. `RunnerInstaller.removePrefixTemplates` e `removeLeftoverRemovals` ainda só reconhecem CrossOver: adicionar limpeza Sikarugir junto ao lifecycle T07. Não há instalação Sikarugir criada por T06.

T08: `DeploymentContent` e `compat_run.sh` ainda têm `crossover-` fixo; consumir estes ids/layout sem mudar TSV, selecionar `bin/wine`/wineserver e carregar o ambiente provado após `arch`. Launch integrado, `steam.exe` e patches em memória não foram testados aqui. T09: seleção UI + suíte completa CI/Xcode. Nenhum app instalado, Steam, wrapper, saves ou configuração global foi alterado.
