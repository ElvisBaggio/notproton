# Projeto — Cities II no Steam nativo com Sikarugir

Atualizado: 2026-10-08 · Autor: codex

- [Repositório privado](https://github.com/ElvisBaggio/notproton)
- [Project e cards](https://github.com/users/ElvisBaggio/projects/8)
- [Especificação](docs/superpowers/specs/2026-10-08-sikarugir-cities2-design.md)
- [Plano de implementação](docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md)
- [Política de agentes e alternativa Claude Code](docs/AGENT_EXECUTION.md)

## Épicos e cards

| ID | Issue | Responsável / modelo padrão | Alternativa Claude Code | Depende de |
|---|---|---|---|---|
| E1 | [#1 — Preparação e referência recuperável](https://github.com/ElvisBaggio/notproton/issues/1) | astra_coordinator / gpt-6-astra | opus para revisão; Astra coordena | gate dos filhos |
| T01 | [#5 — Fixar origem, fonte e identidade da engine Sikarugir 11.0](https://github.com/ElvisBaggio/notproton/issues/5) | engine_audit / gpt-6.1-sol | opus | revisão do plano |
| T02 | [#6 — Inventariar Steam/jogo e preparar restauração verificável](https://github.com/ElvisBaggio/notproton/issues/6) | baseline_recovery / gpt-6.1-sol | sonnet | revisão do plano |
| E2 | [#2 — Viabilidade da ponte Wine–Steam](https://github.com/ElvisBaggio/notproton/issues/2) | astra_coordinator / gpt-6-astra | opus para revisão; Astra coordena | gate dos filhos |
| T03 | [#7 — Compilar a ponte e o shim para a fonte exata do Sikarugir](https://github.com/ElvisBaggio/notproton/issues/7) | wine_bridge / gpt-6.1-sol | opus | [#5](https://github.com/ElvisBaggio/notproton/issues/5) |
| T04 | [#8 — Resolver e validar os patches ntdll específicos da engine](https://github.com/ElvisBaggio/notproton/issues/8) | ntdll_port / gpt-6.1-sol | opus | [#5](https://github.com/ElvisBaggio/notproton/issues/5), [#7](https://github.com/ElvisBaggio/notproton/issues/7) |
| T05 | [#9 — Provar Steam API real pelo motor isolado — gate de viabilidade](https://github.com/ElvisBaggio/notproton/issues/9) | bridge_probe / gpt-6.1-sol | opus | [#6](https://github.com/ElvisBaggio/notproton/issues/6), [#7](https://github.com/ElvisBaggio/notproton/issues/7), [#8](https://github.com/ElvisBaggio/notproton/issues/8) |
| E3 | [#3 — Integração do runner no NotProton](https://github.com/ElvisBaggio/notproton/issues/3) | astra_coordinator / gpt-6-astra | opus para revisão; Astra coordena | gate dos filhos |
| T06 | [#10 — Adicionar origem Sikarugir ao catálogo e aos caminhos do runner](https://github.com/ElvisBaggio/notproton/issues/10) | runner_model / gpt-6.1-sol | sonnet | [#9](https://github.com/ElvisBaggio/notproton/issues/9) |
| T07 | [#11 — Integrar cópia, patch, instalação e reparo sem dependência CrossOver](https://github.com/ElvisBaggio/notproton/issues/11) | runner_lifecycle / gpt-6.1-sol | opus | [#10](https://github.com/ElvisBaggio/notproton/issues/10) |
| T08 | [#12 — Adaptar launcher, prefixos e ferramentas Wine ao motor fixado](https://github.com/ElvisBaggio/notproton/issues/12) | launch_prefix / gpt-6.1-sol | sonnet | [#11](https://github.com/ElvisBaggio/notproton/issues/11) |
| T09 | [#13 — Expor ferramenta na interface e empacotar o fork sem atualização indevida](https://github.com/ElvisBaggio/notproton/issues/13) | app_integration / gpt-6.1-sol | sonnet | [#12](https://github.com/ElvisBaggio/notproton/issues/12) |
| E4 | [#4 — Cities II jogável com saves e rollback](https://github.com/ElvisBaggio/notproton/issues/4) | astra_coordinator / gpt-6-astra | opus para revisão; Astra coordena | gate dos filhos |
| T10 | [#14 — Implantar com backup e testar retorno ao estado anterior](https://github.com/ElvisBaggio/notproton/issues/14) | deployment_validation / gpt-6.1-sol | sonnet | [#6](https://github.com/ElvisBaggio/notproton/issues/6), [#13](https://github.com/ElvisBaggio/notproton/issues/13) |
| T11 | [#15 — Instalar Cities II em biblioteca isolada e abrir pelo Steam nativo](https://github.com/ElvisBaggio/notproton/issues/15) | cities_integration / gpt-6.1-sol | sonnet | [#14](https://github.com/ElvisBaggio/notproton/issues/14) |
| T12 | [#16 — Validar sessão, save/reabertura e entregar operação documentada](https://github.com/ElvisBaggio/notproton/issues/16) | acceptance_docs / gpt-6-luna | sonnet | [#15](https://github.com/ElvisBaggio/notproton/issues/15) |

## Execução e estado

Estado inicial: 4 épicos e 12 cards em Todo, com Prontidão = Aguarda revisão do plano. Os cards têm relação nativa de sub-issue com o épico e bloqueadores nativos entre tarefas.

O plano usa subagentes por card e revisão independente. Após sua revisão por Elvis, liberar T01/T02; os demais só avançam após dependências e gates. Modelos indicados não são contas GitHub nem representam agentes já executando.

T01/T02 podem ocorrer em paralelo em territórios distintos. T03–T12 são sequenciais pelo acoplamento das interfaces. Ao fechar cada card, incluir evidência, commit, checks e sincronizar Status; o épico só fecha depois de seus filhos e gate.

Nenhuma implementação começou. Runtime, save/reabertura e rollback continuam não executados.
