# T04 — porte dos patches ntdll para Sikarugir 11.0 r0

Data: 2026-10-09 · Agente: claude · Modelo efetivo: `claude-opus-5-5` (Claude Code `opus`) · Branch: `claude/t04-ntdll-prep` (base `origin/codex/game-agnostic-scope` `db21814`)

**Estado histórico do preparo: PARCIAL, aguardando T03.** Hooks resolvidos e validados nas duas arquiteturas, testes negativos passando, manifesto parcial gerado. `payloadHash`/`patchedHash` e a aplicação real em cópia ficam pendentes porque dependem do payload do detour, que só será construído depois de T03. Nada roda em runtime.

## Entradas (somente leitura)

Cópias da engine instalada em `scratch/sikarugir/orig/<arch>/ntdll.dll`, com escrita removida. Hashes conferidos contra o original e contra o `engine-lock.json` de T01 (`files[]`, schemaVersion 2, `abiCheck=PASS`):

| arquitetura | sha256 (clean) | imageBase |
|---|---|---|
| x86_64-windows | `da7e1ea5d7e6bca3192ff5aa4a603302a9572233a1dbe02c9c8d85505101f676` | `0x170000000` |
| i386-windows | `e1ce5ae37f57cee3c4fea80b681fbf64e3f0611b36d5c9125851c03dea985589` | `0x7bc00000` |

Origem: `wrapper-steam.app/Contents/SharedSupport/wine/lib/wine/<arch>/ntdll.dll`. O wrapper, a engine, os prefixos e o Steam não foram alterados.

## Método

1. **TDD.** Criei `ntdll-patch/tests/test_sikarugir.py` com fixtures PE sintéticas (PE32 e PE32+ geradas no próprio teste, sem binário de terceiros e sem capstone). A primeira execução falhou: com o python3 do sistema, `resolve.py` não importava sem capstone. Corrigido o import, a falha passou a ser a esperada, `apply` sem `patch_file`/`patch_bytes`, em 14 erros. Depois da implementação, os 10 testes passam.
2. **Patcher guiado por pins** (`apply.py`: `patch_bytes`, `patch_file`, CLI `--manifest`). Antes de escrever qualquer byte, ele confere estas condições: arquitetura (machine × `architecture`), SHA-256 do arquivo inteiro × `cleanHash` (se o arquivo já estiver patcheado, a mensagem diz "already patched"), `payloadHash` presente e igual, RVA do hook e do payload inteiramente dentro dos dados raw de uma seção, bytes do hook iguais a `expectedBytes` e cave com o preenchimento esperado. Ele também recusa aplicar no próprio arquivo de origem. A saída só aparece completa, gravada em `.tmp` e depois movida com `os.replace`. Quando há `patchedHash`, o resultado é conferido contra ele. Nada disso faz desassembly: o patcher consome só o manifesto, o mesmo contrato que o `NtdllPatcher` de T07 deve seguir.
3. **Resolvedor x86_64** (`resolve.py`, mudança mínima em `amd64_load_path` e no hook de `resolve_amd64`).
   - **Causa da falha em T01.** O build_module do Wine 11.0 (Sikarugir e upstream) monta frame `rbp = rsp + 0x80` e guarda `load_path` (rcx) em `[rbp - 0x28]`. O resolvedor só reconhecia spill em `[rsp + N]` e por isso pegava um `mov [rsp + 0x28], rcx` posterior. Esse mov é argumento de saída de outra chamada, e nesse ponto rcx já não é mais o load_path. Depois o resolvedor acusava "slot rewritten" em `0x34dd4`.
   - **Correção.** Quando há `lea rbp, [rsp + K]` antes do spill, o spill `[rbp ± d]` vira o slot rsp `K ± d`. As invariantes passam a valer desde o `lea`: rsp não se move até o hook, rbp não é reescrito e o slot não é regravado em nenhuma das duas formas.
   - **Novas invariantes do hook amd64.** A instrução roubada tem ≥ 5 bytes, não é rip-relativa e nenhum desvio do build_module cai no meio dela. O resultado de alloc_module também tem de ficar guardado em registrador (`wm`).
   - O import de capstone virou opcional: sem ele, `PE`/`apply.patch_bytes` funcionam e qualquer desassembly falha com mensagem clara. `PE(path, data=None)` aceita bytes.
   - Novo `resolve.py --json <ntdll...>`, que emite as entradas do manifesto. `--sh` e o modo relatório não mudaram de interface.
4. **Manifesto.** `scratch/sikarugir/patches.json` (local, ignorado) gerado a partir de `--json` e embrulhado por `scratch/t04/mkpatches.py`. O embrulho recusa se `cleanHash` ≠ pin do engine-lock.
5. **Ensaio sem gravação** (`scratch/t04/dryrun.py`) sobre as cópias reais, com payload fictício de NOPs só para exercitar as checagens. O manifesto real (payloadHash null) é recusado. Com hash fictício, o diff fica só nas regiões previstas, a reaplicação é recusada e as origens continuam intactas. **Isso não é o patch nem prova de funcionamento.**

## Pins derivados do binário Sikarugir

| | x86_64-windows | i386-windows |
|---|---|---|
| build_module | `0x34b40`–`0x354ff` (pdata) | prólogo via ref. de string |
| hookRVA | `0x34f40` | `0x2eba0` |
| expectedBytes | `488b8590000000` (`mov rax, [rbp+0x90]`, teste de `id`) | `8b4514a801` (`mov eax,[ebp+0x14]; test al,1`) |
| resume | `0x34f47` | `0x2eba5` |
| wm (MODREF) | `r14` | `edi` |
| load_path | `rsp+0x58` (= `rbp-0x28`) | `ebp-0x40` |
| cave | padding `0x70855`, 1963 B, fill `0xcc`; payload em `0x70860`, espaço 1952 B | seção anexada `.npdet` em `0x9a000` (4096 B), raw `0x98000` |
| LdrGetDllHandle / LdrLoadDll | `0x17002ef50` / `0x17002ced0` | `0x7bc29e20` / `0x7bc28420` |
| NtProtectVirtualMemory | `0x170055924` | `0x7bc4cb84` |
| NtOpenFile / NtReadFile / NtClose | `0x170055584` / `0x170054fe4` / `0x170055104` | `0x7bc4c9b4` / `0x7bc4c6e4` / `0x7bc4c774` |

Conferências independentes:
- **Fonte** `wine-11.0` `dlls/ntdll/loader.c:2252`: `build_module(LPCWSTR load_path, …, const struct file_id *id, …)`, e `if (id) wm->id = *id;` logo após `alloc_module`. Em x86_64, `[rbp+0x90]` = `rsp+0x110` = 5º argumento (`id`), consistente com o pin CrossOver cx26 (`cmp [rsp+0xf0],0`, também o teste de `id`). O padrão é o mesmo, mas os valores são outros e foram derivados do binário Sikarugir.
- **Varredura linear de todo o `.text`** (`scratch/t04/intoscan.py`): nenhum jmp/call direto cai no interior dos bytes roubados, nas duas arquiteturas.
- **Upstream `wine-11.0`** (build de T01): mesmo padrão em x86_64 (`0x34a1c`, `mov rax,[rbp+0x80]`, wm `r14`, `rsp+0x50`) e em i386 (`0x2e790`, `ebp-0x3c`). Os offsets diferem dos da Sikarugir por causa de `apply_binary_patches`. Os pins vêm só da Sikarugir.
- **`apply_binary_patches`** (personalização Sikarugir dentro de build_module): as strings são referenciadas em `0x35421`–`0x3547e` (x86_64) e `0x2ee38`–`0x2eed7` (i386), depois do hook no layout do código. Não comprovei a ordem em execução; isso fica para T05.
- **Regressão CrossOver** (cx26 instalado, só leitura): self-test "all pinned values reproduced" em x86_64 e i386, e saída `--sh` byte a byte idêntica à do `resolve.py` original para cx26 x86_64/i386 e Sikarugir i386. Os demais builds CrossOver pinados (rosetta, fex, 41069) não estão nesta máquina e não foram reexecutados.

## Verificação

- `rtk proxy python3 -m unittest discover -s ntdll-patch/tests -p 'test_sikarugir.py'`: 10 testes OK com o python3 do sistema, sem capstone, e também no venv com capstone 5.0.7. Testes do card: `test_rejects_unknown_hash`, `test_rejects_changed_hook_bytes`, `test_rejects_out_of_bounds_rva` (não mapeado, sem raw, cruza o fim do raw, cabeçalho, payload além do arquivo), `test_rejects_wrong_architecture` (i386↔x86_64, aarch64) e `test_patch_preserves_unrelated_bytes` (padding e seção anexada). Extras: payload sem pin ou divergente, cave suja, reaplicação e patch no próprio arquivo. Todas as recusas verificam origem intacta e ausência de saída.
- `abi_compare.py` de T01 (POS upstream × Sikarugir com justificativas) segue com exit 0. O arquivo não foi alterado.

## Limites

- Sem runtime e sem patch real: as checagens foram exercitadas em fixtures e num ensaio em memória com payload fictício.
- O tamanho do payload Sikarugir ainda é desconhecido. O espaço no cave x86_64 é de 1952 B (o detour2 CrossOver tem 864 B). Se o payload novo não couber, `shell_vars` recusa, e mudar para seção anexada exige revisar o critério `PAYLOAD[...]`.
- O shim reexecuta `mov rax,[rbp+0x90]` a partir do cave. Isso depende de rbp ser preservado pelo shim (`shim.S` não toca rbp), o que ainda precisa ser confirmado no build do payload.
- Personalizações Sikarugir fora do build_module (HideWineExports, hacks por processo, msync) não são cobertas aqui; isso fica para T05.

## Pendente após T03

1. Construir os payloads x86_64 (`build.sh`) e i386 (`build32.sh`) com os `--sh` acima, usando toolchain local (llvm-mingw de T01 em scratch, sem instalação global). Registrar `payloadHash` e o tamanho.
2. `apply.py --manifest scratch/sikarugir/patches.json <cópia> <saída> <payload>` só em cópia, depois registrar `patchedHash` e confirmar que a reaplicação sobre a saída é recusada.
3. Reexecutar os testes e a resolução read-only, e atualizar este relatório e o manifesto (`status` deixa de ser `PARTIAL`).
4. Incorporar os pins no app só em T07.

## Fechamento — PASS estático, 2026-10-09

Cliente: `codex` · Papel: `ntdll_port` · Modelo efetivo: `gpt-6.1-sol`.
Branch: `codex/t04-ntdll-close`, base `ba9c880` (preparo `3096c26` + linha T01/T02/T03 integrada).
**PASS de construção/aplicação em cópias; revisão independente Claude Code Opus 5.5 solicitada, ainda pendente.** Nenhum runtime Wine executado; T05 continua responsável pela prova de funcionamento e T07 pelos pins no app.

### Build e ABI do payload

Mudança mínima nos scripts: `LLVM_MINGW`, `PYTHON` e `BUILD_DIR` permitem usar a toolchain/venv T01 somente para leitura e colocar toda saída no scratch. Sem essas variáveis, permanecem ferramentas, nomes e interface legados. `resolve.py --sh` fornece todos os pins; falha de resolução interrompe o build. O tamanho produzido é conferido contra `NP_CAVE_ROOM`. O patcher por manifesto também recusa payload maior que `cave.room` (novo teste negativo).

O ld.lld PE não suporta os scripts GNU `link.ld`/`link32.ld`. O caminho LLVM compila e liga **objetos ELF como intermediários freestanding**, extraindo somente `.cave` como bytes; não produz DLL Linux nem introduz libc. x86_64 usa `ms_abi` explicitamente na entrada e nos três ponteiros Nt/Ldr, `-fpie` para referências RIP-relative e `-mno-red-zone`. No caminho GCC Windows, `NP_ABI` vazio mantém a ABI anterior. i386 mantém cdecl na entrada, stdcall nos ponteiros Nt/Ldr e o delta explícito para referências absolutas; apenas o nome da chamada no shim é adaptado para o símbolo ELF sem underscore. Não se alterou a lógica dos detours.

```sh
rtk proxy sh -c '
  export LLVM_MINGW=/Users/elvisoliveira/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/toolchain/llvm-mingw-20260826-ucrt-macos-universal
  export PYTHON=/Users/elvisoliveira/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/venv-capstone/bin/python3
  base="$PWD/scratch/sikarugir"
  BUILD_DIR="$base/payload/x86_64-windows" sh ntdll-patch/build.sh "$base/orig/x86_64-windows/ntdll.dll" sikarugir
  BUILD_DIR="$base/payload/i386-windows" sh ntdll-patch/build32.sh "$base/orig/i386-windows/ntdll.dll" sikarugir
'
```

Toolchain llvm-mingw 20260826 de T01, sem instalação global. `llvm-readelf -r`: nenhuma relocation pendente nos dois links. `llvm-objdump -d` e asserts capstone: entrada no início do payload, contexto Nt/Ldr nos endereços pinados, wm r14/edi, load_path rsp+0x58/ebp-0x40, bytes roubados reexecutados e jmp para os resumes exatos. Shim x86_64 não modifica rbp; função C preserva/restaura rbp e os demais registradores não voláteis pela ABI MS. O aviso `_start` ausente é do intermediário ELF; o payload entra por shim_entry3/shim_entry32, não pelo entrypoint ELF. Reconstrução em diretórios novos `scratch/sikarugir/rebuild/<arch>/` deu bytes e hashes idênticos nas duas arquiteturas.

### Artefatos finais (ignorados)

Manifesto: `scratch/sikarugir/patches.json`, `status=COMPLETE`, `pending=[]`, hashes preenchidos, executor registrado. Cópias limpas revalidadas contra os pins, manifesto resolvido novamente do binário e engine-lock T01 `abiCheck=PASS`. Artefato T03 x86_64 lsteamclient.dll relido e hash conferido `2933ac86d886f1264fabfbb97f21f53967452fca2397f29ecdbd29f83616c7ac`; o payload procura esse nome/exports em runtime, sem embutir a ponte. T03 não fornece ponte i386: payload i386 foi construído/aplicado estaticamente por exigência deste card, sem promessa de caminho i386 funcional.

| Arquitetura | Payload / bytes / SHA-256 | ntdll patchada SHA-256 |
|---|---|---|
| x86_64-windows | `payload/x86_64-windows/detour2-sikarugir.bin`, 834/1952 B, `526dfad08eeeab29b6ce4c9c7843a9adb27496280a19a41ec61d271ad66d982b` | `64930d7e55ceaa0216b432d428a0752bd26d2893941a440af03890f6b6f88631` |
| i386-windows | `payload/i386-windows/detour32-sikarugir.bin`, 1370/4096 B, `50daa1d304380ea3d12018d7c9457a4c8d532427fe814ded412f039dc0be7e0f` | `932f5d47883aada83f84f18065ee9f56e5cc5c9e05644fb70357b3cc5f92c4f8` |

Saídas: `scratch/sikarugir/patched/<arch>/ntdll.dll`. Aplicação executada pela CLI `apply.py --manifest`; depois `patchedHash` preenchido e resultado recalculado com hash fixado. Script local assert-based `scratch/sikarugir/verify.py` registra diff e testa recusas CLI. As origens copiadas e as duas ntdll **instaladas** foram relidas e seguem com os hashes clean da tabela inicial.

### Diff de regiões

Intervalos de arquivo abaixo são `[início, fim)`; todos os bytes antigos fora deles foram comparados individualmente e preservados.

- x86_64: hook `[0x34f40,0x34f47)` e payload `[0x70860,0x70ba2)`. 817 bytes realmente diferentes; comprimento do arquivo inalterado. Hook final `e91bb90300cccc`.
- i386: hook `[0x2eba0,0x2eba5)`; NumberOfSections `[0x7e,0x80)`; SizeOfImage `[0xc8,0xcc)`; cabeçalho `.npdet` `[0x260,0x288)`. 21 bytes antigos realmente diferentes. Acrescentados 4096 B em `[0x98000,0x99000)`, payload `[0x98000,0x9855a)`, restante zero. RVA `.npdet=0x9a000`; hook final `e95bb40600`.
- Manifesto contém `changedFileRanges` completos (inclusive lacunas de bytes iguais), `allowedFileRanges`, contagem alterada/adicionada e mensagens de recusa por arquitetura.

### Checks e limites

- `python3 -m unittest discover -s ntdll-patch/tests -p 'test_*.py'`: **11 testes PASS** no Python do sistema (ausência de capstone confirmada) e no venv capstone 5.0.7.
- Nas duas imagens reais copiadas: reaplicação recusada como `already patched`; mutação de um byte fora do hook recusada como hash `unknown`. Entrada preservada byte a byte; nenhuma saída nem `.tmp` após recusa.
- CrossOver cx26 instalado, somente leitura, x86_64/i386: self-test **all pinned values reproduced**; `resolve.py --sh` byte a byte idêntico ao resolvedor anterior ao preparo (`3096c26^`). Demais builds CrossOver ausentes não reexecutados; build GCC legado não refeito.
- `sh -n` dos scripts e `git diff --check`: PASS. Shellcheck indisponível.
- Não foram tocados wrapper, engine instalada, prefixos, Steam, saves, app, Makefile, bridge, lsteamclient, steam-shim ou território do probe paralelo. Sem runtime, instalação global ou binário versionado. Efeito de HideWineExports/apply_binary_patches e funcionamento real ficam para T05.
