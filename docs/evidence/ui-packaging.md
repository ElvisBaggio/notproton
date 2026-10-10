# T09 — interface, empacotamento e suíte Swift (origem Sikarugir)

Agente: claude, modelo efetivo `sonnet` (Claude Sonnet 5.5). Toolchain: Xcode em `/Applications/Xcode.app` (licença aceita), `swift test --no-parallel` real.

## Mudanças

- UI: nova seção "Sikarugir 11.0 (experimental)" no StatusView, separada de CrossOver (`SikarugirRow`, `SystemStatus.addSikarugir/setUpSikarugir`, botão "Add Sikarugir…", Set Up/Repair/Reinstall/Remove Copy). `CrossOverRow.rows` não gera linha para builds Sikarugir. Erro de engine incompatível: `SikarugirSource.pick` acrescenta "NotProton supports only Sikarugir 11.0 revision 0 (x86_64/Rosetta)…". CrossOver sem alteração de fluxo.
- Achado T07 (guarda de perfil): a mensagem de `requireSignatureProfile` agora diz que vale para toda ferramenta (CrossOver e Sikarugir), e a seção Sikarugir repete isso. Teste novo cobre a mensagem.
- Achado T08 (aviso ntdll): `verify_runner` só emite `no patched ntdll … in the bridge` para CrossOver; Sikarugir segue checando builtins x86_64 (sem i386). `dylib/tests/sikarugircheck.sh` executa a função real nos dois ramos.
- Empacotamento: `AppUpdater.shouldStart(info:)` (função pura; chave `NPExperimental` no Info.plist) e menu "Check for Updates…" desabilitado no experimental. Makefile: `make app-sikarugir` gera `out/NotProton Sikarugir.app` (id `com.notproton.NotProton.sikarugir`, sem `SUFeedURL`/`SUPublicEDKey`, `NPExperimental=true`) reaproveitando o alvo `app`; `sikarugir-payload-check` exige os 3 arquivos da ponte pinada. `deploy` e `LAUNCHABLE_BUNDLES` não tocam o app novo. `run` (compat_run.sh), `detour*-sikarugir.bin` (Package.swift) e a ponte Sikarugir entram no bundle e no `DeploymentContent` (arquivo `notproton-sikarugir-11.0-r0/run`).

## Regressões herdadas corrigidas (achadas ao rodar a suíte real)

Com Xcode a suíte revelou 5 falhas de T08 que o harness swiftc não via, todas por testes que fazem grep no `compat_run.sh` e pegavam o ramo Sikarugir: `LaunchEnvTests` (PATH), `PrefixToolsTests` (variáveis exportadas; link de perfil `$profile_user`), `ShimAgreementTests` (lista de arquiteturas: o loop voltou a ter lista literal, com `continue` para i386 no Sikarugir). Testes ajustados para o ramo CrossOver; comportamento CrossOver inalterado.

## Provas

| Prova | Resultado |
|---|---|
| `swift test --no-parallel` (app/) | 518 testes em 60 suítes: 517 PASS, 0 falhas, 1 SKIP (`Real rebuild`: exige prefixos reais; SKIP não conta como PASS) |
| Linha de base antes das mudanças (278ea79, payload não staged) | 502 testes, 32 issues: 28 por falta de payload (ambiente) e 5 regressões T08 acima |
| `make seedcheck envcheck buildcheck settingscheck routecheck bridgecheck gamedrivecheck` | PASS (0 falhas) |
| `sikarugircheck.sh` (inclui `verify_runner` por origem) | PASS |
| `sh -n` compat_run.sh e dylib/tests/*.sh | PASS |
| runcheck/scriptcheck | SKIP (shellcheck ausente; não instalado) |
| `make -o app-payload app-sikarugir` | `out/NotProton Sikarugir.app` construído e assinado ad hoc; Info.plist conferido (id, `NPExperimental`, sem Sparkle); `run` do bundle idêntico a compat_run.sh; recursos `detour{2,32}-sikarugir.bin` e ponte `sikarugir-11.0-r0/` (3 arquivos) presentes; não existe `out/NotProton.app` |
| Abertura do bundle | processo vivo após 5 s (sem verificação visual por captura) |

## Limites e ambiente

- Payload usado nos testes e no bundle foi montado localmente (ignorado pelo Git): `appinfo`, `iconmaker`, `notproton.dylib`, `overlay-shim.dylib` e a ponte CrossOver copiados do app instalado 1.1.0 (somente leitura), `run`/assinaturas/`build-time` do repositório e a ponte Sikarugir de `t03-bridge/scratch/sikarugir/bridge` verificada por hash. `make app-payload` completo não roda aqui: `vendor/dobby` ausente (dylib não compila). Em CI/máquina com dobby, `make app-payload` substitui isso.
- `make app` padrão não foi executado (depende do dylib); o alvo `app` compartilhado foi exercitado via `app-sikarugir -o app-payload`.
- Não implantado em NotProton/Steam instalados (T10). Convivência com a 1.1.0 instalada (`DeploymentContent.blocksInstallation` por versão igual/mais nova; mesmo nome de bundle de recursos) fica para T10.
- Selecionar a engine no NSOpenPanel e rodar o setup real não foram exercitados com GUI.

## Revisão Opus 5.5 — payload construído do repositório (2026-10-10)

Revisor: Claude Code Opus 5.5 (`claude-opus-5-5`). O payload da execução do Sonnet copiou `notproton.dylib`, `overlay-shim.dylib`, `appinfo`, `iconmaker` e a ponte CrossOver do app 1.1.0 instalado, por falta de `vendor/dobby`. Na revisão:

- Dobby buscado no commit fixado `5dfc8546954ce3b3198132ab13fddb89ee92cdd7` (conforme `vendor/README.md`), `make dobby` e `make app-payload` completos a partir do repositório: PASS.
- `make -o app-payload app-sikarugir` → `out/NotProton Sikarugir.app` (1.1.1); `codesign --verify --deep`: PASS. Payload contém ponte CrossOver e `bridge/sikarugir-11.0-r0/`.
- `swift test --no-parallel` com esse payload (após `touch Package.swift`, porque o manifesto só inclui `Resources/payload` se ele existir na avaliação): **518 testes em 60 suítes, passed**.
- Para T10: implantar somente o app gerado do repositório (nunca o payload copiado do 1.1.0).
