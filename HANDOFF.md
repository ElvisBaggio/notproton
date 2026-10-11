# Handoff

Atualizado: 2026-10-11 · Agente: claude · Modelo efetivo: opus (claude-opus-5-5) · Branch: `claude/post-e4-handoff`.

**Estado.**
- **E1–E4 concluídos.** O gate do E4 foi aceito com ressalvas pela Astra (`docs/reviews/astra-e4-gate.md`), e o `main` foi atualizado pelo PR #37. As issues #14, #15, #16 e #4 estão fechadas.
- Jogos confirmados pela ferramenta: PEAK (T12) e GHPC (AppID 1705180, D3D11 via D3DMetal).
- O fix 1.1.1 (Ubisoft Connect, #18) já está no código: `steam-shim/steam.cpp` e `dylib/version.h` = 1.1.1. Evidência: `docs/evidence/ubisoft-1.1.1.md`.
- **Cities II estacionado** (`docs/evidence/cities-launcher.md`). Retomar só com card próprio.

**Próximo passo.**
- Fechar no GitHub a issue #18 e os PRs #19/#20, que foram superados porque partem de branches antigas. O fechamento automático foi bloqueado por permissão, então fica para o Elvis.
- Upstream já está em v1.1.6. Abrir um card para portar manualmente 1.1.2–1.1.6 (decisão do T09b).
- Ressalvas do E4 (opcionais):
  - gameplay e saves aceitos só como "PASS por relato";
  - D3D12 não provado;
  - o helper `legacycompat/iscriptevaluator.exe` não existe e falha sempre (`status=1`);
  - o rollback faz o Steam re-baixar os depots Windows (runbook passo 3a).
- Opcional: apagar as opções SwiftShader do Cities II no Steam.

**Limites.**
- Backups do T10 em `scratch/t10-backup/20261011-pre-rollback/` (ignorado).
- Nenhum código alterado.
