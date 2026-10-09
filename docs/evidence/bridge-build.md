# T03 — build da ponte Sikarugir: BLOCKED

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
