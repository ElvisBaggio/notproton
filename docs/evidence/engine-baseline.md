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
