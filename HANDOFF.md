# Handoff

Atualizado: 2026-10-10 · Agente: claude · Modelo efetivo: sonnet · Branch: codex/t09-sikarugir-ui.

**Estado.** T09 implementado para revisão: seção Sikarugir na UI, `app-sikarugir` (bundle experimental sem Sparkle), guarda de perfil documentada para todas as origens, aviso ntdll só CrossOver. Suíte Swift real: 518 testes, 517 PASS, 0 falhas, 1 SKIP. Evidência: docs/evidence/ui-packaging.md.

**Próximo passo.** Revisão Claude Code Opus 5.5 na issue #13; depois T10 (deploy→rollback→readback→redeploy, convivência com a 1.1.0, `run` novo via SteamInstaller) e prova de sessão real do T08.

**Limites.** Payload local montado com binários do app 1.1.0 (dobby ausente); runcheck/scriptcheck SKIP (sem shellcheck); GUI não exercitada por clique.
