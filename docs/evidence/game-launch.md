# T11 — Instalação e abertura do jogo de teste (D1 = PEAK)

## Pré-condições T11

Data: 2026-10-10 · Agente: claude · Modelo efetivo: `sonnet` (Sonnet 5.5, `claude-sonnet-5-5`) · Branch `claude/t11-peak-prep` (base `origin/codex/game-agnostic-scope`) · Issue #15.
Escopo: preparo somente leitura. Nada foi instalado, comprado, baixado ou executado; o Steam não foi controlado. **T11 não foi iniciado nem provado**; depende de T10. Nenhum SteamID, nome de conta ou token foi copiado.

### 1. Depots, launch e Cloud (cache local `appcache/appinfo.vdf`)

Método: parser binário mínimo (Python stdlib, magic `0x07564429`, tabela de strings; 244 apps no cache) em `scratch/appinfo_probe.py` (scratch ignorado, sem instalar pacote). Substitui o SteamDB (403). O cache é do cliente Steam do Mac, lido sem abri-lo para escrita. Leitura do cache em 2026-10-10; o `buildid` muda a cada atualização do jogo.

| App | No cache | `common/oslist` | `osarch` | Depots | Observação |
|-----|----------|-----------------|----------|--------|------------|
| PEAK 3527290 | sim | `windows` | 64 | **só 3527291** (`oslist=windows`, `osarch=64`); nenhum depot macOS nem Linux | Branch `public`: buildid 25739797; manifest gid 7760699995234210393; download 1 565 047 488 B (~1,46 GiB); instalado 1 930 335 969 B (~1,80 GiB); há 1 branch privada |
| Prelude 2316660 | **não** | — | — | — | Fora do cache; só a API pública da loja (windows+linux, sem mac, D1). Depots exigem `steamcmd +app_info_print` ou SteamDB depois |
| Banana 2923300 | **não** | — | — | — | Igual ao Prelude |

Conclusão (PEAK): ausência de depot macOS confirmada localmente, sem SteamDB. Pelo Steam nativo do Mac a única opção é o depot Windows 3527291, com ferramenta de compatibilidade. Observação: `common/steam_deck_compatibility` marca categoria 3 (Deck "Verified"), `recommended_runtime=proton-10.0-beta`, build testado 19603959.

Entradas `config/launch` do PEAK (`installdir=PEAK`):

| # | Executável | Argumentos | `type` | oslist/osarch | Descrição |
|---|------------|------------|--------|---------------|-----------|
| 5 | `PEAK.exe` | — | option1 | windows/64 | PEAK using DX12 |
| 6 | `PEAK.exe` | `-force-d3d11` | option2 | windows/64 | PEAK using DX11 |
| 8 | `PEAK.exe` | `-force-vulkan` | option3 | windows | PEAK using Vulkan |
| 9 | `PEAK.exe` | `-force-vulkan` | default | linux (BetaKey `internal-playtesting`) | Steam Deck Default |

Implicação para T11: o jogo expõe seletores nativos de renderer (DX12, DX11, Vulkan). A opção DX11 (`-force-d3d11`) é a rota de menor risco para o Mac e contorna o requisito "DirectX 12" da loja. A opção 9 é Linux e não se aplica.

Steam Cloud (`ufs`), **contradizendo a nota da loja** do D1 ("sem Steam Cloud listado"): o PEAK tem Auto-Cloud.

| Plataforma | root | path | pattern | Cota / arquivos |
|------------|------|------|---------|-----------------|
| Windows | `WinAppDataLocalLow` | `LandCrab/PEAK` | `*.peak` | 10 000 000 B (~9,5 MiB) · máx. 10 arquivos |
| Linux | `LinuxXdgConfigHome` | `unity3d/LandCrab/PEAK` | `*.peak` | idem |
| MacOS | `MacAppSupport` | `unity.LandCrab.PEAK` | `*.peak` | idem (existe a regra, mas não há build macOS) |

Risco de Cloud: o Steam sincroniza só a regra da plataforma da *ferramenta/SO* efetivo. Rodando como Windows via compatibilidade o esperado é a regra `WinAppDataLocalLow`, mas não está provado se o Steam nativo do Mac a avalia como `Windows` ou `MacOS`. **Passo 1 do T11 deve registrar isso** antes de jogar: Cloud pode copiar saves para o prefixo ou ignorá-los; não resolver conflito automaticamente.

### 2. Caminho de save/config

| Jogo | Windows (fonte) | No prefixo Wine (esperado) | Confiança |
|------|-----------------|----------------------------|-----------|
| PEAK | `%USERPROFILE%\AppData\LocalLow\LandCrab\PEAK\*.peak` (appinfo `ufs`, root `WinAppDataLocalLow`) | `<prefixo>/drive_c/users/<usuário-wine>/AppData/LocalLow/LandCrab/PEAK/` | Alta para o diretório (campo oficial do jogo). **A empresa é `LandCrab`, não "Team PEAK"** (que é o `developer`). Usuário-wine e a existência do `LocalLow` dependem do prefixo; confirmar após a primeira execução. Config do Unity pode estar em `HKCU\Software\LandCrab\PEAK` (registro, `user.reg`); não verificado |
| Prelude 2316660 | não obtido (appinfo ausente; PCGamingWiki respondeu bloqueio) | Hipótese Godot: `.../AppData/Roaming/Godot/app_userdata/Halls of Torment/` | Baixa; confirmar em T11 se a reserva for acionada |

`<usuário-wine>` não está registrado no repositório: depende do prefixo criado pelo T03/T10; verificar com `ls <prefixo>/drive_c/users`.

### 3. Posse da conta

| Verificação local | Resultado |
|-------------------|-----------|
| `steamapps/libraryfolders.vdf` | sem 3527290; `apps` vazia (nenhum jogo instalado) |
| `steamapps/appmanifest_*.acf` | inexistentes |
| `appcache/appinfo.vdf` | PEAK presente, mas esse cache também guarda apps apenas visitados na loja; **não prova posse** |
| `appcache/librarycache/3527290/` | existe, idem: cache de metadados, **não prova posse** |

Conclusão: **posse não verificável localmente** sem ler `licensecache`/`userdata` (descartado por conter dados da conta). **Confirmar com Elvis** que a conta possui 3527290 (R$ 23,99 segundo a loja em 2026-10-10) antes de T11; a compra é decisão dele.

**Atualização 2026-10-10:** Elvis confirmou que a conta **possui o PEAK (3527290)**. Pré-condição de posse atendida; nenhum dado da conta foi registrado.

### 4. Sequência proposta do T11 (após T10, com Elvis)

1. Conferir pré-condições: T10 concluído e rollback testado; posse confirmada; espaço (~1,8 GiB instalados + ~1,5 GiB de download, margem de 10 GiB); Steam fechado para qualquer deploy de ferramenta, depois aberto por Elvis.
2. Snapshot: `libraryfolders.vdf`, `config.vdf`/`appmanifest` ausentes, hashes do wrapper (conforme T02/T10). Cloud: registrar estado antes (conta pode já ter saves na nuvem).
3. Criar biblioteca Steam **isolada** (pasta exclusiva do projeto, fora da biblioteca atual) e definir como destino da instalação.
4. Em Propriedades > Compatibilidade, selecionar `notproton-sikarugir-11.0-r0` para o AppID 3527290; sem Steam Windows.
5. Instalar. Conferir em `appmanifest_3527290.acf` na biblioteca isolada: `appid`, `buildid` (esperado 25739797 ou o vigente), `depots` com `3527291` e nenhum depot macOS; registrar o tamanho (`SizeOnDisk`).
6. Primeira abertura pelo Jogar. Preferir launch option DX11 (`-force-d3d11`, entrada 6) para a primeira tentativa; se falhar, registrar DX12 e Vulkan separadamente. Diagnosticar por camada: ponte (Steam/lsteamclient), Wine (prefixo, loader), jogo (Unity).
7. Gameplay real (não só menu), registrar build, renderer efetivo e saída do processo; conferir que o botão Jogar volta ao estado correto.
8. Verificar caminho do save no prefixo e se o Steam Cloud sincronizou `*.peak`.

Logs a consultar: Steam `~/Library/Application Support/Steam/logs/` (`content_log.txt`, `compat_log.txt`, `console_log.txt`, `cloud_log.txt`), log do Unity do jogo em `<prefixo>/drive_c/users/<usuário-wine>/AppData/LocalLow/LandCrab/PEAK/Player.log`, e a saída do wrapper/engine conforme T10. Antes de anexar ao repositório, filtrar SteamID, nome de conta e caminhos pessoais.

### 5. Riscos

| Risco | Detalhe | Mitigação |
|-------|---------|-----------|
| Renderer DX12 | Wrapper hoje com `D3DMETAL=0`/`DXVK=0`; loja exige DX12. Investigação em paralelo em `claude/dx12-renderer-risk` (só referenciado) | Usar `-force-d3d11` (launch option 6) ou `-force-vulkan` (8); ver aquele branch para a análise |
| Cloud/plataforma | Regra Windows vs MacOS do `ufs` não provada para ferramenta no Mac | Registrar no Passo 1; não resolver conflitos |
| Posse/compra | Não verificável localmente | Elvis confirma; não comprar automaticamente |
| Cache `appinfo` datado | Build e manifesto podem ter mudado desde 2026-10-10 | Reler `appmanifest` e `buildid` na instalação |
| Prelude/Banana sem appinfo | Reservas sem depot confirmado | `steamcmd +app_info_print` só se acionadas |
| Possível patch/ proteção | Sem DRM de terceiros listado; Unity pode ter anti-cheat opcional não observado | Observar em primeira abertura; patch só com hash/build |
| Dados de conta nos logs | Logs do Steam incluem SteamID | Manter em `scratch/`; commitar só allowlist |

### Fontes

- Cache local do cliente Steam (leitura): `~/Library/Application Support/Steam/appcache/appinfo.vdf`, `steamapps/libraryfolders.vdf`, `appcache/librarycache/`.
- `docs/evidence/d1-game-candidates.md` (decisão D1, API da loja de 2026-10-10); `docs/evidence/steam-api-probe.md` (T05).
- Plano: `docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md`, cards T11 e T12.
- PCGamingWiki: tentativa via API sem resposta utilizável em 2026-10-10 (não usada como fonte).

## T11 — primeira abertura real (2026-10-10, Agente: claude, opus)

- PEAK (3527290) instalado pelo Steam nativo do Mac, ferramenta `notproton-sikarugir-11.0-r0` forçada em Compatibilidade, opção `-force-d3d11`.
- 1ª tentativa: Unity "Failed to initialize graphics" — `WINEDLLPATH` genérico perdia para o `d3d11` builtin (wined3d). Prova A/B rodando `PEAK.exe` direto: `WINEDLLPATH` → `d3d11: failed to create device`; `WINEDLLPATH_D3DMETAL` + `CX_D3DMETALPATH` → `Direct3D 11.0 [level 11.1]` via D3DMetal.
- Com a correção no `compat_run.sh`: **o jogo abriu e o menu respondeu ao mouse** (relato do Elvis). O risco `EnableMouseInPointer` não se manifestou.
- Pendente (T12): sessão ≥ 15 min, save, fechar jogo e Steam, reabrir e conferir persistência; testar DX12 sem `-force-d3d11`.
