# Handoff

Atualizado: 2026-10-09 · Agente: claude (Opus 5.5) · Máquina: mac

## Atualização T02 (claude, branch `claude/t02-steam-profile`)

**Estado.** Perfil `signatures/macos.arm64/1791415817.json` gerado para o build Steam ativo **1791415817** (confirmado por `content_log.txt`, `bootstrap_log.txt` e manifesto `publicbeta` instalado). Validação **estática**: 18/18 assinaturas resolvidas por âncora nas cópias em `scratch/steam-1791415817/`, padrões de bytes únicos, endereços e 8 vptrs RTTI conferidos por decodificação independente, `sigcheck.py` passa com 4 perfis. Ferramentas novas: `dylib/tests/sigstatic.c` (resolve sem `dlopen`) e `dylib/tests/sigprofile.py` (gera o JSON). Detalhes, hashes e limites em `docs/evidence/system-baseline.md`.

**Próximo passo.** Revisão Claude Code Opus 5.5 aprovada (issue #6); `anchorcheck` real PASS em 2026-10-09 (18/18, 8/8 vptrs); **integrado a `codex/game-agnostic-scope`** (merge desta branch). T05/T10 passam a ter perfil para o build ativo; se o Steam atualizar, regerar com `sigstatic --emit` + `sigprofile.py`.

**Bloqueios.** Bloqueio do perfil removido. T02 com aceite cumprido (perfil validado estático + `anchorcheck` real, revisão aprovada). Perfil ainda não implantado e loader/hooks não exercitados — isso é T07/T10. T01 concluído e integrado (ABI D2-c PASS); T03 liberado.

## Estado (registro do reescopo, agente codex)

- Escopo: instalar jogos Windows e iniciá-los pelo Steam nativo do Mac com Sikarugir 11.0 revision 0, sem CrossOver. Cities II é opcional posterior; não há promessa de compatibilidade universal ou suporte a múltiplas engines.
- Branch: `codex/game-agnostic-scope`; base NotProton 1.1.0 em `05a27874798ffbffb8e64a37595bde6f16d5320a`.
- Claude Code Sonnet 5.5 concluiu a revisão do reescopo em `8462af8`, recomendando **aprovar com ajustes F1–F8**. Findings em `docs/reviews/claude-scope-review-findings.md`.
- Decisões de Elvis: F1 gerar perfil de assinatura para o build Steam atual; F2 pedir ao mantenedor o manifesto da engine; F4 escolher o jogo depois do inventário T02. Pedido público ao mantenedor: https://github.com/Sikarugir-App/Sikarugir/issues/288.
- Ajustes F1–F8 aplicados ao plano/spec e aos cards #5, #6, #9, #11, #12 e #15; prontidão dos outros itens reflete dependências, sem rótulo de revisão pendente. Requisição de revisão Opus 5.5 foi deixada na PR #21 e nos cards concluídos.
- **T01 replanejado (2026-10-09, decisão de Elvis D2-c):** a fonte exata do mantenedor deixa de ser gate. Novo aceite: base upstream `wine-11.0` (`db11d0fe`) com ABI verificada no binário (exports, syscalls, unix calls, funções-alvo dos hooks) contra a ntdll do Sikarugir; lock vai a schemaVersion=2 com `provenanceMode`, `baseSource` e `abiCheck`. Pedido #288 segue aberto (reforçar com LGPL); se a fonte chegar, substitui a verificação. Trabalho anterior: branch `codex/t01-engine-provenance`, commit `40e8c58` (hashes/versão/arquiteturas revalidados; passo 1 concluído). Issue #5 volta a pronta para execução com o novo aceite.
- T02: **aceite cumprido e integrado** a esta branch (`codex/t02-steam-baseline` `a073897` + `claude/t02-steam-profile` `ab259ab`). Perfil `1791415817` validado estaticamente e por `anchorcheck` real; revisão Opus 5.5 aprovada. Implantação do perfil e loader/hooks ficam em T07/T10.
- T01: **aceite D2-c cumprido e integrado** a esta branch (`claude/t01-abi-check` `3829312`). ABI PASS nas superfícies (a)–(d); revisão Opus 5.5 aprovada (issue #5). T03 liberado; T04–T12 seguem dependências.
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
- Revisão Claude Code Opus 5.5 aprovada e integrado em `codex/game-agnostic-scope` (plano D2-c já presente nesta linha). Reproduzidos: PASS/negativos/controle; teste de mutação confirma que a superfície (b) acusa syscall alterado. Atenção T05: `apply_binary_patches` da Sikarugir altera módulos no carregamento (inclui alvo CEF); verificar que não toca lsteamclient/steam.exe. O pedido #288 segue aberto.

## Próximo passo

1. T03: primeira tentativa BLOCKED (`dcc8a73`, `codex/t03-bridge-sikarugir`): `steam.exe` exige `WINE_EXTERNAL`/`CXX_PE_LIBS`, ausentes no 11.0. Decisão de Elvis: `lsteamclient` na árvore `wine-11.0` verificada; `steam.exe` fora da árvore com llvm-mingw (libc++ estática). Retomada pelo Codex na mesma branch. `lsteamclient.so` no `x86_64-unix` da cópia isolada da engine. T01 e T02 concluídos.
2. T04: derivar pins do binário Sikarugir e adaptar `resolve.py` em x86_64; mapear a lista de `apply_binary_patches` da Sikarugir.
3. T05 em seguida (API Steam real, AppID conforme D1); depois T06–T09 e T10. D1: candidatos em `docs/evidence/d1-game-candidates.md` (claude, 2026-10-09; principal sugerido Banana 2923300); **Elvis escolheu Halls of Torment: Prelude 2316660** (reserva Banana).
4. T11 instala jogo Windows novo em biblioteca isolada pelo Steam nativo; T12 (Luna 6) comprova >=15 min e persistência/reabertura, save quando suportado ou dados pertinentes/configuração caso contrário. Cities II permanece teste posterior opcional.

Regra de modelos: Astra planeja e revisa; implementação padrão por `gpt-6.1-sol` ou `gpt-6-luna`, incluindo scripts de prova e testes. Pedido posterior de Elvis autoriza **Claude Code como alternativa**, com aliases `sonnet`/`opus` definidos por card e modelo efetivo registrado ao iniciar. Não trocar cliente/modelo automaticamente nem editar o mesmo território em paralelo.

## Histórico anterior ao reescopo

- Ponte upstream preparada com Wine 11.15; engine observada no wrapper é Sikarugir 11.0. Viabilidade ainda não comprovada.
- Fonte exata da engine, versão efetiva do Steam e configuração gráfica carregada precisam de validação na execução do plano.
- Localização atual do Cities II precisa ser confirmada; o antigo drive S: aponta para diretório ausente. Em 2026-10-09 Elvis esclareceu que Cities usa Steam Windows instalado no Wine. Este é o fluxo de referência informado por ele; o objetivo permanece Steam nativo com Sikarugir. Não houve validação runtime pelo agente.
- NotProton 1.1.0 e pasta de suporte já existem; inventariar e preparar rollback antes de futura implantação.
- Em 2026-10-08, Elvis havia autorizado a execução do plano anterior na branch `codex/sikarugir-card-execution`; revisão Astra aprovou o plano incremental. Esse estado é histórico e não substitui os ajustes atuais F1–F8.
- Atualizar issue e Project ao terminar cada card; não encerrar gates sem evidência funcional. Nunca publicar trabalho pessoal no upstream sem autorização.
