# T04 — porte dos patches ntdll para Sikarugir 11.0 r0 (parte preparatória)

Data: 2026-10-09 · Agente: claude · Modelo efetivo: `claude-opus-5-5` (Claude Code `opus`) · Branch: `claude/t04-ntdll-prep` (base `origin/codex/game-agnostic-scope` `db21814`)

**Estado: PARCIAL, aguardando T03.** Hooks resolvidos e validados nas duas arquiteturas, testes negativos passando, manifesto parcial gerado. `payloadHash`/`patchedHash` e a aplicação real em cópia ficam pendentes porque dependem do payload do detour, que só será construído depois de T03. Nada roda em runtime.

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
