# T07 — Lifecycle Sikarugir

Data: 2026-10-10 · Agente/cliente: codex · Modelo efetivo: `gpt-6.1-sol` · Papel: `runner_lifecycle` · Branch: `codex/t07-sikarugir-lifecycle` · Base: `2cb890d` (T06 integrado).

Implementação concluída para revisão; issue #11 permanece aberta/In Progress. Revisão Claude Code Opus 5.5 e aceite Astra pendentes. Nenhuma instalação global, execução de Wine, controle do Steam ou alteração de wrapper/prefixos/saves.

## Contratos implementados

- `RunnerInstaller.clone(SikarugirInstall)` revalida versão e os cinco hashes T06 na fonte, clona por `/bin/cp -c -R` para staging exclusivo e revalida fonte/destino. Engine em `runners/sikarugir-11.0-r0/wine`, Frameworks em `wine/Frameworks`. Não há fallback de cópia Sikarugir nem hardlinks.
- Frameworks: mapa de todos os caminhos relativos, diretórios, hashes de arquivos e destinos dos symlinks; symlinks que escapam são recusados. Mapa fonte antes = fonte depois = destino. Registro local `wine/.notproton-frameworks.json` permite readback/verify posterior. O registro descreve a cópia aceita; não é um novo pin de proveniência do fabricante.
- Publicação usa `renameatx_np(RENAME_SWAP)` quando o destino existe, ou `rename` na primeira instalação. Falha anterior à troca preserva o destino; staging exclusivo é removido. CrossOver também verifica staging antes da troca, preservando seus hashes/licença e fallback de cópia existentes.
- `RunnerSetup.run(SikarugirInstall)` realiza stage/patch antes de publicar uma substituição. `prepare` é a mesma entrada de setup/reparo, mas só consulta licença para `.crossOver`. Reparo de builtin é automático; loader/Frameworks/original ntdll adulterados são recusados e exigem recópia da fonte conhecida.
- `RunnerPatcher.install` valida fontes, trabalha numa segunda cópia APFS, verifica a árvore resultante e só então troca o destino. Backup limpo ntdll preservado. Sikarugir verifica `bin/wine` por hash e nunca o re-assina; CrossOver mantém entitlements/assinatura e agora recusa lista vazia de loaders.
- Ponte exclusiva `bridge/sikarugir-11.0-r0`: `steam.exe` → `wine/bin/steam.exe`, DLL → `wine/lib/wine/x86_64-windows/lsteamclient.dll`, SO → `wine/lib/wine/x86_64-unix/lsteamclient.so`, ao lado da `ntdll.so`. Nenhuma ponte i386/arm64 é declarada. T08 consumirá o `steam.exe` exclusivo no prefixo.
- `BridgePayload.locate/stage` integra os três arquivos exclusivos sem substituir a ponte CrossOver. `make app-payload` pode incorporar a ponte de `scratch/sikarugir/bridge`, com validação de todos os hashes antes de copiar. Ausência preserva o pacote CrossOver; setup Sikarugir recusa ponte ausente. `bridge/stage-sikarugir-payload.py` é o staging verificado, sem downloads/dependências novas. Recursos de ponte são ignorados pelo Git; só os detours próprios são versionados, seguindo o padrão CrossOver já existente.
- `DeploymentContent.files` recebeu apenas a adaptação necessária do caller de builtins por origem, incluindo destino `bin/steam.exe`. UI, launcher e empacotamento experimental permanecem T08/T09. `payload.manifest` permanece CrossOver, pois o conjunto Sikarugir é opcional; pins específicos estão no patcher, não em entradas obrigatórias do inventário CrossOver.
- Limpeza de templates e `.removing` reconhece ambas as origens e preserva o tratamento de locks/symlinks existente.
- `SteamRepair.swift` restaura o bootstrap Valve assinado e não repara runners nem exige licença CrossOver: não precisou de alteração. Reparo de runner passa por `RunnerSetup.prepare`/`RunnerPatcher.install`, incluindo o caller já existente em `SteamInstaller.run`.

## Pins conferidos contra os manifests vigentes T03/T04

| Arquivo | SHA-256 |
|---|---|
| payload x64 (834 B) | `d73b0f846a13e062b8da4acc0fbbac62c9e43a3ad531afcf0434d1417085e15f` |
| payload i386 | `a1305ebed9e42cc6a37a5df333d42da17de8012cca8e4deeb72f6b4a8cb5b620` |
| ntdll x64 final | `ef8e99712f845f5c4e7ee01a0475d3ccaf84114d54a0a6c962808fee34b68b29` |
| ntdll i386 final | `60c6a031ea679833d6f8a81e4873cb60d98815ed9f7220c2046ed58443cfcc03` |
| steam.exe | `56979db411cb12b48610c09b8fc01db3c34bb3c7e31ea53f1b17dafaf7f98b70` |
| lsteamclient.dll x64 | `2933ac86d886f1264fabfbb97f21f53967452fca2397f29ecdbd29f83616c7ac` |
| lsteamclient.so x64 com LC_UUID (T03/T05) | `d71f954cf1c1a2355e9dfd7e8de593d8a4d1274117d42626394d4e95c7379a9c` |

Payloads lidos de `t04-close/scratch/sikarugir/payload`, offsets/hooks/caves transcritos de `patches.json`, e ponte lida de `t03-bridge/scratch/sikarugir/bridge/manifest.json`, todos somente leitura. Swift `NtdllPatcher.stage` reproduziu os dois hashes finais usando os bytes reais da engine. Recursos CrossOver existentes não foram alterados.

## Guarda Steam/perfil (R6)

Contrato mínimo: cliente **instalado em disco**, não processo vivo. `SteamInstaller.activeClientBuild` lê `<clientRoot>/package/beta`; canal vazio seleciona `steam_client_osx.manifest`, `publicbeta` seleciona `steam_client_publicbeta_signed-2_osx.manifest`; outros canais são recusados. Exige um único `"version" "<inteiro positivo>"`. Usa o arquivo `.manifest`, não o manifesto de download sem esse sufixo nem a versão do bootstrap `Steam.app`.

`requireSignatureProfile` decodifica `steam_build` de cada JSON, exige nome `<steam_build>.json` e exatamente um perfil correspondente ao build instalado. Perfis históricos distintos podem coexistir. Mismatch único, duplicação, metadado ausente/malformado ou arquivo ausente recusam antes de lock de instalação, stop, bridge, runner patch, cópia de dylib e hooks/plist. Fixtures Steam existentes receberam metadados reais de perfil e um manifesto isolado, sem mascarar validação. O ensaio negativo chama `SteamInstaller.run` real e prova plist intacto/nenhuma pasta de suporte criada.

Limite: a guarda não autentica o manifesto Valve nem consulta o build de um processo em execução; lançamento integrado e comportamento após atualização são validações posteriores. Não altera o resolver/hook runtime neste card.

## Validação local

Toolchain: Apple Swift 6.4 (`swiftlang-6.4.0.34.1`), target arm64 macOS 27.2; `xcode-select -p` = `/Library/Developer/CommandLineTools`.

| Verificação | Resultado |
|---|---|
| RED contra `RunnerPatcher.swift` original do HEAD: exigir diagnóstico de zero loaders | FAIL esperado (assert, sinal 5) |
| 15 métodos Swift novos de `RunnerLifecycleTests`, corpos convertidos para asserts, arquivos reais | PASS |
| 40 métodos existentes: clone CrossOver (7), licença criptográfica (10), ntdll sintético/recursos (14), ponte (9), no harness com fontes reais | PASS |
| Ensaio com engine real: clone APFS + 1032 entradas Frameworks; dois patches Swift; instalação/readback; falha após patch parcial; setup/reparo/idempotência; fonte de ponte inválida; integridade original | PASS |
| Staging Python: input inválido não altera destino; inputs válidos copiados | PASS (1 teste) |
| Staging Python dos três artefatos reais T03 para scratch | PASS |
| Makefile: seedcheck, envcheck, buildcheck, settingscheck, routecheck, bridgecheck, gamedrivecheck, sigcheck | PASS |
| `make runcheck` | SKIP: sem shellcheck; não contado como PASS |
| `sh -n dylib/feats/compat_run.sh` | PASS |
| `swift test --no-parallel` completo | **NOT RUN**: build falha em SwiftUIMacros ausente; exige Xcode/CI |
| `git diff --check` | PASS |

Harnesses apenas em `scratch/t07-checks`, sem macros/UI. Compilam os arquivos reais de catálogo, discovery, clone, setup, patchers, ponte, deployment, SteamInstaller/SteamRepair/SteamBundle e seus helpers. Boundaries: `Bundle.module` aponta para bundle de recursos de teste; `AppVersion` é fixo; `AppLog` é silencioso; tipos de library/arch e `PrefixStore.libraries` isolam descoberta das bibliotecas pessoais. Nenhum stub de lifecycle, licença, hash, patch, verify ou guarda Steam. Métodos novos de setup usam closures de stage/patch/verify para testar licença; o ensaio real usa as implementações de produção dessas três funções.

Comandos executados (artefatos e cópias somente em scratch ou `/tmp`):

```sh
rtk proxy sh scratch/t07-checks/compile.sh
rtk proxy sh -c 'T07_RESOURCES="$PWD/scratch/t07-checks/Resources.bundle" /tmp/t07-checks'
rtk proxy sh scratch/t07-checks/compile-regression.sh
rtk proxy sh -c 'T07_RESOURCES="$PWD/scratch/t07-checks/Resources.bundle" /tmp/t07-regression'
rtk proxy sh scratch/t07-checks/compile-integration.sh
rtk proxy sh -c 'T07_RESOURCES="$PWD/scratch/t07-checks/Resources.bundle" /tmp/t07-integration "$HOME/Applications/Sikarugir/wrapper-steam.app/Contents/SharedSupport/wine" /Users/elvisoliveira/_dev/notproton/scratch/worktrees/t03-bridge/scratch/sikarugir/bridge "$PWD/scratch/t07-checks/lifecycle-bridge"'
rtk proxy python3 -m unittest discover -s bridge/tests -p test_stage_sikarugir_payload.py
rtk proxy python3 bridge/stage-sikarugir-payload.py /Users/elvisoliveira/_dev/notproton/scratch/worktrees/t03-bridge/scratch/sikarugir/bridge scratch/t07-checks/staged-payload/bridge/sikarugir-11.0-r0
rtk proxy make runcheck seedcheck envcheck buildcheck settingscheck routecheck bridgecheck gamedrivecheck sigcheck
rtk proxy sh -n dylib/feats/compat_run.sh
rtk proxy swift test --package-path app --no-parallel --disable-sandbox --cache-path /tmp/t07-spm-cache -Xswiftc -module-cache-path -Xswiftc /tmp/t07-module-cache
rtk git diff --check
```

A regressão local selecionou somente os 40 métodos sem dependência de instalações reais/downloads/parâmetros; nenhum retorno precoce foi contado como PASS. Os 15 testes novos ficam versionados para Swift Testing/Xcode. A suíte completa não foi substituída por este harness, nem foram contados testes que retornam cedo por falta de engine como PASS.

## Próximo passo

Revisão independente Claude Code Opus 5.5 (registrar modelo efetivo) e aceite Astra antes de T08. T08: launcher/prefixos, ambiente provado depois de `arch`, bridge exclusiva/steam.exe, trigger, lançamento integrado e observação de `apply_binary_patches` em memória. T09 mantém a suíte Swift completa em Xcode/CI e integração UI/pacote experimental. Nenhuma prova de jogo, renderer, save/reabertura ou rollback vivo é reivindicada pelo T07.
