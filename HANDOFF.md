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
- Atualização de fonte na branch `codex/sikarugir-ubisoft-1.1.1`: fix agregado upstream 1.1.1 no shim para descoberta Steam pelo Ubisoft Connect, versão 1.1.1 e regressão host. Card de manutenção #18. NotProton instalado permanece 1.1.0; nenhuma implantação/runtime executados.
- T01/T02 retomados por subagentes `engine_audit` e `baseline_recovery`, ambos Codex / `gpt-6.1-sol`. Evidências em `docs/evidence/engine-baseline.md` e `system-baseline.md`; ensaio de recuperação isolado passou.
- T01 bloqueado: pacote oficial e cinco hashes conferidos, mas fonte/patchset correspondentes não identificados. T02 parcial: cliente Steam observado 1791415817, jogo/build/Cloud ainda sem validação. Ubisoft Connect não encontrado no prefixo.
- Fix #18: teste antes falhou e depois passou; `bridgecheck` e `routecheck` passaram. Build PE e descoberta real no Ubisoft permanecem NOT RUN; ver `docs/evidence/ubisoft-1.1.1.md`.

## Próximo passo

1. Resolver fonte e patchset exatos da engine em T01 (#5); não consumir o lock incompleto em T03.
2. Completar T02 (#6): localização/build do jogo, Steam Cloud, compatibilidade efetiva do cliente Steam e backup do estado imediatamente anterior ao deploy.
3. Compilar shim corrigido e ponte contra fonte validada em ambiente isolado; cumprir T05 (#9) antes da integração do app.
4. Validar descoberta real pelo Ubisoft Connect com shim 1.1.1 em prefixo isolado e cenário comparável 1.1.0; não usar o Steam Windows original como prova.

Regra de modelos: Astra planeja e revisa; implementação padrão por `gpt-6.1-sol` ou `gpt-6-luna`, incluindo scripts de prova e testes. Pedido posterior de Elvis autoriza **Claude Code como alternativa**, com aliases `sonnet`/`opus` definidos por card e modelo efetivo registrado ao iniciar. Não trocar cliente/modelo automaticamente nem editar o mesmo território em paralelo.

## Bloqueios / decisões pendentes

- Ponte upstream preparada com Wine 11.15; engine observada no wrapper é Sikarugir 11.0. Viabilidade ainda não comprovada.
- Fonte exata da engine, versão efetiva do Steam e configuração gráfica carregada precisam de validação na execução do plano.
- Localização atual do Cities II precisa ser confirmada; o antigo drive S: aponta para diretório ausente. Elvis afirma que consegue abrir o jogo pelo Sikarugir.
- NotProton 1.1.0 e pasta de suporte já existem; inventariar e preparar rollback antes de futura implantação.
- Pedido de retomada e delegação em 2026-10-08 libera revisão e preparação T01/T02 e manutenção #18. Não libera dependências/gates de T03–T12: fonte exata e prova real continuam bloqueantes.
- Atualizar issue e Project ao terminar cada card; não encerrar gates sem evidência funcional. Nunca publicar trabalho pessoal no upstream sem autorização.
