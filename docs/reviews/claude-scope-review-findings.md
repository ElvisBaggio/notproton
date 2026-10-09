# Revisão do reescopo — findings (Claude Code)

Data: 2026-10-09 · Autor: claude · Cliente: Claude Code · **Modelo efetivo: claude-sonnet-5-5** (o recado pedia `opus`; Elvis autorizou rodar com sonnet nesta sessão) · Branch revisada: `codex/game-agnostic-scope` (4c7d23a) · Revisão somente de documentos e leitura de código; nenhum arquivo do Codex editado, nenhum probe executado.

**Escopo lido:** AGENTS.md, HANDOFF.md, PROJECT.md, AGENT_EXECUTION.md, spec e plano completos (T01–T12), evidências T01/T02, recovery.md, `loader.c`/`resolver.c`/`aob.c`/`sigdb.h`, `compat_run.sh`. **Não coberto:** corpo das issues #1–#16 no GitHub (o `gh` roda sem acesso à API dentro do sandbox; o board foi lido via comando do Elvis antes do reescopo), a ponte `lsteamclient`, os testes do #18.

## Recomendação

**Aprovar com ajustes.** O reescopo é coerente: objetivo, marcos, dependências e papéis batem entre spec, plano e PROJECT.md; modelos, alternativas, Luna 6 no T12 e os gates (fonte, ABI, API real, 15 min, rollback) foram preservados. Os ajustes abaixo fecham lacunas que fariam T05/T10 falhar por motivo que nenhum card cobre. Tudo aqui é documentação/planejamento; nenhuma afirmação deste arquivo é evidência de runtime.

## Findings priorizados

### P1 — ajustar antes de liberar T01/T02

**F1. Suporte do cliente Steam não tem dono nem card.** Spec §5.1 e T02 ("Parar se: Steam sem versão suportada") exigem cliente suportado, mas nenhum card produz o perfil de assinaturas. Fato verificado: cliente 1791415817; perfis em `signatures/macos.arm64` e no suporte instalado: 1788400362, 1789086785, 1790904859. `loader.c:install_thread` não instala nenhum hook se qualquer assinatura de `steamclient.dylib` falhar; logo, T05 (probe pelo Steam nativo) e T10 não passam com o cliente atual, e a falha pareceria da ponte/Wine. Além disso `steam_build` do perfil nunca é comparado ao build ativo (casamento único porém errado passaria) e `steamui.dylib` instala parcialmente. **Recomendação:** acrescentar ao T02 (ou novo pré-requisito de T05) uma saída explícita: gerar/validar perfil para o build em uso (via `dylib/tests/sigcheck.py`/fixtures) ou fixar/desligar a atualização do Steam num build com perfil; e decidir se o loader passa a checar `steam_build`. Dono: T02 decide, T07/loader implementa (território do Codex).

**F2. T01 bloqueado sem caminho de decisão.** `engine-lock.json` está `blocked-source-provenance`; o plano diz só "parar/voltar ao planejamento". Com o reescopo, T03–T12 inteiros dependem disso. **Recomendação:** registrar um ponto de decisão do Elvis com prazo: (a) pedir ao mantenedor o manifesto (commit, patches em ordem, opções) do asset SHA-256 `dcb3de3a…befcf9`; (b) trocar a engine por outra com fonte demonstrável (invalida hashes/hooks e a restrição "Sikarugir 11.0 r0 fixado"); (c) caminho intermediário a aprovar explicitamente: aceitar ABI "verificada no binário" (comparar ntdll.so/símbolos do asset com o Wine 11.0 upstream) em vez de fonte exata, o que hoje contradiz o aceite de T01 e deve ser decidido, não assumido.

**F3. T05 depende de estado vivo do Steam antes do T10.** T05 exige "Steam nativo autenticado" com a ponte, mas o rollback/backup real só ocorre em T10, e o NotProton instalado é 1.1.0 enquanto o fonte é 1.1.1 (#18 não implantado). **Recomendação:** dizer no T05 qual estado do NotProton/Steam é usado (instalado, somente leitura, sob backup de T02) e que T05 não implanta; registrar 1.1.0 vs 1.1.1 como estado anterior no manifesto de T10.

**F4. Jogo de teste sem critério nem dono.** T05 precisa do AppID antes do probe e T11 instala do zero, mas "jogo simples legitimamente disponível" não tem critério. **Recomendação:** nova decisão de Elvis antes de T05 (marco D1): jogo só Windows (sem build macOS, para o Steam usar Steam Play), pequeno, inicializa a API Steam, com saves ou configuração persistente identificável, e conta/Cloud conhecidos. Registrar AppID/build no card.

### P2 — corrigir no plano/documentos

**F5. T02: schema do plano ≠ JSON existente.** O plano define `steamClientBuild, steamSupportEvidence, wrapperState, diskFreeBytes, touchedFiles, referenceGame?`. O `system-baseline.json` atual tem `steamClientBuild`, `gameAppID`, `gamePath`, `cloudState`, `saveFiles`… e **não** tem `steamSupportEvidence`, `wrapperState` nem `referenceGame`. A evidência T02 ainda é Cities-cêntrica. **Recomendação:** migrar o JSON/relatório para o schema novo (Cities vira `referenceGame` opcional) antes de dar T02 por pronto.

**F6. T08: `CX_HOME` é exportado incondicionalmente.** `dylib/feats/compat_run.sh:23` faz `export CX_HOME=…CrossOver`, usado nas linhas ~508 e ~1365. O passo "remover exigência de CX_HOME apenas no caminho Sikarugir" precisa de guarda por build/flavor e de teste que prove que o ambiente Sikarugir não herda o CX_HOME nem o CrossOver. Acrescentar o caso a `envcheck.sh`.

**F7. HANDOFF.md mistura estados.** O bloco "Estado" ainda diz "T01/T02 liberados" e "execução autorizada" do escopo antigo, abaixo do aviso novo. Risco de outro agente ler a autorização antiga. **Recomendação:** mover tudo anterior ao reescopo para "Histórico" e deixar um único estado atual: todos aguardam esta revisão.

**F8. Integridade das fronteiras de teste (T11).** Parar-se ao usar Steam Windows está bem; acrescentar verificação explícita de que o jogo instalado é a versão Windows (manifest/depot) e de que o Steam nativo não selecionou o build macOS.

### P3 — observações

- T01 cita Swift 6.2; o ambiente medido tem Swift 6.4 (relatório já registra). Atualizar o texto do plano para "≥ 6.2".
- #18 corretamente não Done e fora dos gates da integração; T09 deve construir a partir do fonte 1.1.1 e documentar isso.
- Rosetta PASS e hashes de T01 foram reproduzidos nesta sessão (5/5), mas são evidência de inventário, não de viabilidade.
- Verificado: todos os arquivos citados nos "Files" de T06–T09 e os checks `buildcheck/envcheck/seedcheck/bridgecheck/routecheck` existem; `resolve.py` existe; os alvos `make runcheck`/`bridge` existem.

## Distinção documento × evidência
Documentação/plano: spec, plano, PROJECT.md, HANDOFF.md. Evidência reproduzida nesta revisão (inventário local): hashes da engine, backups de saves, build Steam 1791415817, ausência de perfil exato, comportamento do loader por leitura de código. **Nenhuma evidência de runtime** (ponte, Steam API, jogo, rollback real) existe; todos os gates continuam NOT RUN.

## Pedido ao coordenador
Aplicar F1–F5 no plano/cards (F1, F2 e F4 exigem decisão de Elvis) e atualizar HANDOFF.md (F7); só então liberar T01/T02. Esta revisão não libera cards nem encerra gates.
