# Handoff

Atualizado: 2026-10-09 · Agente: claude (Claude Code, modelo efetivo `claude-opus-5-5`, alias `opus`) · Máquina: mac

## Estado

- Escopo: instalar jogos Windows e iniciá-los pelo Steam nativo do Mac com Sikarugir 11.0 revision 0, sem CrossOver. Cities II é opcional posterior; não há promessa de compatibilidade universal ou suporte a múltiplas engines.
- Branch: `codex/game-agnostic-scope`; base NotProton 1.1.0 em `05a27874798ffbffb8e64a37595bde6f16d5320a`.
- Claude Code Sonnet 5.5 concluiu a revisão do reescopo em `8462af8`, recomendando **aprovar com ajustes F1–F8**. Findings em `docs/reviews/claude-scope-review-findings.md`.
- Decisões de Elvis: F1 gerar perfil de assinatura para o build Steam atual; F2 pedir ao mantenedor o manifesto da engine; F4 escolher o jogo depois do inventário T02. Pedido público ao mantenedor: https://github.com/Sikarugir-App/Sikarugir/issues/288.
- Ajustes documentais F3/F5/F6/F7/F8 sendo incorporados. T01/T02 só começam depois desses ajustes e da sincronização dos cards; podem rodar em paralelo, em worktrees separados. Pela D2-c (replanejamento `eaf350c`), o gate de T01 passou a ser ABI verificada no binário. Ele resultou em PASS nas superfícies (a)–(d) (ver seção T01 abaixo), mas T03 só começa depois da revisão e da liberação do coordenador.
- #18 permanece aberto/não Done e não demonstra integração/runtime.
- Especificação e plano: `docs/superpowers/specs/2026-10-08-sikarugir-cities2-design.md` e `docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md`. Project: https://github.com/users/ElvisBaggio/projects/8. Papéis e modelos: `docs/AGENT_EXECUTION.md`.
- NotProton instalado continua 1.1.0; a fonte local é 1.1.1. Nada foi implantado no Steam. Gates de API real, jogo Windows, sessão persistente e rollback seguem NOT RUN.

## T01 — verificação de ABI pelo binário (D2-c), 2026-10-09

- Branch `claude/t01-abi-check` (base `origin/codex/t01-engine-provenance`). Executor: Claude Code, modelo efetivo `claude-opus-5-5`.
- `abiCheck.status=PASS` para upstream `wine-11.0` (`db11d0fe6a169c457e23d007e20404643d067aa8`) × Sikarugir 11.0 r0 nas superfícies (a)–(d). Houve 11 divergências, todas irrelevantes com evidência e nenhuma bloqueante. O negativo com a ntdll 11.x do CrossOver falha como esperado (25 divergências, exit 1). Detalhes em `docs/evidence/engine-baseline.md` (seção D2-c) e em `docs/evidence/engine-abi-report.md`.
- Entregas: `ntdll-patch/tests/abi_compare.py`, que usa só stdlib, `nm` e `llvm-objdump`; `ntdll-patch/tests/abi_justifications-sikarugir-11.0-r0.json`, preso aos hashes do par; `scratch/sikarugir/engine-lock.json` local, com schemaVersion 2 e `provenanceMode=binary-abi-verified`. A toolchain (llvm-mingw 20260826/20261006, bison 3.8.2, m4 1.4.19) e os builds ficam só em `scratch/` deste worktree, sem instalação global.
- Atenção para T03: lsteamclient.so tem de resolver `@rpath/ntdll.so` para a ntdll da cópia da engine, ou seja, ficar no mesmo `x86_64-unix`.
- Atenção para T04: build_module da Sikarugir contém `apply_binary_patches`, e os pins têm de vir do binário Sikarugir. `resolve.py` falha em x86_64 tanto no upstream 11.0 quanto na Sikarugir ("load_path slot rewritten"); em i386 resolve.
- Risco residual: personalizações fora das superfícies comparadas (HideWineExports, hacks por processo Steam, msync, Rosetta, D3DMetal). Só T05 cobre isso. Nenhum runtime foi executado.
- Pendências: revisão Claude Code Opus 5.5; Astra/coordenador decidir se T01 vira Done e se T03 é liberado; fundir o plano replanejado (`eaf350c`, em `codex/game-agnostic-scope`) com esta linha. A cópia do plano nesta branch é anterior ao D2-c. O pedido #288 segue aberto.

## Próximo passo

1. Finalizar e revisar F1–F8 no plano/spec/PROJECT e sincronizar descrição/prontidão dos cards.
2. T01: revisar o PASS de ABI (D2-c) e decidir a liberação de T03. Se o manifesto do mantenedor chegar, trocar para `provenanceMode=maintainer-source`. T02 migra o manifesto para o schema atual, valida perfil Steam do build 1791415817 e ensaio de recuperação.
3. Após T01/T02, executar T03–T05 em sequência: ABI/patches exatos, depois API real com AppID selecionado segundo D1 e Steam nativo. Em seguida T06–T09 e T10.
4. T11 instala jogo Windows novo em biblioteca isolada pelo Steam nativo; T12 (Luna 6) comprova >=15 min e persistência/reabertura, save quando suportado ou dados pertinentes/configuração caso contrário. Cities II permanece teste posterior opcional.

Regra de modelos: Astra planeja e revisa; implementação padrão por `gpt-6.1-sol` ou `gpt-6-luna`, incluindo scripts de prova e testes. Pedido posterior de Elvis autoriza **Claude Code como alternativa**, com aliases `sonnet`/`opus` definidos por card e modelo efetivo registrado ao iniciar. Não trocar cliente/modelo automaticamente nem editar o mesmo território em paralelo.

## Histórico anterior ao reescopo

- Ponte upstream preparada com Wine 11.15; engine observada no wrapper é Sikarugir 11.0. Viabilidade ainda não comprovada.
- Fonte exata da engine, versão efetiva do Steam e configuração gráfica carregada precisam de validação na execução do plano.
- Localização atual do Cities II precisa ser confirmada; o antigo drive S: aponta para diretório ausente. Em 2026-10-09 Elvis esclareceu que Cities usa Steam Windows instalado no Wine. Este é o fluxo de referência informado por ele; o objetivo permanece Steam nativo com Sikarugir. Não houve validação runtime pelo agente.
- NotProton 1.1.0 e pasta de suporte já existem; inventariar e preparar rollback antes de futura implantação.
- Em 2026-10-08, Elvis havia autorizado a execução do plano anterior na branch `codex/sikarugir-card-execution`; revisão Astra aprovou o plano incremental. Esse estado é histórico e não substitui os ajustes atuais F1–F8.
- Atualizar issue e Project ao terminar cada card; não encerrar gates sem evidência funcional. Nunca publicar trabalho pessoal no upstream sem autorização.
