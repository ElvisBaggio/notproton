# Handoff

Atualizado: 2026-10-09 · Agente: codex · Modelo efetivo: gpt-6.1-sol · Máquina: mac

## T03 — PASS de build reproduzível (2026-10-09, Agente: codex)

**Revisão Claude Code Opus 5.5 (2026-10-09): aprovado e integrado em `codex/game-agnostic-scope`.** Conferido: hashes dos três artefatos; `steam.exe` sem libc++/libunwind/msvcp/vcruntime dinâmicos (só Win32 + UCRT); `lsteamclient.so` x86_64 com `@rpath/ntdll.so` + `LC_RPATH @loader_path/`; os 11 símbolos Wine/Nt que a `.so` importa existem na `ntdll.so` do Sikarugir; `--artifacts` e negativos PASS. Não refeito por mim: rebuild limpo (reprodutibilidade fica pela evidência do Codex). Mudança de comportamento: `steam.exe` externo não inicializa OpenVR (status VR ~0). UCRT/`api-ms-win-crt` e `ucrtbase` precisam existir na engine; T05 confirma.

**Estado.** Cliente codex, papel wine_bridge, modelo efetivo gpt-6.1-sol; branch `codex/t03-bridge-sikarugir`. Decisão `b441be3` integrada antes da retomada. `make bridge-sikarugir`: lsteamclient Unix/PE na base Wine 11.0 verificada; steam.exe externo com llvm-mingw T01 e runtime C++ estática. Gate positivo e sete negativos PASS; controle real com C++ dinâmica recusado. `file`/`otool`/`llvm-objdump`, exports Unix e layout adjacente à ntdll Sikarugir conferidos estaticamente. Reconfigure/rebuild do zero produziu os mesmos três hashes brutos. `make -n bridge` idêntico ao anterior. Evidência completa em `docs/evidence/bridge-build.md`, preservando o BLOCKED anterior.

**Artefatos.** Sob `scratch/sikarugir/bridge/` (ignorados): `steam.exe` SHA-256 `56979db411cb12b48610c09b8fc01db3c34bb3c7e31ea53f1b17dafaf7f98b70`; `x86_64-windows/lsteamclient.dll` `2933ac86d886f1264fabfbb97f21f53967452fca2397f29ecdbd29f83616c7ac` (também cópia flat); `x86_64-unix/lsteamclient.so` `3dd9b54f642ad73bc8f24c3b71de65b38ef35de6424456126b9060d1fa74fdea`. Manifesto local `manifest.json`. ntdll upstream não distribuída.

**Próximo passo.** Pedido de revisão independente Claude Code Opus 5.5 na issue #7; registrar modelo efetivo do revisor. Issue permanece aberta e Project In Progress até revisão/aceite. T04 segue sua dependência; nenhum probe/runtime T05 iniciado por este card.

**Bloqueios e limites.** Bloqueio de build removido; revisão independente pendente. Nenhum runtime Wine executado. T05 deve verificar a extensão pública kernel32 de conversão de caminhos, CP_UNIXCP/NT flags, API Steam real e personalizações Sikarugir (HideWineExports/apply_binary_patches). OpenVR Linux já indisponível no shim PE; i386 somente quando requerido. Shellcheck indisponível; sintaxe shell e checks aplicáveis PASS. Wrapper/engine instalada/prefixos/Steam/NotProton/saves e artefatos originais T01 preservados.

## T03 — BLOCKED histórico (2026-10-09, Agente: codex)

**Estado.** Cliente codex, papel wine_bridge, modelo efetivo gpt-6.1-sol; branch `codex/t03-bridge-sikarugir`. Lock schemaVersion 2/ABI PASS copiado e fonte Wine 11.0 em commit `db11d0fe6a169c457e23d007e20404643d067aa8` conferida. TDD RED e tentativa real de registro do build confirmam base sem `WINE_EXTERNAL`, `EXTERNAL_SUBDIRS` e `CXX_PE_LIBS`/bibliotecas C++ PE exigidos pelo shim atual. Check read-only em `bridge/tests/sikarugir-buildcheck.sh`; evidências em `docs/evidence/bridge-build.md`. Sete recusas negativas PASS, gate positivo RED esperado. Scripts de produção/Makefile preservados após remoção dos experimentos; nenhum artefato compilado.

**Próximo passo.** Revisão solicitada para Claude Code Opus 5.5 e decisão sobre adaptação do shim ao build Wine 11.0. Revisor deve registrar modelo efetivo. Não substituir implicitamente a base por 11.15 nem encerrar T03.

**Bloqueios.** Condição de parada T03: interfaces de build ausentes na base verificada. Hashes de saída, otool/file e rebuild NOT RUN; runtime e integração não liberados. T01/T02 continuam concluídos. Nenhuma gravação nos originais T01, wrapper, engine instalada, Steam, prefixos ou saves.

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

1. T03 concluído e integrado (`c983e5e`; build separado aprovado por Elvis). T01 e T02 concluídos.
2. T04: preparo revisado em `claude/t04-ntdll-prep` (`3096c26`; pins x86_64/i386 do binário Sikarugir, patcher por manifesto). Falta: payloads com os artefatos de T03, aplicar em cópia, `payloadHash`/`patchedHash`, recusa de reaplicação no binário real.
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
