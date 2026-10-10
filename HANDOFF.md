# Handoff

Atualizado: 2026-10-10 · Agente: claude · Modelo efetivo: sonnet · Branch: claude/t09b-remove-crossover.

**Estado.** T09b: CrossOver removido do código (app, dylib, ntdll-patch, lsteamclient, bridge, Makefile). App único `NotProton Sikarugir.app`. Swift: 452 testes, 446 PASS, 0 falhas, 6 SKIP explícitos; checks do Makefile e `sh -n` PASS (anchorcheck/sigdb-fixtures falham igual na base). Ensaio do launcher chega a CreateSteamPipe. Evidência: docs/evidence/remove-crossover.md (inclui mapa para portar o upstream).

**Próximo passo.** Revisão Claude Code Opus 5.5 na issue #22; depois T10 (convivência com o 1.1.0, deploy→rollback, prova com Steam logado: `sh scratch/t09b-runtime/run.sh run`).

**Limites.** `detour*.c` ainda têm `#ifdef` do CrossOver (hashes pinados exigem reconstrução); `CompatTool.Flavor` com um único caso; testes de clone real ficam SKIP sem engine/runner instalado.
