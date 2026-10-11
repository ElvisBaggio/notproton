# T10 — deploy → rollback → readback → redeploy

Data: 2026-10-11 · Agente: claude · Modelo efetivo: opus (claude-opus-5-5) · Branch: `claude/t10-deploy-rollback` · Execução física: Elvis (Repair, Install e UI do Steam).

Pacote: NotProton Sikarugir 1.1.1 (`install-build.json` builtAt `1791681908`), runner `sikarugir-11.0-r0`. Steam client `1791592380` (publicbeta), perfil `signatures/macos.arm64/1791592380.json` presente. Disco livre: 264 GiB.

Decisão do Elvis (opção b): rollback **100% original**, sem manter o bloqueio de atualização; se o Steam atualizar, gerar perfil novo. Não atualizou: o build permaneceu `1791592380` em todas as fases.

## Manifesto e backup

Script: `scratch/t10-backup/t10_snapshot.py` (ignorado). Manifesto privado `scratch/t10-backup/20261011-pre-rollback/manifest.json`, schemaVersion=1, modo 0600, com `steamClientBuild`, assinatura externa, `diskFreeBytes` e `touchedFiles[{path,existed,mode,sha256|treeSha256,backupPath}]`. Backup por clone APFS (`cp -Rc -P -p`), sem hard link; cada cópia conferida por hash/árvore e inode distinto.

Alvos (todos existiam antes):

| Alvo | Papel |
|---|---|
| `/Applications/Steam.app` (bundle inteiro) | `notproton.dylib`, `LSEnvironment.DYLD_INSERT_LIBRARIES`, assinatura ad hoc |
| `Steam.AppBundle/Steam/Contents/Info.plist` | injeção interna |
| `Steam.AppBundle/Steam/Contents/MacOS/steam.cfg`, `Steam/steam.cfg` | bloqueio de atualização |
| `Steam/compatibilitytools.d/notproton-sikarugir-11.0-r0` | ferramenta registrada |
| `Steam/config/config.vdf` | controle de arquivo alheio |
| `notproton/install-build.json`, `dylib.version`, `tools`, `backups/Info.plist.before-notproton` | registro do deploy |

Fora do escopo do rollback e preservados: runners, prefixos/compatdata, saves, biblioteca, demais arquivos da pasta de suporte. Não foi usado o "Remove" do app (apaga a pasta de suporte inteira).

## Estado anterior (deploy vivo)

`Steam.app` assinatura **ad hoc** (sem TeamIdentifier), `DYLD_INSERT_LIBRARIES=/Applications/Steam.app/Contents/MacOS/notproton.dylib` nos plists externo e interno, `BootStrapperInhibitUpdateOnLaunch=enable` nos dois `steam.cfg`. Deploy visível no Steam por UI (opção NotProton Sikarugir) e em uso: PEAK (T12) e GHPC (1705180, sessão de 2026-10-11 00:20, shim `exited status=0`; Elvis relatou que funcionou).

## Rollback (Repair Steam + remoção da ferramenta)

1. Steam fechado (só `ipcserver` residual). Elvis executou **Repair Steam** no NotProton Sikarugir.app: bundle Valve baixado com hash fixado, injeção interna limpa, bloqueio de atualização removido.
2. `compatibilitytools.d/notproton-sikarugir-11.0-r0` **movida** (não apagada) para `scratch/t10-backup/20261011-pre-rollback/moved/`.

Readback estático (`after-rollback.json`):
- `codesign --verify --strict /Applications/Steam.app` **OK**; `Authority=Developer ID Application: Valve Corporation (MXGJJ98X76)`, `TeamIdentifier=MXGJJ98X76`, `Identifier=com.valvesoftware.steam`.
- `LSEnvironment` externo e interno = só `LC_ALL`; `notproton.dylib` ausente.
- Os dois `steam.cfg` ausentes; `compatibilitytools.d` vazio.
- `config.vdf`, `install-build.json`, `dylib.version`, `tools` com hash idêntico ao backup. `Info.plist.before-notproton` removido pelo próprio Repair (backup obsoleto).

Readback funcional (UI, Elvis): Steam original **abriu normalmente** e a opção NotProton Sikarugir **sumiu** da lista de compatibilidade. Build após abrir: `1791592380` (sem auto-update).

## Redeploy

Elvis clicou **Install** no NotProton Sikarugir.app (o Install reinicia o Steam). Comparação `after-redeploy.json` × manifesto anterior:

| Alvo | Resultado |
|---|---|
| `/Applications/Steam.app` (árvore inteira) | **idêntico** (`f74a88f8…`) |
| `Info.plist` interno, dois `steam.cfg`, pasta `notproton-sikarugir-11.0-r0` | **idênticos** |
| `dylib.version`, `tools` | idênticos |
| `install-build.json` | mesmo conteúdo (versão, builtAt, dylibHashes); só a ordem das chaves mudou |
| `backups/Info.plist.before-notproton` | recriado a partir do plist Valve limpo (sem injeção) — mais correto que o anterior, que já continha a injeção |
| `config.vdf` | só cache de servidores CM do Steam (`steamserver.net`, ping/load, `dc`); nenhuma chave de ferramenta |

`codesign --verify --strict` OK (ad hoc, como no estado anterior). Elvis confirmou por UI que a opção NotProton Sikarugir **voltou** à lista.

## Resultado

- Deploy visível no Steam: **PASS** (UI).
- Rollback real e estado anterior funcional: **PASS** (assinatura Valve, sem injeção, Steam original abre, ferramenta fora da lista; arquivos alheios preservados).
- Redeploy conferido: **PASS** por hash byte a byte dos alvos + UI.
- Jogo aberto **após** o redeploy: **NOT RUN** (Elvis optou por não abrir). A identidade de hash não comprova runtime; a prova de jogo fica com T11/T12 (PEAK e GHPC funcionaram com estes mesmos bytes antes do rollback).
- Wrapper Sikarugir original: o wrapper antigo foi apagado pelo Elvis antes deste card; o atual (`~/Applications/Sikarugir/Sikarugir.app`) não é alvo do deploy e não foi tocado.

## Achado preexistente (não regressão)

`compatdata/949230/notproton-run.log`: o helper de install script falha sempre (`Failed to create process "S:\Steam.AppBundle\Steam\Contents\MacOS\legacycompat\iscriptevaluator.exe" … : 2` → `helper exited status=1`, 9/9 ocorrências, antes e depois do T10). `legacycompat/` está vazio no bundle interno. O Steam segue para o launch mesmo assim (visto no Cities II). Investigar à parte se algum jogo depender do install script.
