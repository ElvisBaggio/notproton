# Handoff

Atualizado: 2026-10-11 · Agente: claude · Modelo efetivo: opus (claude-opus-5-5) · Branch: `codex/game-agnostic-scope`. Sessão anterior: opencode (deepseek-flash), 2026-10-10.

**Estado.**
- Fechados por decisão do Elvis em 2026-10-10: #1 [E1] e #3 [E3] (gates cumpridos; comentários de encerramento registrados).
- E4: T12 (#16) tem PASS de runtime registrado (`docs/evidence/game-launch.md`, sessão/save/reabertura do PEAK) mas o território documental do card ainda falta (`docs/runbooks/steam-sikarugir.md`, `docs/evidence/acceptance.md`, HANDOFF). T10 (#14) segue pendente (deploy→rollback→readback→redeploy real; `docs/evidence/deployment-rollback.md` não existe). T11 (#15) continua bloqueado por T10.
- **Cities II (teste opcional pós-E4) — ESTACIONADO por decisão do Elvis em 2026-10-11.** Detalhes em `docs/evidence/cities-launcher.md`. A ferramenta não é a causa (PEAK passou pela mesma cadeia). (1) A janela do Paradox Launcher fica branca até no motor original do wrapper Sikarugir com prefixo limpo, com qualquer renderer e versão do launcher: é o Sikarugir 11.0 r0. (2) Bypass para `Cities2.exe` sobe o jogo (D3D11 via D3DMetal) mas morre em `IOException` do Mono ao listar DLCs no init do Steamworks — classe de bug do Wine que `macgameport/cities-skylines-2-macos` contorna com 10 patches binários no jogo + DXMT. O jogo é D3D11, não DX12 (handoff anterior corrigido).

**Próximo passo.** T10 (#14). Cities II só com card próprio ("Cities II: patches em cópia + DXMT", com revisão). Opcional: apagar as opções de inicialização SwiftShader do Cities II no Steam.

**Limites.** Testes do Cities II manuais, fora dos cards; nada alterado no código/tool; nenhum processo deixado rodando; capturas, `Player.log` e scripts em `scratch/cities-launcher/` (ignorado).
