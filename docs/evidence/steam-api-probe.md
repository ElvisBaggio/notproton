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
