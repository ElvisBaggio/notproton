# Probe da API Steam — T05, Passo 1 (preparo, sem runtime)

Data: 2026-10-09 · Agente: claude · Modelo efetivo: `sonnet` (Sonnet 5.5, `claude-sonnet-5-5`) · Branch `claude/t05-probe-prep` (base `origin/codex/game-agnostic-scope`).
Escopo: somente o Passo 1 do card (probe, runner, negativos sem Wine). Nenhum Wine, Steam, wrapper, engine, prefixo ou save foi tocado. **T05 continua aberto; o gate de viabilidade NÃO foi provado.** Passos 2–4 dependem de T04.

## Desenho

- `bridge/tests/steam-api-probe.c`: PE x86_64 mínimo. Não usa nem embute DLL/header da Valve. Carrega `steamclient64.dll` em tempo de execução (a que a ponte `lsteamclient` fornece, como faz `steam-shim/steam.cpp`), chama `CreateInterface("SteamClient021")` e usa slots de vtable crus: `CreateSteamPipe`(0), `ConnectToGlobalUser`(2), `GetISteamUser`(5), `GetISteamUtils`(9); `ISteamUtils::GetAppID`(9); `ISteamUser::BLoggedOn`(1). Versões de interface e slots seguem o layout público do SDK e **não foram verificados em execução**: confirmar no T05 real (se `CreateInterface` devolver NULL, ajustar a versão para a que `lsteamclient` aceita).
- Saída: somente `STEAM_INIT=ok|fail`, `APP_ID=<n>`, `AUTHENTICATED=yes|no`. Nunca SteamID, nome ou token. Exit 0 só se init ok, `APP_ID == --appid` e `BLoggedOn`; `--appid` é obrigatório (sem default). Modos: `--appid <n>` e `--selftest` (tabela de decisão, sem Steam).
- `bridge/tests/run-steam-api-probe.sh --engine <cópia> --prefix <scratch> --bridge <artefatos-T03> --appid <n> [--probe] [--loader] [--manifest] [--check-only]`. Valida tudo antes de executar: argumentos obrigatórios e `--appid` inteiro positivo; prefixo, engine e bridge sob `<repo>/scratch/` (realpath); recusa engine que seja ou esteja dentro do wrapper (`~/Applications/Sikarugir*`, `/Applications/Sikarugir*`, `*.app`); confere SHA-256 dos arquivos da bridge contra `manifest.json` (`files{caminho: sha256}`, formato do T03; avisa se não houver manifesto); loader vem de `--loader` ou de `loaderRelativePath` do `engine-lock.json`. Executa o loader da cópia com `WINEPREFIX` e `SteamAppId`/`SteamGameId` do `--appid`, guarda o log bruto só em `<prefixo>/probe-raw.log`, publica apenas linhas `STEAM_INIT|APP_ID|AUTHENTICATED` com valor curto e aborta (exit 3) se a saída tiver número com cara de SteamID (`7656119…`). `--verify-output <arquivo> --appid <n>` roda só o parser. `--negatives` executa os casos abaixo.
- Limite conhecido: `GetAppID` reflete o AppID que o cliente associa ao processo (env `SteamAppId`); o runner o define igual ao `--appid`, portanto o assert pega divergência do cliente nativo/ponte, não prova sozinho a autenticidade do jogo. A prova de sessão é `BLoggedOn` contra o Steam nativo.

## Build e hash (somente em `scratch/`, ignorado)

Compilador: llvm-mingw 20260826 ucrt (T01, leitura), `x86_64-w64-mingw32-clang -O2 -Wall -Wextra`, sem warnings.

- `scratch/t05/steam-api-probe.exe`: PE32+ console x86-64, SHA-256 `fd956173ccfb93c2bd2d656895b73f15e0bcaab708ce7f7cb8120a571f8657bc`.
- Imports (`llvm-objdump -p`): `KERNEL32.dll` e API sets UCRT `api-ms-win-crt-{stdio,runtime,locale,heap,private,string,convert,math,environment}-l1-1-0.dll`. Nenhuma DLL Valve; `steamclient64.dll` só via `LoadLibraryA` em tempo de execução. As API sets UCRT precisam existir na engine (mesma ressalva do T03; o T05 real confirma).

## Casos negativos

| Caso | Resultado |
|---|---|
| Prefixo fora de `scratch/` => recusa (exit 2) | PASS (`--negatives`) |
| Engine = wrapper original => recusa (exit 2) | PASS |
| `--appid` ausente / inválido => recusa (exit 2) | PASS |
| Argumento obrigatório ausente => recusa | PASS |
| Probe compilado nativo sem Steam: `STEAM_INIT=fail`, exit 1 (`-DPROBE_NATIVE`) | PASS (execução manual) |
| `--selftest` do probe: init falso, AppID diferente, sem login, esperado=0 => decisão de falha; caso completo => 0 | PASS (5/5) |
| Parser: init fail / AppID diferente / não autenticado / saída vazia / SteamID na saída => exit não zero | PASS (exit 1; SteamID exit 3) |
| Controle positivo do parser (saída correta => exit 0) | PASS |
| Hash da bridge diverge do manifesto => recusa (copia da bridge T03 com 1 byte alterado) | PASS (manual, em `scratch/t05`) |
| Caminho de sucesso e filtro com loader falso que imprime as 3 linhas + ruído com SteamID | PASS (manual; só as 3 linhas saíram) |
| Sem Steam nativo sob Wine => exit não zero | **NOT RUN** (exige Wine/T04) |
| AppID diferente sob Wine real | **NOT RUN** |
| Sucesso real (init + AppID + login) | **NOT RUN** |
| Prefixo descartável sem erro de loader/server/Unix-call (Passo 2) | **NOT RUN** |
| Wrapper original intacto após a execução (Passo 4) | **NOT RUN** |

Reproduzir os PASS: `sh bridge/tests/run-steam-api-probe.sh --negatives` (11/11) e `cc -DPROBE_NATIVE -o scratch/t05/probe-native bridge/tests/steam-api-probe.c && scratch/t05/probe-native --selftest`.

## Como rodar no T05 real (após T04)

Pré-condições: Steam nativo aberto e autenticado na conta que possui PEAK (D1, AppID **3527290**; decisão de 2026-10-10, reserva Prelude 2316660); cópia da engine com ntdll patchada (T04) em `scratch/`; artefatos T03 em `scratch/sikarugir/bridge/` com `manifest.json`; `lsteamclient.so` ao lado da ntdll Sikarugir da cópia; prefixo descartável em `scratch/`.

```
sh bridge/tests/run-steam-api-probe.sh \
  --engine <copia-validada-em-scratch> --prefix <prefixo-descartavel-em-scratch> \
  --bridge scratch/sikarugir/bridge --appid 3527290
```

Esperado: `STEAM_INIT=ok`, `APP_ID=3527290`, `AUTHENTICATED=yes`, exit 0. Antes: registrar em `system-baseline` o estado NotProton 1.1.0 / fonte 1.1.1 e confirmar que o wrapper original não mudou (hash antes/depois). O AppID vem da decisão D1 registrada, não de default do runner. O estado de montagem do prefixo (como a ponte e `steam.exe` entram na cópia da engine, registro, `steamclient64.dll` visível ao `LoadLibraryA`) é trabalho do Passo 2 e não está implementado aqui.

## Pendências

Revisão independente Claude Code Opus 5.5 (registrar modelo efetivo do revisor); Passos 2–4 após T04; confirmação das versões/slots de interface na execução real.


## Passo 2 — 2026-10-09: BLOCKED no loader do wineserver

Cliente: **codex** · Papel: `bridge_probe` · Modelo efetivo: **gpt-6.1-sol** · Branch: `codex/t05-steam-probe`, base `bd1b260`.

**Resultado: BLOCKED.** A montagem estática passou, mas `arch -x86_64 scratch/t05/engine/bin/wine wineboot -u`, com `WINEPREFIX` descartável e `WINEARCH=win64`, saiu **1** antes de inicializar o prefixo. Log bruto: `scratch/t05/wineboot-raw.log`. Diagnóstico exato:

```text
dyld: Library not loaded: @rpath/libinotify.0.dylib
Referenced from: scratch/t05/engine/bin/wineserver
Reason: no LC_RPATH's found
```

`otool -L` confirma esse import. A biblioteca existe em `wrapper-steam.app/Contents/Frameworks/`, **fora** da entrada `Contents/SharedSupport/wine` fornecida para a cópia. Nenhuma dependência foi instalada ou copiada e nenhum rpath/binário foi modificado para contornar a condição de parada. Isso é falha da preparação do ambiente Mach-O do wineserver, não evidência de falha de ABI da ponte. Uma próxima execução autorizada deve preparar as dependências transitivas em cópia e sua resolução antes de repetir wineboot.

### Montagem e integridade

`bridge/tests/stage-sikarugir-engine.sh` usa exclusivamente `cp -c -R` (clone APFS, sem hard links), recusa engine/prefixo existentes, valida manifesto COMPLETE de T04, hashes limpos antes e patchados depois, manifesto T03, hash do probe e do trigger Valve. O script cria a engine em `scratch/t05/engine/`, ponte local em `scratch/t05/bridge/`, probe e arquivos de Steam no prefixo `scratch/t05/pfx/`. Todas as cópias são relidas e comparadas por SHA-256; asserts são os self-checks do script. Manifesto: `scratch/t05/stage-manifest.json`, com hashes antes/depois do wrapper, arquivos colocados e `winebootExit=1`. O prefixo contém arquivos de montagem, mas **não foi inicializado com sucesso**.

| Artefato | SHA-256 |
|---|---|
| ntdll.dll x86_64 patchada | `64930d7e55ceaa0216b432d428a0752bd26d2893941a440af03890f6b6f88631` |
| ntdll.dll i386 patchada | `932f5d47883aada83f84f18065ee9f56e5cc5c9e05644fb70357b3cc5f92c4f8` |
| lsteamclient.dll x86_64 | `2933ac86d886f1264fabfbb97f21f53967452fca2397f29ecdbd29f83616c7ac` |
| lsteamclient.so x86_64 | `3dd9b54f642ad73bc8f24c3b71de65b38ef35de6424456126b9060d1fa74fdea` |
| steam.exe T03 | `56979db411cb12b48610c09b8fc01db3c34bb3c7e31ea53f1b17dafaf7f98b70` |
| steamclient64.dll trigger Valve | `caba4826aa3501039d095aee1843a6bfb270fb43a3ab4455b2d6733223579fee` |
| probe do passo 1 | `fd956173ccfb93c2bd2d656895b73f15e0bcaab708ce7f7cb8120a571f8657bc` |

`lsteamclient.so` fica em `engine/lib/wine/x86_64-unix/` ao lado da **ntdll.so original**, SHA-256 `c9948aab11b674b182c8dd41e212cb0be10568adeb47a28721151561456f5b6c`; `otool` confirma `@rpath/ntdll.so` e `LC_RPATH @loader_path/`. A DLL PE fica em `engine/lib/wine/x86_64-windows/` e também no Steam do prefixo. `steam.exe` e a cópia flat Unix ficam no Steam do prefixo, seguindo `dylib/feats/compat_run.sh` e `lsteamclient/build.sh --install`; `SteamInstaller.swift` só implanta payload/runner e não substitui essa montagem por prefixo.

**Correção documental do passo 1:** `steamclient64.dll` não é simplesmente um alias de lsteamclient. O fluxo existente exige a DLL Valve como trigger PE; o detour T04 intercepta `build_module`, carrega `lsteamclient.dll`, redireciona exports e suprime resolução de imports do trigger. O trigger foi lido do NotProton já instalado, hash conferido contra `valve-packages.manifest`, e clonado no prefixo sem escrever na instalação. Nenhuma DLL/header Valve entrou no código ou Git. O runner agora usa Rosetta explicitamente, `WINEPATH=C:\Program Files (x86)\Steam`, `steamclient64=n;lsteamclient=b` e permite `WINEDEBUG` direcionado. Isso disponibiliza o nome a `LoadLibraryA` sem renomear a DLL builtin nem executar `steam.exe` para alterar registro/abrir Steam.

### Até onde chegou e limites

- A engine foi copiada, ntdlls substituídas e ponte/trigger/probe colocados; `wineboot` criou o diretório do prefixo e falhou ao iniciar wineserver.
- **Smoke do probe NOT RUN.** Steam nativo estava aberto na checagem somente leitura; não foi fechado, aberto nem logado pelo agente. Além dessa pré-condição ausente, o loader bloqueia qualquer prova.
- Não houve evidência de lsteamclient carregada, hook executado ou Unix call. Cave x86_64 mapeado/executável e efeito de `apply_binary_patches` em lsteamclient/steam.exe: **NOT OBSERVED**, pois nenhum processo PE chegou à inicialização. Não se infere funcionamento dos hashes/builds.
- Checagem somente leitura após falha: nenhum processo da engine/prefixo descartável permaneceu vivo.
- `sh -n` dos dois scripts, negativos do runner **11/11** e `--check-only` com AppID 3527290 **PASS**; recusa de reaplicação do staging em diretórios existentes PASS. Check-only não prova runtime.
- Cinco arquivos-chave do wrapper foram hasheados antes/depois e coincidem integralmente com `engine-baseline.md`: wine `874d068e…`, wineserver `2cd17901…`, ntdll.so `c9948aab…`, ntdll x86_64 `da7e1ea5…`, ntdll i386 `e1ce5ae3…`. Hashes completos no manifesto e tabela do baseline. Wrapper, Steam, NotProton, prefixos originais e saves preservados.
- NotProton instalado 1.1.0 / fonte 1.1.1 é o estado previamente registrado por T02; não houve implantação nem nova auditoria de versão nesta execução.

### Comando exato do passo 3 (Elvis/coordenador)

**Não executar enquanto wineboot/loader e o negativo sem Steam não passarem e a revisão não for aceita.** Depois, com Steam nativo autenticado e PEAK legítimo na conta confirmado:

```sh
cd /Users/elvisoliveira/_dev/notproton/scratch/worktrees/t05-probe
rtk proxy env WINEDEBUG=-all,+module,+steamclient sh bridge/tests/run-steam-api-probe.sh \
  --engine scratch/t05/engine --prefix scratch/t05/pfx \
  --bridge scratch/t05/bridge --loader bin/wine --appid 3527290
```

Saída esperada do passo 3: `STEAM_INIT=ok`, `APP_ID=3527290`, `AUTHENTICATED=yes`, exit 0. Logs brutos ficam exclusivamente em `scratch/t05/pfx/probe-raw.log`. O mesmo comando, com Steam fechado, será o negativo pendente e deve produzir falha explícita/exit não zero **com** prova do hook/ponte carregados. Não executado aqui.

Pedido de revisão independente: **Claude Code Opus 5.5**, registrar modelo efetivo do revisor; revisar isolamento, montagem/trigger, hashes e causa do bloqueio. T05/issue #9 permanecem abertos; nenhum gate de viabilidade ou próximos cards foi liberado.


## Retomada do Passo 2 — 2026-10-09: prefixo PASS; ponte Unix BLOCKED

Cliente **codex**, papel `bridge_probe`, modelo efetivo **gpt-6.1-sol**, branch `codex/t05-steam-probe`, retomada de `d3c83e5`. Card #9 relido; T05 permanece aberto/In Progress. Não houve execução positiva com Steam autenticado nem implantação. Estado T02 registrado: NotProton instalado 1.1.0 / fonte-base 1.1.1; não reauditado nesta rodada.

**Resultado:** o bloqueio de `libinotify` foi resolvido e o script final inicializou um prefixo novo: `wineboot -u` **exit 0**, sem falha loader/wineserver/Unix-call nessa inicialização. O negativo real, com `steam_osx` ausente imediatamente antes do comando, chegou ao detour e à DLL PE da ponte; imprimiu `STEAM_INIT=fail`, `APP_ID=0`, `AUTHENTICATED=no`, runner **exit 1**. Não é ainda o negativo de sessão desejado: o Mach-O Unix da ponte foi rejeitado pelo loader Rosetta por **missing LC_UUID load command**. Gate de viabilidade NÃO aprovado.

### Launcher, ambiente mínimo e controles da causa

`strings Contents/MacOS/Sikarugir` confirma `frameworksFolderPath`, `/Frameworks`, `DYLD_FALLBACK_LIBRARY_PATH`, `/usr/lib`, `WINEDLLPATH`, `WINEDLLPATH_PREPEND`, variantes `_DXMT`, `_D9VK`, `_DXVK`, `_CNCD`, `_D3DMETAL`, `CX_ROOT` e **`SikarugirAppWine11`**. `Contents/Info.plist` contém opções de renderer e esync/msync, sem valores DYLD/WINEDLLPATH; `SharedSupport` tem apenas `winetricksHelpList.plist` como plist. Plists Resources de Configure.app e strings do seu executável não forneceram definições adicionais dessas variáveis. Não foi executado o launcher original.

| Variável/ação | Valor final e motivo |
|---|---|
| `DYLD_FALLBACK_LIBRARY_PATH` | `<engine-copia>/Frameworks:/usr/lib`: resolve libinotify e dependências locais. Definida por `/usr/bin/env` **depois** de `arch -x86_64`, pois o binário Apple protegido limpa DYLD herdado. |
| `SikarugirAppWine11` | `1`: marcador obrigatório da ntdll Unix Sikarugir; o binário testa presença por `getenv`. Ausência causa `exit(1)` silencioso antes de inicializar PE. Não contém caminho. |
| `WINEPREFIX` / `WINEARCH` | Prefixo absoluto de scratch / `win64`, impedindo uso de prefixo e arquitetura herdados. |
| `WINEDEBUG` | wineboot `-all,+module`; smoke `-all,+module,+steamclient,+virtual`, logs privados em scratch. |
| `SteamAppId` / `SteamGameId` | `3527290`, derivados do argumento obrigatório do runner. |
| `WINEPATH` | `C:\Program Files (x86)\Steam`: disponibiliza trigger PE no prefixo. |
| `WINEDLLOVERRIDES` | `steamclient64=n;lsteamclient=b`: trigger nativo e ponte builtin. |
| Limpeza herdada | Runner remove `DYLD_*`, `WINEDLLPATH*`, `CX_*`, `WINESERVER`, `WINELOADER`, `WINELOADERNOEXEC`; staging remove todos `WINE*`/DYLD/CX antes dos valores explícitos. |

`WINEDLLPATH` e suas variantes **não são necessários** ao wineboot/smoke observado: localização adjacente da engine encontra builtins. Controle com `WINEDLLPATH=<copia>/lib/wine` não corrigiu a falha sem marcador. Renderer, GST e flags msync/esync não são necessários ao probe de API; não foram adicionados ao ambiente final.

Controles salvos em scratch: fallback antes de arch falha, após arch `wineserver --version` retorna Wine 11.0; sandbox padrão falha no bootstrap Mach (`Can't check in server_mach_port`), execução autorizada fora sandbox avança. Sem marcador, wineboot e controle com **ntdll x86_64 limpa somente na cópia**, prefixo separado, falham exit 1. Caminho PE absoluto wineboot também falha sem marcador, excluindo fallback `start.exe` como causa. Instrumentação descartável de `exit` revelou ntdll Unix RVA `0x1fbc1` chamando `0x6cae0` (exit 1); disassembly mostra `getenv("SikarugirAppWine11")` e salto se NULL. Mesma ntdll Unix SHA-256 `c9948aab…` do baseline. Com marcador, wineboot passa. Interposer/debugger foram usados apenas no diagnóstico em scratch; **não estão nos scripts finais**. A primeira tentativa do interposer recursou, foi corrigida; esse log não é evidência de runtime da ponte.

### Montagem, integridade e dependências

`stage-sikarugir-engine.sh` agora clona também **todo** `Contents/Frameworks` para `scratch/t05/engine/Frameworks`, exclusivamente `cp -c -R`. Asserts verificam hashes, topologia dos symlinks, containment de cada symlink dentro da cópia e inodes diferentes (sem hard links). Histórico de todas as tentativas preservado em `scratch/t05-history-*`; nenhuma remoção do wrapper. Manifesto final `scratch/t05/stage-manifest.json`: `winebootExit=0`, `status=BLOCKED_BRIDGE_LC_UUID`, `smokeExit=1`.

Antes/depois do runtime: **cinco arquivos-chave + 965 entradas Frameworks MATCH**, inclusive comparação completa fonte/cópia e ausência de hardlinks. Hash do mapa Frameworks (JSON keys ordenadas, separadores `,`/`:`): `bf9bada4906e717adda817c6854443c26eaeea73ce68860bf152788762c2dbef`. Mapa inclui SHA-256 de cada arquivo regular e destino literal de cada symlink; está somente em scratch. `libinotify.0.dylib`: `38ce29a0bc0339b346b5b43bbc65b42c1e317495437bd8455087f1298d95ce5c`. `otool -L` confirma wineserver => `@rpath/libinotify.0.dylib` => libSystem; wine => libSystem; ntdll.so => frameworks sistema/libSystem; lsteamclient.so => ntdll adjacente/libc++/libSystem. As bibliotecas de sistema não foram copiadas. Nenhum runtime path final aponta ao wrapper original.

| Arquivo original | SHA-256 antes = depois |
|---|---|
| wine | `874d068ebd42114388e77edffc526d85460350f9d599d074acd951a2f0a32e2c` |
| wineserver | `2cd179014ba76e2dfe5748a5debb40eeff0ff7e93a35948d9e1c2ca0ef4ad235` |
| ntdll.so | `c9948aab11b674b182c8dd41e212cb0be10568adeb47a28721151561456f5b6c` |
| ntdll.dll x86_64 | `da7e1ea5d7e6bca3192ff5aa4a603302a9572233a1dbe02c9c8d85505101f676` |
| ntdll.dll i386 | `e1ce5ae37f57cee3c4fea80b681fbf64e3f0611b36d5c9125851c03dea985589` |

Hashes dos payloads/ponte/trigger/probe permanecem os da tabela da seção BLOCKED histórica. Frameworks completo preserva também dependências de SDL, freetype, MoltenVK e GStreamer; isso não implica que todas foram carregadas neste probe.

### Smoke: alcance, cave e nova causa precisa

Com Steam nativo fechado (checagem `pgrep -x steam_osx` sem PID), executado:

```sh
rtk proxy env WINEDEBUG=-all,+module,+steamclient,+virtual \
  sh bridge/tests/run-steam-api-probe.sh \
  --engine scratch/t05/engine --prefix scratch/t05/pfx \
  --bridge scratch/t05/bridge --loader bin/wine --appid 3527290
```

Log privado `scratch/t05/pfx/probe-raw.log`: trigger `steamclient64.dll` mapeado; o fluxo entra no detour e chama `LdrLoadDll` de `lsteamclient.dll`; PE da ponte mapeada em `0x6ffffc8d0000`, `DllMain PROCESS_ATTACH` retorna 1; detour torna trigger RWX por `NtProtectVirtualMemory`. A sequência corresponde ao payload T04, que faz esse carregamento/proteção. Cave x86_64 RVA `0x70860`, base ntdll `0x6ffffff40000`, endereço **`0x6ffffffb0860`**: trace virtual mostra o intervalo **`0x6ffffff41000–0x6ffffffb0fff` com `c-r-x`**, portanto mapeado e executável; comportamento de carregamento/proteção comprova execução do payload, além da observação do mapa.

A fronteira Unix falha precisamente em `get_builtin_unix_funcs`/`dlopen(<copia>/lib/wine/x86_64-unix/lsteamclient.so)`: **missing LC_UUID load command**. `otool -l` não contém LC_UUID; `lsteamclient/build.sh:200` adiciona `-Wl,-no_uuid` no modo Sikarugir para reprodutibilidade. Próxima ação **T03**: produzir Mach-O com UUID aceito por Rosetta, verificar reprodutibilidade e atualizar manifesto/hashes; depois remontar T05 e repetir negativo. Não alterar/assinar binários originais nem contornar Rosetta na execução final.

Há uma segunda observação: mesmo após o detour, o trigger tenta imports `tier0_s64.dll`/`vstdlib_s64.dll` e falha `c0000135`. **Hipótese T04, não correção aplicada:** payload faz `flags |= LDR_DONT_RESOLVE_REFS`; na fonte upstream Wine11 `fixup_imports` retorna sem resolução se esse bit estiver **limpo**, e o limpa antes de resolver quando presente. Revalidar semântica/ponto do hook no binário Sikarugir antes de alterar payload. Nenhuma DLL Valve adicional foi copiada para mascarar isso.

`apply_binary_patches`: não houve observação direta de entrada/decisão/escritas dessa função sobre lsteamclient. Hashes em disco continuam iguais, mas **isso não prova ausência de patches em memória**. A DLL PE carregou e o Unix foi rejeitado; não se atribui o erro LC_UUID ao patcher. `steam.exe` **não foi executado** nesta rodada, logo efeito do patcher sobre ele NOT OBSERVED. Próxima prova deve instrumentar a função em runtime depois de corrigir o Mach-O da ponte.

### Checks e próximo passo

Sintaxe dos dois scripts PASS; negativos **11/11** PASS; check-only PASS. Self-check descartável com loader Mach-O x86_64 de asserts: paths herdados `WINESERVER/WINELOADER/WINEDLLPATH/CX_ROOT` removidos, arquitetura win32 herdada substituída por win64, DYLD pós-arch e marcador presentes, saída CRLF normalizada: **PASS**. O teste revelou alternação incompatível no sed BSD; runner usa `sed -E` agora. Filtro CRLF corrigido para não omitir as três linhas reais do PE. Loader fake é apenas teste do runner, separado da falha real.

Passo 3 **não executar ainda**: primeiro corrigir T03 LC_UUID e esclarecer imports T04, remontar e passar negativo de sessão, revisão Astra e Claude Code Opus 5.5. Depois, com Steam do Mac aberto/logado e PEAK legítimo na conta, comando exato:

```sh
cd /Users/elvisoliveira/_dev/notproton/scratch/worktrees/t05-probe
rtk proxy env WINEDEBUG=-all,+module,+steamclient sh bridge/tests/run-steam-api-probe.sh \
  --engine scratch/t05/engine --prefix scratch/t05/pfx \
  --bridge scratch/t05/bridge --loader bin/wine --appid 3527290
```

Esperado no passo 3: init ok, AppID 3527290, authenticated yes, exit 0. Pedido de revisão independente **Claude Code Opus 5.5**, registrar modelo efetivo do revisor: isolamento/APFS, ambiente launcher, integridade, alcance real do hook e novo bloqueio LC_UUID. T05/issue #9 e gate E2 continuam abertos; Steam/biblioteca/saves/NotProton/wrapper originais preservados.


## Continuação do Passo 2 — 2026-10-09: LC_UUID resolvido; BLOCKED nos imports do trigger T04

Cliente **Codex**, agente `codex`, papel `bridge_probe`, modelo efetivo **gpt-6.1-sol**. Branch `codex/t05-steam-probe`, base `482af4c`. Steam do Mac **fechado** antes dos dois smokes e após eles (`pgrep -x steam_osx`, exit 1); nenhum processo da engine isolada restante. `git pull --ff-only`: Already up to date. Somente diagnóstico e documentação; nenhum payload T04 alterado.

**Resultado do passo 2: BLOCKED_T04_TRIGGER_IMPORTS.** A ponte Unix agora abre e fornece sua tabela de funções; o probe continua falhando no `LoadLibraryA("steamclient64.dll")`, antes de `GetProcAddress`/`CreateInterface`/SteamClient021. Portanto a falha não se limita à ausência de Steam logado e não é benigna. T05/E2 continuam abertos, Project In Progress; passo 3 não liberado.

### Hashes e smoke válido

Conferidas independentemente as três cópias de `lsteamclient.so`: `bridge/x86_64-unix/`, `engine/lib/wine/x86_64-unix/` e `pfx/drive_c/Program Files (x86)/Steam/`, todas sob `scratch/t05/`. SHA-256 **`d71f954cf1c1a2355e9dfd7e8de593d8a4d1274117d42626394d4e95c7379a9c`**, igual ao novo manifesto T03. `otool -l`: LC_UUID **BDC32712-2045-33EE-9B0F-3F37FCD8F4E1**, `@rpath/ntdll.so`, `LC_RPATH @loader_path/`. Os hashes de `lsteamclient.dll` (`2933ac86…`) e `steam.exe` (`56979db4…`) permanecem os da tabela histórica; todos os binários staged conferem.

O coordenador informou a correção T03 em `152df29`, branch `claude/t03-lc-uuid`; o rebuild/relink reproduzível não foi reexecutado neste card. O hash de `bridge/manifest.json` no stage-manifest ainda era o antigo `77d9855f…`; o conteúdo novo foi validado contra seus três artefatos e seu hash real **`60b3c3ecea54bb3c062f9f463cf4f9cb8938b3d1d9233d49b903505d6425854b`** foi atualizado somente no manifesto local. Isso não era divergência de binário nem bloqueava o runner.

Executado fora do sandbox, necessário para bootstrap Mach/lock do wineserver, sem mudar o ambiente final do runner:

```sh
rtk proxy env WINEDEBUG=-all,+module,+steamclient \
  sh bridge/tests/run-steam-api-probe.sh \
  --engine scratch/t05/engine --prefix scratch/t05/pfx \
  --bridge scratch/t05/bridge --loader bin/wine --appid 3527290
```

Resultado: runner **exit 1**, linhas explícitas **`STEAM_INIT=fail`, `APP_ID=0`, `AUTHENTICATED=no`**. Log válido preservado em `scratch/t05/smoke-uuidfix-valid-raw.log` (cópia de `pfx/probe-raw.log`); ignorados `smoke-uuidfix.out` e o antigo log de 95 B da tentativa do coordenador.

- Linhas 4877–4879/4958–5141: `lsteamclient.dll` builtin carrega e PROCESS_ATTACH retorna 1; detour T04 foi alcançado.
- Linhas 5634–5639: imports `tier0_s64.dll` e `vstdlib_s64.dll` do trigger Valve ausentes, `status=c0000135`.
- Linha 5685: **o próprio `steamclient64.dll` falha `c0000135`**. Linhas 5686–5688: o probe imprime a falha explícita. No código do probe, `if (!mod) return;` precede toda chamada à API; Steam aberto não corrige esse caminho de loader.

### Resolução Unix comprovada separadamente

DllMain ignora o retorno de `__wine_init_unix_call`, portanto PROCESS_ATTACH=1 isoladamente não comprovaria a resolução Unix. Uma segunda execução diagnóstica usou um interposer Mach-O x86_64 descartável de `dlopen`/`dlsym`, compilado com clang e guardado exclusivamente em `scratch/t05/unix-resolution-trace.{c,dylib}`; nenhuma instrução da engine/ponte/payload foi alterada. Ambiente idêntico ao runner, com `DYLD_INSERT_LIBRARIES` adicionado **após** `arch` via `/usr/bin/env`. Não faz parte do comando de produção. Log `scratch/t05/unix-resolution-raw.log`:

```text
5819: T05_DLOPEN=<engine-copia>/lib/wine/x86_64-unix/lsteamclient.so HANDLE=0xff8a0
5820: T05_DLSYM=__wine_unix_call_funcs POINTER=0x20b89c1e0
```

Handles/endereços são desta execução, não pins. Self-checks: Steam ausente, processo PE **exit 1**, mesmas três linhas de falha e mesmos imports bloqueantes. Na fonte `winecrt0/unix_lib.c:92`, `__wine_init_unix_call` consulta `MemoryWineUnixFuncs`; `ntdll/unix/virtual.c:837` faz exatamente esse dlopen e dlsym, retornando SUCCESS quando a tabela é não nula. Assim **carregamento Mach-O e resolução da tabela Unix estão observados**; o valor de retorno PE de `__wine_init_unix_call` não foi capturado diretamente. Nenhuma chamada Steam da tabela foi exercitada porque o trigger falhou antes. Não houve erro LC_UUID ou erro de resolução Unix nos novos logs.

### Causa exata T04: máscara errada e operação invertida

Fonte upstream fornecida, somente leitura: `/Users/elvisoliveira/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/wine-11.0`, base `wine-11.0` usada pelo projeto.

1. `include/winternl.h:4006`: **`LDR_DONT_RESOLVE_REFS = 0x40000000`**, um flag interno de `LDR_DATA_TABLE_ENTRY.Flags`. Não confundir com `DONT_RESOLVE_DLL_REFERENCES=1`, argumento público de LoadLibrary/build_module.
2. `loader.c:1543`: `alloc_module` cria o MODREF com esse bit **marcado**. `loader.c:1492–1493`: `fixup_imports` retorna SUCCESS sem resolver se o bit estiver **limpo**; quando marcado, limpa-o e resolve imports/TLS. O nome do bit descreve estado pendente, não uma solicitação de supressão nesse ponto do fluxo.
3. `ntdll-patch/detour.c` define a máscara incorreta **`0x00000002`** e faz `*WM_FLAGS(wm) |= LDR_DONT_RESOLVE_REFS`. Isso deixa o bit real 0x40000000 intacto: `fixup_imports` continua normalmente. Mesmo trocar apenas a máscara mantendo OR não resolveria.
4. `shim.S` preserva os registradores, passa wm=`r14`/load_path=`rsp+0x58`, reexecuta `mov rax,[rbp+0x90]` e retorna a `0x34f47`. O hook `0x34f40` fica **logo depois de alloc_module**, antes de `update_load_config` e `fixup_imports`. Não altera o argumento público `flags` de build_module. Não há supressão posterior no shim.
5. Binário Sikarugir x86_64 confirmado por disassembly da cópia (log `scratch/t05/uuidfix-loader-disassembly.txt`): alloc_module em RVA **0x355b8–0x355cf** escreve **0x40000000** (ou 0xc0000000 builtin) em **wm+0x68**; build_module em **0x35145** chama fixup_imports **0x31ac0**; essa função em **0x31adb–0x31af0** lê wm+0x68, testa **0x40000000**, salta ao retorno de sucesso se limpo e faz AND **0xbfffffff** quando marcado. A falha em **0x351c8–0x351d3** zera `*module` e devolve o erro. Os offsets são RVA desta Sikarugir, não do upstream. Fonte, binário e trace concordam.

**Conclusão [alta confiança]: bug do payload x86_64 T04 para Wine 11.0, não benigno.** Correção mínima exata proposta ao responsável T04, **não aplicada neste card**:

```diff
-#define LDR_DONT_RESOLVE_REFS  0x00000002
+#define LDR_DONT_RESOLVE_REFS  0x40000000
...
-    *WM_FLAGS(wm) |= LDR_DONT_RESOLVE_REFS;
+    *WM_FLAGS(wm) &= ~LDR_DONT_RESOLVE_REFS;
```

Com o bit limpo, fixup_imports trata o trigger como já resolvido e o entrypoint de sucesso instalado pelo detour pode ser chamado; manter o bit real marcado também suprimiria PROCESS_ATTACH (`loader.c:1690/1776`). Não copiar DLLs Valve faltantes para mascarar a causa. `shim.S` não precisa mudar para essa correção. Condicionar a limpeza ao sucesso das trampolines deve ser avaliado pelo responsável T04, já que `setup_trampolines` atualmente retorna void mesmo se a proteção falha. Rebuild, novos payloadHash/patchedHash e teste runtime pós-correção ainda são necessários: esta proposta não foi testada em payload modificado.

`detour32.c` repete a constante 0x2, mas também altera o argumento público `flags` com `FLAGS_BIT`; seu fluxo deve ser auditado separadamente pelo T04. Não transplantar cegamente a solução x86_64 nem alegar prova runtime i386 (T03 só fornece ponte x86_64).

### Integridade, limites e próxima ação

Após os dois smokes: **cinco hashes do wrapper + 965 entradas de Frameworks MATCH** com o inventário anterior; binários staged/trigger/probe também MATCH. Asserts e readback em `scratch/t05/uuidfix-integrity.json`. `stage-manifest.json` local agora registra `BLOCKED_T04_TRIGGER_IMPORTS`, smokeExit=1 e hash atualizado do manifesto da ponte. Steam não foi aberto/fechado pelo agente; não houve gravação em wrapper, engine instalada, Steam, biblioteca ou saves. Nenhum processo da cópia permaneceu vivo.

Nenhum script/payload de produção mudou: checks aplicáveis são asserts de hashes/inventário, trace Unix, disassembly e `git diff --check`. Não reexecutei testes de produção inalterados nem rebuild T03/T04. `apply_binary_patches` em memória continua NOT OBSERVED; `steam.exe` não executado. Não se usa hash em disco para provar ausência de patches em memória.

**Próxima ação:** responsável T04 corrigir máscara/operação, reconstruir/aplicar somente em cópias com novos manifests e revisão; repetir este negativo com Steam fechado, demonstrando que LoadLibrary/CreateInterface chegam à ponte e só falta a sessão nativa. Depois revisão Astra/Claude Code Opus 5.5 e passo 3 com Steam autenticado. Pedido de revisão independente **Claude Code Opus 5.5**, registrar cliente/modelo efetivo do revisor: confirmar os dois erros de flag, ponto do hook, evidência Unix e manutenção do bloqueio de T05/E2. Nenhum próximo card liberado.


## Continuação do Passo 2 — 2026-10-09: PASS, biblioteca nativa carregada / Steam fechado

Cliente **Codex**, papel `bridge_probe`, modelo efetivo **gpt-6.1-sol**, branch `codex/t05-steam-probe`, base `26c100e`. Retomada somente deste território; fonte T03 consultada em modo leitura. Steam do Mac comprovadamente fechado antes/depois (`pgrep -x steam_osx` exit 1, fora sandbox). Nenhum Steam foi iniciado, encerrado, copiado ou alterado pelo agente.

**Resultado [alta confiança]: PASSO 2 PASS.** O negativo chega à biblioteca nativa e cria a interface; falha em CreateSteamPipe com Steam ausente: `STEAM_INIT=fail`, `APP_ID=0`, `AUTHENTICATED=no`, runner exit **1**. Não houve assert, `unable to load native steamclient library`, c0000135 nem falha loader/Unix-call observada. O processo retornou normalmente. Isso remove o bloqueio desta preparação; **T05/E2 continuam abertos**, sem positivo, aceite Astra ou liberação de próximos cards.

### Fonte e ambiente confirmado

- Fonte efetiva T03: `scratch/proton-lsc/lsteamclient/unixlib.cpp:739–799` no worktree `t03-bridge`. `steamclient_init` sincroniza `SteamAppId` e `IgnoreChildProcesses` (745–746); em macOS lê `STEAM_COMPAT_CLIENT_INSTALL_PATH` e monta `<dir>/steamclient.dylib` (751–752), senão usa DYLD (755–757). `dlopen(RTLD_NOW)` e sete exports nativos precisam resolver; `Loaded host steamclient` só sai depois disso (779–799).
- `steamclient_main.c:360–382` transporta as duas variáveis Windows para o Unix call. Não lê SteamGameId/STEAM_COMPAT_DATA_PATH neste fluxo. `IgnoreChildProcesses` não foi imposto: o probe não lança filhos.
- `steam-shim/steam.cpp:1524,1596–1597,1821`: SteamGameId participa do lançamento/init de jogo; CLIENT_INSTALL_PATH e LIBRARY_PATHS geram libraryfolders.vdf dentro do prefixo. O shim steam.exe **não é executado** neste probe.
- Fluxo real do NotProton é o script `dylib/feats/compat_run.sh`, distribuído pelo app. Linhas 98–111 derivam AppID de STEAM_COMPAT_APP_ID/SteamAppId/data path e exportam SteamAppId/SteamGameId para o jogo; 878–879 derivam WINEPREFIX de DATA_PATH; 1072–1076 fornecem CLIENT_INSTALL_PATH ou o fallback instalado `~/Library/Application Support/Steam/Steam.AppBundle/Steam/Contents/MacOS`; 1373–1376 repassam variáveis no fluxo launcher. O probe usa WINEPREFIX explícito de scratch e AppID explícito; não executa staging/legacycompat do launcher nem inventa biblioteca/data path de jogo.

Runner agora exige **`--steam-client <diretório Contents/MacOS instalado>`**, resolve o caminho, exige a instalação padrão desta máquina e biblioteca legível, exporta CLIENT_INSTALL_PATH sem copiar/gravar no cliente. Mantém lookup Wine na cópia. Também recusa logs que escapem de scratch por symlink. Sintaxe shell, check-only, negativos/parser **14/14**, `git diff --check` PASS. O probe não mudou, portanto seu selftest/build não foram repetidos.

### Log real e integridade

Log privado preservado: `scratch/t05/client-path-negative-raw.log`. Linhas-chave da rodada definitiva:

```text
6030: CreateInterface name: SteamClient021
6107: steamclient_init Loaded host steamclient from "…/Steam/Contents/MacOS/steamclient.dylib"
6114: create_winISteamClient_SteamClient021 -> ponte criada (ponteiro não nulo)
6115: winISteamClient_SteamClient021_CreateSteamPipe
6116: STEAM_INIT=fail
6117: APP_ID=0
6118: AUTHENTICATED=no
```

Primeira rodada exploratória produziu o mesmo resultado; a checagem de processos falhou no sandbox (`Cannot get process list`), por isso o inventário completo e o negativo definitivo foram repetidos fora dele. Inventários completos antes/depois idênticos em `scratch/t05/client-path-before.json` e `client-path-after.json`; asserts também conferem baseline anterior e cópia de Frameworks.

SHA-256 `steamclient.dylib` **antes = depois**: `3db7cac83567792f98bc36e4f545bba6cb9aaa545846c02e489e07f0ba4ff6ec`. Cinco arquivos originais do wrapper **antes = depois**:

| Arquivo | SHA-256 |
|---|---|
| bin/wine | `874d068ebd42114388e77edffc526d85460350f9d599d074acd951a2f0a32e2c` |
| bin/wineserver | `2cd179014ba76e2dfe5748a5debb40eeff0ff7e93a35948d9e1c2ca0ef4ad235` |
| lib/wine/x86_64-unix/ntdll.so | `c9948aab11b674b182c8dd41e212cb0be10568adeb47a28721151561456f5b6c` |
| lib/wine/x86_64-windows/ntdll.dll | `da7e1ea5d7e6bca3192ff5aa4a603302a9572233a1dbe02c9c8d85505101f676` |
| lib/wine/i386-windows/ntdll.dll | `e1ce5ae37f57cee3c4fea80b681fbf64e3f0611b36d5c9125851c03dea985589` |

Frameworks: **965 entradas**, hashes de arquivos e destinos de symlinks MATCH (original/cópia/baseline). Hash do mapa JSON ordenado: `bf9bada4906e717adda817c6854443c26eaeea73ce68860bf152788762c2dbef`. ntdll x86_64 da cópia corrigida T04: `ef8e99712f845f5c4e7ee01a0475d3ccaf84114d54a0a6c962808fee34b68b29`. Nenhuma alteração de binários foi necessária nesta rodada. Dados de conta e logs brutos permanecem exclusivamente em scratch.

### Passo 3 — comando exato (pendente)

Após revisão do PASSO 2, Steam do Mac aberto/logado e PEAK legítimo (3527290) na conta, a partir deste worktree:

```sh
rtk proxy env WINEDEBUG=-all,+module,+steamclient sh bridge/tests/run-steam-api-probe.sh \
  --engine scratch/t05/engine --prefix scratch/t05/pfx \
  --bridge scratch/t05/bridge --loader bin/wine --appid 3527290 \
  --steam-client "$HOME/Library/Application Support/Steam/Steam.AppBundle/Steam/Contents/MacOS"
```

Esperado: `STEAM_INIT=ok`, `APP_ID=3527290`, `AUTHENTICATED=yes`, exit 0. **Não executado nesta rodada.** A preparação PASS não comprova autenticação, jogo, i386, save/reabertura, patches Sikarugir em memória ou fluxo steam.exe. NotProton instalado 1.1.0 / fonte-base 1.1.1 permanecem os estados registrados no T02, não reauditados.

Pedido de revisão independente: **Claude Code Opus 5.5**, registrar modelo efetivo do revisor; conferir fonte/ambiente, recusa de escrita fora scratch, logs e integridade. Astra ainda deve aceitar o gate após positivo. Issue #9 e Project permanecem In Progress.


## Passo 3 — 2026-10-09 22:34 -03:00: PASS real com Steam autenticado / PEAK

Cliente **Codex**, papel **bridge_probe**, modelo efetivo **gpt-6.1-sol**, worktree `scratch/worktrees/t05-probe`, branch `codex/t05-steam-probe`, base `cdf3be5` (integrada à branch de escopo em `b73fd50`, conforme handoff de Elvis). `git pull --ff-only`: Already up to date. Steam aberto e logado por Elvis, com PEAK/AppID **3527290** na conta conforme autorização explícita; o agente não iniciou, fechou, reiniciou ou fez login no cliente.

**Resultado [alta confiança]: PASS do probe e do gate de viabilidade técnica medido pelo T05.** Processo Windows da cópia Sikarugir chegou à biblioteca Steam nativa instalada e às interfaces SteamClient021, SteamUtils010 e SteamUser023; sessão autenticada observada via BLoggedOn, não inferida de processo/build. Aceite independente do gate por Astra e revisão Claude Code Opus 5.5 ainda pendentes; T05/E2 não encerrados e nenhum próximo card liberado.

### Pré-condições e execução exata

`pgrep -x steam_osx` exit **0** antes/depois. `content_log.txt`: última linha de versão `[2026-10-09 22:31:47] Client version: 1791415817`, igual ao perfil T02. Sem controle do Steam; leituras de processos/probe foram executadas fora do sandbox após este impedir a listagem. NotProton instalado 1.1.0 / fonte-base 1.1.1 são o registro T02, não uma nova auditoria nesta rodada.

```sh
rtk proxy env WINEDEBUG=-all,+module,+steamclient sh bridge/tests/run-steam-api-probe.sh \
  --engine scratch/t05/engine --prefix scratch/t05/pfx \
  --bridge scratch/t05/bridge --loader bin/wine --appid 3527290 \
  --steam-client "$HOME/Library/Application Support/Steam/Steam.AppBundle/Steam/Contents/MacOS"
```

Saída pública, allowlist exata conferida sem identificadores, nomes ou tokens:

```text
STEAM_INIT=ok
APP_ID=3527290
AUTHENTICATED=yes
```

**Exit do runner: 0**, incluindo exit do probe conferido pelo runner. Log bruto privado `scratch/t05/step3-peak-probe-raw.log`; saída pública `scratch/t05/step3-peak-probe-filtered.txt`. Linhas-chave sanitizadas (omitidos caminhos, parâmetros, ponteiros e valores de usuário):

```text
5964: CreateInterface name: SteamClient021
6119: Loaded host steamclient
6137: winISteamClient_SteamClient021_CreateSteamPipe
6200: winISteamClient_SteamClient021_ConnectToGlobalUser
6201: winISteamClient_SteamClient021_GetISteamUser
6204: winISteamClient_SteamClient021_GetISteamUtils
6207: winISteamUtils_SteamUtils010_GetAppID
6208: winISteamUser_SteamUser023_BLoggedOn
```

### Controle AppID diferente com Steam aberto

Mesmo comando/engine/prefixo, apenas `--appid 480`: **exit 0** e `STEAM_INIT=ok / APP_ID=480 / AUTHENTICATED=yes`. Logs privados preservados em `scratch/t05/step3-480-probe-raw.log` e `step3-480-probe-filtered.txt`. Sem c0000135, erro de biblioteca nativa, assertion failed ou err:steamclient nos dois logs.

**Negativo de contexto/licença NÃO INFORMATIVO pelo desenho atual.** O runner define `SteamAppId` e `SteamGameId` iguais a `--appid`; GetAppID devolveu o contexto solicitado também para 480. O probe não fixa PEAK, não consulta propriedade/licença e não inicia o jogo. Portanto o positivo prova init/API/sessão autenticada no contexto PEAK, não a posse da licença (esta foi declarada por Elvis), nem a rejeição de outro AppID.

Controle adicional do parser com a saída real de 480 e `--appid 3527290`: **exit 1**, `falha: APP_ID='480', esperado '3527290'`. Isso comprova rejeição de divergência na saída, separadamente do controle runtime acima. Nenhum código foi alterado para fabricar uma recusa runtime.

### Integridade antes/depois e encerramento

Inventários `scratch/t05/step3-before.json` e `step3-after.json`: igualdade total por assert e igualdade com o baseline do Passo 2 nas três superfícies. SHA-256 dos dois inventários JSON: **`cc3a8baff5d930b0cbb63cc244514a96b4f16d05a07533eca990b38ff183c5a2`** (antes = depois).

| Arquivo original do wrapper | SHA-256 antes | Depois |
|---|---|---|
| bin/wine | `874d068ebd42114388e77edffc526d85460350f9d599d074acd951a2f0a32e2c` | igual |
| bin/wineserver | `2cd179014ba76e2dfe5748a5debb40eeff0ff7e93a35948d9e1c2ca0ef4ad235` | igual |
| lib/wine/i386-windows/ntdll.dll | `e1ce5ae37f57cee3c4fea80b681fbf64e3f0611b36d5c9125851c03dea985589` | igual |
| lib/wine/x86_64-unix/ntdll.so | `c9948aab11b674b182c8dd41e212cb0be10568adeb47a28721151561456f5b6c` | igual |
| lib/wine/x86_64-windows/ntdll.dll | `da7e1ea5d7e6bca3192ff5aa4a603302a9572233a1dbe02c9c8d85505101f676` | igual |

`steamclient.dylib` instalada antes = depois: **`3db7cac83567792f98bc36e4f545bba6cb9aaa545846c02e489e07f0ba4ff6ec`**. Frameworks originais: **965 entradas**, hashes de todos os arquivos e destinos de symlinks antes = depois. SHA-256 do mapa `json.dumps(frameworks, sort_keys=True)` nesta rodada: **`67abe5fee7bed7918f0e742ddf5f5afd115ab7d28e53f63d6db67136f5f2cec5`**; o serializador usa espaços padrão, por isso difere do digest compacto anterior, mas o mapa comparado é idêntico ao baseline.

`ps -axo pid=,command=` filtrado pelos caminhos absolutos da engine/prefixo: **0 processos isolados restantes**, Steam nativo continua aberto. Nenhuma escrita do agente em instalação Steam, NotProton, wrapper, biblioteca ou saves. O cliente aberto pode atualizar seus próprios logs; a integridade aqui cobre explicitamente as superfícies acima.

Validação desta rodada: positivo real exit0; controle runtime 480 exit0 com limite documentado; mismatch parser exit1; allowlist dos dois logs públicos; hashes/readback; ausência de processos isolados; `git diff --check`. Sem mudanças de produção, não repetidos build/negativos estáticos já registrados. Não testados steam.exe, i386, execução de PEAK, renderer, save/reabertura, rollback de implantação ou apply_binary_patches em memória.

**Próximo passo:** revisão independente **Claude Code Opus 5.5**, registrar cliente/modelo efetivo do revisor e avaliar explicitamente o limite do negativo AppID; Astra aceitar o gate antes de integração/liberação. Issue #9 permanece aberta; Project #8 confirmado **In Progress / Pronto**, papel bridge_probe / gpt-6.1-sol preservados.
