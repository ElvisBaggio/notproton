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
