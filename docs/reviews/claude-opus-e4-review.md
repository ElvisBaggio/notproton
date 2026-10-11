# Revisão Opus — T10, T11, T12 (E4)

Data: 2026-10-11 · Revisor: Claude Code · Modelo efetivo: opus (claude-opus-5-5) · Base: `codex/game-agnostic-scope` @ `cb0fe82`.

**Independência:** o mesmo cliente (claude/opus) executou T10–T12. Esta revisão não é independente e **não substitui** a revisão Sol 6.1/Astra exigida pelo critério 15 do `acceptance.md`, que segue NOT RUN.

## O que foi conferido ao vivo (não só nos documentos)

| Afirmação | Conferência | Resultado |
|---|---|---|
| Hashes implantados (`acceptance.md`) | `shasum` de `notproton.dylib` e `run` | batem |
| Deploy vivo | `codesign -dv /Applications/Steam.app` → ad hoc; `compatibilitytools.d/notproton-sikarugir-11.0-r0` presente | bate |
| Correção do renderer | `WINEDLLPATH_D3DMETAL` em `PrefixTools.swift:115`, `compat_run.sh:43` e três testes | presente |
| GHPC: prefixo não reinicializa | `notproton-run.log`: `cloned … template` aparece 1 vez em 2 execuções | bate |
| GHPC: API Steam e renderer | `Player.log`: `Initializing for App ID = 1705180`, `Direct3D 11.0 [level 11.1]` | bate |
| Wrapper atual (13) | aberto em 2026-10-11, subiu `Configure.app` | PASS |

## Achados

**R1 (média): o runbook depende de script não versionado.** O passo 2 do "Rollback vivo" (`recovery.md`) chama `scratch/t10-backup/t10_snapshot.py`, e o `scratch/` é ignorado pelo git. Se o `scratch/` se perder, o backup por manifesto não é reproduzível, o que enfraquece o critério 14 ("recuperar sem esta conversa"). O script não guarda segredos. Correção: versionar o script, por exemplo em `tools/`, e incluir `compatdata/*` e `appmanifest_*.acf` como alvos opcionais (passo 3a).

**R2 (baixa): o guia promete D3D12 sem teste.** A tabela "Combinação fixada" de `steam-sikarugir.md` diz "D3DMetal (D3D11/D3D12)", mas só o D3D11 foi provado. Correção: "D3D11 (D3D12 não testado)".

**R3 (baixa): Cloud do PEAK descrito de forma contraditória.** O `game-launch.md` (T12) diz "Steam Cloud ativo (`steam_autocloud.vdf`)", e o guia diz "o PEAK não sincronizou". As duas coisas são verdade (Cloud ativo, AutoCloud achou 0 arquivos `*.peak`), mas o texto confunde. Correção: unificar a frase.

**R4 (informativo, a favor): o "jogo após redeploy" do T10 tem prova.** O T10 registra NOT RUN para jogo depois do redeploy (00:37:43). Mas a sessão do GHPC às 02:06 (T11) aconteceu depois do redeploy, com os mesmos bytes, `exited status=0` e D3D11 via D3DMetal. Esse item do T10 pode passar a PASS (log), citando o T11.

## Parecer por card

| Card | Parecer Opus | Ressalvas |
|---|---|---|
| T10 (#14) | aprovar com ressalvas | critério 3 FAIL parcial aceito pelo Elvis; R1; R4 permite fechar o "jogo após redeploy" |
| T11 (#15) | aprovar com ressalvas | biblioteca não isolada (desvio aceito); gameplay por relato aceito pelo Elvis |
| T12 (#16) | aprovar com ressalvas | R1–R3; sessão e persistência só por relato (rastros do PEAK apagados na desinstalação) |

**Correções (2026-10-11, claude/opus):** R1 → `tools/rollback_snapshot.py` versionado, com `--games`; runbook atualizado. R2 e R3 → texto do guia e de `game-launch.md` corrigido.

Gate do E4: continua **aberto** até a revisão Sol 6.1/Astra (critério 15). R1 é a única correção que eu faria antes dela.
