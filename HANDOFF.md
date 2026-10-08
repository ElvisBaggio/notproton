# Handoff

Atualizado: 2026-10-08 · Agente: codex · Máquina: mac

## Estado

- Projeto pessoal: Cities: Skylines II pelo Steam nativo com NotProton e motor Sikarugir, sem depender de CrossOver.
- Especificação aprovada; plano detalhado preparado em `docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md`, aguardando revisão antes da implementação.
- Base: NotProton v1.1.0, commit `05a27874798ffbffb8e64a37595bde6f16d5320a`.
- Branch de documentação: `codex/sikarugir-cities2-design`; `origin` aponta ao repositório pessoal privado https://github.com/ElvisBaggio/notproton e `upstream` ao projeto original.
- Especificação: `docs/superpowers/specs/2026-10-08-sikarugir-cities2-design.md`.
- Project: https://github.com/users/ElvisBaggio/projects/8. Épicos #1–#4 e cards #5–#16; índice em `PROJECT.md`.
- Revisão do plano: PR draft https://github.com/ElvisBaggio/notproton/pull/17. Readback confirmou 16 itens Todo, 12 relações pai/filho e 14 dependências nativas, todos com papéis/modelos preenchidos.
- Papéis e modelos nos cards e em `docs/AGENT_EXECUTION.md`; `CLAUDE.md` importa `AGENTS.md`.
- Apenas investigação somente leitura e documentação. Nenhuma implementação ou teste de runtime foi executado.

## Próximo passo

1. Elvis revisa o plano e confirma execução por subagentes, com revisão independente por card.
2. Após revisão, liberar T01 (#5)/T02 (#6); demais cards seguem dependências nativas.
3. Respeitar gate de prova real da ponte em T05 (#9) antes da integração do app.

Regra de modelos: Astra planeja e revisa; implementação padrão por `gpt-6.1-sol` ou `gpt-6-luna`, incluindo scripts de prova e testes. Pedido posterior de Elvis autoriza **Claude Code como alternativa**, com aliases `sonnet`/`opus` definidos por card e modelo efetivo registrado ao iniciar. Não trocar cliente/modelo automaticamente nem editar o mesmo território em paralelo.

## Bloqueios / decisões pendentes

- Ponte upstream preparada com Wine 11.15; engine observada no wrapper é Sikarugir 11.0. Viabilidade ainda não comprovada.
- Fonte exata da engine, versão efetiva do Steam e configuração gráfica carregada precisam de validação na execução do plano.
- Localização atual do Cities II precisa ser confirmada; o antigo drive S: aponta para diretório ausente. Elvis afirma que consegue abrir o jogo pelo Sikarugir.
- NotProton 1.1.0 e pasta de suporte já existem; inventariar e preparar rollback antes de futura implantação.
- Plano publicado ainda precisa de revisão para iniciar execução. Estado inicial: Todo e Aguarda revisão do plano.
- Atualizar issue e Project ao terminar cada card; não encerrar gates sem evidência funcional. Nunca publicar trabalho pessoal no upstream sem autorização.
