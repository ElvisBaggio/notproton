# Handoff

Atualizado: 2026-10-09 · Agente: claude (Opus 5.5) · Máquina: mac

## Estado

- Escopo: instalar jogos Windows e iniciá-los pelo Steam nativo do Mac com Sikarugir 11.0 revision 0, sem CrossOver. Cities II é opcional posterior; não há promessa de compatibilidade universal ou suporte a múltiplas engines.
- Branch: `codex/game-agnostic-scope`; base NotProton 1.1.0 em `05a27874798ffbffb8e64a37595bde6f16d5320a`.
- Claude Code Sonnet 5.5 concluiu a revisão do reescopo em `8462af8`, recomendando **aprovar com ajustes F1–F8**. Findings em `docs/reviews/claude-scope-review-findings.md`.
- Decisões de Elvis: F1 gerar perfil de assinatura para o build Steam atual; F2 pedir ao mantenedor o manifesto da engine; F4 escolher o jogo depois do inventário T02. Pedido público ao mantenedor: https://github.com/Sikarugir-App/Sikarugir/issues/288.
- Ajustes F1–F8 aplicados ao plano/spec e aos cards #5, #6, #9, #11, #12 e #15; prontidão dos outros itens reflete dependências, sem rótulo de revisão pendente. Requisição de revisão Opus 5.5 foi deixada na PR #21 e nos cards concluídos.
- **T01 replanejado (2026-10-09, decisão de Elvis D2-c):** a fonte exata do mantenedor deixa de ser gate. Novo aceite: base upstream `wine-11.0` (`db11d0fe`) com ABI verificada no binário (exports, syscalls, unix calls, funções-alvo dos hooks) contra a ntdll do Sikarugir; lock vai a schemaVersion=2 com `provenanceMode`, `baseSource` e `abiCheck`. Pedido #288 segue aberto (reforçar com LGPL); se a fonte chegar, substitui a verificação. Trabalho anterior: branch `codex/t01-engine-provenance`, commit `40e8c58` (hashes/versão/arquiteturas revalidados; passo 1 concluído). Issue #5 volta a pronta para execução com o novo aceite.
- T02: branch `codex/t02-steam-baseline`, commit `a073897`; schema/readback atualizados e ensaio descartável PASS; bloqueio restante é o perfil Steam exato para build `1791415817`. **Em execução por Claude Code `sonnet`** (subagente) na branch `claude/t02-steam-profile`, derivada de `a073897`; não editar `codex/t02-steam-baseline` em paralelo. `sigcheck.py` confirma nomes, não anchors ou build. Issue #6 mantém In Progress e prontidão bloqueada.
- T01/T02 não foram integrados à branch de reescopo; commits estão publicados em branches próprios aguardando revisão Opus 5.5. T03–T12 continuam bloqueados por proveniência/perfil e dependências.
- #18 permanece aberto/não Done e não demonstra integração/runtime.
- Especificação e plano: `docs/superpowers/specs/2026-10-08-sikarugir-cities2-design.md` e `docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md`. Project: https://github.com/users/ElvisBaggio/projects/8. Papéis e modelos: `docs/AGENT_EXECUTION.md`.
- NotProton instalado continua 1.1.0; a fonte local é 1.1.1. Nada foi implantado no Steam. Gates de API real, jogo Windows, sessão persistente e rollback seguem NOT RUN.

## Próximo passo

1. T01: executar o card replanejado (toolchain local mingw-w64/bison em scratch, build upstream 11.0, comparador de ABI). T02: concluir o perfil `1791415817` em `claude/t02-steam-profile`. Nenhum dos dois fecha por evidência estática parcial.
2. Revisar os commits/solicitações Opus 5.5 nos cards #5 e #6 antes de integrá-los; não fechar nenhum gate por evidência estática.
3. Só depois da proveniência e do perfil Steam aprovados, retomar T03–T05 em sequência; escolher AppID conforme D1 depois do inventário. Em seguida T06–T09 e T10.
4. T11 instala jogo Windows novo em biblioteca isolada pelo Steam nativo; T12 (Luna 6) comprova >=15 min e persistência/reabertura, save quando suportado ou dados pertinentes/configuração caso contrário. Cities II permanece teste posterior opcional.

Regra de modelos: Astra planeja e revisa; implementação padrão por `gpt-6.1-sol` ou `gpt-6-luna`, incluindo scripts de prova e testes. Pedido posterior de Elvis autoriza **Claude Code como alternativa**, com aliases `sonnet`/`opus` definidos por card e modelo efetivo registrado ao iniciar. Não trocar cliente/modelo automaticamente nem editar o mesmo território em paralelo.

## Histórico anterior ao reescopo

- Ponte upstream preparada com Wine 11.15; engine observada no wrapper é Sikarugir 11.0. Viabilidade ainda não comprovada.
- Fonte exata da engine, versão efetiva do Steam e configuração gráfica carregada precisam de validação na execução do plano.
- Localização atual do Cities II precisa ser confirmada; o antigo drive S: aponta para diretório ausente. Em 2026-10-09 Elvis esclareceu que Cities usa Steam Windows instalado no Wine. Este é o fluxo de referência informado por ele; o objetivo permanece Steam nativo com Sikarugir. Não houve validação runtime pelo agente.
- NotProton 1.1.0 e pasta de suporte já existem; inventariar e preparar rollback antes de futura implantação.
- Em 2026-10-08, Elvis havia autorizado a execução do plano anterior na branch `codex/sikarugir-card-execution`; revisão Astra aprovou o plano incremental. Esse estado é histórico e não substitui os ajustes atuais F1–F8.
- Atualizar issue e Project ao terminar cada card; não encerrar gates sem evidência funcional. Nunca publicar trabalho pessoal no upstream sem autorização.
