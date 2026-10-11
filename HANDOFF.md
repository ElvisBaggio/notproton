# Handoff

Atualizado: 2026-10-11 · Agente: claude · Modelo efetivo: opus (claude-opus-5-5) · Branch: `claude/t12-acceptance-docs`.

**Estado.**
- Fechados por decisão do Elvis em 2026-10-10: #1 [E1] e #3 [E3].
- **T10 (#14) executado, aguardando revisão.** Evidência: `docs/evidence/deployment-rollback.md`; procedimento: `docs/runbooks/recovery.md` ("Rollback vivo"). Fluxo:
  - Backup por manifesto com clone APFS.
  - Rollback 100% original por decisão do Elvis: Repair Steam, que restaura a assinatura Valve `MXGJJ98X76`, e a ferramenta movida para fora.
  - Readback: Steam original abre e a ferramenta some da lista.
  - Redeploy: alvos byte-idênticos ao estado anterior e ferramenta de volta na UI.
  - O Steam ficou no build `1791592380`. Jogo depois do redeploy: **NOT RUN** (Elvis não abriu); a prova de jogo fica com T11/T12.
- **Efeito colateral do rollback do T10 (descoberto depois do merge):** com o Steam original aberto sem a ferramenta, o Steam removeu os depots Windows. O Cities II baixou 8,3 GB de DLC de novo e o PEAK passou a exigir re-download. Em seguida o Elvis desinstalou o PEAK, e o Steam apagou o `compatdata/3527290`. O GHPC não foi afetado. O runbook ganhou o passo 3a. O aceite "arquivos alheios preservados" do T10 falhou parcialmente.
- Jogos confirmados pela ferramenta: PEAK (T12) e **GHPC** (AppID 1705180, 2026-10-11, Elvis relatou que funcionou; shim `exited status=0`).
- Achado preexistente: o helper `legacycompat/iscriptevaluator.exe` não existe e falha sempre (`status=1`). O Steam segue para o launch mesmo assim.
- **Cities II estacionado** por decisão do Elvis em 2026-10-11 (`docs/evidence/cities-launcher.md`, PR #25). A janela do Paradox Launcher fica branca até no Sikarugir original. Abrir o `Cities2.exe` direto cai numa `IOException` do Mono. Retomar só com card próprio.

**Próximo passo.**
- Revisão do T10 por Claude Code Opus 5.5 e por Astra.
- **T11 (#15) PASS por decisão do Elvis** com GHPC (1705180) na biblioteca padrão (desvio aceito). Depot Windows, D3D11 via D3DMetal, API Steam, saída limpa e Cloud comprovados por log; gameplay pelo relato dele (log mostra só o menu). Evidência em `docs/evidence/game-launch.md`. Aguarda revisão.
- **T12 (#16): documentos publicados**: `docs/runbooks/steam-sikarugir.md` (guia) e `docs/evidence/acceptance.md` (15 critérios). O gate do E4 **ainda não fecha**: falta abrir o wrapper atual (13, NOT RUN) e a revisão Sol 6.1/Astra (15, NOT RUN); o 3 (rollback preservando os jogos) é FAIL parcial; os itens 10–12 são PASS só por relato.
- Documentos que faltam no T12.
- Opcional: apagar as opções SwiftShader do Cities II no Steam.

**Limites.**
- Backups e manifestos em `scratch/t10-backup/20261011-pre-rollback/` (ignorado). A pasta da ferramenta antes do rollback está em `moved/`.
- Nenhum código alterado.
