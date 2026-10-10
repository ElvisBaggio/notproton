# Handoff

Atualizado: 2026-10-10 · Agente: claude · Modelo efetivo: sonnet · Branch: codex/t08-sikarugir-launcher.

**Estado.** T08 implementado para revisão (launcher por origem, prefixos/ferramentas na engine copiada, Perfil A D3DMetal, ensaio integrado com Steam fechado até `CreateSteamPipe`). Evidência: docs/evidence/launcher.md.

**Próximo passo.** Revisão Claude Code Opus 5.5 na issue #12 (modelo do revisor pendente); prova de sessão real com Steam logado (comando em launcher.md); depois T09 (suíte Swift em Xcode/CI, UI/pacote, instalar `run` novo) e T10/T11.

**Limites.** Swift completo NOT RUN (sem Xcode); runcheck/scriptcheck SKIP (shellcheck ausente). AUTHENTICATED=yes no launcher integrado não provado.
