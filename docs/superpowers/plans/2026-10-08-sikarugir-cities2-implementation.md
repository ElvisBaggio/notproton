# Integração Steam nativo + Sikarugir — plano

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir instalar versões Windows de jogos e iniciá-las pelo Steam nativo do Mac com Sikarugir 11.0 revision 0; validar a base com um jogo simples legitimamente disponível. Cities II é teste opcional posterior.

**Architecture:** Fork mínimo do NotProton v1.1.0. Manter a ponte Steam existente, adaptar seus componentes internos ao Wine Sikarugir 11.0 e introduzir uma origem explícita no runner. A prova de API real precede a integração do aplicativo; implantação e jogo usam cópias isoladas.

**Tech Stack:** Swift >=6.2/SwiftPM, C/C++, shell POSIX, Python, Clang/SDK macOS, mingw-w64 e ferramentas Apple; reutilizar as dependências upstream.

**Spec:** [2026-10-08-sikarugir-cities2-design.md](../specs/2026-10-08-sikarugir-cities2-design.md)

**Estado:** Claude Code Sonnet 5.5 revisou o reescopo em 2026-10-09 e recomendou aprovação com ajustes F1–F8 (ver `docs/reviews/claude-scope-review-findings.md`); ajustes documentais e cards aplicáveis foram sincronizados. T01/T02 foram retomados em paralelo: T01 permanece BLOCKED pela proveniência exata; T02 permanece BLOCKED por perfil Steam compatível com 1791415817. T03–T12 seguem bloqueados pelas dependências e gates técnicos. Base: `05a27874798ffbffb8e64a37595bde6f16d5320a`.

## Global Constraints

- Uso pessoal, um único Mac; integração agnóstica ao jogo com uma engine fixada. Não é suporte agnóstico a engines nem garantia de compatibilidade com todos os jogos. Cities II é teste opcional posterior, fora dos gates base.
- Motor fixado: wine sikarugir 11.0 (revision 0), caminho x86_64/Rosetta; nenhuma troca automática de engine.
- Preservar wrapper, engine, prefixo, biblioteca e saves originais; cópia independente/clone APFS, nunca hard link.
- Gates: API Steam real; inicialização pelo Steam nativo; sessão >=15 minutos com estado persistente reaberto e rollback demonstrado.
- Manter validações de versão, hashes, arquitetura e bytes; nenhum bypass de licença CrossOver no caminho CrossOver.
- Toda implementação por gpt-6.1-sol ou gpt-6-luna; alternativa Claude Code expressamente permitida pelo pedido posterior e detalhada em [AGENT_EXECUTION.md](../../AGENT_EXECUTION.md).
- Astra coordena/revisa e não implementa. Codex e Claude não editam o mesmo território simultaneamente.
- Fonte/offsets/payloads só recebem valores derivados de evidência. Falha no gate de ABI volta ao planejamento.
- Não instalar dependências ou modificar instalações vivas nesta etapa de publicação.

## Review Focus

- Caminhos com espaços e build adulterado: preservar argumentos e recusar escape do diretório. Testes em T08.
- Engine alterada ou assinatura incompatível: recusar antes de tocar destino. Testes T04/T06/T07.
- Falha parcial ou clone existente: manter destino válido e restaurar somente arquivos tocados. T02/T07/T10.
- Duas inicializações/rebuild e prefixos de motores diferentes: preservar locks e isolamento. T08.
- Updates/Steam Cloud e jogo em outra build: invalidar combinação anterior, não sobrescrever fork/saves e não reaplicar patch histórico. T09/T11/T12.

## Mapa de arquivos e interfaces

Caminhos Model/, Support/ e Views/ abaixo são relativos a `app/Sources/NotProtonApp/`; nomes Swift de testes são relativos a `app/Tests/NotProtonAppTests/`. Todos os demais caminhos são relativos à raiz.

- Origem e identidade: SupportedRunner, SikarugirSource novo, SupportPaths e RunnerStore (T06).
- Lifecycle e payload: RunnerInstaller, RunnerSetup, RunnerPatcher, NtdllPatcher, SteamInstaller e SteamRepair (T07).
- Execução/prefixos: compat_run.sh, PrefixTools e PrefixRebuild (T08).
- UI/pacote/update: SystemStatus, StatusView, DeploymentContent, InstallPayload e AppUpdater (T09).
- Bridge e patches: scripts existentes sob bridge/, lsteamclient/, steam-shim/ e ntdll-patch/ (T03–T05).
- Evidências, lockfiles e backups: relatórios sanitizados em docs/; dados de máquina e binários somente em scratch/ ignorado.

## Ordem e revisão

T01 e T02 podem ocorrer em paralelo, em territórios separados. Depois: T03 → T04 → T05 → T06 → T07 → T08 → T09 → T10 → T11 → T12. T05 também depende de T02; T10 revalida T02. Não paralelizar T06–T09: compartilham contratos e testes.

Cada card termina com revisão independente e commit `[codex] ...` ou `[claude] ...`, push sem force, handoff e sincronização do Project. Não commitar scratch, saves, credenciais ou DLLs proprietárias. Testes de lógica nova seguem falha → mudança mínima → sucesso; tarefas operacionais têm ensaio e readback, sem criar testes que apenas repitam documentação.

## E1 — Preparação e referência recuperável

**Resultado:** Identificar engine, fonte, estado do Steam/NotProton/wrapper e restauração antes de desenvolver.

**Gate do épico:** T01 e T02 concluídos com evidências; base da engine fixada com ABI verificada no binário e restauração ensaiada.

### T01: Fixar identidade da engine Sikarugir 11.0 e verificar ABI pelo binário

**Executor:** `engine_audit` / `gpt-6.1-sol`. **Alternativa:** Claude Code `opus` (ou `sonnet` quando Elvis designar), no mesmo papel. **Revisor:** Astra; revisão Claude Code Opus 5.5.

**Dependências:** revisão do plano; sem predecessor técnico. **Replanejado em 2026-10-09 por decisão de Elvis (D2-c):** a fonte exata do mantenedor deixa de ser pré-requisito; o gate passa a ser ABI verificada no binário.

**Files:**
- Atualizar docs/evidence/engine-baseline.md; scratch/sikarugir/engine-lock.json (local, ignorado).
- Criar ntdll-patch/tests/abi_compare.py (ou script equivalente mínimo) com check executável; árvores Wine e builds somente em scratch/.
- Ler o wrapper, pacote WS12WineSikarugir11.0.tar.xz e bridge/setup-wine-tree.sh; não modificar a engine.

**Interfaces / entrega:** engine-lock.json com schemaVersion=2, runnerID=sikarugir-11.0-r0, `provenanceMode` (`binary-abi-verified` ou `maintainer-source`), `baseSource{url,tag,commit}` (candidato upstream `wine-11.0`, `db11d0fe6a169c457e23d007e20404643d067aa8`), `abiCheck{status,reportPath,comparedSurfaces,divergences[]}`, sourceURL/sourceCommit/sourcePatches (null enquanto o mantenedor não responder), version, architecture, loaderRelativePath, files[{path,sha256}], toolchain. T03 consome `baseSource` somente com `abiCheck.status=PASS`.

- [x] **Passo 1:** Comparar pacote original e engine instalada (hashes dos cinco arquivos e `version` já validados em `40e8c58`).
- [ ] **Passo 2:** Preparar toolchain sem instalação global automática: mingw-w64 (llvm-mingw) e bison recente em prefixo local de scratch/, ou instalação aprovada por Elvis. Registrar versões no lock.
- [ ] **Passo 3:** Compilar `ntdll.so` (x86_64-unix) e `ntdll.dll` (x86_64-windows, i386-windows) do upstream `wine-11.0` em scratch/, com opções próximas às documentadas pelo Gcenx (registrar as usadas; não afirmar que são as da engine).
- [ ] **Passo 4:** Comparar build upstream × pacote Sikarugir nas superfícies que a ponte, o shim e os patches consomem: (a) exports PE e símbolos Unix exportados; (b) tabela de syscalls (nome e número dos stubs Nt*/Zw* em ntdll.dll); (c) tabela de unix calls (`__wine_unix_call_funcs` e equivalentes: quantidade e ordem); (d) funções-alvo dos hooks de T04 (prólogos/bytes e tamanho, normalizando relocações); (e) diff de strings/símbolos para listar personalizações Sikarugir. Toda divergência é registrada e classificada como irrelevante ou bloqueante para a ponte, com justificativa.
- [ ] **Passo 5:** Salvar lock e relatório. Se houver divergência bloqueante não explicada, `abiCheck.status=BLOCKED` e T03 não começa.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project; pedido de revisão Opus 5.5.

**Testes e asserts:** cada files[].path existe e o SHA-256 coincide; version é `wine sikarugir 11.0 (revision 0)`; `baseSource.commit` resolve no repositório indicado; `abi_compare.py` falha (exit não zero) quando alimentado com um par de binários de versões diferentes (ex.: ntdll 11.15 da bridge existente × Sikarugir) e passa para o par upstream 11.0 × Sikarugir somente se as superfícies (a)–(d) coincidirem.

**Verificação:** reler engine-lock.json, reexecutar o comparador e conferir que o relatório lista superfícies, contagens e divergências. Resultado esperado: ABI das superfícies consumidas verificada ou card BLOCKED, nunca Done por inferência.

**Aceite:** Identidade e hashes da engine registrados; base upstream fixada por commit; ABI das superfícies (a)–(d) idêntica ou com divergências justificadas como irrelevantes; personalizações Sikarugir listadas. Nenhum arquivo do wrapper alterado. Risco residual (patch Sikarugir fora das superfícies comparadas) registrado; T05 é a prova real que o cobre.

**Parar se:** Pacote divergente sem explicação, arquitetura incompatível, divergência bloqueante nas superfícies (a)–(d) ou impossibilidade de compilar o upstream 11.0. Pedido ao mantenedor (#288) continua aberto; se a fonte chegar, `provenanceMode=maintainer-source` substitui a verificação e T03 recompila contra ela.

### T02: Inventariar Steam e preparar restauração verificável

**Executor:** `baseline_recovery` / `gpt-6.1-sol`. **Alternativa:** Claude Code `sonnet`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** revisão do plano; sem predecessor técnico.

**Files:**
- Criar docs/runbooks/recovery.md e docs/evidence/system-baseline.md.
- Criar scratch/sikarugir/system-baseline.json e backups locais com acesso restrito; reaproveitar ferramentas macOS.
- Ler SteamInstaller.swift, SteamRepair.swift, Uninstall.swift e configurações existentes.

**Interfaces / entrega:** Produzir `system-baseline.json` com schemaVersion=1, steamClientBuild, steamSupportEvidence, wrapperState, diskFreeBytes e touchedFiles[{path,existed,sha256,mode,symlinkTarget,backupPath}]. `steamSupportEvidence` registra o resultado da verificação do perfil para o build ativo, incluindo perfis/hashes usados e `sigcheck.py`/fixtures; não aceitar apenas o perfil mais recente quando ele não casa com `steamClientBuild`. Gerar e validar um perfil para o build Steam atual observado (1791415817 no inventário anterior), sem fixar ou desabilitar updates. `wrapperState` distingue versão instalada do NotProton (1.1.0), base de fonte (1.1.1) e estado do wrapper. `referenceGame{appID,build,path,prefixPath,cloudState}` é opcional e nunca gate da integração base. Caminhos e conta permanecem locais; ausência vira diagnóstico, nunca dado inventado. Migrar o manifesto atual para este schema sem perder as evidências históricas; manter detalhes de Cities II apenas em `referenceGame`, quando ainda válidos.

- [ ] **Passo 1:** Inventariar wrapper, prefixos e saves existentes como dados a preservar; registrar referências de jogos somente quando disponíveis. Localização/build/Cloud do Cities II não bloqueiam a integração base; não reinterpretar S: ausente como ausência global.
- [ ] **Passo 2:** Inventariar Steam e NotProton já instalados, versão efetiva do cliente, integrações e política de updates; validar um perfil de assinaturas para o build ativo com `dylib/tests/sigcheck.py` e fixtures; medir espaço para cópias. Se o perfil não puder ser gerado/validado, T02 fica bloqueado e registra a causa sem escolher perfil antigo por conveniência.
- [ ] **Passo 3:** Documentar ordem de backup/restauração de arquivos, plists, assinatura, ferramentas e estado anterior; usar cópia/clone APFS, nunca hard link.
- [ ] **Passo 4:** Ensaiar restauração em diretório temporário com arquivo, symlink, permissão e arquivo antes inexistente; comparar estado. Não restaurar sobre instalações reais nesta tarefa.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** Ensaio: conteúdo, permissão e alvo do symlink voltam ao original; arquivo criado pela simulação desaparece; arquivo alheio permanece. Backup incompleto não pode ser declarado utilizável.

**Verificação:** Conferir hashes, modos e links antes/depois do ensaio e registrar readback. Resultado esperado: restauração exata dos itens tocados, sem apagar diretórios compartilhados.

**Aceite:** Estado Steam/NotProton/wrapper inventariado; saves existentes preservados. `system-baseline.json` segue o schema acima e mantém `referenceGame` opcional, sem bloqueio por localização/build/Cloud do Cities II. Versão real do Steam e perfil de assinaturas correspondente ao build ativo foram validados. Ensaio de restauração passou; proteção dos dados existentes e espaço documentados. Cloud do jogo de teste será validado em T11 antes de tocá-lo.

**Parar se:** Backup não restaurável, perfil de assinaturas não validado para o build Steam ativo ou risco de sobrescrever saves sem resolução.

### Decisões de Elvis após inventário

**D1 — Jogo-base para T05/T11:** selecionar somente depois de T02. Deve ser pequeno, ter versão somente Windows (sem depot/build macOS), inicializar a API Steam, oferecer save ou configuração persistente identificável e ter conta/Cloud conhecidos. Registrar AppID/build e evidência de elegibilidade antes de T05. Não usar Cities II como jogo-base. **Decisão de Elvis (2026-10-10): PEAK, AppID 3527290** (substitui Halls of Torment: Prelude 2316660, que vira reserva; Banana 2923300 segunda reserva). PEAK: só Windows na loja, Steam Achievements, sem DRM/anti-cheat de terceiros listado, ~4 GB. Riscos registrados: exige DirectX 12 (wrapper hoje com D3DMETAL=0/DXVK=0; renderer é tema de T11/T12, não do probe de API do T05) e não lista Steam Cloud (persistência em T12 por progresso/configuração local). Candidatos e verificações pendentes em `docs/evidence/d1-game-candidates.md` (depot macOS no SteamDB/steamcmd, caminho do save, resgate na conta, `SteamAPI_Init` real em T05).

**D2 — Proveniência da engine (revisada em 2026-10-09):** Elvis escolheu a opção (c) do F2: aceitar ABI verificada no binário contra o upstream `wine-11.0` (`db11d0fe6a169c457e23d007e20404643d067aa8`) em vez de exigir a fonte exata. O pedido ao mantenedor (https://github.com/Sikarugir-App/Sikarugir/issues/288) continua aberto, reforçado pela obrigação LGPL de fornecer a fonte correspondente; se chegar, substitui a verificação. Não trocar de engine implicitamente nem pular a comparação de ABI.

## E2 — Viabilidade da ponte Wine–Steam

**Resultado:** Provar que Wine Sikarugir 11.0 pode usar a API Steam nativa com patches próprios.

**Gate do épico:** T03–T05 concluídos e Astra aceita prova real; build ou menu não bastam.

### T03: Compilar a ponte e o shim para a base verificada do Sikarugir

**Executor:** `wine_bridge` / `gpt-6.1-sol`. **Alternativa:** Claude Code `opus`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** T01.

**Files:**
- Modificar bridge/setup-wine-tree.sh, lsteamclient/build.sh, steam-shim/build.sh e Makefile apenas no caminho necessário.
- Criar bridge/tests/sikarugir-buildcheck.sh e docs/evidence/bridge-build.md.
- Artefatos locais sob scratch/sikarugir/bridge/; não versionar binários de terceiros.

**Interfaces / entrega:** Consumir engine-lock.json de T01. Reutilizar WINE_URL/WINE_TAG/WINE_COMMIT/WINE_SRC/WINE_BUILD já existentes; introduzir alvo make bridge-sikarugir para x86_64/Rosetta, com partes i386 apenas quando requeridas. Saída é árvore bridge compatível com os consumidores existentes, isolada da bridge CrossOver. **Decisão de Elvis (2026-10-09), após BLOCKED de `dcc8a73`:** o Wine 11.0 não tem `WINE_EXTERNAL` nem `CXX_PE_LIBS`, que só o `steam.exe` (C++) exige. Então `lsteamclient` (Unix e PE) segue compilada na árvore `wine-11.0` verificada, registrando só ela no configure; o `steam.exe` é compilado **fora** da árvore Wine com o llvm-mingw validado em T01, runtime C++ do llvm-mingw ligada estaticamente, importando apenas DLLs Win32 do sistema. Não portar `WINE_EXTERNAL`/`CXX_PE_LIBS` para 11.0 nem trocar para 11.15.

- [ ] **Passo 1:** Escrever check de parâmetros que exige `baseSource.commit` (ou `sourceCommit` quando `provenanceMode=maintainer-source`) fixado e `abiCheck.status=PASS`, rejeita árvore divergente e impede fallback silencioso para Wine 11.15/arm64; executar e confirmar falha antes da mudança.
- [ ] **Passo 2:** Adaptar o build mínimo mantendo o caminho CrossOver atual; construir lsteamclient e steam.exe contra a base validada.
- [ ] **Passo 3:** Conferir dependências com file/otool e ausência de caminhos CrossOver obrigatórios no runner Sikarugir.
- [ ] **Passo 4:** Executar check, compilar novamente a partir da configuração registrada e documentar arquiteturas e hashes.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** bridge/tests/sikarugir-buildcheck.sh: commit diferente => exit não zero antes de build; seleção Rosetta => não construir FEX; artefatos x86_64 Unix e PE correspondentes; caminho upstream segue disponível.

**Verificação:** rtk proxy sh bridge/tests/sikarugir-buildcheck.sh; rtk make bridge-sikarugir. Esperado: checks PASS e build completo com manifesto local de arquitetura/hash; compilação sozinha não libera integração.

**Aceite:** Ponte reproduzível para a base fixada. Saída isolada e arquiteturas conferidas. Check negativo de commit passa; nenhuma troca de motor implícita.

**Parar se:** Base sem interfaces exigidas pela ponte, mistura de arquiteturas ou dependência irredutível do CrossOver.

### T04: Resolver e validar os patches ntdll específicos da engine

**Executor:** `ntdll_port` / `gpt-6.1-sol`. **Alternativa:** Claude Code `opus`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** T01, T03.

**Files:**
- Modificar ntdll-patch/resolve.py, apply.py, build.sh e build32.sh somente conforme achados.
- Criar ntdll-patch/tests/test_sikarugir.py e docs/evidence/ntdll-port.md.
- Gerar dados e payloads no scratch; incorporar pins definitivos no aplicativo apenas em T07.

**Interfaces / entrega:** Consumir engine-lock.json e artefatos T03. Preservar interface resolve.py --sh <ntdll.dll> e scripts existentes; produzir scratch/sikarugir/patches.json com cleanHash, patchedHash, architecture, hookRVA, expectedBytes, payloadHash e evidence para cada arquitetura necessária. Nenhum offset inventado no plano.

- [ ] **Passo 1:** Criar fixtures PE sintéticas e asserts para hash desconhecido, bytes do hook divergentes, RVA fora do arquivo e arquitetura errada; confirmar falhas antes de adaptar.
- [ ] **Passo 2:** Resolver hooks sobre cópias dos binários exatos; derivar constantes e gerar payload adequado à engine.
- [ ] **Passo 3:** Aplicar apenas em cópia, verificar bytes preservados e hash resultante; testar recusa de reaplicação indevida.
- [ ] **Passo 4:** Rodar testes e registrar o relatório com limites comprovados.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** test_rejects_unknown_hash, test_rejects_changed_hook_bytes, test_rejects_out_of_bounds_rva, test_rejects_wrong_architecture: saída não zero/exceção e entrada intacta; test_patch_preserves_unrelated_bytes: diferença só nas regiões previstas.

**Verificação:** rtk proxy python3 -m unittest discover -s ntdll-patch/tests -p 'test_sikarugir.py'; resolver a ntdll real em modo leitura e conferir manifesto. Esperado: testes PASS e patches verificáveis; nenhum runtime implícito.

**Aceite:** Pins derivados dos arquivos reais, sem reaproveitar offsets CrossOver por suposição. Testes negativos passam e originais intactos. Artefatos identificam arquitetura, bytes e hashes.

**Parar se:** Hook ambíguo, invariantes ausentes ou necessidade de substituir ntdll pela versão 11.15.

### T05: Provar Steam API real pelo motor isolado — gate de viabilidade

**Executor:** `bridge_probe` / `gpt-6.1-sol`. **Alternativa:** Claude Code `opus`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** T02, T03, T04.

**Files:**
- Criar bridge/tests/steam-api-probe.c e bridge/tests/run-steam-api-probe.sh.
- Criar docs/evidence/steam-api-probe.md; logs brutos somente em scratch.

**Interfaces / entrega:** Probe usa interfaces Steam disponíveis no projeto; verifica init bem-sucedido, AppID igual ao AppID legítimo selecionado e registrado para o probe e sessão autenticada, imprimindo apenas booleanos/AppID, nunca SteamID/token. Runner recebe engine/prefix/bridge por argumentos explícitos, exige prefixo de scratch e devolve exit 0 apenas após todas as provas. T05 usa a instalação existente do Steam nativo somente para a chamada de API; não instala nem implanta NotProton, não altera a instalação Steam e não modifica wrapper/biblioteca/saves. O relatório registra o estado observado no manifesto T02: NotProton instalado 1.1.0, fonte-base 1.1.1 e qualquer divergência relevante.

- [ ] **Passo 1:** Escrever asserts do probe e caso negativo sem Steam; conferir que Steam ausente/init falsa resulta em falha explícita.
- [ ] **Passo 2:** Inicializar prefixo descartável com cópia patchada e bridge construída; registrar ausência de erro loader/server/Unix-call.
- [ ] **Passo 3:** Após o inventário T02, Elvis seleciona e registra um AppID elegível conforme decisão D1; executar com Steam nativo autenticado e contexto válido; registrar a seleção e disponibilidade antes do probe; não instalar Steam Windows nem substituir autenticação.
- [ ] **Passo 4:** Verificar que o wrapper original permaneceu intacto e publicar relatório PASS/FAIL; Astra revisa gate antes de liberar E3.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** Sem Steam nativo => exit não zero; AppID diferente do selecionado => exit não zero; init e contexto correto => exit 0; prefixo fora de scratch => recusa; log não contém identificador de usuário.

**Verificação:** rtk proxy sh bridge/tests/run-steam-api-probe.sh --engine <copia-validada> --prefix <scratch-descartavel> --bridge <artefatos-T03> --appid <appid-legitimo-selecionado>. Esperado: STEAM_INIT=ok, APP_ID=<appid-legitimo-selecionado>, AUTHENTICATED=yes e exit 0; engine/prefix/bridge vêm dos manifests; AppID vem da seleção legítima registrada antes do probe, sem default fixo.

**Aceite:** Chamada real à API via Steam nativo comprovada. Casos negativos documentados; comunicação Unix sem falhas. Revisão do gate pelo Astra registrada antes de integração.

**Parar se:** Compile-only, sucesso obtido pelo Steam Windows ou falha persistente de ABI não aprovam o gate.

## E3 — Integração do runner no NotProton

**Resultado:** Instalar, reparar, selecionar e iniciar o motor Sikarugir com isolamento e checks existentes.

**Gate do épico:** T06–T09 concluídos, regressões CrossOver passam e pacote experimental conferido.

### T06: Adicionar origem Sikarugir ao catálogo e aos caminhos do runner

**Executor:** `runner_model` / `gpt-6.1-sol`. **Alternativa:** Claude Code `sonnet`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** T05.

**Files:**
- Modificar Model/SupportedRunner.swift, Support/SupportPaths.swift e Model/RunnerStore.swift sob app/Sources/NotProtonApp/.
- Criar Model/SikarugirSource.swift e app/Tests/NotProtonAppTests/SikarugirSourceTests.swift.
- Estender DetectionTests.swift e RunnerStateTests.swift.

**Interfaces / entrega:** Adicionar RunnerOrigin: String, Sendable {crossOver,sikarugir} e RunnerBuild.origin com default crossOver. Criar SikarugirInstall: Sendable {root: URL, build: RunnerBuild}; SikarugirSource.inspect(root: URL) throws -> SikarugirInstall. Fixar id=sikarugir-11.0-r0, tool.name=notproton-sikarugir-11.0-r0, flavor=rosetta, display=Sikarugir 11.0 (experimental). Manter assinaturas SupportPaths.runnerRoot(forBuild:runners:) e clonedRoot(forBuild:runners:); novo layout runners/sikarugir-11.0-r0/wine.

- [ ] **Passo 1:** Criar testes da descoberta por hashes exatos, origem errada, hash alterado e layout; confirmar falha inicial.
- [ ] **Passo 2:** Adicionar origem explícita e descoberta específica sem converter Sikarugir em CrossOverInstall.
- [ ] **Passo 3:** Centralizar caminhos preservando IDs/layouts CrossOver e reconhecimento de clones no RunnerStore.
- [ ] **Passo 4:** Executar testes e verificar que a serialização TSV continua com quatro colunas name/build/flavor/display.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** testSikarugirBuildHasStableID; testChangedLoaderIsRejected; testWrongArchitectureIsRejected; testSikarugirRootIsIsolated; testCrossOverPathsRemainUnchanged; TSV split por tab produz exatamente 4 campos por linha.

**Asserts mínimos do contrato de T06 (Swift Testing):**

```swift
let build = try #require(SupportedRunners.build(id: "sikarugir-11.0-r0"))
#expect(build.origin == .sikarugir)
#expect(build.tools.map(\.name) == ["notproton-sikarugir-11.0-r0"])
let root = SupportPaths.clonedRoot(forBuild: build.id, runners: URL(filePath: "/tmp/test runners"))
#expect(root.path == "/tmp/test runners/sikarugir-11.0-r0/wine")
```

**Verificação:** rtk proxy sh -c 'cd app && swift test --no-parallel --filter "SikarugirSourceTests|DetectionTests|RunnerStateTests"'. Esperado: PASS, sem alteração de fixtures CrossOver para esconder regressão.

**Aceite:** Identidade estável e única; engine desconhecida recusada. Catálogo inclui origem sem framework de plugins. Paths e TSV CrossOver preservados.

**Parar se:** Necessidade de mascarar Sikarugir como CrossOver ou alterar formato compartilhado sem consumidores atualizados.

### T07: Integrar cópia, patch, instalação e reparo sem dependência CrossOver

**Executor:** `runner_lifecycle` / `gpt-6.1-sol`. **Alternativa:** Claude Code `opus`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** T06.

**Files:**
- Modificar Model/RunnerInstaller.swift, RunnerSetup.swift, RunnerPatcher.swift, NtdllPatcher.swift, SteamInstaller.swift e SteamRepair.swift.
- Atualizar Resources/payload.manifest e Package.swift apenas para payload próprio necessário.
- Estender RunnerInstallerTests, RunnerSetupTests, RunnerPatcherTests, NtdllPatcherTests, SteamInstallerTests, SteamRepairTests e CrossOverLicenseTests.

**Interfaces / entrega:** Adicionar overloads RunnerInstaller.clone(from: SikarugirInstall, replacingExisting: Bool=false, runners: URL=SupportPaths.runners) throws -> RunnerBuild e RunnerSetup.run(from: SikarugirInstall, replacingExisting: Bool=false, report: @Sendable (Phase)->Void={_ in}) throws -> Outcome. Preservar prepare, verifyClone, RunnerPatcher.install e entradas CrossOver; selecionar comportamento por build.origin. Bridge Sikarugir exclusiva sob bridge/sikarugir-11.0-r0, consumindo manifests T03/T04. A validação do perfil Steam deve exigir igualdade entre o build ativo e o build registrado no perfil; rejeitar combinação única porém divergente, antes de instalar hooks.

- [ ] **Passo 1:** Escrever testes: setup/repair Sikarugir não chamam licença CrossOver, enquanto origem CrossOver continua exigindo licença; falha de clone/patch preserva destino anterior.
- [ ] **Passo 2:** Implementar os overloads, validação do loader correto, staging de payload e assinatura adequada à engine.
- [ ] **Passo 3:** Atualizar todos os callers de install e repair para a mesma verificação por origem; usar manifests do gate aprovado, não blobs genéricos.
- [ ] **Passo 4:** Rodar testes e ensaiar falha parcial em diretórios temporários; confirmar que nenhuma bridge compartilhada foi sobrescrita.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** testSikarugirSetupDoesNotCallCrossOverLicense; testCrossOverStillRequiresLicense; testRepairVerifiesSikarugirLoader; testFailedPatchPreservesExistingClone; testSikarugirBridgeDoesNotReplaceCrossOverPayload; testUnknownHashRefusesInstall.

**Verificação:** rtk proxy sh -c 'cd app && swift test --no-parallel --filter "RunnerInstallerTests|RunnerSetupTests|RunnerPatcherTests|NtdllPatcherTests|SteamInstallerTests|SteamRepairTests|CrossOverLicenseTests"'. Esperado: PASS, incluindo falhas injetadas.

**Aceite:** Setup e repair funcionam pela mesma origem. Licenciamento CrossOver preservado para CrossOver. Clone, bridge e assinatura isolados; recuperação de falha parcial demonstrada.

**Parar se:** Cópia incompleta, assinatura não validável ou reparo ainda dependente de caminhos CrossOver.

### T08: Adaptar launcher, prefixos e ferramentas Wine ao motor fixado

**Executor:** `launch_prefix` / `gpt-6.1-sol`. **Alternativa:** Claude Code `sonnet`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** T07.

**Files:**
- Modificar dylib/feats/compat_run.sh e app/Sources/NotProtonApp/Model/PrefixTools.swift, PrefixRebuild.swift.
- Estender dylib/tests/buildcheck.sh, envcheck.sh, seedcheck.sh, bridgecheck.sh, routecheck.sh e app/Tests/NotProtonAppTests/PrefixToolsTests.swift, RunnerSwitchTests.swift.

**Interfaces / entrega:** Consumir os mesmos build id/tool id/layout de T06 e bridge isolada de T07. Manter verbos existentes do launcher e formato TSV. Para sikarugir-11.0-r0 selecionar bin/wine, bin/wineserver e lib/wine/x86_64-unix da cópia; validar loader real contra T01. Prefixo vem de STEAM_COMPAT_DATA_PATH exclusivo, nunca do wrapper.

- [ ] **Passo 1:** Criar regressões para caminhos com espaços, build adulterado com ../, engine ausente, prefixo bloqueado, duas inicializações concorrentes e ausência de `CX_HOME`/variáveis CrossOver no ambiente Sikarugir; executar para falhar.
- [ ] **Passo 2:** Adaptar seleção de raiz/loader/bridge e reutilizar locks e tratamento de erro existentes. Remover exigência de CX_HOME apenas no caminho Sikarugir.
- [ ] **Passo 3:** Fazer PrefixTools e PrefixRebuild usarem a mesma resolução da engine; não criar um segundo mapeamento divergente.
- [ ] **Passo 4:** Executar checks shell e Swift; confirmar logs úteis e redação de campos que exponham conta/token. Estender `envcheck.sh` para provar que o caminho Sikarugir não exporta nem herda `CX_HOME`/CrossOver, preservando o ambiente atual no caminho CrossOver.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** build adulterado => recusa sem executar; caminho com espaços preservado como argumento; concorrência não corrompe template; prefixo do wrapper nunca tocado; Wine tool e launcher escolhem mesmo loader; Sikarugir não recebe `CX_HOME` nem variáveis CrossOver; flavor CrossOver permanece funcional.

**Verificação:** rtk make runcheck buildcheck envcheck seedcheck bridgecheck routecheck; rtk proxy sh -c 'cd app && swift test --no-parallel --filter "PrefixToolsTests|RunnerSwitchTests"'. Esperado: PASS real; SKIP por ferramenta ausente não conta como sucesso.

**Aceite:** Botão Jogar poderá encaminhar argumentos sem perda. Prefixos e templates isolados, locks preservados. Ferramentas Wine e rebuild concordam com launcher; checks CrossOver passam.

**Parar se:** Vazamento de prefixo/bridge entre motores ou perda de validação/tratamento de erros na movimentação do código.

### T09: Expor ferramenta na interface e empacotar o fork sem atualização indevida

**Executor:** `app_integration` / `gpt-6.1-sol`. **Alternativa:** Claude Code `sonnet`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** T08.

**Files:**
- Modificar app/Sources/NotProtonApp/SystemStatus.swift, Views/StatusView.swift, Support/AppUpdater.swift, Model/DeploymentContent.swift e Model/InstallPayload.swift.
- Modificar app/Info.plist, app/Package.swift e Makefile somente para distinguir build experimental.
- Estender SystemStatusTests.swift, DeploymentContentTests.swift, InstallPayloadTests.swift; criar ExperimentalUpdateTests.swift.

**Interfaces / entrega:** Adicionar SystemStatus.addSikarugir() async para selecionar raiz de engine e acionar SikarugirSource.inspect + RunnerSetup.run. Mostrar linha Sikarugir 11.0 (experimental) separada das CrossOverRow. Gerar NotProton Sikarugir.app com bundle id local com.notproton.NotProton.sikarugir; não substituir /Applications/NotProton.app. Desabilitar atualização upstream somente no bundle experimental.

- [ ] **Passo 1:** Escrever testes para detecção, diagnóstico de engine incompatível, registro da ferramenta e updater experimental desativado; confirmar falha.
- [ ] **Passo 2:** Integrar seleção e setup ao fluxo existente, sem redesenho da interface; manter ações CrossOver.
- [ ] **Passo 3:** Empacotar payloads da engine correta e identificar build experimental para prevenir troca por upstream.
- [ ] **Passo 4:** Executar testes, abrir pacote local e verificar visualmente seleção/erro antes de qualquer deploy no Steam.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** testExperimentalBundleDoesNotStartUpstreamUpdater; testExistingBundleKeepsUpdaterBehavior; testUnsupportedSikarugirShowsActionableError; testPayloadContainsOnlyPinnedSikarugirBridge; testSikarugirNotListedAsCrossOver.

**Verificação:** rtk proxy sh -c 'cd app && swift test --no-parallel --filter "SystemStatusTests|DeploymentContentTests|InstallPayloadTests|ExperimentalUpdateTests"'; rtk make app. Esperado: testes PASS e app experimental abre; build não equivale a deploy concluído.

**Aceite:** Ferramenta selecionável com nome correto. App experimental distinguível, sem sobrescrever app original. Updater não substitui fork; payload correto e erro claro.

**Parar se:** UI mostra CrossOver no lugar do Sikarugir, updater upstream ativo no fork ou payload de outra ABI.

## E4 — Jogo Windows pelo Steam nativo com persistência e rollback

**Resultado:** Implantar de forma recuperável e demonstrar sessão real pelo Steam nativo.

**Gate do épico:** T10–T12 concluídos; sessão >=15 minutos, estado persistente reaberto (save quando suportado; dados pertinentes/configuração caso contrário) e rollback comprovados.

### T10: Implantar com backup e testar retorno ao estado anterior

**Executor:** `deployment_validation` / `gpt-6.1-sol`. **Alternativa:** Claude Code `sonnet`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** T02, T09.

**Files:**
- Atualizar docs/runbooks/recovery.md e criar docs/evidence/deployment-rollback.md.
- Operar apenas alvos de instalação do fork revisados; correções de código retornam ao proprietário T07/T08/T09.

**Interfaces / entrega:** Consumir pacote T09 e inventário T02 revalidado no momento da implantação. Produzir manifesto local dos arquivos realmente tocados, backup correspondente e relatório de deploy → rollback → readback → redeploy. Nenhum rollback remove pasta de suporte inteira.

- [ ] **Passo 1:** Fechar Steam, conferir versão suportada, processos, espaço e hashes; fazer backup do estado imediatamente anterior.
- [ ] **Passo 2:** Implantar pacote/ferramenta e verificar opção no Steam nativo por UI, não somente arquivo/registro.
- [ ] **Passo 3:** Encerrar Steam, executar rollback e verificar conteúdo, configurações, assinatura operacional e abertura do Steam original.
- [ ] **Passo 4:** Reimplantar a versão validada para teste do jogo e registrar IDs/hashes; interromper em qualquer divergência.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** Teste real de rollback: Steam original reabre; ferramentas/configuração anteriores restauradas; arquivos alheios preservados; wrapper original abre; engine/prefixo originais mantêm integridade.

**Verificação:** Executar runbook recovery.md e conferir cada pós-condição em logs e UI; registrar screenshots sem dados privados quando necessário. Esperado: rollback e redeploy demonstrados, não apenas backup criado.

**Aceite:** Deploy visível no Steam. Rollback real executado e estado anterior funcional. Redeploy conferido; manifesto e evidências registrados.

**Parar se:** Steam aberto, build incompatível, backup inválido ou restauração sem readback.

### T11: Instalar jogo Windows de teste e abrir pelo Steam nativo

**Executor:** `cities_integration` / `gpt-6.1-sol`. **Alternativa:** Claude Code `sonnet`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** T10.

**Files:**
- Criar docs/evidence/game-launch.md; reutilizar docs/runbooks/recovery.md.
- Biblioteca/prefixo local exclusivos; qualquer patch do jogo deve incluir hash/build e backup local, sem distribuir DLL proprietária.

**Interfaces / entrega:** Após o inventário T02, Elvis seleciona e registra um AppID que cumpra D1: jogo pequeno, somente Windows (sem build macOS), inicializa a API Steam, possui save ou configuração persistente identificável e tem conta/Cloud conhecidos. Instalar do zero pelo Steam nativo em biblioteca/prefixo exclusivos com notproton-sikarugir-11.0-r0; não reutilizar Cities II, sua biblioteca ou prefixo. Inventário T02 protege o estado geral; nenhuma localização/build/Cloud do Cities II é pré-condição.

- [ ] **Passo 1:** Conferir espaço e Cloud do jogo selecionado; preservar quaisquer dados existentes e não resolver conflitos automaticamente.
- [ ] **Passo 2:** Instalar a versão Windows do jogo simples do zero via Steam nativo em biblioteca de teste isolada; conferir manifesto/depot para provar que foi instalado o conteúdo Windows e confirmar que o Steam nativo não escolheu um build macOS; registrar AppID, build, prefixo e ferramenta selecionada.
- [ ] **Passo 3:** Selecionar ferramenta e iniciar via Jogar; diagnosticar separadamente ponte/Wine/jogo. Eventual patch deve casar com build atual.
- [ ] **Passo 4:** Entrar em gameplay real e registrar build, renderer efetivo, mensagens e saída do processo; retorno do botão Jogar ao estado correto.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** Manifesto/depot confirma conteúdo Windows e build macOS não selecionado; jogo inicia pelo Steam nativo sem cliente Windows; biblioteca e saves originais preservados; reabrir não reinicializa prefixo; falhas possuem diagnóstico atribuível.

**Verificação:** Verificação funcional pela UI do Steam e do jogo, com logs da execução correlacionados. Esperado: gameplay real pelo novo fluxo; menu sozinho não basta.

**Aceite:** Instalação Windows gerenciada em biblioteca isolada. Gameplay real via Steam nativo e motor correto. Versão/renderer conferidos; saves e biblioteca originais preservados.

**Parar se:** Uso involuntário de Steam Windows, patch incompatível com build ou conflito de saves pendente.

### T12: Validar sessão, persistência/reabertura e documentar operação

**Executor:** `acceptance_docs` / `gpt-6-luna`. **Alternativa:** Claude Code `sonnet`, no mesmo papel. **Revisor:** Astra; execução física com Elvis quando exigida.

**Dependências:** T11.

**Files:**
- Criar docs/runbooks/steam-sikarugir.md e docs/evidence/acceptance.md; atualizar HANDOFF.md.
- Revisor técnico: subagente integration_review em gpt-6.1-sol; Elvis participa da sessão de jogo.

**Interfaces / entrega:** Relatório com versões Steam/game/engine, hashes dos artefatos, renderer, duração >=15 min, ação identificável, estado persistente identificado sem dados pessoais (slot de teste se suportado; dados pertinentes/configuração caso contrário) e resultado de reabertura. Cada critério deve ser PASS/FAIL/NOT RUN com evidência; nenhum NOT RUN permite encerrar o épico.

- [ ] **Passo 1:** Orientar Elvis a iniciar gameplay do jogo selecionado, realizar ação identificável e jogar por pelo menos 15 min. Salvar em slot separado se suportado; caso contrário alterar dados pertinentes/configuração persistente e registrar o método.
- [ ] **Passo 2:** Encerrar jogo e Steam, reabrir via Steam nativo e confirmar o estado persistente identificado (save quando suportado; dados pertinentes/configuração caso contrário); registrar comportamento funcional e falhas.
- [ ] **Passo 3:** Revisor Sol 6.1 confere regressão do wrapper, rollback T10 e critérios da spec; corrigir falhas nas tarefas proprietárias.
- [ ] **Passo 4:** Documentar instalar/iniciar/salvar/recuperar, combinações fixadas e política de updates; atualizar cards, épicos e handoff após aceitação.
- [ ] **Fechamento:** revisar diff e evidências; commit dos arquivos deste card; push e atualização de HANDOFF/issue/Project.

**Testes e asserts:** Teste funcional: alteração persiste após encerrar jogo+Steam; sessão >=15 min; wrapper original continua utilizável; evidência de rollback T10 existe; guia permite recuperar sem conhecimento desta conversa.

**Verificação:** Executar checklist docs/runbooks/steam-sikarugir.md com Elvis. Esperado: todos os critérios PASS; anotar limitações sem prometer desempenho e sem encerrar antes da validação física.

**Aceite:** Sessão e persistência comprovadas por Elvis. Revisão independente Sol 6.1/Astra aceita evidências. Guia e handoff publicados; board corresponde ao estado real.

**Parar se:** Ausência de teste humano, crash, perda de dados ou qualquer critério NOT RUN. Luna não assume correções da ponte.

## Revisão do plano e método de execução

Método recomendado: subagentes por card, com revisor separado. Default Sol 6.1 e Luna 6 conforme tabela; Claude Code é alternativa por card, não execução paralela dos mesmos arquivos. O reescopo foi autorizado por Elvis em 2026-10-09. Todos os cards: Prontidão = Aguarda revisão do plano novo; Status diferente de Done. Não implementar nem executar probes antes da revisão; após aprovação respeitar predecessores e gates.

Cobertura conferida: spec §§1/6 → T05/T10–T12; §§2/4 → política e todos os cards; §§3/5.3 → T01/T03–T05; §§5.1/5.2 → T06–T09; §5.4 → T02/T11/T12; §7 → T02/T07–T12; §8 → testes de cada card. Os valores desconhecidos de fonte, offsets e suporte efetivo ao cliente Steam são entregas bloqueantes de T01/T02/T04, não placeholders de implementação.
