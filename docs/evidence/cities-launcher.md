# Cities: Skylines II — Paradox Launcher no motor Sikarugir (teste opcional pós-E4)

Data: 2026-10-10 · Agente: opencode · Modelo efetivo: deepseek-flash · Branch: `codex/game-agnostic-scope`.
Escopo: Cities II é teste **opcional posterior** (não é gate do E4). Nenhuma alteração no repositório ou na ferramenta implantada; testes manuais no prefixo isolado `~/Library/Application Support/Steam/steamapps/compatdata/949230/pfx`.

## Objetivo

Abrir Cities: Skylines II (AppID 949230) pelo Steam nativo do Mac com a ferramenta `notproton-sikarugir-11.0-r0`. Sintoma relatado: Steam mostra "jogando", mas nenhuma janela útil aparece.

## Fluxo real do launch (confirmado nos logs)

Steam → tool `run` (`compat_run.sh`) → `wine steam.exe` (shim) → `Cities Skylines II/Launcher/dowser.exe` (bootstrapper 2025.1) → instala VC++ redist + Paradox Launcher v2 (subiu 2024.15 e se auto-atualizou para **2026.12** no primeiro boot) → `Paradox Launcher.exe` (**Electron/Chromium**, `resources/app.asar`) → botão Jogar → `Cities2.exe`.

Logs:
- `compatdata/949230/notproton-run.log`
- `<prefixo>/drive_c/users/steamuser/AppData/Local/Paradox Interactive/launcher-v2/logs/launcher-2026-10-10.log` (principal)
- …`/launcher-bootstrapper.log` (mostra o comando executado do launcher)
- …`/launcher-dowser.log`, `…/cpatch.log`

## Achados

1. **D3DMetal (estado atual da ferramenta) → GPU process do Chromium crasha em loop**: `Child process is gone … {"type":"GPU","reason":"crashed","exitCode":-1073741819}` (0xC0000005, access violation). Janela ficou invisível → transparente → branca em tentativas sucessivas. O `Cities2.exe` nunca é spawnado; não existe `Player.log`. O launcher registra `start_game` (auto-start via `--pdxlLauncherInvokedTimestamp`) mas nada é lançado.
2. **A ferramenta força D3DMetal**: `dylib/feats/compat_run.sh:31-34` remove `CX_*`/`DYLD_*`/`WINEDLLPATH*` herdados; `:43-46` exporta `WINEDLLPATH_D3DMETAL`, `CX_D3DMETALPATH` e `CX_APPLEGPTK_LIBD3DSHARED_PATH`. Os `DXMT_*` sobrevivem, mas as DLLs do DXMT não entram no search path — logo `DXMT_METALFX_SPATIAL_SWAPCHAIN`/`DXMT_CONFIG` (sugestão do Elvis) são **inertes hoje**. Ativar DXMT exigiria o tool setar `WINEDLLPATH_DXMT` (território T07/T08). O ntdll.so do runner contém `WINEDLLPATH_DXMT` **e** `WINEDLLPATH_D3DMETAL`; o DXMT local é `v0.80-244-g7c8dee1` e suporta `DXMT_CONFIG`/`METALFX_SPATIAL_SWAPCHAIN`/`metalSpatialUpscaleFactor` (strings confirmados nos DLLs).
3. **Com DXMT o GPU não crasha** (`winemetal.so` carregado), mas **a janela continua branca** do mesmo jeito.
4. **A página renderiza por dentro**: com `--remote-debugging-port=9222`, `Page.captureScreenshot` via DevTools devolve o onboarding completo ("GET STARTED"), `document.visibilityState=visible`, `hasFocus=true`, body com fundo transparente. Ou seja: **é problema de apresentação da janela Chromium no Wine**, não da página nem do GPU. Capturas em `scratch/cities-launcher/pagina-interna-devtools.png` (página OK) e `…/janela-swiftshader-branca.png` (janela branca).
5. **Flags/lançamentos testados no launch manual** (captura da janela via `screencapture -l` permaneceu branca; arquivos byte-a-byte idênticos em vários casos):
   - `--disable-gpu --disable-direct-composition`
   - `--disable-features=CalculateNativeWinOcclusion`
   - `wine explorer /desktop=lp,1280x800` (virtual desktop)
   - resize forçado via CDP (`Browser.setWindowBounds`) — só muda o tamanho; segue branco
   - `--use-angle=swiftshader --enable-unsafe-swiftshader` — também branco no launch direto
6. ~~**Conflito de renderer**: o jogo exige DX12.~~ **Corrigido em 2026-10-11 (claude):** o `Player.log` mostra o jogo em `Direct3D 11.0 [level 11.1]`; não há conflito de renderer entre launcher e jogo.
7. **Referências externas (CrossOver, mesma classe de problema)**:
   - `dstavgr/paradox-launcher-v2-2026-11-1-macos-crossover-fix`: (i) launch options `%command% --use-angle=swiftshader --enable-unsafe-swiftshader` para o Electron/Chromium renderizar por SwiftShader; (ii) adicionar a pasta do jogo ao PATH do bottle (`HKCU\Environment`) — CrossOver 26.2+ quebrou o spawn relativo `../Cities2.exe` (`spawn Cities2.exe ENOENT`, sintoma "exit code null"). **Nosso launcher também não spawna o jogo** — verificar logs por ENOENT; a parte do PATH é genérica e aplicável.
   - `alien-agent/cs2-macos-patcher` (README): confirma CS2 = DX12 → D3DMetal; "DXMT is DX11-only — do not use" para o jogo; documenta o mesmo bug de spawn do CrossOver 26.2.
   - `gamesir-labs/gamehub-for-mac#33`: contorno = bypassar o launcher importando o exe; o jogo roda normal.

## Comandos reutilizáveis

Kill de tudo no prefixo:

```sh
R="$HOME/Library/Application Support/notproton/runners/sikarugir-11.0-r0/wine"
W="$HOME/Library/Application Support/Steam/steamapps/compatdata/949230/pfx"
/usr/bin/arch -x86_64 /usr/bin/env WINEPREFIX="$W" DYLD_FALLBACK_LIBRARY_PATH="$R/Frameworks:/usr/lib" "$R/bin/wineserver" -k
```

Launch manual só do launcher (teste, sem Steam), com DXMT + flags:

```sh
R="$HOME/Library/Application Support/notproton/runners/sikarugir-11.0-r0/wine"
W="$HOME/Library/Application Support/Steam/steamapps/compatdata/949230/pfx"
/usr/bin/arch -x86_64 /usr/bin/env HOME="$HOME" WINEPREFIX="$W" WINEARCH=win64 \
  WINELOADER="$R/bin/wine" WINESERVER="$R/bin/wineserver" SikarugirAppWine11=1 \
  DYLD_FALLBACK_LIBRARY_PATH="$R/Frameworks:/usr/lib" \
  WINEDLLPATH_DXMT="$R/Frameworks/renderer/dxmt/wine" \
  "$R/bin/wine" "C:\\Program Files\\Paradox Interactive\\launcher\\launcher-v2.2026.12\\Paradox Launcher.exe" \
  --remote-debugging-port=9222
```

Janelas Wine no macOS (window id): `scratch/cities-launcher/winlist.swift` → `swift winlist.swift`.
Capturar uma janela: `screencapture -x -l <windowid> out.png`.
Screenshot de dentro da página / estado do DOM: `scratch/cities-launcher/devtools-shot.js` → `node devtools-shot.js` (requer o flag acima).

## Estado / limites

- Testes **manuais**, nada commitado; nenhum processo deixado rodando (wineserver -k).
- O prefixo 949230 recebeu apenas o que o próprio dowser instalou (VC++ redist + launcher v2 2026.12 + `chromium-data`). Saves/biblioteca do jogo não foram tocados; nenhum `Player.log` foi criado.
- Steam Windows não foi usado; Steam nativo do Mac permanece.
- Cities II continua teste opcional pós-E4; nada aqui encerra gate.

## Próximos passos sugeridos (Opus)

1. **Spawn**: verificar `ENOENT`/`spawn` nos logs do launcher; aplicar a pasta do jogo no PATH do prefixo (`HKCU\Environment`) — provável mesmo bug do CrossOver 26.2, corrigível no tool.
2. **Apresentação**: reproduzir `--use-angle=swiftshader --enable-unsafe-swiftshader` pela cadeia real do Steam (verificar se o dowser repassa args ao launcher — a linha `Executing command …` do `launcher-bootstrapper.log` mostra). Se não repassar, implementar no tool.
3. **Alternativa estrutural**: feature no tool para trocar o alvo do launch (`dowser.exe` → `Cities2.exe`) por opt-in/AppID, mantendo D3DMetal; ou seletor de renderer por jogo (DXMT para o launcher). Área T07/T08 — exige card e revisão.
4. Não misturar DLLs DXMT/D3DMetal na mesma execução.

## Continuação 2026-10-11 — Agente: claude · Modelo efetivo: opus (claude-opus-5-5)

Conclusão: **Cities II estacionado.** A ferramenta não é a causa (PEAK passou T12 pela mesma cadeia); os dois bloqueios são do jogo/launcher sob Wine. Retomar só com card próprio de port.

1. **Spawn (passo 1)**: não há `ENOENT`/`spawn` em nenhum log. O `start_game` do `launcher-*.log` é telemetria de abertura (`"loadtype":"cold"`), não clique em Jogar; o launcher nunca tentou lançar o jogo porque a janela branca impede o clique. `S:` → pasta do Steam e `ExecutableValidator` passam. PATH em `HKCU\Environment` **não aplicado** (sem evidência de que seja necessário).
2. **Argumentos (passo 2)**: opções de inicialização do Steam chegam inteiras ao launcher (shim `launch_args` → `steam.exe` → `dowser.exe` → `Executing command … --use-angle=swiftshader --enable-unsafe-swiftshader` → processos Chromium). Com SwiftShader pela cadeia real o GPU process **não crasha mais**, mas a janela segue transparente→branca.
3. **Isolamento da janela branca** (capturas em `scratch/cities-launcher/`):

   | Motor | Prefixo | Launcher | Renderer | Janela |
   |---|---|---|---|---|
   | runner notproton | 949230 | 2026.12 (Chromium 148) | D3DMetal / DXMT / SwiftShader / wined3d | branca |
   | runner notproton | 949230 | 2024.15 (Chromium 114) | wined3d | branca |
   | **motor original do wrapper Sikarugir** | **limpo (scratchpad)** | 2026.12 | wined3d (padrão do wrapper, `D3DMETAL=0`) | transparente/branca |

   Runner e motor do wrapper só diferem em `ntdll.dll` patchado (T04) e `lsteamclient`; `ntdll.so` idêntico. Logo **não é** o `compat_run.sh`, patch, ponte, prefixo nem versão do launcher: é o Sikarugir 11.0 r0 (driver winemac) apresentando a janela do Electron.
4. **Bypass do launcher**: shim chamado direto com o ambiente do Steam e alvo `Cities2.exe`. Cadeia completa OK (shim → `steam.exe` → `Cities2.exe`), Unity 2022.3.71f1, jogo 1.6.2f1, D3DMetal `Direct3D 11.0 [level 11.1]`. Falha em `SteamworksPlatform.Initialize → RemapDLCs → ContentHelper.ListContent → IOException` (Mono `LongDirectory`), depois `[SceneFlow] [FATAL]`. Log: `scratch/cities-launcher/Player-cities2-direto.log`.
5. **Referência**: `macgameport/cities-skylines-2-macos` documenta essa classe (Wine deixa `GetLastError` lixo nos caminhos de falha de diretório → Mono gera `IOException`). Stack que funciona lá: Wine 11 + **DXMT** + Steam Windows no prefixo + **10 patches binários nos arquivos do jogo** (`mscorlib`, `Colossal.IO`, `PDX.SDK.dll`…); no Wine 10, 17 patches incluindo bypass de licença do Coherent Gameface (não publicado). Conflita com a regra de preservar a biblioteca (só seria viável em cópia) e é port específico do jogo.

Estado: nada alterado no repo/tool; prefixo 949230 sem mudanças além das do próprio launcher/jogo (logs, `chromium-data`, `Player.log`); opções de inicialização SwiftShader ainda no Steam (podem ser apagadas); nenhum processo rodando. Para retomar: card "Cities II: patches em cópia + DXMT", com revisão.

## B1 — causa raiz da `IOException` (2026-10-11) — Agente: claude · Modelo efetivo: opus (claude-opus-5-5) · Card #40

**Conclusão:** o Sikarugir 11.0 (r0 e r1) não troca o `gsbase` para o TEB ao entrar em código PE no macOS. Ele usa o esquema antigo de slots TSD do pthread, em que só `gs:[0x30]` (TEB Self) e `gs:[0x58]` são emulados. O JIT do Mono do Unity lê o last-error **inline** em `gs:[0x68]` (`TEB->LastErrorValue`), sem chamar `GetLastError()`. Sob o Sikarugir ele recebe lixo, `LongDirectory.EnumerateFileSystemIterator` (Colossal.IO) cai no `throw` de `IL_0165` (`GetLastWin32Error() != 18` depois de `FindNextFile`) e o jogo morre em `ContentHelper.ListContent`. O Wine 11.0 upstream chama `_thread_set_tsd_base(NtCurrentTeb())` e não tem o problema.

Cadeia confirmada:

1. `Player.log`: `LongDirectory+<EnumerateFileSystemIterator>d__15.MoveNext () [0x00165]` ← `ListContent [0x00057]` = `LongDirectory.EnumerateDirectories(kContentPath)` sobre `Cities2_Data/Content`.
2. IL (`dnfile`/`dncil`): `IL_0144 FindNextFile` → `IL_014e Marshal.GetLastWin32Error` → `!= 18` → `IL_0165 throw`. O P/Invoke está correto (`FindNextFileW`, `SetLastError=true`, Unicode); o bug não está no jogo.
3. `tools/cities-b1/b1probe.c` carrega o Mono do jogo (`mono-2.0-bdwgc.dll`) e chama `LongDirectory.GetFiles` do `Colossal.IO.dll` real, em prefixo novo no scratch, sem Steam e sem tocar na biblioteca. Também faz `FindFirstFileW`/`FindNextFileW` puro no mesmo processo.
4. `+relay`: o Wine define 18 nas duas cadeias (`NtQueryDirectoryFile` → `80000006` → `RtlNtStatusToDosError` = `0x12`); depois do `FindNextFileW` do Mono **não existe chamada a `GetLastError`**, ou seja, a leitura é inline.
5. `tools/cities-b1/gsprobe.c`: `SetLastError(n)` e depois `GetLastError()` vs `mov %gs:0x68`.

| Motor | `ntdll.so` importa `_thread_set_tsd_base` | `gs:[0x68]` | `GetLastError` puro | `LongDirectory.GetFiles` (Mono do jogo) |
|---|---|---|---|---|
| runner notproton = `WS12WineSikarugir11.0` (r0, `ntdll.so` `c9948aab…`) | não | lixo `0x30f8140` | 18 | **IOException 5/5** |
| motor original do wrapper Sikarugir (sem patch T04) | não | — | 18 | **IOException 5/5** |
| `WS12WineSikarugir11.0_1` (r1, `f51a9828…`) | não | lixo `0xc24080` | 18 | **IOException 5/5** |
| Wine stable 11.0_1 stock (Gcenx, tar `b50dc50e…`) | **sim** | **18/19/20 OK** | 18 | **OK 5/5** |

Descartados: patch ntdll do T04, ponte/`lsteamclient`, `compat_run.sh`, prefixo, Steam (o probe não usa nenhum deles), camada Win32 do Wine. Também explica a medição da macgameport ("Wine 11.0 corrige; 0x5af040a0 com cara de ponteiro"): o build de 11.0 deles tem o swap de gsbase.

Alcance: afeta **qualquer jogo Unity/Mono** neste runner que dependa de `Marshal.GetLastWin32Error()` depois de um P/Invoke que falha. PEAK/GHPC passaram porque não seguem esse caminho na inicialização.

Reproduzir (`R` = diretório do motor com `bin/wine`; `FW` = Frameworks, opcional):

```sh
T=<llvm-mingw>/bin; $T/x86_64-w64-mingw32-clang -O1 -o gsprobe.exe tools/cities-b1/gsprobe.c
$T/x86_64-w64-mingw32-clang -O1 -o b1probe.exe tools/cities-b1/b1probe.c
tools/cities-b1/run.sh "$R" <prefixo-scratch> 'Z:\…\gsprobe.exe'
tools/cities-b1/run.sh "$R" <prefixo-scratch> 'Z:\…\b1probe.exe' "$G" "$G\Cities2_Data\Content"   # G = pasta do jogo (Windows)
```

Motores baixados para A/B: `scratch/sikarugir/engines-b1/` (ignorado).

Em aberto: por que o Sikarugir não usa o swap de gsbase (compatibilidade com D3DMetal/GPTK? desempenho no Rosetta?). Sem fonte do build 11.0 publicado não dá para confirmar.

Pesquisa de motores do Sikarugir Creator (mesmo probe, 2026-10-11): `WS12WineSikarugir10.0_8` (`2a6bcf2a…`), `WS12WineCX24.0.7_7` (`203f9e9f…`) e `WS12WineGPTK1.1_3` (`e6efcbf0…`) **também falham**: nenhum importa `_thread_set_tsd_base`, `gs:[0x68]` é lixo e `LongDirectory` lança exceção. Com `WINEMSYNC=1` o resultado não muda. Nenhuma opção do wrapper (aba Options/Advanced) altera o `gs`. Até agora, só o Wine stock passa.

### Caminho 1 (espelhar o last-error em `gs:[0x68]`): verificação de segurança REPROVADA (2026-10-11, claude)

- No Sikarugir o `gsbase` em código PE é o TSD do pthread do macOS. `gs:[0x68]` = slot 13 = `__PTK_LIBC_GMTIME_KEY` (`libpthread/private/pthread/tsd_private.h`), o ponteiro do buffer por thread do `gmtime()` da libc. Os slots que o Sikarugir usa (6 → `gs:0x30` TEB, 11 → `gs:0x58`) são livres; o 13 não.
- O `ntdll.so` do runner importa `_gmtime`/`_localtime`/`_ctime`/`_asctime` (`nm -u`). Upstream `dlls/ntdll/unix/system.c` (wine-11.0) chama `gmtime()` no cálculo de fuso horário (linhas 2705, 2907, 2963, 2984, 3226), alcançável de qualquer thread PE.
- Gravar um código de erro (≠0) no slot 13 faz o próximo `gmtime()` daquela thread escrever no endereço do código (ex.: `0x12`): crash. **Espelhamento ingênuo descartado.**
