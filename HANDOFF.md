# Handoff

Atualizado: 2026-10-12 · Agente: claude · Modelo efetivo: opus (claude-opus-5-5) · Branch: `claude/rawmouse-44` (empilhada sobre `claude/legacycompat-41` → `claude/bridge-i386`).

**Estado.**
- **E1–E4 concluídos** (gate E4 aceito com ressalvas, `docs/reviews/astra-e4-gate.md`; `main` via PR #37). Jogos confirmados: PEAK, GHPC e agora Ghost Recon Wildlands (460930).
- **#42 ponte i386** (`claude/bridge-i386`): `lsteamclient.dll` i386 (`bd277143…`), gatilho `steamclient.dll` e `syswow64/lsteamclient.dll` nos prefixos antigos. Probe 32-bit autenticado; Ubisoft Connect recebe o ticket. Perfil Steam 1791686101 incluído. Evidência: `docs/evidence/bridge-build.md`.
- **#41 installscript** (`claude/legacycompat-41`, `073f62e`): o `run` copia o `iscriptevaluator.exe` da Valve (já no payload) para `legacycompat/` do cliente; Wildlands passa a `helper exited status=0` e o avaliador rodou DirectX e recriou a chave do Uplay. Falta o aceite com prefixo novo.
- **#44 mouse raw** (`claude/rawmouse-44`, `202a6b6`): `notproton-rawmouse.dylib` (`39d6aeed…`, após a revisão) troca os deltas acelerados/quantizados do winemac pelos do `GCMouse` em modo mira e prende o cursor. Wildlands "ficou bom" (Elvis, 2026-10-12). `CaptureDisplaysForFullscreen` voltou a opt-in (`c9ebcf4`). Evidência: `docs/evidence/raw-mouse.md`.
- App instalado: `/Applications/NotProton Sikarugir.app` = build desta branch; backups `/Applications/-bak-a4087cb-…` (antes do #44) e `/Applications/-bak-202a6b6-…` (antes do opt-in da captura). Cada rebuild pede religar "Gerenciamento de apps" e rodar Install.
- **Cities II estacionado** (`docs/evidence/cities-launcher.md`; #40).

**Próximo passo.** Tudo está em cards no Project 8:
- **#45** aceite, revisão e merge da pilha #42 → #41 → #44 (checklist: Install/tela preta, PEAK/GHPC, save, prefixo novo, revisão Opus 5.5/Astra, PRs).
- **#46** `WINEDEBUG` padrão de baixo custo (log de ~33 MB/s com o Ubisoft Connect).
- **#43** update pendente do Steam aplicado apesar do bloqueio.
- **#47** porte manual do upstream 1.1.2 → 1.1.6.
- **#48** build reproduzível dos PEs da ponte; **#49** teclas mortas (`^`); **#50** frame pacing/renderer real; **#51** D3D12 e saves (ressalvas do E4).
- **#40** Cities II estacionado (decisão do Elvis entre motor Wine 11 + DXMT, reportar ao Sikarugir ou deixar parado).

**Bloqueios / limites.**
- Prefixo 460930 tem a chave de teste `Uninstall\Uplay-np41-bak` (inofensiva); backups do registro em `scratch/wildlands/`.
- A dylib de mouse depende do `winemac.so` fixado do sikarugir-11.0-r0; outro build exige refazer os offsets (fica inerte).
- O Ubisoft Connect (wined3d) gera erros de OpenGL sem parar; com o `WINEDEBUG` padrão o log do jogo cresce ~33 MB/s. Usar `WINEDEBUG=-all` no Wildlands.
