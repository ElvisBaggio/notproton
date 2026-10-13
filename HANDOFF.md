# Handoff

Atualizado: 2026-10-12 · Agente: claude · Modelo efetivo: opus (claude-opus-5-5) · Branch: `main` (PRs #54–#57 abertos, aguardando revisão/merge do Elvis).

**Estado.**
- **E1–E4 concluídos** (gate E4 aceito com ressalvas, `docs/reviews/astra-e4-gate.md`; `main` via PR #37). Jogos confirmados: PEAK, GHPC e agora Ghost Recon Wildlands (460930).
- **#42 ponte i386** (`claude/bridge-i386`): `lsteamclient.dll` i386 (`bd277143…`), gatilho `steamclient.dll` e `syswow64/lsteamclient.dll` nos prefixos antigos. Probe 32-bit autenticado; Ubisoft Connect recebe o ticket. Perfil Steam 1791686101 incluído. Evidência: `docs/evidence/bridge-build.md`.
- **#41 installscript** (`claude/legacycompat-41`, `073f62e`): o `run` copia o `iscriptevaluator.exe` da Valve (já no payload) para `legacycompat/` do cliente; Wildlands passa a `helper exited status=0` e o avaliador rodou DirectX e recriou a chave do Uplay. Falta o aceite com prefixo novo.
- **#44 mouse raw** (`claude/rawmouse-44`, `202a6b6`): `notproton-rawmouse.dylib` (`39d6aeed…`, após a revisão) troca os deltas acelerados/quantizados do winemac pelos do `GCMouse` em modo mira e prende o cursor. Wildlands "ficou bom" (Elvis, 2026-10-12). `CaptureDisplaysForFullscreen` voltou a opt-in (`c9ebcf4`). Evidência: `docs/evidence/raw-mouse.md`.
- #41, #42, #44 e #45 fechados (PR #52; aceites com ressalva registrados nos cards). App instalado: `/Applications/NotProton Sikarugir.app` = build de `0631e5e` (o `main` só muda `replace_file`/shellcheck depois disso); backups `/Applications/-bak-a4087cb-…` (antes do #44) e `/Applications/-bak-202a6b6-…` (antes do opt-in da captura). Cada rebuild pede religar "Gerenciamento de apps" e rodar Install.
- **Cities II estacionado** (`docs/evidence/cities-launcher.md`; #40). Causa raiz e probes do B1: PR #54. Rascunho de issue para o Sikarugir (opção D, gsbase/`gs:[0x68]`) em `scratch/sikarugir/issue-gsbase-draft.md`; **não publicado**, espera o OK do Elvis.

**Próximo passo.** Revisar e mergear os PRs abertos em 2026-10-12. Eles combinam sem conflito. Depois rodar `make app-payload`, gerar o app, fazer Install e o smoke test (PEAK, GHPC e Wildlands abrindo e autenticando):
- **#54** Cities II B1: evidência e probes (só docs/tools). Depois do merge, apagar `claude/cities-b1`, local e remota.
- **#55** (#43) Status avisa quando o build do Steam no manifesto, instalado ou baixado e pendente, não tem perfil. Não descarta o pacote pendente.
- **#56** (#46) `WINEDEBUG=-all` por padrão; `NOTPROTON_LOG=1` volta a `err+all,fixme-all`. Aceite: log do Wildlands em KB.
- **#57** (#47) Porte parcial do upstream 1.1.7 (triagem em `docs/evidence/upstream-port-1.1.7.md`).
- **#48** adiado: corrigir o `__FILE__` muda os PEs fixados e exige um probe novo da Steam API. Fazer junto com o próximo rebuild da ponte.
- **#49** teclas mortas, **#50** frame pacing e **#51** D3D12/saves dependem de teste interativo do Elvis.
- **#40**: publicar o rascunho da issue no Sikarugir, se o Elvis aprovar.

**Bloqueios / limites.**
- Prefixo 460930 limpo dos testes (chave do Uplay restaurada); backups do registro em `scratch/wildlands/`.
- A dylib de mouse depende do `winemac.so` fixado do sikarugir-11.0-r0; outro build exige refazer os offsets (fica inerte).
- O Ubisoft Connect (wined3d) gera erros de OpenGL sem parar; com o `WINEDEBUG` padrão o log do jogo cresce ~33 MB/s. Usar `WINEDEBUG=-all` no Wildlands até o merge do #56.
- O shellcheck não está instalado neste Mac: `runcheck`/`scriptcheck` são pulados em silêncio (`make` sai com 0).
