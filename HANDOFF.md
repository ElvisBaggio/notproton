# Handoff

Atualizado: 2026-10-09 · Agente: codex · Modelo efetivo: gpt-6.1-sol · Máquina: mac

## T11 — Pré-condições PEAK preparadas (2026-10-10, Agente: claude, modelo efetivo sonnet)

Somente leitura; T11 não iniciado (depende de T10). PEAK 3527290: depot único Windows 3527291 (sem macOS), launch DX12/DX11 (`-force-d3d11`)/Vulkan, Auto-Cloud `LocalLow/LandCrab/PEAK/*.peak`; posse não verificável localmente, confirmar com Elvis. Detalhes e riscos em `docs/evidence/game-launch.md`, branch `claude/t11-peak-prep`, issue #15.

## Achados menores T01-T03 fechados (2026-10-09, Agente: claude, modelo efetivo: sonnet)

abi_compare falha na superficie (b) com 0 syscalls/contagens desiguais (+teste), buildcheck --artifacts exige LLVM_MINGW com mensagem clara, sigstatic limita rebuild_pattern a __TEXT; steam_build_date 1791415817 segue vazio (sem fonte local explicita; so o build id = epoch 2026-10-07T23:30:17Z, inferencia).

## T05 — Passo 3 PASS real, revisão pendente (2026-10-09 22:34 -03:00, Agente: codex)

**Estado.** Cliente Codex, papel bridge_probe, modelo efetivo gpt-6.1-sol, branch codex/t05-steam-probe, base cdf3be5. Steam aberto/logado por Elvis; processo confirmado antes/depois, build content_log 1791415817. Comando exato autorizado: STEAM_INIT=ok / APP_ID=3527290 / AUTHENTICATED=yes, exit0; trace real CreateSteamPipe/ConnectToGlobalUser/GetISteamUser/GetISteamUtils/GetAppID/BLoggedOn. Gate de viabilidade técnica observado PASS, ainda sem aceite independente. Logs públicos allowlist sem dados de conta; brutos só scratch. Cinco hashes wrapper + 965 entradas Frameworks + steamclient.dylib antes/depois/baseline MATCH; zero processos da engine isolada restantes. Sem controle do Steam ou mudanças originais.

**Próximo passo.** Revisão Claude Code Opus 5.5 solicitada na issue #9 (modelo efetivo do revisor pendente); Astra aceita o gate antes de integrar/liberar próximos cards. Evidência datada Passo 3 em docs/evidence/steam-api-probe.md. Issue #9 aberta; Project In Progress/Pronto.

**Bloqueios/limites.** Controle --appid480 também exit0 (init ok/AppID480/auth yes): negativo runtime não-informativo porque SteamAppId deriva de --appid; não prova propriedade/licença nem rejeição de outro jogo. Parser sobre saída480 esperando3527290 recusa exit1. Steam.exe, i386, PEAK/renderer/save/reabertura/rollback e patches em memória não testados; não encerrar T05/E2 por conta própria. Histórico preservado abaixo.



## T05 — Passo 2 PASS: negativo chega à Steam nativa (2026-10-09, Agente: codex)

**Estado.** Cliente Codex, papel bridge_probe, modelo efetivo gpt-6.1-sol, branch codex/t05-steam-probe, base 26c100e. Runner exige --steam-client para o Contents/MacOS instalado e exporta STEAM_COMPAT_CLIENT_INSTALL_PATH conforme fonte T03/launcher original. Steam fechado confirmado antes/depois; LoadLibrary/CreateInterface SteamClient021/steamclient.dylib nativa/CreateSteamPipe reais. Negativo exit1, STEAM_INIT=fail / APP_ID=0 / AUTHENTICATED=no, sem assert/c0000135/erro Unix. PASSO 2 PASS. Wrapper cinco hashes, Frameworks 965 entradas e steamclient.dylib intactos; sintaxe/check-only/negativos14/14/diff PASS. Evidência datada em docs/evidence/steam-api-probe.md.

**Próximo passo.** Revisão Claude Code Opus 5.5 solicitada na issue #9 (modelo efetivo pendente), depois passo3 Steam autenticado/PEAK3527290 com comando exato na evidência, incluindo --steam-client. Astra aceita gate após positivo.

**Bloqueios/limites.** Nenhum bloqueio no passo2. T05/E2 abertos/In Progress; positivo, steam.exe, i386, jogo/save e patches em memória não testados. Steam não iniciado pelo agente; nenhum próximo card liberado. Histórico abaixo preservado.

## T05 — Continuação do Passo 2: Unix resolvido / imports T04 BLOCKED (2026-10-09, Agente: codex)

**Estado.** Cliente Codex, papel `bridge_probe`, modelo efetivo `gpt-6.1-sol`, branch `codex/t05-steam-probe`, base `482af4c`. Steam fechado em toda a rodada. Três .so SHA-256 `d71f954c…` e manifesto T03 conferidos; LC_UUID presente. Smoke real exit1: init fail/AppID0/auth no. Interposer descartável observa dlopen da .so e dlsym Unix funcs não nulos. O trigger falha c0000135 por tier0_s64/vstdlib_s64 antes de qualquer API. Cinco hashes do wrapper + 965 entradas Frameworks intactos. Evidência nova preserva o histórico em `docs/evidence/steam-api-probe.md`.

**Próximo passo.** T04: detour.c usa máscara 0x2 errada; Wine11/Sikarugir usa 0x40000000. Trocar a máscara e limpar o bit com AND ~ (OR também é incorreto nesse ponto) antes de fixup_imports. Proposta exata na evidência, não aplicada. Rebuild/novos manifestos em cópias, revisão e repetir negativo; só depois Steam logado/passo3. Claude Code Opus 5.5 solicitado na issue #9; modelo efetivo do revisor pendente.

**Bloqueios.** `BLOCKED_T04_TRIGGER_IMPORTS`, não benigno: LoadLibraryA retorna NULL e probe não chega a CreateInterface. LC_UUID deixou de bloquear. T05/E2 abertos/In Progress. Nenhum payload ou script de produção editado; apply_binary_patches em memória NOT OBSERVED e steam.exe não executado. Positivo/autenticação e runtime i386 não testados.

## T05 — Retomada do Passo 2: prefixo PASS / Unix bridge BLOCKED (2026-10-09, Agente: codex)

**Estado.** Cliente `codex`, papel `bridge_probe`, modelo efetivo `gpt-6.1-sol`, branch `codex/t05-steam-probe`. Frameworks APFS clone completo; wineboot fresh exit0. Ambiente mínimo exige DYLD fallback da cópia após arch/Rosetta e marker `SikarugirAppWine11=1` (ntdll Unix termina exit1 sem ele). Cinco hashes originais + 965 entradas Frameworks antes/depois MATCH, fonte/cópia e symlinks/inodes verificados. Negativo real Steam fechado: init fail/AppID0/auth no, exit1; detour entrou, cave RX mapeado e lsteamclient PE carregada. Unix Mach-O rejeitado por missing LC_UUID (T03 usa -no_uuid). Evidências/logs em `docs/evidence/steam-api-probe.md` e scratch; histórico anterior preservado.

**Próximo passo.** T03 deve remover/corrigir ausência UUID com rebuild reprodutível e novo manifesto; T04 investigar resolução indevida de imports trigger (hipótese semântica do bit LDR_DONT_RESOLVE_REFS). Remontar/repetir negativo; Astra e Claude Code Opus 5.5 revisam antes do passo3 Steam autenticado/PEAK3527290. Comando exato na evidência. Sintaxe, negativos11/11, check-only e selfcheck ambient/CRLF PASS.

**Bloqueios.** LC_UUID em lsteamclient.so; negativo observado falha na montagem Unix, ainda não só ausência de sessão. apply_binary_patches em memória NOT OBSERVED; steam.exe não executado. Gate T05 não aprovado; original/prefixos/saves preservados; nenhum passo3 positivo executado.

## T05 — Passo 2 BLOCKED (2026-10-09, Agente: codex)

**Estado.** Cliente `codex`, papel `bridge_probe`, modelo efetivo `gpt-6.1-sol`, branch `codex/t05-steam-probe` de `bd1b260`. Clone APFS da engine em `scratch/t05/engine`, T04 patchadas (x86_64 `64930d7e…`, i386 `932f5d47…`), ponte T03 + trigger Valve conferidos e prefixo descartável montado. `wineboot -u` sob Rosetta saiu 1: dyld wineserver não resolve `@rpath/libinotify.0.dylib` (`no LC_RPATH's found`). Biblioteca está fora da engine, em Frameworks do wrapper. Logs e manifesto só em `scratch/t05/`; cinco hashes do wrapper antes/depois MATCH. Negativos 11/11, sintaxe, check-only e recusa de reuso do staging PASS.

**Próximo passo.** Revisão Claude Code Opus 5.5 solicitada na issue #9 (modelo efetivo do revisor pendente); preparar dependências transitivas em cópia em nova execução autorizada, repetir wineboot e negativo sem Steam. Comando exato do passo 3, condicionado a esses gates e Steam autenticado/PEAK legítimo, em `docs/evidence/steam-api-probe.md`.

**Bloqueios.** Loader wineserver; Steam nativo estava aberto e não foi encerrado pelo agente. Probe/Unix-call/hooks/cave/apply_binary_patches NOT RUN/NOT OBSERVED. Não declarar ABI falha nem viabilidade PASS. Sem mudanças em wrapper, Steam, NotProton instalado, prefixos originais ou saves; passo 3 não executado; issue aberta.

## T04 — correção LDR flags, 2026-10-09, Agente: codex

**Estado.** Cliente codex, papel ntdll_port, modelo efetivo gpt-6.1-sol, branch codex/t04-ldr-flags. Define de build ativado somente para cleanHash Sikarugir; limpa bit interno Wine11 0x40000000 após sucesso das trampolines em x64/i386. FLAGS_BIT público i386=1 auditado e preservado. 12 testes com/sem capstone PASS, rebuilds idênticos, aplicação por manifesto/diff/reapply em cópias PASS. Regressão fonte preprocessada CX idêntica; full build LLVM x64 baseline idêntico 3fb37065…; pin legado e35b8344… preservado no recurso mas rebuild GCC não reproduzido (toolchain ausente/não fixada).

**Hashes novos.** Payload x64 d73b0f846a13e062b8da4acc0fbbac62c9e43a3ad531afcf0434d1417085e15f (834 B); i386 a1305ebed9e42cc6a37a5df333d42da17de8012cca8e4deeb72f6b4a8cb5b620 (1338 B). ntdll x64 ef8e99712f845f5c4e7ee01a0475d3ccaf84114d54a0a6c962808fee34b68b29; i386 60c6a031ea679833d6f8a81e4873cb60d98815ed9f7220c2046ed58443cfcc03.

**Smoke.** Somente scratch T05 autorizado, Steam fechado. Trigger LoadLibrary/PROCESS_ATTACH PASS, CreateInterface SteamClient021 alcançada na ponte, sem c0000135. Novo bloqueio: steamclient_init não encontra biblioteca nativa via fallback DYLD (STEAM_COMPAT_CLIENT_INSTALL_PATH ausente), assert T03 aborta antes das 3 linhas do probe. Runner exit1 STEAM_INIT=None: negativo completo NOT PASS. Cinco hashes wrapper + 965 Frameworks MATCH. Evidência docs/evidence/ntdll-port.md.

**Próximo passo/bloqueios.** Revisão Astra aprovada para publicação com limites; revisão corretiva Claude Code Opus5.5 pendente; issue8 já CLOSED, apenas comentário solicitado. T05 permanece OPEN/bloqueado na descoberta da biblioteca Steam nativa; nenhum gate API/sessão liberado. Sem ponte/runtime i386, save/reabertura ou rollback funcional. Não editar territórios T03/T05 para contornar o bloqueio.

## T04 — PASS estático, revisão pendente (2026-10-09, Agente: codex)

**Estado.** Cliente `codex`, papel `ntdll_port`, modelo efetivo `gpt-6.1-sol`, branch `codex/t04-ntdll-close`. Payloads locais LLVM construídos e reproduzidos: x86_64 834/1952 B; i386 1370/4096 B. Aplicação CLI por manifesto somente em cópias, diff restrito às regiões previstas, recusas reais de reaplicação/hash desconhecido com entrada intacta. Suíte 11 testes PASS com/sem capstone; cx26 --sh idêntico ao resolvedor anterior ao preparo. `scratch/sikarugir/patches.json` COMPLETE; evidência em `docs/evidence/ntdll-port.md`.

**Hashes ntdll patchadas.** x86_64 `64930d7e55ceaa0216b432d428a0752bd26d2893941a440af03890f6b6f88631`; i386 `932f5d47883aada83f84f18065ee9f56e5cc5c9e05644fb70357b3cc5f92c4f8`. Artefatos em `scratch/sikarugir/patched/<arch>/ntdll.dll`; originais instalados/copied clean preservados.

**Próximo passo.** Revisão independente Claude Code Opus 5.5 solicitada na issue #8; registrar modelo efetivo no parecer. Issue aberta e Project In Progress até aceite. Depois T05 prova runtime/API Steam; T07 incorpora pins no app.

**Bloqueios e limites.** Nenhum bloqueio estático. Revisão ainda pendente; nenhum runtime Wine executado. Intermediário ELF freestanding com ABI MS explícita para x86_64, i386 cdecl/stdcall existente. Ponte i386 não existe em T03, portanto este payload não comprova integração i386. Shellcheck/build GCC legado/demais variantes CrossOver não executados. Território paralelo preservado.

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
2. T04 concluído e integrado (`e96a406`, Codex Sol; preparo `3096c26`, Claude Opus). Payloads x86_64 834/1952 B e i386 1370/4096 B; ntdll patchadas x86_64 `64930d7e…`, i386 `932f5d47…` (só em scratch); revisão Opus 5.5 aprovada (#8). Pins definitivos no app ficam para T07.
3. **T05 (execução real) é o próximo gate e precisa de Elvis:** Steam nativo aberto e logado e PEAK (3527290) na conta (decisão de 2026-10-10; Prelude 2316660 vira reserva). Preparo (passo 1) integrado (`34824e5`): probe PE + runner, 11 negativos sem Wine PASS. Falta o passo 2 (montar cópia da engine com ntdll patchada + ponte T03 + prefixo descartável) e rodar. Depois T06–T09 e T10. D1: `docs/evidence/d1-game-candidates.md`.
4. T11 instala jogo Windows novo em biblioteca isolada pelo Steam nativo; T12 (Luna 6) comprova >=15 min e persistência/reabertura, save quando suportado ou dados pertinentes/configuração caso contrário. Cities II permanece teste posterior opcional.

Regra de modelos: Astra planeja e revisa; implementação padrão por `gpt-6.1-sol` ou `gpt-6-luna`, incluindo scripts de prova e testes. Pedido posterior de Elvis autoriza **Claude Code como alternativa**, com aliases `sonnet`/`opus` definidos por card e modelo efetivo registrado ao iniciar. Não trocar cliente/modelo automaticamente nem editar o mesmo território em paralelo.

## Histórico anterior ao reescopo

- Ponte upstream preparada com Wine 11.15; engine observada no wrapper é Sikarugir 11.0. Viabilidade ainda não comprovada.
- Fonte exata da engine, versão efetiva do Steam e configuração gráfica carregada precisam de validação na execução do plano.
- Localização atual do Cities II precisa ser confirmada; o antigo drive S: aponta para diretório ausente. Em 2026-10-09 Elvis esclareceu que Cities usa Steam Windows instalado no Wine. Este é o fluxo de referência informado por ele; o objetivo permanece Steam nativo com Sikarugir. Não houve validação runtime pelo agente.
- NotProton 1.1.0 e pasta de suporte já existem; inventariar e preparar rollback antes de futura implantação.
- Em 2026-10-08, Elvis havia autorizado a execução do plano anterior na branch `codex/sikarugir-card-execution`; revisão Astra aprovou o plano incremental. Esse estado é histórico e não substitui os ajustes atuais F1–F8.
- Atualizar issue e Project ao terminar cada card; não encerrar gates sem evidência funcional. Nunca publicar trabalho pessoal no upstream sem autorização.
2. T05 Passo 1 (2026-10-09, Agente: claude, modelo `sonnet`): probe PE + runner + 11 negativos sem Wine PASS em `claude/t05-probe-prep` (hash do probe e como rodar em `docs/evidence/steam-api-probe.md`); falta Wine/Steam real após T04 e revisão Opus 5.5 (issue #9, aberta).
