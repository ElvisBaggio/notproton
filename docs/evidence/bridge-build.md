# T03 — build da ponte Sikarugir

## Tentativa inicial — BLOCKED (2026-10-09)

Data: 2026-10-09 · Cliente: codex · Agente/papel: wine_bridge · Modelo efetivo: gpt-6.1-sol.
Branch: `codex/t03-bridge-sikarugir`, base `db21814`.

## Resultado e causa

**BLOCKED pela condição de parada do card: a base fixada não oferece interfaces exigidas pelo shim atual.** T01 continua válido: ABI PASS da ntdll não equivale à disponibilidade das interfaces do sistema de build introduzidas depois do Wine 11.0. Nenhuma troca para Wine 11.15 foi feita.

A árvore upstream `wine-11.0` foi clonada localmente, sem hardlinks, da fonte T01 para `scratch/sikarugir/wine/`; HEAD conferido: `db11d0fe6a169c457e23d007e20404643d067aa8`. O lock T01 foi copiado para `scratch/sikarugir/engine-lock.json` e relido: schemaVersion 2, provenanceMode binary-abi-verified, abiCheck.status PASS. Os originais T01 foram usados somente para leitura. A cópia inicial continha `.git` de worktree e foi substituída por clone com metadados próprios antes da tentativa.

A tentativa real de `make bridge-sikarugir`, com configuração experimental restrita a Rosetta/x86_64, falhou no registro dos componentes, antes de configure/compilação:

```text
==> source tree at pinned db11d0fe6a169c457e23d007e20404643d067aa8
==> registering dlls/lsteamclient and programs/steam.exe with configure
error: patch failed: configure:23493
error: configure: patch does not apply
make: *** [bridge-sikarugir] Error 1
```

Reprodução independente, sem gravação:

```sh
rtk proxy git -C scratch/sikarugir/wine apply --check /Users/elvisoliveira/_dev/notproton/scratch/worktrees/t03-bridge/bridge/register-components.diff
```

Não é apenas deslocamento das linhas do patch. `bridge/register-components.diff:7` requer `WINE_EXTERNAL(programs/steam.exe)` para que makedep ignore includes internos do jsoncpp amalgamado; a base 11.0 não contém a macro em `aclocal.m4` nem `EXTERNAL_SUBDIRS` em `configure`. O patch registrado para 11.15 adiciona o shim a `EXTERNAL_SUBDIRS` e usa a macro. `steam-shim/Makefile.in:5` importa `$(CXX_PE_LIBS)`, que representa libc++, libc++abi e libunwind PE conforme comentário nas linhas 2–4. Na base 11.0 não existem `CXX_PE_LIBS`, `libs/c++`, `libs/c++abi` nem `libs/unwind`. Seu makedep possui mecanismo antigo `EXTLIB`, associado a biblioteca estática; não é a interface `WINE_EXTERNAL` consumida pelo shim.

Backport dessas interfaces ou mudança da integração C++ exigiria nova decisão de escopo. As alterações experimentais dos scripts e Makefile foram retiradas; os quatro arquivos de produção permanecem iguais à base desta branch. Não foi entregue alvo `bridge-sikarugir` nem build parcialmente utilizável.

## TDD e checks

O check foi escrito antes das adaptações; primeiro RED: `AssertionError: configuração Sikarugir ausente`. O teste final foi reduzido ao gate read-only que valida lock, commit real, seleção Rosetta e disponibilidade das interfaces. Permanece **RED esperado**, com diagnóstico concreto:

```sh
rtk proxy sh bridge/tests/sikarugir-buildcheck.sh
# exit 1: sikarugir-buildcheck: BLOCKED: Wine fixado não oferece WINE_EXTERNAL exigido pelo shim
```

Sete negativos executados com cópias temporárias do lock: schemaVersion 1, ABI BLOCKED, WINE_COMMIT divergente, commit da árvore divergente, UNIX_ARCH arm64, HOST aarch64 e WINE_TAG wine-11.15; todos recusados antes de build, com a causa esperada. `sh -n`, `git diff --check` e `make -n bridge` passaram. O dry-run legado conserva builds Rosetta e FEX; build legado completo não foi executado. O teste não declara PASS do card.

## Hashes e layout

| Entrada local | SHA-256 |
|---|---|
| engine-lock.json | `a248fa46b4a32764da4f21db8e327ccd89ba70bfbc9e461928ac887e2ff4bec4` |
| wine-11.0/aclocal.m4 | `e9e947bc7eacb84e481b54d7b3586c7438bc1c9446ec1e5791189c579d13bb0b` |
| wine-11.0/configure | `2ecf7de966e3cd315ce0852a4da6bdb7b2a19451e2b2c10991c56938ab91e515` |

**Artefatos lsteamclient.so/lsteamclient.dll/steam.exe: não produzidos; hashes, file/otool e rebuild reproduzível NOT RUN.** Não houve FEX, i386, Wine/runtime, instalação global ou gravação em engine/wrapper/prefixos/Steam/NotProton/saves. O build-env experimental e log local permanecem em scratch ignorado para diagnóstico.

A condição T01 continua obrigatória para a retomada: o futuro `lsteamclient.so` deve ficar em `lib/wine/x86_64-unix` da **cópia isolada** da engine, ao lado da ntdll Sikarugir original. Seu import `@rpath/ntdll.so`, com LC_RPATH `@loader_path/`, deve resolver para essa ntdll; jamais distribuir/substituir a ntdll upstream de build. T03 não verificou esse layout em artefato construído.

## Próximo passo e revisão

Solicitar revisão Claude Code Opus 5.5 do bloqueio e decisão explícita sobre adaptação do shim ao sistema de build 11.0 (ou fonte correspondente do mantenedor, quando disponível). Registrar cliente/modelo efetivo do revisor. T03 permanece aberto; T04/T05 não são liberados por este diagnóstico.


## Retomada aprovada — PASS de build reproduzível (2026-10-09)

Cliente **codex**, papel **wine_bridge**, modelo efetivo **gpt-6.1-sol**, branch `codex/t03-bridge-sikarugir`. Merge de `origin/codex/game-agnostic-scope` aplicado antes da implementação (inclui decisão `b441be3`); HANDOFF das duas linhas preservado. A seção BLOCKED acima é histórica e permanece como evidência da tentativa `dcc8a73`.

### Implementação e entradas

- Base `wine-11.0`, commit `db11d0fe6a169c457e23d007e20404643d067aa8`; lock T01 schemaVersion 2, `abiCheck.status=PASS`, SHA-256 `a248fa46b4a32764da4f21db8e327ccd89ba70bfbc9e461928ac887e2ff4bec4`. Cópia privada de fonte com `.git` próprio; originais T01 usados somente para leitura.
- `bridge/register-lsteamclient-11.0.diff` adiciona somente `dlls/lsteamclient` em configure/configure.ac. Patch 11.15 `bridge/register-components.diff` permanece intacto. Nenhum backport de `WINE_EXTERNAL`, `EXTERNAL_SUBDIRS`, `CXX_PE_LIBS` ou bibliotecas C++ PE.
- `make bridge-sikarugir` usa `bridge/build-sikarugir.sh` e o modo `SIKARUGIR=1` nos scripts existentes. Rosetta/x86_64, sem i386 ou FEX. Artefatos e manifesto em `scratch/sikarugir/bridge/`; nenhum alvo de instalação.
- O `makedep` 11.0 não possui parser de `.cpp` em `parse_functions[]`, logo não reconhece seu `#pragma makedep unix`. Apenas no Makefile.in da cópia `dlls/lsteamclient`, as linhas `.cpp` são retiradas do SOURCES PE; os **219** arquivos C++ continuam compilados pelo build Unix manual já existente, dentro do build da base verificada. Include antecipado de `wchar.h` evita que o macro de proibição `wcsncpy` da winbase.h alcance libc++. Isso não altera o Wine original.
- Ponte Unix: Apple clang 21.0.0, SDK macOS 27.0, `-arch x86_64`, deployment target 14.0, `-O2`, sem `-g` e com `-Wl,-no_uuid` (**SUPERADO em `152df29`**: `-no_uuid` removido porque o dyld recusa dylib sem LC_UUID; ld64 deriva o UUID do conteúdo e o relink segue reproduzível; `lsteamclient.so` vigente `d71f954cf1c1a2355e9dfd7e8de593d8a4d1274117d42626394d4e95c7379a9c`, a `3dd9b54f…` abaixo é histórica). Eliminados debug map com mtimes e UUID variável; assinatura x86_64 ausente conforme regra existente. Ponte PE: llvm-mingw no Wine, com `llvm-strip --strip-all` na cópia de saída. `SOURCE_DATE_EPOCH=1767916800` fixado.
- Shim externo: llvm-mingw **20260826**, clang **23.1.0**, T01, `-std=c++17 -O2 -static -static-libgcc -static-libstdc++ -mwindows -Wl,--no-insert-timestamp`. Runtime C++ libc++/libc++abi/libunwind resolvida estaticamente. Os includes de compilação são SDK Steam 142, fontes do shim e headers llvm-mingw, sem headers internos de Wine.
- `steam-shim/mingw_compat.h` fornece debug, `ARRAY_SIZE`, POSIX compat existente e declarações de NT directory APIs. A extensão **pública** kernel32 `wine_get_dos_file_name` é resolvida via GetProcAddress, com erro explícito se ausente, sem import PE exclusivo Wine. `CP_UNIXCP` e `ProcessWineMakeProcessSystem` conservam o contrato existente em runtime. A indisponibilidade de OpenVR Linux já era imposta pelo adaptador PE `dlfcn.h`; o caminho externo registra falha equivalente sem incluir Unix/Vulkan internos. Não foi acrescentado suporte VR.

### Receita local

Pré-condições: lock copiado de T01 e clone privado Wine 11.0 em `scratch/sikarugir/wine/`. Nenhuma instalação global. Exportar apenas a toolchain validada e bison/m4 locais:

```sh
rtk proxy sh -c '
  export LLVM_MINGW=/Users/elvisoliveira/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/toolchain/llvm-mingw-20260826-ucrt-macos-universal
  export PATH=/Users/elvisoliveira/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/toolchain/bison/bin:/Users/elvisoliveira/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/toolchain/m4/bin:$PATH
  make bridge-sikarugir
'
rtk proxy sh bridge/tests/sikarugir-negativecheck.sh
```

A receita escolhe `/usr/bin/clang` para o host macOS explicitamente: `clang` do PATH llvm-mingw não é o compilador Apple com SDK do host. Opções configure completas ficam no script e em `scratch/sikarugir/wine-build/config.status`. Logs: `build-external.log`, `rebuild-clean.log`, inspeções `*-inspection.txt`, `artifact-check.log` e `dynamic-negative.log`, todos em scratch ignorado.

### Inspeções e condição da ntdll

`file`, `otool -L/-l` e `llvm-objdump -p` executados nos três artefatos. `file`: `.so` Mach-O x86_64, `.dll` PE32+ DLL x86-64, `.exe` PE32+ GUI x86-64. `otool` não exibe load commands Mach-O para os PEs; seus imports foram inspecionados por llvm-objdump.

Ponte Unix, `otool -L`:

```text
@rpath/lsteamclient.so
@rpath/ntdll.so
/usr/lib/libc++.1.dylib
/usr/lib/libSystem.B.dylib
```

`otool -l`: `LC_RPATH path @loader_path/`. Sem dependências de CrossOver ou caminhos de scratch. O libc++ **macOS** da ponte Unix é biblioteca do sistema; a recusa de runtime C++ dinâmica aplica-se ao **PE steam.exe**.

Layout estático de prova em `scratch/sikarugir/link-layout/lib/wine/x86_64-unix/`: ponte ao lado da **cópia da ntdll Sikarugir** de T01. Hash relido e comparado ao lock: `c9948aab11b674b182c8dd41e212cb0be10568adeb47a28721151561456f5b6c`. Assim `@rpath/ntdll.so` + `@loader_path/` resolve para essa cópia. Este é um fixture de layout, sem loader/engine executado; T05 deverá verificar o carregamento real. A ntdll upstream foi usada apenas para link no build, **não incluída na saída bridge** nem substituída na engine instalada.

Imports `steam.exe`: USER32, ADVAPI32, SHLWAPI, SHELL32, msi, ntdll, KERNEL32 e API sets UCRT (`api-ms-win-crt-*` do sistema). **Nenhum** libc++.dll, libc++abi.dll, libunwind.dll, msvcp140, vcruntime140 ou import de símbolo `wine_*`/`__wine*`. Imports `lsteamclient.dll`: user32, ws2_32, ucrtbase, kernel32, ntdll. A tabela Unix `__wine_unix_call_funcs` está exportada.

### Checks e reprodução

Gate positivo de lock/base/layout/artefatos **PASS**. Os sete negativos estão agora preservados como teste executável (`sikarugir-negativecheck.sh`): schemaVersion 1, ABI BLOCKED, WINE_COMMIT divergente, commit real divergente, UNIX_ARCH arm64, HOST aarch64/FEX e WINE_TAG 11.15; todos **PASS** (recusa antes do build, com causa esperada). Controle adicional real: compilado PE C++ com runtime dinâmica, substituído temporariamente apenas o steam.exe da saída de teste; gate recusou `libc++.dll`/`libunwind.dll`, e o original foi restaurado com hash conferido. Nenhum desses executáveis foi executado.

`make -n bridge` comparado byte a byte com Makefile de `dcc8a73`: **idêntico**. `bridge/register-components.diff`: sem alterações. Teste existente `steam-shim/tests/install-paths-check.sh`: **PASS**. Sintaxe shell e `git diff --check`: **PASS**. Shellcheck não disponível; sem instalação para esse check.

Reconstrução **do zero**: removidos somente `scratch/sikarugir/wine-build/` (incluindo configure e objetos) e `scratch/sikarugir/bridge/`, reconfigurado e compilado tudo novamente. **PASS: os três SHA-256 brutos são idênticos**, sem normalização posterior para a comparação. Limite: mesma toolchain, SDK e layout deste Mac; não afirma reprodução entre máquinas. Manifesto local: `scratch/sikarugir/bridge/manifest.json`; comparação: `scratch/sikarugir/reproducibility.json`.

| Artefato sob scratch/sikarugir/bridge/ | SHA-256 nas duas compilações |
|---|---|
| `steam.exe` | `56979db411cb12b48610c09b8fc01db3c34bb3c7e31ea53f1b17dafaf7f98b70` |
| `x86_64-windows/lsteamclient.dll` | `2933ac86d886f1264fabfbb97f21f53967452fca2397f29ecdbd29f83616c7ac` |
| `x86_64-unix/lsteamclient.so` | `3dd9b54f642ad73bc8f24c3b71de65b38ef35de6424456126b9060d1fa74fdea` |


### Limites e revisão

Nenhum runtime Wine, Steam, prefixo, wrapper, engine instalada, NotProton ou save foi usado/alterado. Build e prova de layout não liberam T05. Persistem para T05 a disponibilidade efetiva da extensão pública de conversão de caminhos, o comportamento de CP_UNIXCP/NT flags, a comunicação Steam real e a influência do `apply_binary_patches`/HideWineExports da Sikarugir. i386 permanece ausente até haver consumidor que o exija; OpenVR Linux não é suportado pelo shim PE.

Revisão independente **solicitada para Claude Code Opus 5.5**, com registro do modelo efetivo esperado no parecer. Issue #7 deve continuar aberta e Project In Progress até revisão/aceite; nenhuma revisão independente foi executada por este cliente nesta retomada.

## #42 — lsteamclient i386 (wow64) para o Sikarugir 11.0 r0 (2026-10-11) — Agente: claude · Modelo efetivo: opus (claude-opus-5-5)

Motivo: o Ubisoft Connect (32-bit, exigido por Ghost Recon Wildlands 460930) falha com `Failed to load module 'C:\Program Files (x86)\Steam\steamclient.dll'` e não ativa a compra do Steam. O consumidor i386 previsto acima apareceu.

Build (sem tocar no worktree do T03 nem em nada instalado):
- Fonte: clone APFS de `scratch/worktrees/t03-bridge/scratch/sikarugir/wine` → `scratch/sikarugir/wine` (`db11d0fe6a169c457e23d007e20404643d067aa8`, `lsteamclient` registrado pelo `register-lsteamclient-11.0.diff`).
- Build dir novo `scratch/sikarugir/wine-build-i386`: mesmas `CONFIGURE_OPTS` do T03 (`build-env.sh`), trocando só `--enable-archs=x86_64` por `--enable-archs=i386,x86_64`; llvm-mingw 20260826 (`i686-windows`), `SOURCE_DATE_EPOCH=1767916800`, flags PE iguais às do T03 (`-g -O2`).
- `make dlls/lsteamclient/i386-windows/lsteamclient.dll` → `llvm-strip --strip-all`.
- **Metade unix não muda:** o `lsteamclient.so` x86_64 distribuído já exporta `___wine_unix_call_wow64_funcs` e os thunks `wow64_*`.

Artefato `i386-windows/lsteamclient.dll` (strip): PE i386, 2.076.672 bytes, marcador `Wine builtin DLL` em 0x40, 74 exports (igual ao x86_64, incluindo `CreateInterface`/`Steam_BGetCallback`/`Breakpad_*`), imports `kernel32`/`ntdll`/`ucrtbase`/`user32`/`ws2_32` (iguais ao x86_64). Hash normalizado (`pe-info.py`, timestamp/checksum zerados): `16299d034712121a`.

Reprodutibilidade: um segundo configure+build em `scratch/sikarugir/wine-build-i386-rebuild` dá, depois do strip, um arquivo **byte a byte idêntico** (`cmp` = 0). Os binários com debug diferem só pelo caminho do build dir no DWARF.

Runtime (Steam do Mac aberto e logado, tudo em `scratch/b42/`):
- Motor: clone APFS do runner instalado (`ntdll` i386 `60c6a031…` e x86_64 `ef8e9971…` já patchados pelo T04) + `lib/wine/i386-windows/lsteamclient.dll`.
- Prefixo novo (`wineboot -i`) + gatilhos Valve em `Program Files (x86)\Steam`: `steamclient.dll` i386 `e9e961c9…` e `steamclient64.dll` `caba4826…`, ambos conferidos contra `valve-packages.manifest`.
- `bridge/tests/steam-api-probe.c` agora compila para i386 (`__thiscall`, `LoadLibraryA("steamclient.dll")`); `run-steam-api-probe.sh` passa `steamclient=n;steamclient64=n;lsteamclient=b`, igual ao `compat_run.sh`.
- `+loaddll` 32-bit: `steam-api-probe32.exe` native → `C:\windows\system32\lsteamclient.dll` **builtin (i386)** → `Program Files (x86)\Steam\steamclient.dll` native. O detour i386 do T04 entrega a ponte.

| Probe (AppID 460930) | STEAM_INIT | APP_ID | AUTHENTICATED | rc |
|---|---|---|---|---|
| x86_64 (controle) | ok | 460930 | yes | 0 |
| **i386** | **ok** | **460930** | **yes** | **0** |

Pendente no card: staging pelo app/`compat_run.sh` (`lib/wine/i386-windows/lsteamclient.dll` no runner; `steamclient.dll` no prefixo), `build-sikarugir.sh`/manifesto com o i386 e prova no Wildlands (Ubisoft Connect sem o erro de `steamclient.dll`, 3559 na conta, `GRW.exe` iniciado).

### #42 — integração (2026-10-11, claude)

- `bridge/build-sikarugir.sh`: segunda árvore `scratch/sikarugir/wine-build-i386` (`--enable-archs=i386,x86_64`, configurada só na primeira vez) para o PE i386; strip; manifesto com `i386-windows/lsteamclient.dll`. A árvore x86_64 do T03 não muda: numa árvore dual-arch o PE x86_64 sai diferente do fixado.
- `sikarugir-buildcheck.sh --artifacts`: PE i386 (`coff-i386`), imports iguais aos do x86_64 e `___wine_unix_call_wow64_funcs` no `.so`.
- Pins: `RunnerPatcher.sikarugirBridge`, `stage-sikarugir-payload.py` e `payload.manifest` ganham `i386-windows/lsteamclient.dll` = `bd277143ea313df40f2a7cb844051e34eb115c44ce1014920af89f1b5d5a549a`. O Set Up/Repair do runner instala em `lib/wine/i386-windows/`.
- `compat_run.sh`: `bridge_files` inclui o gatilho Valve `steamclient.dll` (i386, `e9e961c9…`, já no payload); `verify_runner` avisa se faltar `i386-windows/lsteamclient.dll` no runner.
- Testes: `bridgecheck` (5 arquivos), `sikarugircheck` (aviso i386), `PayloadManifestTests`/`BridgePayloadTests`/`RunnerPatcherTests`/`RunnerLifecycleTests`. `make app-tests` (com `--manifest-cache none`, depois do `app-payload`): **452/452**. As suítes shell da CI passam. Os 4 testes de reparo com clone real são pulados enquanto o runner instalado não tiver o i386 (dependem de um clone "saudável").
- `make bridge-sikarugir` completo nesta checkout: rc=0, `sikarugir-buildcheck: PASS`, i386 = `bd277143…`.

**Achado: a reprodutibilidade dos PEs depende do caminho.** O `steam.exe` e o `lsteamclient.dll` x86_64 compilados nesta checkout deram `a41205e7…`/`5efccfbb…`, e não os pins `56979db4…`/`2933ac86…`. Os PEs embutem o caminho absoluto do fonte (strings `__FILE__`, ex.: `…/scratch/worktrees/t03-bridge/scratch/sikarugir/wine/dlls/lsteamclient/steam_input_manual.c`), então o T03 só se reproduz no caminho original. A ponte local usa as três peças x86_64 fixadas do T03 mais a i386 nova (o i386 se reproduz desde que compilado a partir de `scratch/sikarugir/wine`). Correção sugerida em card próprio: `-ffile-prefix-map` no build, com novos pins validados em runtime.

### #42 — prefixo antigo sem `syswow64/lsteamclient.dll` (2026-10-11, claude)

Sintoma no Wildlands depois do Install/Repair (runner com o i386, prefixo com `steamclient.dll`): o Ubisoft Connect continuou com `Failed to load module 'C:\Program Files (x86)\Steam\steamclient.dll'` e o Wine registrou `import_dll Library tier0_s.dll / vstdlib_s.dll (which is needed by …\Steam\steamclient.dll) not found`.

Isolamento com `scratch/b42/loadmodes.c` (i386; carrega o gatilho como launchers fazem: nome, caminho completo, `LOAD_WITH_ALTERED_SEARCH_PATH`, `LOAD_LIBRARY_SEARCH_*`, `SetDefaultDllDirectories`):
- motor de scratch + prefixo de scratch: os 6 modos carregam, ponte ativa;
- sem `WINEDLLOVERRIDES`/`WINEPATH`: caminho completo ainda carrega;
- **runner real + clone APFS do prefixo real: falha (tier0_s.dll)**; motor de scratch + prefixo real: falha; runner real + prefixo de scratch: carrega. **A variável é o prefixo.**
- Diferença: o prefixo de scratch, criado por `wineboot` com o runner já com o i386, tem `windows/syswow64/lsteamclient.dll`. O do Wildlands, criado antes, não tem. O Wine 11 só acha o builtin quando existe esse arquivo em `system32`/`syswow64`; sem ele, o `resolve_lsteam` do detour i386 falha, o detour desiste e os imports da Valve são resolvidos.
- Copiar o builtin i386 do runner para `syswow64` no clone do prefixo real fez a ponte assumir.

Correção: `compat_run.sh` `place_wow64_lsteamclient` (depois do `verify_runner`) copia `runner/lib/wine/i386-windows/lsteamclient.dll` para `drive_c/windows/syswow64/` quando falta ou difere; teste em `sikarugircheck.sh` (cópia e idempotência). Suítes shell e 452/452 Swift passam. `shellcheck` não está instalado nesta máquina (fica para a CI).

### #42 — prova no Wildlands (2026-10-11 19:15, claude)

App com `84640e6` instalado, Install feito, prefixo 460930 com `syswow64/lsteamclient.dll`. `notproton-run.log` sem erros `tier0_s.dll`/`vstdlib_s.dll`; `game_starter_log.txt` sem `Failed to initialize Steam API` (antes: 17:06, 18:53, 19:03). `launcher_log.txt` 19:16:00: `Login Type: ticket, platform: Steam` → `AccountsNotLinked` / `BusLoginSteam, Cannot login without a linked Steam account`. O Ubisoft Connect (32-bit) obteve o ticket da sessão Steam pela ponte i386 e a Ubisoft o recebeu. A recusa é de conta (Steam não vinculada à conta Ubisoft), não do runtime. Ativação do 3559 e `GRW.exe` dependem do vínculo da conta (ação do usuário).

**19:23 — jogo iniciado.** O 401 das tentativas por credenciais era a senha (tecla morta `^` do teclado do Mac chegando como outro caractere no Wine; confirmado pelo usuário). Com a senha correta: `Login Type: credentials` → `User: …` → `Play session (1) successfully started for game 3559` → `Game with process id 1248 has been started with product id 3559` / `connected (API version: 1.0.0)`; processo `S:\steamapps\common\Wildlands\GRW.exe -uplay_steam_mode` rodando. Gameplay/save ainda não comprovados.
