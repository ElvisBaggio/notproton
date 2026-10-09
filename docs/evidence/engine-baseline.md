# Engine Sikarugir — inventário T01

Data: 2026-10-08 · Agente: codex · Subagente: engine_audit · Modelo: gpt-6.1-sol.

Estado: **BLOCKED — fonte e patchset exatos não identificados**. Inventário somente leitura liberado pelo coordenador; nenhum runtime, instalação, patch ou alteração do wrapper.

## Identidade e integridade

A engine do wrapper declara `wine sikarugir 11.0 (revision 0)`. O pacote local `WS12WineSikarugir11.0.tar.xz` tem 167224628 bytes e SHA-256 `dcb3de3acab2eaf37591768dc7f6f6c20fa8e6b69c88ddd61e63798c02befcf9`, igual ao digest fornecido pela API de releases do repositório oficial. Asset criado em 2026-09-25. A comparação abaixo extraiu somente estes arquivos para scratch, sem extrair sobre o wrapper; não constitui comparação integral dos demais arquivos do pacote.

| Arquivo relativo à engine | SHA-256 | Pacote vs. instalado |
|---|---|---|
| `bin/wine` | `874d068ebd42114388e77edffc526d85460350f9d599d074acd951a2f0a32e2c` | MATCH |
| `bin/wineserver` | `2cd179014ba76e2dfe5748a5debb40eeff0ff7e93a35948d9e1c2ca0ef4ad235` | MATCH |
| `lib/wine/x86_64-unix/ntdll.so` | `c9948aab11b674b182c8dd41e212cb0be10568adeb47a28721151561456f5b6c` | MATCH |
| `lib/wine/x86_64-windows/ntdll.dll` | `da7e1ea5d7e6bca3192ff5aa4a603302a9572233a1dbe02c9c8d85505101f676` | MATCH |
| `lib/wine/i386-windows/ntdll.dll` | `e1ce5ae37f57cee3c4fea80b681fbf64e3f0611b36d5c9125851c03dea985589` | MATCH |

`file` identifica bin/wine como Mach-O x86_64 e ntdll.so como biblioteca Mach-O x86_64. `otool -L bin/wine` registra apenas libSystem; isso não prova ausência de dependências transitivas da engine. O receipt com.apple.pkg.RosettaUpdateAuto existe; execução Rosetta passou posteriormente com executável mínimo x86_64 isolado, conforme seção de aprofundamento. Wine original não foi executado.

## Proveniência

- [Release oficial das engines](https://github.com/Sikarugir-App/Engines/releases/tag/v1.0): asset, digest e tamanho conferidos ao vivo pela API GitHub.
- [Pacote correspondente](https://github.com/Sikarugir-App/Engines/releases/download/v1.0/WS12WineSikarugir11.0.tar.xz).
- [Repositório Wine da organização](https://github.com/Sikarugir-App/wine): master observado em `455e3509b98a6919fd4ad1def4803e08c41c03b2`, commit “Release 11.19.”, data 2026-10-02. **Não é identificado como fonte deste pacote**.
- [README oficial](https://github.com/Sikarugir-App/Sikarugir): informa manutenção das engines por Gcenx; fonte LGPL ali indicada cobre Configure.app, não estabelece commit/patchset desta engine.

A release e o README de Engines não vinculam este asset a um commit de fonte ou patchset. Não preencher sourceCommit com Wine upstream 11.0 nem com master 11.19 por inferência. Lock local conserva sourceURL/sourceCommit/sourcePatches como null e status bloqueado; ele não é consumível para T03. Falha de aceite é explícita: sourceCommit não pode ser resolvido como fonte correspondente.

## Ferramentas e limites

Clang 21.0.0, Swift 6.4, SDK macOS 27.0, CMake 4.4.4 e Python3 estão disponíveis. mingw-w64 não foi encontrado no PATH; Capstone não está no Python3 consultado. bison/flex encontrados são os do sistema; bridge/setup-wine-tree.sh exige ferramentas de build mais novas e mingw. Não houve instalação global.

O build existente fixa Wine 11.15 (`2df1ee28039cf84776eb1421ed90bd154cebb65f`) e ntdll da árvore compilada. Isso não permite afirmar ABI compatível com a engine 11.0. A atualização do shim para descoberta do Steam é independente da identificação da engine no código, mas executar sua bridge sob Sikarugir exige T01/T03/T04/T05; sucesso estático da correção não libera integração do runner ou jogo.

## Verificação

Assert de SHA-256 passou para os cinco arquivos listados entre pacote e instalado; version também coincide. Lock foi escrito e relido com igualdade de estrutura. Nenhum arquivo do wrapper foi escrito. Execução Rosetta passou com executável mínimo isolado; fonte exata e build reproduzível permanecem indeterminados. Wine original, API Steam e fluxo Ubisoft Connect continuam NOT RUN.

## Aprofundamento após liberação dos cards

A revisão incremental liberou T01/T02, na branch `codex/sikarugir-card-execution`. O inventário foi ampliado sem tocar instalações.

- O tag público [wine-11.0](https://github.com/Sikarugir-App/wine/releases/tag/wine-11.0) resolve ao commit `db11d0fe6a169c457e23d007e20404643d067aa8`; a branch stable em Gcenx/wine coincide. Isso identifica Wine upstream 11.0, sem provar que foi a fonte usada na engine personalizada.
- A API de refs de Sikarugir-App/wine e Gcenx/wine não retornou refs cujo nome contenha Sikarugir; busca GitHub de código por Sikarugir nesses dois repositórios não retornou resultados. Resultados negativos de busca não demonstram inexistência de fonte privada ou removida.
- O [commit de publicação](https://github.com/Sikarugir-App/Engines/commit/3f6f7e2beacff563fd849dd6ec8da7a6b5dbb1e0) adiciona WS12WineSikarugir11.0 ao EngineList em 2026-09-25, sem diff de build, commit de Wine ou patchset.
- Engines expõe somente workflow de publicação de GitHub Pages; APIs de workflows de Sikarugir-App/wine e Gcenx/wine não forneceram workflow de build vinculando o asset.
- [Portfile wine-stable](https://github.com/Gcenx/macports-wine/blob/main/emulators/wine-stable/Portfile) usa Wine11.0 e lista llvm-mingw_fixes.patch e 0001-win32u-Enable-host-Vulkan-portability-enumeration.diff. É candidato de receita, sem ligação demonstrada com o pacote Sikarugir; não adotado como patchset efetivo. Portfile sikarugir empacota Creator1.0.1, não a engine.
- Strings da ntdll.so do pacote revelam `wine-11.0 (Sikarugir)` e `SikarugirAppWine11`, confirmando identidade personalizada; não fornecem commit de fonte.

**Rosetta PASS:** Clang compilou um executável mínimo x86_64 em scratch; `file` confirmou Mach-O x86_64 e `arch -x86_64` executou com `X86_64_EXECUTION=ok`, exit0. Wine original e prefixos não foram executados. Bison efetivo é 2.3; flex 2.6.4.

**Destravamento concreto:** obter manifesto da build desse asset/digest contendo commit do Wine, patches aplicados e opções de build, ou localizar release/arquivo público que vincule esses três itens ao pacote. Nenhum contato externo foi enviado. Até isso ocorrer sourceCommit/sourcePatches permanecem null; T03 não deve começar a partir de candidatos. Não substituir engine ou remover o requisito de fonte para satisfazer o gate.


## Retomada T01 — 2026-10-09

Executor: `engine_audit_resume` · Codex / `gpt-6.1-sol`. Resultado: **BLOCKED**, sem alteração dos cinco hashes já validados e sem execução de T03.

A consulta ampliada às árvores, branches e releases públicas por API GitHub não encontrou vínculo demonstrável entre o pacote fixado e uma árvore de fonte personalizada:

- [Branches de Sikarugir-App/wine](https://api.github.com/repos/Sikarugir-App/wine/branches?per_page=100): somente `master` (`455e3509b98a6919fd4ad1def4803e08c41c03b2`). [Gcenx/wine](https://api.github.com/repos/Gcenx/wine/branches?per_page=100): `master`, `stable` (`db11d0fe6a169c457e23d007e20404643d067aa8`) e `oldstable` (`b073859675060c9211fcbccfd90e4e87520dc2c2`). Nenhuma dessas branches identifica a personalização presente nas strings do binário.
- [Árvore pública de Engines](https://github.com/Sikarugir-App/Engines): README, EngineList, página e workflow estático. [Assets da release](https://api.github.com/repos/Sikarugir-App/Engines/releases/tags/v1.0) não incluem asset nomeado como fonte/source/src. O arquivo automático “Source code” do GitHub corresponde a esse repositório de publicação, não demonstra conter fonte Wine correspondente.
- [Gcenx/macOS_Wine_builds README](https://github.com/Gcenx/macOS_Wine_builds): lista dependências MacPorts, llvm-mingw e opções de configure para seus pacotes Winehq. Esta documentação ajuda a preparar ferramentas, mas não identifica o patchset nem a receita da engine Sikarugir fixada. Não transpor suas opções para `engine-lock.json` como se fossem a build efetiva.
- [Gcenx/wine-packaging](https://github.com/Gcenx/wine-packaging/tree/master/packaging-wine/macosx) possui scripts genéricos de empacotamento; não há identificação do asset Sikarugir 11.0 r0 na árvore consultada. [Gcenx/wine-on-mac](https://github.com/Gcenx/wine-on-mac) deixa a seção de build como TODO. [Sikarugir-foss-sources](https://github.com/Sikarugir-App/Sikarugir-foss-sources) contém a árvore do aplicativo; não fornece o vínculo faltante da engine. Winerosetta é uma biblioteca auxiliar separada e não resolve a fonte de ntdll/Wine.

Esses resultados são negativos dentro das superfícies públicas consultadas, sem afirmar inexistência de fontes em outros locais. Nenhum programa externo desses repositórios foi executado; nenhum contato ou issue foi enviado ao mantenedor.

**Opções para destravar:** (1) obter do mantenedor o commit/arquivo de fonte, série ordenada de patches com hashes e opções/toolchain usados para o asset `WS12WineSikarugir11.0.tar.xz`, identificado pelo SHA-256 acima; (2) localizar esse manifesto em uma publicação oficial ainda não encontrada; (3) se a fonte permanecer indisponível, retornar ao planejamento para aprovação explícita de outra engine com fonte demonstrável. A opção 3 muda a versão fixada e invalida os hashes/hooks planejados; não foi aplicada. Uma compilação a partir do tag upstream 11.0 ou do Portfile candidato não satisfaz o aceite de T01.

**Readback:** `engine-lock.json` mantém `status=blocked-source-provenance` e `sourceURL/sourceCommit/sourcePatches=null`. As faltas de mingw/Capstone e bison antigo já registradas continuam sem instalação neste card; não há build correspondente ou prova de ABI. Wrapper, prefixos, biblioteca e runtime vivo preservados.


## Retomada após revisão F1–F8 — 2026-10-09

Executor: `t01_engine_provenance` · Cliente: Codex · Modelo efetivo: `gpt-6.1-sol` · Branch: `codex/t01-engine-provenance` · Base: `b09836e`.

**Resultado: BLOCKED — aguardando manifesto do mantenedor.** A revisão Sonnet 5.5 e a incorporação de F1–F8 liberam esta auditoria; não substituem a comprovação de fonte, patchset e opções da build. O [pedido público autorizado por Elvis](https://github.com/Sikarugir-App/Sikarugir/issues/288) está aberto e sem comentários na consulta desta rodada. As afirmações anteriores sobre ausência de contato descrevem as rodadas históricas anteriores a esse pedido.

### Readback desta rodada

- A API da [release oficial v1.0](https://github.com/Sikarugir-App/Engines/releases/tag/v1.0) ainda informa o asset com 167224628 bytes e digest `sha256:dcb3de3acab2eaf37591768dc7f6f6c20fa8e6b69c88ddd61e63798c02befcf9`.
- Os cinco arquivos da tabela e `version` foram relidos no wrapper e na extração histórica `package-reference/wswine.bundle`; todos os hashes coincidem com os valores publicados. Cada caminho foi resolvido e conferido dentro de sua raiz antes da leitura. Loader, wineserver e ntdll Unix são Mach-O x86_64; ntdll Windows são PE32+ x86-64 e PE32 i386. `otool -L bin/wine` continua listando libSystem.
- O pacote `.tar.xz` original não foi localizado na busca limitada ao nome exato em Downloads e scratch do projeto; não foi baixado nem relido nesta rodada. A comparação atual cobre a extração histórica e os cinco arquivos instalados, sem afirmar integridade de todo o pacote, wrapper ou prefixo.
- Clang 21.0.0, Swift 6.4, SDK 27.0, CMake 4.4.4, Python 3.14.8 e flex 2.6.4 confirmados. `i686-w64-mingw32-gcc` e `x86_64-w64-mingw32-gcc` ausentes do PATH; Capstone ausente nesse Python; bison 2.3 continua antigo para o script existente. Nenhuma dependência foi instalada.
- Receipt Rosetta presente. A execução x86_64 PASS permanece evidência histórica; nenhum novo probe Rosetta, execução Wine, build ou teste de ABI foi realizado.
- O lock local do worktree foi salvo com modo `0600`, relido e comparado com sua estrutura em memória. Conserva schemaVersion=1, runnerID `sikarugir-11.0-r0`, status `blocked-source-provenance` e `sourceURL/sourceCommit/sourcePatches=null`; registra esta revalidação e seus limites. Não é consumível por T03.

A resolução de `sourceCommit` segue **BLOCKED**, pois o mantenedor ainda não forneceu commit exato, patches ordenados e opções/toolchain explicitamente vinculados ao digest do asset. T01 permanece aberto/não Done; T03 não deve iniciar. Nenhum binário ou arquivo do wrapper, engine, prefixo, biblioteca ou saves foi escrito por esta execução.

### Pedido de revisão ao Claude Code Opus 5.5

Revisar esta evidência e o lock local, com foco na distinção entre identidade binária e proveniência, limites da comparação, campos de fonte nulos e bloqueio de T03. Registrar cliente e modelo efetivo do revisor antes da revisão; Opus 5.5 é o modelo solicitado, ainda não executado. A revisão deste relatório não encerra o gate de proveniência ou de runtime.


## Verificação de ABI pelo binário (D2-c) — 2026-10-09

Executor: Claude Code · modelo efetivo `claude-opus-5-5` (alias `opus`) · Branch: `claude/t01-abi-check` (base `origin/codex/t01-engine-provenance`, `40e8c58`). Card replanejado lido de `origin/codex/game-agnostic-scope` (`eaf350c`, seção T01/D2); a cópia do plano nesta branch ainda é anterior ao replanejamento.

**Resultado: `abiCheck.status=PASS` nas superfícies (a)–(d), com 11 divergências, todas classificadas como irrelevantes com evidência; nenhuma bloqueante.** Isso não é prova de runtime: Wine não foi executado, nenhum prefixo, wrapper, Steam ou save foi escrito. `sourceURL/sourceCommit/sourcePatches` seguem `null`; o pedido #288 continua aberto.

### Método

1. **Identidade.** Os cinco hashes e `version` foram relidos no wrapper e na extração `package-reference` (todos MATCH). Cópias somente leitura das três ntdll foram feitas para `scratch/abi/sikarugir/`.
2. **Toolchain local, sem instalação global.** Tudo foi instalado em `scratch/toolchain/` a partir de releases oficiais com hash conferido:

   | Ferramenta | Versão | SHA-256 do download |
   |---|---|---|
   | llvm-mingw (build principal) | 20260826, clang 23.1.0 | `48bedd161f14ae25a3646cb750b57ee3188e97e34bd3c52240c1810aa74d6a7f` |
   | llvm-mingw (controle + llvm-objdump) | 20261006, clang 23.1.3 | `a7a19b11048e89372637d26279cdb7c430ed3cf8c1e224310421312bf986ebf6` |
   | GNU bison | 3.8.2 | `9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2` |
   | GNU m4 (o m4 do sistema foi recusado pelo bison) | 1.4.19 | `63aede5c6d33b6d9b13511cd0be2cac046f2e70fd0a07aa9573a04a82783af96` |
   | capstone (venv em scratch, só para `resolve.py` em leitura) | 5.0.9 | `fc269c5082e17d7f9f265cd6980e2fdc6ab572df913951d76db0357e06b8001d` |

   O hash do llvm-mingw 20260826 coincide com o `checksums` do Portfile `cross/llvm-mingw` de Gcenx/macports-wine, que era a versão do Portfile quando o asset foi publicado. Isso aproxima o codegen, mas **não demonstra** que foi o compilador da Sikarugir. Também foram usados Apple clang 21.0.0, SDK 27.0 e flex 2.6.4 do sistema.
3. **Fonte upstream.** `git clone --depth 1 --branch wine-11.0 https://gitlab.winehq.org/wine/wine.git` resolveu o tag anotado `ce295733…` para o commit `db11d0fe6a169c457e23d007e20404643d067aa8` ("Release 11.0."), conferido por `rev-parse`.
4. **Build em scratch.** Host aarch64 com `--host=x86_64-apple-darwin`, `CC="clang -arch x86_64"`, `MACOSX_DEPLOYMENT_TARGET=14.0` (o minos da ntdll.so Sikarugir) e `--with-mingw=<llvm-mingw>/bin/clang`, além de `--disable-tests --enable-archs=i386,x86_64` e `--without-*` para bibliotecas que a ntdll não usa (lista completa em `toolchain.configure` do lock). As opções seguem de perto as publicadas em Gcenx/macOS_Wine_builds, **sem afirmar que são as da Sikarugir**. Alvos compilados: `dlls/ntdll/ntdll.so`, `x86_64-windows/ntdll.dll` e `i386-windows/ntdll.dll`. Um reconfigure + make repetido produziu os mesmos hashes (`d6648b19…`, `7a1f47f2…` e `7149c2b6…`). Para comparar, as PE passaram por `llvm-strip --strip-all` e a ntdll.so por `strip -x`, como no pacote. Um segundo build com llvm-mingw 20261006 serviu de controle.
5. **Comparador** `ntdll-patch/tests/abi_compare.py`: usa só stdlib, mais `nm` e `llvm-objdump`. Ele cobre (a) exports PE (nome, ordinal e forwarder) e exports Unix, com install name, dependências e LC_RPATH; (b) números de syscall dos stubs Nt*/Zw*; (c) a tabela interna de unix calls (pares de arrays de ponteiros de função com entrada compartilhada, validado contra o símbolo `_unix_call_wow64_funcs` do build upstream), os nomes de lookup da unixlib e os imediatos dos wrappers PE; (d) disassembly normalizado e tamanho de LdrGetDllHandle, LdrLoadDll, NtProtectVirtualMemory, NtOpenFile, NtReadFile, NtClose, build_module e alloc_module, com endereços, relocações e operandos RIP mascarados; (e) diff de strings, apenas informativo. O exit é 1 se houver divergência em (a)–(d) sem entrada `irrelevante` com id exato. O arquivo `ntdll-patch/tests/abi_justifications-sikarugir-11.0-r0.json` fica preso aos hashes do par; se o par for outro, o exit é 2.

### Checks executados

| Par | Justificativas | Resultado |
|---|---|---|
| ntdll do CrossOver instalado (string `wine-11.0-8726-g2e2f5fca349`, hashes `cx26` pinados em `resolve.py`) × Sikarugir | não | **FAIL**, exit 1, 25 divergências: export `__wine_rpc_NtReadFile`, ordinais deslocados, 3 exports Unix e LdrLoadDll/LdrGetDllHandle diferentes |
| mesmo par | sim | exit 2: justificativas recusadas porque os hashes não correspondem |
| upstream 11.0 × Sikarugir | não | FAIL, exit 1 (11 divergências) |
| upstream 11.0 × Sikarugir | sim | **PASS**, exit 0, 11 divergências e 0 falhando |
| upstream 11.0 (llvm-mingw 20261006) × Sikarugir | não | mesmos 11 ids: o resultado independe da versão do llvm-mingw testada |

Não havia build 11.15 da bridge (`scratch/wine-build-dual` ausente). Por isso, o negativo usou a ntdll 11.x do CrossOver, a que a bridge existente usa.

Contagens: exports PE 1461 (upstream) e 1462 (Sikarugir) em x86_64, 1483 e 1484 em i386; syscalls 516 em x86_64 e 528 em i386, todas com o mesmo número; exports Unix 287 e 287; tabela de unix calls com 8 entradas no upstream e 9 na Sikarugir, com entrada compartilhada no índice 7 nos dois.

### Divergências e classificação

| Id | Classe | Justificativa resumida |
|---|---|---|
| `a:pe-export:{x86_64,i386}:+__wine_unix_call` | irrelevante | Export aditivo. Nenhum export upstream falta e nenhum ordinal comum muda. |
| `a:unix-linkage:id` | irrelevante | O install name próprio é `ntdll.so` na Sikarugir e `@rpath/ntdll.so` no upstream. A `win32u.so` da própria Sikarugir depende de `@rpath/ntdll.so` com LC_RPATH `@loader_path/`, que é o mesmo esquema que lsteamclient.so terá. **Condição T03:** instalar lsteamclient.so no `x86_64-unix` da cópia isolada da engine e conferir com otool. |
| `c:unix-table:count` (8→9) | irrelevante | A 9ª entrada é acrescentada no fim e o índice 7 é compartilhado nos dois. Os imediatos PE (`wine_server_call`=3, `fd_to_handle`=4, `handle_to_fd`=5, `__wine_dbg_write`=2) coincidem. É contrato interno do par ntdll Sikarugir, que não é substituído. |
| `c:func:x86_64:wine_server_call`, `c:func:i386:wine_server_{fd_to_handle,handle_to_fd}` | irrelevante | Codegen (`jmp *%rax` em vez de `jmp *mem`; `movl` escalares em vez de `movups`), com imediatos iguais. |
| `d:func:{x86_64,i386}:alloc_module` | irrelevante | Só slots de pilha e alinhamento mudam. Deslocamentos de campos e imediatos são idênticos, incluindo DllBase/Flags de WINE_MODREF usados pelo payload (`0x30`/`0x68` em x86_64, `0x18`/`0x34` em i386). |
| `d:func:{x86_64,i386}:build_module` | irrelevante para T03; **atenção T04** | Há uma **personalização Sikarugir confirmada**: `apply_binary_patches` (strings "Found matching %s, applying patch", "CEF cmd_line_args_disabled …") é referenciado apenas por build_module, e `perform_relocations` aparece inlinado. Nenhum deslocamento de campo upstream some. `resolve.py`, em modo leitura, acha em i386 o mesmo padrão de hook em upstream e Sikarugir (`8b4514a801`, wm `edi`); só muda `load_path`, ebp-0x3c no upstream e ebp-0x40 na Sikarugir. Em x86_64, falha **igualmente** nos dois com "load_path slot rewritten". A adaptação do resolvedor é trabalho de T04, que deve derivar pins do binário Sikarugir e nunca do upstream. |

### Personalizações Sikarugir observadas (e)

A lista vem só das strings, sem afirmar o comportamento:

- caminho de build `/Users/gcenx/Documents/GitHub/wine-private/...`, banner `wine-sikarugir %s is a testing version containing experimental patches.` e identificador `ntdll-55554944ced185cda520382ba0109adbb7cd70f8`, que não resolve como commit em wine/wine nem em Gcenx/wine;
- msync (`WINEMSYNC`), hacks Rosetta (`ROSETTA_X87_PATH`, emulação XGETBV/NOP, debug registers) e D3DMetal (`CX_APPLEGPTK_LIBD3DSHARED_PATH`, regiões de código não nativo);
- `WINEDLLPATH_{DXVK,DXMT,D3DMETAL,D9VK,CNCD}` e `WINENCPU`;
- `HideWineExports` e `apply_binary_patches`;
- listas de processos de launchers: Steam (`steamwebhelper.exe`, `gameoverlayui*.exe`), Epic, EA, Ubisoft, GOG, Battle.net e Rockstar.

### Risco residual

As personalizações acima ficam fora das superfícies comparadas. As mais próximas do fluxo são HideWineExports (lookups de exports Wine), os hacks por nome de processo Steam e o patcher binário em build_module. Só T05, com a API Steam real pelo motor isolado, as cobre. O PASS vale para os binários de hash fixado; qualquer outra engine invalida as justificativas, e o comparador recusa. O lock schemaVersion=2 em `scratch/sikarugir/engine-lock.json` (local, ignorado, modo 0600) foi relido, e os cinco hashes foram reconferidos contra wrapper e extração. A cópia schemaVersion=1 no checkout principal não foi alterada. Relatório integral: [engine-abi-report.md](engine-abi-report.md).

### Pedido de revisão ao Claude Code Opus 5.5

Revisar o comparador, as justificativas, em especial build_module/T04 e a linkage `ntdll.so`, os checks negativos e o lock. O revisor deve registrar cliente e modelo efetivo. A revisão não encerra gates de runtime.
