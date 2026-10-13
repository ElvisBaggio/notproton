# Handoff

Atualizado: 2026-10-12 · Agente: claude · Modelo efetivo: opus (claude-opus-5-5) · Branch: `main` (PRs #54–#58 mergeados pelo Elvis em 2026-10-13, `2c7f5c0`).

**Estado.**
- **E1–E4 concluídos** (gate E4 aceito com ressalvas, `docs/reviews/astra-e4-gate.md`; `main` via PR #37). Jogos confirmados: PEAK, GHPC e agora Ghost Recon Wildlands (460930).
- **#42 ponte i386** (`claude/bridge-i386`): `lsteamclient.dll` i386 (`bd277143…`), gatilho `steamclient.dll` e `syswow64/lsteamclient.dll` nos prefixos antigos. Probe 32-bit autenticado; Ubisoft Connect recebe o ticket. Perfil Steam 1791686101 incluído. Evidência: `docs/evidence/bridge-build.md`.
- **#41 installscript** (`claude/legacycompat-41`, `073f62e`): o `run` copia o `iscriptevaluator.exe` da Valve (já no payload) para `legacycompat/` do cliente; Wildlands passa a `helper exited status=0` e o avaliador rodou DirectX e recriou a chave do Uplay. Falta o aceite com prefixo novo.
- **#44 mouse raw** (`claude/rawmouse-44`, `202a6b6`): `notproton-rawmouse.dylib` (`39d6aeed…`, após a revisão) troca os deltas acelerados/quantizados do winemac pelos do `GCMouse` em modo mira e prende o cursor. Wildlands "ficou bom" (Elvis, 2026-10-12). `CaptureDisplaysForFullscreen` voltou a opt-in (`c9ebcf4`). Evidência: `docs/evidence/raw-mouse.md`.
- #41, #42, #44 e #45 fechados (PR #52; aceites com ressalva registrados nos cards). App instalado: `/Applications/NotProton Sikarugir.app` = build de `0631e5e` (o `main` só muda `replace_file`/shellcheck depois disso); backups `/Applications/-bak-a4087cb-…` (antes do #44) e `/Applications/-bak-202a6b6-…` (antes do opt-in da captura). Cada rebuild pede religar "Gerenciamento de apps" e rodar Install.
- **Cities II estacionado** (`docs/evidence/cities-launcher.md`; #40). Causa raiz e probes do B1: `docs/evidence/cities-launcher.md` + `tools/cities-b1/` (PR #54). Opção D feita: reportado ao Sikarugir em https://github.com/Sikarugir-App/Sikarugir/issues/289 (2026-10-12, com aprovação do Elvis). Aguardando resposta; se não houver, a alternativa é a opção C (Wine stock + DXMT), com risco para os jogos que já funcionam.

**Próximo passo.** A `main` (`2c7f5c0`) passou em `swift test` 457/457 e nos checks de shell. O app instalado ainda é o build de `0631e5e`, então nada do que segue está ativo. Para ativar e dar o aceite: fazer backup do app em `/Applications`, `make app`, instalar, religar "Gerenciamento de apps", rodar Install e fazer o smoke test (PEAK, GHPC e Wildlands abrindo e autenticando).
- **#43** (PR #55): o Status avisa quando o build do Steam no manifesto (instalado ou baixado e pendente) não tem perfil. Aceite: ver o aviso quando o Steam baixar um build novo. Não descarta o pacote pendente.
- **#46** (PR #56): `WINEDEBUG=-all` por padrão; `NOTPROTON_LOG=1` volta a `err+all,fixme-all`. Aceite: Wildlands **sem** `WINEDEBUG=-all` nas opções, com o `notproton-run.log` em KB.
- **#47** (PR #57): porte parcial do upstream 1.1.7 (`docs/evidence/upstream-port-1.1.7.md`). Aceite: smoke test e um `Steam.dll` oculto em `steamapps/common/`.
- **#48** adiado: corrigir o `__FILE__` muda os PEs fixados e exige um probe novo da Steam API. Fazer junto com o próximo rebuild da ponte.
- **#49** teclas mortas, **#50** frame pacing e **#51** D3D12/saves dependem de teste interativo do Elvis.
- **#40**: aguardar a resposta do Sikarugir (#289).

**Bloqueios / limites.**
- Limpeza de 2026-10-13: saíram os worktrees de agentes (`.claude/worktrees`), os worktrees de probe T05–T09b e `prof92380`, `scratch/t10-backup`, `scratch/b42`, `scratch/sikarugir/engines-b1` e as branches locais já mergeadas. Os docs de evidência desses gates citam caminhos que não existem mais (histórico). **Não apagar** `scratch/worktrees/t03-bridge` e `t04-close` (usados por `bridge/tests/stage-sikarugir-engine.sh`), `scratch/proton-lsc` (`lsteamclient/fetch.sh`) e `scratch/sikarugir/{bridge,wine,wine-build*}`.
- O toolchain fica em `scratch/toolchain/`: llvm-mingw 20260826 e 20261006, bison 3.8.2 e m4 1.4.19 (downloads com hash conferido contra `docs/evidence/engine-baseline.md`, em `scratch/toolchain/downloads/`) e `venv-capstone` (capstone 5.0.7). Recriado depois que a limpeza apagou a cópia antiga, que ficava dentro de um worktree de agente. `LLVM_MINGW=$PWD/scratch/toolchain/llvm-mingw-20260826-ucrt-macos-universal`; com `ENGINE_LOCK=scratch/worktrees/t03-bridge/scratch/sikarugir/engine-lock.json`, `sikarugir-buildcheck.sh --artifacts` dá PASS. O `scratch/sikarugir/engine-lock.json` do repo principal ainda está em schemaVersion 1 (anterior ao T01).
- Prefixo 460930 limpo dos testes (chave do Uplay restaurada); backups do registro em `scratch/wildlands/`.
- A dylib de mouse depende do `winemac.so` fixado do sikarugir-11.0-r0; outro build exige refazer os offsets (fica inerte).
- O Ubisoft Connect (wined3d) gera erros de OpenGL sem parar; com o `WINEDEBUG` padrão o log do jogo cresce ~33 MB/s. Resolvido no código pelo #56; vale depois de instalar o app novo.
- shellcheck 0.11.0 instalado via Homebrew em 2026-10-12. Antes, `runcheck`/`scriptcheck` eram pulados em silêncio; agora rodam e passam.
- A `claude/cities-b1` remota não pôde ser apagada ("push declined due to repository rule violations"). O conteúdo dela está na `main` pelo #54. Para apagar, use o GitHub ou ajuste o ruleset.
