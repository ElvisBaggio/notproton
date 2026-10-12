# Mouse raw no Sikarugir (#44) e installscript (#41)

Autor: claude (opus `claude-opus-5-5`) · 2026-10-11/12 · branches `claude/legacycompat-41` → `claude/rawmouse-44`.

## #44 — câmera aos trancos no Wildlands (460930)

**Sintoma.** Câmera anda aos trancos e pula mesmo com FPS alto. GHPC disfarça (câmera lenta).

**Hipóteses descartadas com teste.**

| Hipótese | Teste | Resultado |
|---|---|---|
| Jogo recentraliza o cursor a cada quadro | trace `+cursor` | só 5 `SetCursorPos` na sessão |
| Clipping falha com dois monitores | `UseConfinementCursorClipping` no prefixo; jogar só na tela do Mac | trancos iguais (chave revertida) |
| I/O do log (Ubisoft Connect grava ~33 MB/s de `wined3d_check_gl_call`) | `WINEDEBUG=-all` | trancos iguais |

Latência macOS→Wine medida no trace `+cursor`: p50 7 ms, p99 15 ms.

**Causa.** Trace `WINEDEBUG=-all,+rawinput,+dinput`: o jogo lê o mouse por DirectInput (`GetDeviceState` ~42 mil chamadas), alimentado pelo raw input do Wine. Dos 5278 deltas entregues, 43% eram zero e 59% tinham |dx| ≤ 2 (giro lento: `-1, 0, 0, -1, 0, -1…`). O `winemac.drv` deriva esse "raw" da posição do cursor do macOS: acelerada e truncada em pontos inteiros (`floor()` no caminho `MOUSE_MOVED_ABSOLUTE`). O wineserver do Sikarugir ainda entrega o raw como posição absoluta (`usFlags=1`, patch dele; o upstream manda relativo). Desligar a aceleração do macOS melhorou só um pouco.

**Por que não patch no driver.** O `winemac.so` do Sikarugir (`b1b103d8…`) tem a integração Metal/D3DMetal (`macdrv_create_metal_device`, `CAContextSwapChain`, `d3dmetal_client_surface`, `my_*`) e não tem fonte publicada (`engine-lock.json`: `blocked-source-provenance`). Um `winemac.so` do upstream quebraria o D3DMetal.

**Correção.** `rawmouse/rawmouse.m` → `notproton-rawmouse.dylib` (x86_64), carregada pelo `run` via `DYLD_INSERT_LIBRARIES` só no Wine do jogo:
- Só arma se o `winemac.so` carregado tiver o hash fixado; usa as funções internas desse build (`macdrv_create_event` `+0x11210`, `macdrv_release_event` `+0x106c0`, tipo relativo `0xc`, campos `+0x18/+0x1c/+0x20/+0x28`), lidas por disassembly e pelo runtime ObjC.
- Com o app ativo e o cursor do Windows escondido (`clientWantsCursorHidden`), troca `-[WineApplicationController handleMouseMove:]` (swizzle) e posta os deltas do `GCMouse` (contagens do sensor, sem aceleração) como eventos relativos do winemac; prende o cursor do macOS (`CGAssociateMouseAndMouseCursorPosition`). Cmd+Tab solta.
- `NOTPROTON_RAW_MOUSE=0` desliga; `NOTPROTON_RAW_MOUSE_SCALE` multiplica os deltas; `NOTPROTON_RAW_MOUSE_DEBUG=1` loga no stderr.
- Build reproduzível (`make out/notproton-rawmouse.dylib`, `-install_name` fixo): `0cb160ea44f5dc3c42e114e526d2385312afe1e26384850ae4bbeeff508137d9`, igual em outro diretório; fixado em `RunnerPatcher.sikarugirBridge` e no `payload.manifest`.

**Prova.**
- Viabilidade: dylib injetada no Wine (Rosetta) enxerga os mouses no `GCMouse` e recebe deltas inteiros do sensor.
- `rawmouse/tests/rawprobe.c` (janela com cursor escondido, loga `WM_INPUT`), lado a lado no mesmo prefixo de scratch:
  - sem a dylib: 2242 eventos `usFlags=1` (posição absoluta);
  - com a dylib: 974 eventos relativos, giro lento `-1,-1,-1,-3,-2,-3,-2,-3,-3,-4,-4,-5,-6…`, nenhum zero.
- Wildlands pelo Steam (app `202a6b6`, 2026-10-12): `rawmouse: …/notproton-rawmouse.dylib` no `notproton-run.log`; Elvis: "ficou bom".

**Efeito colateral corrigido.** `CaptureDisplaysForFullscreen` (ligado para todos em `a4087cb`) apagava a tela do Mac com o jogo no monitor externo. Com o cursor preso pela dylib, voltou a ser opt-in (`NOTPROTON_CAPTURE_DISPLAYS=1`, commit `c9ebcf4`).

**Limites.** Menus que desenham o próprio cursor andam em contagens do sensor (velocidade pode diferir do macOS). Ao sair do modo mira, o cursor do macOS reaparece onde estava. Outro build do Sikarugir exige refazer os offsets (a dylib fica inerte até lá).

## #41 — installscript.vdf

O Steam roda o `installscript.vdf` pelo compat tool com `legacycompat/iscriptevaluator.exe` da pasta do cliente, que no Mac vem vazia. O payload já baixa esse binário do pacote da Valve (x86_64, só DLLs do sistema). `install_legacycompat` (`compat_run.sh`) copia `bridge/legacycompat/*` para `STEAM_COMPAT_CLIENT_INSTALL_PATH/legacycompat` a cada launch; coberto por `sikarugircheck`.

Prova (Wildlands, 2026-10-11):
- antes: `Failed to create process … iscriptevaluator.exe … : 2` → `helper exited status=1`;
- depois: `helper exited status=0`; no primeiro run o avaliador rodou o DirectX (regsvr32 XAudio2_0–7, xactengine);
- com a chave `Uninstall\Uplay` renomeada (`Uplay-np41-bak`, backup em `scratch/wildlands/reg-before-41-rename/`), o avaliador recriou `Uninstall\Uplay` ("Uplay"=1) em ~5 s; sem arquivos novos do launcher (instalador provavelmente viu o Uplay presente).

Pendente para o aceite: prefixo novo instalado do zero; PEAK/GHPC sem script seguem iguais.
