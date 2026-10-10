# Risco DX12 do PEAK na engine Sikarugir 11.0 r0

Agente: claude (Claude Code, modelo efetivo `sonnet` = Sonnet 5.5) · Data: 2026-10-09 · Branch `claude/dx12-renderer-risk` (base `origin/codex/game-agnostic-scope`).
Somente leitura: wrapper original só lido (`strings`, `plutil`, `shasum`, `ls`); nenhum Wine, Steam, instalação ou download de jogo. Pesquisa web só consultou páginas públicas.

## 1. Conclusão

**Risco médio-alto, não inviável.** A engine entrega o que o PEAK precisa por três caminhos, em ordem de preferência:

1. **DX12 via D3DMetal 3.0 (GPTK)**: presente e completo no wrapper (`d3d12.dll`, `dxgi.dll`, `d3d11.dll` + `libd3dshared.dylib`). Caminho nominal para o requisito "DirectX 12". Nenhuma fonte pública confirma PEAK em DX12 por D3DMetal sem defeitos; relatos de CrossOver/Sikarugir indicam jogo iniciável, mas com falhas de entrada (seção 3).
2. **DX11 via `-force-d3d11`**: funciona no PEAK (log real `Forcing GfxDevice: Direct3D 11` em CrossOver 25.1.1/26.0). Roda sobre D3DMetal (d3d11) ou DXMT (d3d11, o renderer padrão do Sikarugir). Mitiga o risco de DX12 sem trocar de jogo.
3. **Vulkan** (o próprio PEAK oferece "DX12" ou "Vulkan" na janela de launch do Steam): winevulkan + MoltenVK 1.4 presente. Relatos de crash Unity nesse modo; só como último recurso.

**Não existe vkd3d-proton no wrapper**, e o DXVK embarcado é 1.10.3 (sem D3D12). DXMT não cobre D3D12 (`_d3d12.dll` renomeado/desativado). Logo, **D3DMetal é o único tradutor D3D12 disponível**. A prova só vem em runtime (teste da seção 5, depois T11); nada aqui prova que o jogo roda.

## 2. Inventário do wrapper

Raiz: `/Users/elvisoliveira/Applications/Sikarugir/wrapper-steam.app/Contents`. Motor: `SharedSupport/wine/version` = `wine sikarugir 11.0 (revision 0)`. Host: Apple M5 Pro (arm64), macOS 27.2; wrapper declara `LSMinimumSystemVersion 14.6`.

### 2.1 Configuração declarada (`Info.plist`, SHA-256 `c1a0d0a4…7164d`)

`D3DMETAL=0`, `DXVK=0`, **`D9VK=1`**, **`CNC_DDRAW=1`**, `MOLTENVKCX=0`, `METAL_HUD=0`, `WINEESYNC=1`, `WINEMSYNC=1`, `WINEDEBUG=-plugplay,+loaddll`, programa `Steam.exe`. Correção ao `system-baseline.md`: D9VK e CNC_DDRAW também estão ligados. Com D3DMETAL=0 e DXVK=0 a UI do Configure.app indica "Default Render: DirectX to Metal translation layer - (DXMT)", ou seja, **o wrapper original usaria DXMT (só D3D10/11)**, o que não serve para DX12.

### 2.2 Renderers em `Frameworks/renderer/`

| Diretório | Versão (arquivo `version`/plist) | Conteúdo relevante | API |
|---|---|---|---|
| `d3dmetal/` (`apple_gptk` é symlink) | D3DMetal framework `CFBundleVersion 3.0`, ProjectName `D3DRendererMetal`, SDK macosx15.4.internal | `wine/x86_64-windows/{d3d12,d3d11,dxgi,atidxx64,nvapi64,nvngx}.dll`, `wine/x86_64-unix/*.so`, `external/libd3dshared.dylib`, `external/D3DMetal.framework` (+ libdxcompiler/dxilconv/metalirconverter, default.metallib) | **D3D11 + D3D12** |
| `dxmt/` | `v0.80-244-g7c8dee1` | `x86_64-windows/{d3d11,d3d10core,dxgi,winemetal,nvapi64,nvngx}.dll`, **`_d3d12.dll`** (prefixo `_`), `x86_64-unix/winemetal.so`, i386 equivalentes | D3D10/11 (D3D12 desativado) |
| `dxvk/` | `DXVK-Sikarugir-async-v1.10.3` | d3d10core/d3d11/dxgi, x64 e i386 | D3D10/11 (sem D3D12) |
| `d9vk/` | `DXVK-Sikarugir-v3.0.2` | `d3d9.dll`, x64 e i386 | D3D9 |
| `cnc_ddraw/` | `cnc-ddraw-v7.1.0.0` | `ddraw.dll` i386 | DirectDraw |

Não há `vkd3d`, `vkd3d-proton` nem `libvkd3d*` em qualquer ponto do wrapper (`find -iname '*vkd3d*'` vazio). `lib/wine/x86_64-windows/d3d12.dll` do motor (88 KB, builtin) exporta stubs `vkd3d_*` e importa `vulkan-1.dll`, mas não há biblioteca vkd3d para carregar: **não é um caminho D3D12 utilizável**.

### 2.3 Vulkan / MoltenVK

`Frameworks/libMoltenVK.dylib` (5,2 MB) e `libMVK_CW.dylib` (CodeWeavers, 5,9 MB), `libvulkan.1.4.350.dylib`, `libvulkan_kosmickrisp.dylib` (14,8 MB, Mesa KosmicKrisp). ICDs em `Resources/vulkan/icd.d/`: `MoltenVK_icd.json` (api 1.4.0, portability), `MVK_CW_icd.json` (1.1.0), `kosmickrisp_mesa_icd.json` (1.4.363). Motor traz `winevulkan.dll/.so` e `winemetal.dll`.

### 2.4 Como o launcher liga cada renderer (`strings -a MacOS/Sikarugir`)

Resultado só de `strings`; o launcher não foi executado e a ordem exata/valores não foram observados. Strings presentes: pastas `/renderer`, `/cnc_ddraw`, `/d3dmetal`, `/dxmt`, `/dxvk`, `/dxvk3`, `/d9vk`, `/vulkan/icd.d`; arquivos-flag `/d3dmetal_force`, `/no_d3dmetal`, `/dxmt_extescape` (esse existe, 0 bytes, em `SharedSupport/wine/`); variáveis `WINEDLLPATH`, `WINEDLLPATH_PREPEND`, `WINEDLLPATH_{D3DMETAL,DXMT,DXVK,D9VK,CNCD}`, `CX_APPLEGPTK_LIBD3DSHARED_PATH`, `CX_APPLEGPT_LIBD3DSHARED_PATH`, `CX_D3DMETALPATH`, `VK_DRIVER_FILES`, `MVK_CONFIG_{FAST_MATH_ENABLED,RESUME_LOST_DEVICE,UE4_HACK_ENABLED,LOG_LEVEL}`, `MTL_HUD_ENABLED`, `DXVK_HUD` (`api,devinfo,fps,version`), `DXMT_ALLOW_CROSS_PROCESS_SWAPCHAIN`, `ROSETTA_ADVERTISE_AVX`, `WINEESYNC`, `WINEMSYNC`, `WINEDLLOVERRIDES`, `SikarugirAppWine11`. Também `/external/libd3dshared.dylib"`. Configure.app (strings) cria/remove `d3dmetal_force`/`no_d3dmetal`, grava `[Software\Wine\Direct3D]` e expõe checkboxes D3DMetal, DXVK, MoltenVK CX, Metal HUD.

Leitura (inferência, a validar com `WINEDEBUG=+loaddll`): para D3DMETAL=1 o launcher anexa `<renderer>/d3dmetal/wine` ao `WINEDLLPATH` (DLLs builtin D3DMetal passam a preceder as do motor) e aponta `CX_APPLEGPTK_LIBD3DSHARED_PATH` para `<renderer>/d3dmetal/external/libd3dshared.dylib`; para MoltenVK define `VK_DRIVER_FILES` com um dos JSONs acima. O motor Sikarugir tem hooks próprios para D3DMetal (`CX_APPLEGPTK_LIBD3DSHARED_PATH`, regiões de código não nativo; `engine-baseline.md`).

### 2.5 Hashes (SHA-256)

| Arquivo | SHA-256 |
|---|---|
| `MacOS/Sikarugir` (launcher) | `c7a33829ad74ee091dcb859e016eb54a1597d85d7bca27b376144f4c2e188606` |
| `d3dmetal/wine/x86_64-windows/d3d12.dll` | `27dcf69bedb20ed557a83953e356ab2477b688c2a2c631f880b7583f30ff0705` |
| `d3dmetal/wine/x86_64-windows/dxgi.dll` | `249711d3d786a9b0bb7c3558f36e472ab07ee21b8dbf118e34c975046832f9a2` |
| `d3dmetal/wine/x86_64-windows/d3d11.dll` | `05fa6f700fb5ee5561dc3a46d98f0aed845d4fa8ab274bff1dc604b0b3f6edd1` |
| `d3dmetal/wine/x86_64-unix/{d3d12,d3d11,dxgi,atidxx64}.so` e `external/libd3dshared.dylib` (idênticos entre si) | `5131e631eee8b542eadf48f4df9fd662d9aeeb59139137e0e6e14047dc434995` |
| `d3dmetal/external/D3DMetal.framework/Versions/A/D3DMetal` | `05a7beaed4494a4f5f53d3f626a82fffc3b70146436a908b7048a0632a49e1a8` |
| `dxmt/wine/x86_64-windows/_d3d12.dll` | `4bb4d0340feac706a005d44dae06bdb801bca13436892b4b02d488c2d6b750a9` |
| `dxmt/wine/x86_64-windows/d3d11.dll` | `90bf11b791af80da3936fd02870331d397a9efd70f2c0b2172eb83e7c5a81185` |
| `dxmt/wine/x86_64-windows/dxgi.dll` | `34f7279c15a29a32b3d988e808826f3a9a18635a483b84d80b8fbbeea4a9e5a5` |
| `dxmt/wine/x86_64-unix/winemetal.so` | `62dbce6c66f23308fcdf58fba7371271b0412a71074ad7add87a801516ce473a` |
| `dxvk/wine/x86_64-windows/d3d11.dll` | `2689020b306da1355000dd9d693c783aec75bdc1fbcac62279e3e34f93f49e79` |
| `dxvk/wine/x86_64-windows/dxgi.dll` | `aa603f3683a38f6bf37d90534ae729b14dfb801794e069e58c48adbf56c8996d` |
| `d9vk/wine/x86_64-windows/d3d9.dll` | `1720019888ef6eb11d39d289c8efdb432f757dfd9c586004713064fae62c57b4` |
| `Frameworks/libMoltenVK.dylib` | `d2168175ed98fffd8ccaa71c85ef2a9aaffd6dea3762c88f0b79f1320b9fe459` |
| `Frameworks/libMVK_CW.dylib` | `3d0708dd5581070c30449b7c466d84ee833af0b96a81c37f637d38fbf313a286` |
| `Frameworks/libvulkan_kosmickrisp.dylib` | `612b0c97cd0edf060b1f944fc30e7f26a468dd470d56e2780e0016039ea9474b` |
| `Frameworks/libvulkan.1.4.350.dylib` | `fb1730bdba23d72288ad4053ebcec5d97ada3c29fae6a181bbc872d36d1b8a0d` |
| `Resources/vulkan/icd.d/MoltenVK_icd.json` | `67ff821250d8e8b3c4adf3ecaf68a1f639dcc6f6a75916b30f339812074136bd` |
| Motor `lib/wine/x86_64-windows/d3d12.dll` (stub vkd3d) | `51a93a91aa2f18a56202fd8ddcaae7b43bd2c300a263bfe71c53de47eb7b3d25` |
| Motor `…/dxgi.dll` | `8651b985252e27f26672939bb9de6b44aafbc70e041855a77296d402e88094d1` |
| Motor `…/winemetal.dll` | `cd93e6ae0808c7660e7a0ff3fd9c464ce7d0b3c9280d6a994352435baeb36b58` |
| Motor `…/winevulkan.dll` | `599c00806ddeb078ece559cb4d3f8959abf2c86cdcd4f8f28611abc566f69aa1` |

Nota de escopo: a engine isolada do T05 clona `Frameworks` por inteiro (965 entradas), portanto `renderer/` já existe na cópia; confirmar os hashes acima na cópia antes de usar.

## 3. Pesquisa (fontes)

**PEAK e renderer.** A loja exige "DirectX: Version 12" (mínimo GTX 1060 / RX 6600 XT; API `appdetails` 3527290, 2026-10-09). Na janela de launch do Steam o jogo oferece **DX12 ou Vulkan**; nenhum desenvolvedor documenta o padrão ([Destructoid](https://www.destructoid.com/should-you-use-vulkan-or-dx12-with-peak/); [Steam: dx12?](https://steamcommunity.com/app/3527290/discussions/0/592900345012695197/): "DX12 and Vulkan are the only options it offers on launch"; relatos mistos: DX12 sem ambientes/sem iniciar, Vulkan com crash Unity).

**Fallback DX11 existe e funciona em Wine.** O repositório [kiku-jw/peak-crossover-mouse-fix](https://github.com/kiku-jw/peak-crossover-mouse-fix) manda lançar o PEAK com DirectX 11 ou a opção `-force-d3d11` e mostra o log `Forcing GfxDevice: Direct3D 11` (CrossOver 25.1.1 e 26.0, PEAK em Unity 6). Um guia de crash ([KeenGamer](https://www.keengamer.com/articles/features/troubleshooting/7-ways-to-fix-peak-not-launching-on-a-windows-pc/)) também cita `-force-d3d11`; outro relato diz que `-d3d11` não surtiu efeito (fonte pior, não confirmada), então preferir `-force-d3d11` e verificar em `Player.log`.

**Mac.** [Guia Deltia's (CrossOver)](https://deltiasgaming.com/how-to-play-peak-on-macos/) recomenda D3DMetal + MSync, "DX12 with D3DMetal or DXMT first; fallback to DX11" e reporta performance "near native" (fonte de blog, sem logs). [Steam: Trouble running Peak through Wine engine?](https://steamcommunity.com/app/3527290/discussions/0/805721739935956279/) (abr/2026, macOS 26.3.1): em **Sikarugir** o jogo abre mas o menu não responde a cliques após atualização Unity; moderador atribui ao tratamento de entrada e aponta engine `WS12WineSikarugir10.0_4` (reportada como correção); para CrossOver, o CrossOver Preview. O erro `EnableMouseInPointer ... Call not implemented` é o mesmo do repo acima. **Risco novo para T11/T12: entrada de mouse em Wine 11 r0** (a engine fixada é 11.0 r0, não a 12/10.0_4 do relato). Steam, set/2025: "mr.nobodyy13" CrossOver "really laggy"; outro usuário diz que multiplayer não funciona via wrapper Wine ([discussão](https://steamcommunity.com/app/3527290/discussions/0/592901183903916208/?ctp=3)); irrelevante para single-player/save. [Whisky docs](https://docs.getwhisky.app/game-support/peak.html) (snippet de busca; a página não carregou para leitura): "You are only able to launch using Vulkan, otherwise it'll just give a Unity crash error", projeto sem manutenção. [CodeWeavers compat DB](https://www.codeweavers.com/compatibility): sem entrada localizada para PEAK. ProtonDB/AppleGamingWiki não consultados (sem retorno útil na busca).

**D3DMetal/GPTK.** GPTK 3.0 saiu em 05/12/2025 e o CrossOver 26.0 incorpora D3DMetal 3.0 ([mybyways](https://mybyways.com/blog/updating-crossover-to-gameporting-toolkit-3-0)); a versão no wrapper é 3.0 (item 2.2). Whisky beta com GPTK importado: D3D12 feature level 12_2, resource binding tier 3 ([release](https://newreleases.io/project/github/frankea/Whisky/release/v4.0.0-beta.1)). Não localizei relato específico de Unity 6 DX12 em D3DMetal além dos guias acima.

**vkd3d-proton + MoltenVK.** Não é alternativa prática: exige descriptor indexing/argument buffers tier 2 (`MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS`, [MoltenVK releases](https://github.com/KhronosGroup/MoltenVK/releases/tag/v1.1.3)); além disso o wrapper não traz vkd3d-proton e T07/T08 não o cobrem. Descartado.

**Reserva: Halls of Torment: Prelude (2316660).** Motor Godot, com build Linux nativo ([GamingOnLinux](https://gamingonlinux.com/2024/09/fight-off-the-immense-hordes-in-halls-of-torment-1-0-out-now)). A loja não lista DirectX nos requisitos (mínimo "Intel Iris Xe / AMD RX 480"). **Não consegui confirmar a API gráfica** (PCGamingWiki retornou 403; buscas sem resultado). Godot usa OpenGL (Compatibility) ou Vulkan/D3D12 (Forward+/Mobile), não DirectX como requisito; num Wine no Mac isso cai em `opengl32` (winemac) ou winevulkan/MoltenVK, ambos presentes. **Pendente:** identificar a versão Godot e o renderer no executável ao instalar (`strings` por "Godot Engine v" e `rendering/renderer`), ou `--rendering-driver opengl3` se aceito.

## 4. Recomendação de renderer para T08/T11

Sempre na cópia isolada (`E` = engine copiada, `R` = `E/Frameworks/renderer`), prefixo `STEAM_COMPAT_DATA_PATH` exclusivo, nunca os caminhos do wrapper. **Um único tradutor por execução**: não misturar DLLs DXMT/DXVK com D3DMetal (mesmos nomes `dxgi.dll`/`d3d11.dll`). O launcher original não deve ser usado; o `compat_run.sh` do T08 replica o ambiente.

**Perfil A (padrão, DX12 e DX11): D3DMetal.** Ambiente mínimo, além do já provado no T05 (`SikarugirAppWine11=1`, `DYLD_FALLBACK_LIBRARY_PATH=E/Frameworks:/usr/lib` depois de `arch -x86_64`, `WINEPREFIX`, `WINEARCH=win64`):

```sh
WINEDLLPATH="$R/d3dmetal/wine"
CX_APPLEGPTK_LIBD3DSHARED_PATH="$R/d3dmetal/external/libd3dshared.dylib"
WINEESYNC=1 WINEMSYNC=1
# diagnóstico (primeiras execuções): WINEDEBUG=-all,+loaddll  MTL_HUD_ENABLED=1
# opcional, só se +loaddll mostrar d3d12/dxgi do motor em vez do D3DMetal:
# WINEDLLOVERRIDES="d3d12,d3d11,dxgi=b"   (juntar ao já usado: steamclient64=n;lsteamclient=b)
```

Nota: T05 provou que `WINEDLLPATH` não era necessário para o probe e mandou limpá-lo; para renderer ele passa a ser necessário e deve ser definido de forma explícita no perfil de jogo (o runner continua removendo valores herdados). Não definir `CX_D3DMETALPATH`/`CX_APPLEGPT_LIBD3DSHARED_PATH` sem evidência de necessidade (semântica não observada). Critério de PASS do perfil: `+loaddll` mostra `d3d12.dll`/`dxgi.dll` vindos de `$R/d3dmetal/wine/x86_64-windows` (hashes 2.5) e `libd3dshared.dylib` carregada; nenhum `winemetal`/DXVK.

**Opções de lançamento do jogo (Steam, por tentativa, uma de cada vez):** (1) escolher "DX12" na janela do PEAK; (2) `-force-d3d11` (confirmar `Forcing GfxDevice: Direct3D 11` em `Player.log`); (3) opção "Vulkan" (usa winevulkan; exigiria `VK_DRIVER_FILES="$E/Resources/vulkan/icd.d/MoltenVK_icd.json"` equivalente na cópia, ou MVK_CW; só se 1 e 2 falharem).

**Perfil B (DX11 alternativo): DXMT**, só para `-force-d3d11`: `WINEDLLPATH="$R/dxmt/wine"`; é o padrão que o Configure.app usa com D3DMETAL=0/DXVK=0. Útil como controle se D3DMetal D3D11 falhar. Observação: `dxmt_extescape` (flag de arquivo) existe; sem evidência do efeito.

**Mouse/entrada (risco separado):** se o menu não responder (`EnableMouseInPointer ... Call not implemented` em `Player.log`), o motor 11.0 r0 pode precisar do mesmo reparo que o relato aplicou (engine 10.0_4 ou patch). Não trocar de engine sem novo pedido; registrar como bloqueio do T11.

## 5. Teste barato antes do T11 (proposta, não executada)

Objetivo: separar "D3DMetal/Wine 11 r0 entrega D3D12" de "PEAK/Unity roda", sem instalar jogo e sem Steam. Programa C++ `d3d12probe.cpp` (~120 linhas):

1. `CreateDXGIFactory1` e `EnumAdapters1`: imprimir descrição/VRAM do adaptador (esperado: GPU Apple via D3DMetal).
2. `D3D12CreateDevice(adapter, D3D_FEATURE_LEVEL_12_0, ...)`, depois tentar 12_1 e 12_2; `CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS, OPTIONS1, SHADER_MODEL)` e imprimir resource binding tier e shader model máximo (Unity 6 DX12 usa SM 6.x via DXC; imprimir se `D3D_SHADER_MODEL_6_0+` for aceito).
3. Fila direta, `ID3D12CommandAllocator`/`CommandList`, janela Win32 + `IDXGISwapChain3` (flip model), limpar o RTV com cor fixa por 120 quadros com fence, `Present`; imprimir `FRAMES=120 OK`.
4. Opcional: PSO compute mínimo (shader pré-compilado em bytes DXIL embutidos, ou pular) para exercitar `libdxcompiler`/`metalirconverter`.

Compilar com llvm-mingw x86_64, que tem `d3d12.h` e `dxgi.h`:

```sh
T=/Users/elvisoliveira/_dev/notproton/.claude/worktrees/agent-a0056ab92dea8e784/scratch/toolchain/llvm-mingw-20260826-ucrt-macos-universal/bin
"$T/x86_64-w64-mingw32-g++" -O2 -municode d3d12probe.cpp -ld3d12 -ldxgi -luuid -o scratch/dx12/d3d12probe.exe
```

Executar (por outro agente/Elvis, em cópia da engine e prefixo descartável, com o Perfil A e `WINEDEBUG=-all,+loaddll`): critérios de PASS = criação de device 12_0 sem erro, `FRAMES=120 OK` e `+loaddll` mostrando as DLLs D3DMetal. Controles: mesma execução sem `WINEDLLPATH` (esperado falhar/usar stub vkd3d, prova que o resultado vem do D3DMetal) e Perfil B (esperado falhar em D3D12). Resultados: FAIL no passo 2 ⇒ DX12 inviável nesta engine; PASS ⇒ risco de PEAK reduz a Unity-específico. Limite: não valida o pipeline Unity (bindless, DXC SM6.6, async compute), então PASS aqui **não** aprova DX12 do PEAK; só T11 faz isso. Fica sem executar nesta rodada.

Opcional após PASS: `d3d11probe` equivalente cobre o fallback `-force-d3d11` (perfis A e B).

## 6. Critério de troca para a reserva

Trocar de PEAK para Halls of Torment: Prelude (2316660), decisão final de Elvis, se **qualquer** condição ocorrer no T11, após a ordem DX12 → `-force-d3d11` → Vulkan e com D3DMetal verificado por `+loaddll`:

- o teste da seção 5 falha na criação de device D3D12 **e** o PEAK falha também em `-force-d3d11` (ou em D3D11 por D3DMetal e DXMT); ou
- o jogo chega à tela, mas menu/entrada não responde (`EnableMouseInPointer`) e não há correção na engine fixada dentro do orçamento do card; ou
- o PEAK não sustenta a sessão >= 15 min exigida em T12 (crash/travamento repetido, Unity crash) com qualquer das três opções; ou
- não renderiza frames válidos (tela preta/ambiente ausente) nas três opções.

Não trocar por: multiplayer indisponível, desempenho baixo com jogo estável, ou falha só em DX12 com `-force-d3d11` funcionando (nesse caso, seguir com DX11 e registrar o requisito DX12 da loja como descartado em runtime). Antes de eventual troca, verificar a API do Halls of Torment (seção 3, pendente) e a posse/resgate do Prelude (gratuito).

## 7. Pendências

- Executar o teste da seção 5 (exige Wine; fora desta rodada).
- Confirmar `Forcing GfxDevice` e o set real de variáveis do launcher com `+loaddll` (inferência da seção 2.4).
- Whisky docs e CodeWeavers DB não lidos diretamente; ProtonDB/AppleGamingWiki sem resultado útil.
- Renderer do Halls of Torment não confirmado.
