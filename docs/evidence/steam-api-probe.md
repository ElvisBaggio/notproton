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
