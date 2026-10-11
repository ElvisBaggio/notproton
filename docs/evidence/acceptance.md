# Aceite do E4 (T10–T12)

Data: 2026-10-11 · Agente: claude · Modelo efetivo: opus (claude-opus-5-5) · Branch `claude/t12-acceptance-docs`. Card T12 (#16). Guia: `docs/runbooks/steam-sikarugir.md`.

Legenda: **PASS (log)** = comprovado por log/arquivo; **PASS (relato)** = só pelo relato do Elvis, sem rastro verificável; **NOT RUN** = não executado. Pelo card, nenhum NOT RUN permite encerrar o épico.

## Versões e artefatos

| Peça | Valor |
|---|---|
| Steam cliente | `1791592380` (`publicbeta`) |
| NotProton Sikarugir | 1.1.1 (`builtAt 1791681908`) |
| Motor | Sikarugir 11.0 r0 (`notproton/runners/sikarugir-11.0-r0`) |
| PEAK (3527290) | depot Windows `3527291`, build `25739797` (T11 prep), `-force-d3d11` — **desinstalado em 2026-10-11** |
| GHPC (1705180) | depot `1705181`, build `24952526`, manifest `3699423609009875309` |

SHA-256 dos artefatos implantados (leitura de 2026-10-11):

| Arquivo | SHA-256 |
|---|---|
| `/Applications/Steam.app/Contents/MacOS/notproton.dylib` | `504624bc9a4314b6719d614e228ac989c54430f366992994d760e81887c4ab34` |
| `compatibilitytools.d/notproton-sikarugir-11.0-r0/run` | `ce1c9ec6721719fabf2d8ffb849bf34141e20df85133373357024fa170c65fb4` |
| runner `lib/wine/x86_64-windows/ntdll.dll` (pós-correção do gate E2) | `ef8e99712f845f5c4e7ee01a0475d3ccaf84114d54a0a6c962808fee34b68b29` |
| runner `lib/wine/x86_64-unix/lsteamclient.so` | `d71f954cf1c1a2355e9dfd7e8de593d8a4d1274117d42626394d4e95c7379a9c` |
| runner `lib/wine/x86_64-windows/lsteamclient.dll` | `2933ac86d886f1264fabfbb97f21f53967452fca2397f29ecdbd29f83616c7ac` |
| `notproton/bridge/sikarugir-11.0-r0/steam.exe` | `56979db411cb12b48610c09b8fc01db3c34bb3c7e31ea53f1b17dafaf7f98b70` |

O `run` acima é o anterior ao PR #27 (só comentário mudou); o próximo Install troca o hash.

## Critérios

| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Deploy visível no Steam (T10) | PASS (log + UI) | `deployment-rollback.md` |
| 2 | Rollback real, Steam original funcional (T10) | PASS (log + UI) | assinatura Valve `MXGJJ98X76`, sem injeção, ferramenta fora da lista |
| 3 | Arquivos alheios preservados no rollback (T10) | **FAIL parcial aceito** pelo Elvis (2026-10-11) | depots Windows removidos e re-download (Cities II 8,3 GB, PEAK 1,46 GB); prefixos e saves não apagados pelo rollback. Correção só documental: runbook passo 3a |
| 4 | Redeploy conferido (T10) | PASS (log + UI) | alvos byte-idênticos ao manifesto |
| 5 | Instalação Windows em biblioteca isolada (T11) | **Desvio aceito** pelo Elvis | GHPC na biblioteca padrão |
| 6 | Conteúdo Windows, sem build macOS (T11) | PASS (log) | PEAK: só depot `3527291`; GHPC: `oslist=windows`, depot `1705181`, `Bin/GHPC.exe` |
| 7 | Jogo inicia pelo Steam nativo com o motor certo, sem Steam Windows (T11) | PASS (log) | `notproton-run.log` dos dois jogos; `exited status=0` |
| 8 | Renderer conferido (T11) | PASS (log) | PEAK e GHPC: `Direct3D 11.0 [level 11.1]` via D3DMetal |
| 9 | Reabrir não reinicializa o prefixo (T11) | PASS (log) | GHPC: template clonado só na 1ª execução (00:20); 2ª (02:06) sem clonagem |
| 10 | Gameplay real (T11) | PASS (relato) | GHPC: os `Player.log` mostram só o menu; relato aceito pelo Elvis (2026-10-11) |
| 11 | Sessão ≥ 15 min com ação identificável (T12) | PASS (relato) | PEAK, 2026-10-10. Logs do Steam começam em 2026-10-10 22:34 (depois da sessão) e o prefixo foi apagado na desinstalação; relato aceito pelo Elvis (2026-10-11) |
| 12 | Estado persistente após fechar jogo e Steam e reabrir (T12) | PASS (relato) | PEAK, relato do Elvis; rastros (`Player-prev.log`, `steam_autocloud.vdf`) apagados com o prefixo; relato aceito pelo Elvis (2026-10-11) |
| 13 | Wrapper original continua utilizável | PASS (processo) | o wrapper original foi apagado pelo Elvis antes do T10. O atual (`~/Applications/Sikarugir/Sikarugir.app`), que nunca foi alvo do deploy, abriu em 2026-10-11 via `open` e subiu o `Configure.app` (comportamento normal de wrapper sem programa definido); fechado em seguida |
| 14 | Guia permite recuperar sem esta conversa | PASS (doc) | `steam-sikarugir.md` + `recovery.md` |
| 15 | Revisão independente Sol 6.1 / Astra | **NOT RUN** | pendente |

## Limitações conhecidas

- DX12 do PEAK sem `-force-d3d11`: não testado.
- Cities: Skylines II não funciona (`cities-launcher.md`).
- Helper `iscriptevaluator.exe` ausente (`helper exited status=1`, sem impedir o launch).
- CI `app` não monta a ponte fora do Mac do Elvis.

## Estado do gate do épico

**Não encerrável ainda**: só falta o critério 15 (revisão independente). Em 2026-10-11 o Elvis aceitou o 3 como FAIL parcial com correção documental e os PASS por relato (10–12); o 13 passou ao abrir o wrapper atual.
