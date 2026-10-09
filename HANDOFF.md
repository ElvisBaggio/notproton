# Handoff

Atualizado: 2026-10-09 · Agente: codex · Máquina: mac

## Estado

- Escopo efetivo em 2026-10-09: instalar jogos Windows e iniciar pelo Steam nativo Mac, com Sikarugir 11.0 revision 0 fixado inicialmente e sem CrossOver. Cities II é teste opcional posterior, sem gate de localização/build/Cloud para a base. Não promete todos os jogos nem múltiplas engines.
- Branch atual de reescopo: `codex/game-agnostic-scope`. Todos os cards #1–#16: Prontidão = Aguarda revisão do plano novo; Status diferente de Done. Implementação/probes suspensos; aprovações e bloqueios abaixo pertencem ao histórico anterior.
- **Recado para Claude Code Opus:** ler `docs/reviews/claude-opus-scope-review.md` e revisar objetivos, origem/ABI e marcos; publicar findings em arquivo/PR. Nenhuma sessão Claude iniciada; não implementar durante revisão pendente.
- #18 permanece aberto/não Done; não prova o runtime integrado.
- Histórico do escopo anterior: especificação e plano aprovados para execução incremental em 2026-10-08: autorização explícita de Elvis e revisão independente Astra. T01/T02 liberados; predecessores e gates continuam obrigatórios.
- Base: NotProton v1.1.0, commit `05a27874798ffbffb8e64a37595bde6f16d5320a`.
- Branch de documentação: `codex/sikarugir-cities2-design`; `origin` aponta ao repositório pessoal privado https://github.com/ElvisBaggio/notproton e `upstream` ao projeto original.
- Especificação: `docs/superpowers/specs/2026-10-08-sikarugir-cities2-design.md`.
- Project: https://github.com/users/ElvisBaggio/projects/8. Épicos #1–#4 e cards #5–#16; índice em `PROJECT.md`.
- Revisão do plano: PR draft https://github.com/ElvisBaggio/notproton/pull/17. Readback confirmou 16 itens Todo, 12 relações pai/filho e 14 dependências nativas, todos com papéis/modelos preenchidos.
- Papéis e modelos nos cards e em `docs/AGENT_EXECUTION.md`; `CLAUDE.md` importa `AGENTS.md`.
- Atualização de fonte na branch `codex/sikarugir-ubisoft-1.1.1`: fix agregado upstream 1.1.1 no shim para descoberta Steam pelo Ubisoft Connect, versão 1.1.1 e regressão host. Card de manutenção #18. NotProton instalado permanece 1.1.0; nenhuma implantação/runtime executados.
- T01/T02 retomados por subagentes `engine_audit` e `baseline_recovery`, ambos Codex / `gpt-6.1-sol`. Evidências em `docs/evidence/engine-baseline.md` e `system-baseline.md`; ensaio de recuperação isolado passou.
- T01 bloqueado: pacote oficial e cinco hashes conferidos, mas fonte/patchset correspondentes não identificados. T02 parcial/bloqueado: cliente Steam observado 1791415817 sem compatibilidade comprovada, jogo/build/Cloud ainda sem validação. Backup independente de quatro saves locais (77.406.562 bytes), conferido em 2026-10-09; não cobre Cloud ou instalação. Ubisoft Connect não encontrado no prefixo.
- Fix #18: teste antes falhou e depois passou; `bridgecheck` e `routecheck` passaram. Build PE e descoberta real no Ubisoft permanecem NOT RUN; ver `docs/evidence/ubisoft-1.1.1.md`.

- Continuação em 2026-10-09 autorizada por Elvis: T01/T02 executados por `engine_audit_resume` e `baseline_recovery_resume` (gpt-6.1-sol), revisão `astra_cards_review` (gpt-6-astra). Alterações locais anteriores preservadas. Busca direta em usuários, volumes, aplicações e demais raízes acessíveis não localizou executável/manifesto/DLL; erros de acesso/timeout registrados, sem prova de ausência global.

## Próximo passo

1. Claude Code Opus revisa o reescopo e registra findings em arquivo/PR; recado compartilhado em `docs/reviews/claude-opus-scope-review.md`. Não iniciar sessão automaticamente.
2. Após aprovação explícita da revisão, completar T01 (fonte/patchset exatos) e T02 (Steam/NotProton/wrapper, suporte real do cliente, espaço e recuperação geral). Localização/build/Cloud do Cities II não bloqueiam a base.
3. Cumprir T03–T05: ABI real, patches exatos, probe com AppID legítimo selecionado e Steam nativo; depois integração/assinatura T06–T09 e rollback T10.
4. T11 instala jogo Windows simples novo em biblioteca isolada pelo Steam nativo; T12 (Luna 6) comprova >=15 min e persistência/reabertura, save quando suportado ou dados pertinentes/configuração caso contrário. Teste Cities II posterior é opcional.

Regra de modelos: Astra planeja e revisa; implementação padrão por `gpt-6.1-sol` ou `gpt-6-luna`, incluindo scripts de prova e testes. Pedido posterior de Elvis autoriza **Claude Code como alternativa**, com aliases `sonnet`/`opus` definidos por card e modelo efetivo registrado ao iniciar. Não trocar cliente/modelo automaticamente nem editar o mesmo território em paralelo.

## Bloqueios / decisões pendentes (histórico anterior ao reescopo; prevalece Estado acima)

- Ponte upstream preparada com Wine 11.15; engine observada no wrapper é Sikarugir 11.0. Viabilidade ainda não comprovada.
- Fonte exata da engine, versão efetiva do Steam e configuração gráfica carregada precisam de validação na execução do plano.
- Localização atual do Cities II precisa ser confirmada; o antigo drive S: aponta para diretório ausente. Em 2026-10-09 Elvis esclareceu que Cities usa Steam Windows instalado no Wine. Este é o fluxo de referência informado por ele; o objetivo permanece Steam nativo com Sikarugir. Não houve validação runtime pelo agente.
- NotProton 1.1.0 e pasta de suporte já existem; inventariar e preparar rollback antes de futura implantação.
- Execução dos cards autorizada explicitamente por Elvis em 2026-10-08; branch `codex/sikarugir-card-execution`, após o fix #18 preservado. Sol 6.1 executa T01/T02 e demais cards atribuídos; Luna 6 executará T12. Revisão Astra aprovou plano incremental: fonte exata e prova real continuam bloqueantes, sem pular T03–T12.
- Atualizar issue e Project ao terminar cada card; não encerrar gates sem evidência funcional. Nunca publicar trabalho pessoal no upstream sem autorização.
