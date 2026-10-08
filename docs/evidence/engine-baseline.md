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

`file` identifica bin/wine como Mach-O x86_64 e ntdll.so como biblioteca Mach-O x86_64. `otool -L bin/wine` registra apenas libSystem; isso não prova ausência de dependências transitivas da engine. O receipt com.apple.pkg.RosettaUpdateAuto existe; execução x86_64 não foi testada.

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

Assert de SHA-256 passou para os cinco arquivos listados entre pacote e instalado; version também coincide. Lock foi escrito e relido com igualdade de estrutura. Nenhum arquivo do wrapper foi escrito. Fonte exata, build reproduzível, execução Rosetta, API Steam e fluxo Ubisoft Connect continuam NOT RUN/indeterminados.
