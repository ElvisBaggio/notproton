# Projeto — jogos Windows no Steam nativo com Sikarugir

Atualizado: 2026-10-09 · Autor: codex

- [Repositório privado](https://github.com/ElvisBaggio/notproton)
- [NotProton · Jogos Windows no Steam macOS — Project e cards](https://github.com/users/ElvisBaggio/projects/8)
- [PR de revisão do plano](https://github.com/ElvisBaggio/notproton/pull/17)
- [Especificação](docs/superpowers/specs/2026-10-08-sikarugir-cities2-design.md)
- [Plano de implementação](docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md)
- [Política de agentes e alternativa Claude Code](docs/AGENT_EXECUTION.md)

## Épicos e cards

| ID | Issue | Responsável / modelo padrão | Alternativa Claude Code | Depende de |
|---|---|---|---|---|
| E1 | [#1 — Preparação e referência recuperável](https://github.com/ElvisBaggio/notproton/issues/1) | astra_coordinator / gpt-6-astra | opus para revisão; Astra coordena | gate dos filhos |
| T01 | [#5 — Fixar identidade da engine Sikarugir 11.0 e verificar ABI pelo binário](https://github.com/ElvisBaggio/notproton/issues/5) | engine_audit / gpt-6.1-sol | opus | revisão do plano |
| T02 | [#6 — Inventariar Steam e preparar restauração verificável](https://github.com/ElvisBaggio/notproton/issues/6) | baseline_recovery / gpt-6.1-sol | sonnet | revisão do plano |
| E2 | [#2 — Viabilidade da ponte Wine–Steam](https://github.com/ElvisBaggio/notproton/issues/2) | astra_coordinator / gpt-6-astra | opus para revisão; Astra coordena | gate dos filhos |
| T03 | [#7 — Compilar a ponte e o shim para a base verificada do Sikarugir](https://github.com/ElvisBaggio/notproton/issues/7) | wine_bridge / gpt-6.1-sol | opus | [#5](https://github.com/ElvisBaggio/notproton/issues/5) |
| T04 | [#8 — Resolver e validar os patches ntdll específicos da engine](https://github.com/ElvisBaggio/notproton/issues/8) | ntdll_port / gpt-6.1-sol | opus | [#5](https://github.com/ElvisBaggio/notproton/issues/5), [#7](https://github.com/ElvisBaggio/notproton/issues/7) |
| T05 | [#9 — Provar Steam API real pelo motor isolado — gate de viabilidade](https://github.com/ElvisBaggio/notproton/issues/9) | bridge_probe / gpt-6.1-sol | opus | [#6](https://github.com/ElvisBaggio/notproton/issues/6), [#7](https://github.com/ElvisBaggio/notproton/issues/7), [#8](https://github.com/ElvisBaggio/notproton/issues/8) |
| E3 | [#3 — Integração do runner no NotProton](https://github.com/ElvisBaggio/notproton/issues/3) | astra_coordinator / gpt-6-astra | opus para revisão; Astra coordena | gate dos filhos |
| T06 | [#10 — Adicionar origem Sikarugir ao catálogo e aos caminhos do runner](https://github.com/ElvisBaggio/notproton/issues/10) | runner_model / gpt-6.1-sol | sonnet | [#9](https://github.com/ElvisBaggio/notproton/issues/9) |
| T07 | [#11 — Integrar cópia, patch, instalação e reparo sem dependência CrossOver](https://github.com/ElvisBaggio/notproton/issues/11) | runner_lifecycle / gpt-6.1-sol | opus | [#10](https://github.com/ElvisBaggio/notproton/issues/10) |
| T08 | [#12 — Adaptar launcher, prefixos e ferramentas Wine ao motor fixado](https://github.com/ElvisBaggio/notproton/issues/12) | launch_prefix / gpt-6.1-sol | sonnet | [#11](https://github.com/ElvisBaggio/notproton/issues/11) |
| T09 | [#13 — Expor ferramenta na interface e empacotar o fork sem atualização indevida](https://github.com/ElvisBaggio/notproton/issues/13) | app_integration / gpt-6.1-sol | sonnet | [#12](https://github.com/ElvisBaggio/notproton/issues/12) |
| E4 | [#4 — Jogo Windows pelo Steam nativo com persistência e rollback](https://github.com/ElvisBaggio/notproton/issues/4) | astra_coordinator / gpt-6-astra | opus para revisão; Astra coordena | gate dos filhos |
| T10 | [#14 — Implantar com backup e testar retorno ao estado anterior](https://github.com/ElvisBaggio/notproton/issues/14) | deployment_validation / gpt-6.1-sol | sonnet | [#6](https://github.com/ElvisBaggio/notproton/issues/6), [#13](https://github.com/ElvisBaggio/notproton/issues/13) |
| T11 | [#15 — Instalar jogo Windows de teste e abrir pelo Steam nativo](https://github.com/ElvisBaggio/notproton/issues/15) | cities_integration / gpt-6.1-sol | sonnet | [#14](https://github.com/ElvisBaggio/notproton/issues/14) |
| T12 | [#16 — Validar sessão, persistência/reabertura e documentar operação](https://github.com/ElvisBaggio/notproton/issues/16) | acceptance_docs / gpt-6-luna | sonnet | [#15](https://github.com/ElvisBaggio/notproton/issues/15) |

## Escopo e prontidão efetivos — 2026-10-09

Instalar versões Windows e iniciar pelo Steam nativo Mac com Sikarugir 11.0 revision 0 fixado. A base será validada com jogo simples legitimamente disponível, instalação nova em biblioteca isolada; Cities II opcional depois, sem gate de localização/build/Cloud. Não é suporte a qualquer engine ou garantia de todos os jogos.

Claude Code Sonnet 5.5 revisou o reescopo e recomendou aprovação com ajustes F1–F8 em [findings](docs/reviews/claude-scope-review-findings.md). Elvis decidiu gerar perfil de assinaturas para o build Steam atual, solicitar ao mantenedor o manifesto da engine ([pedido](https://github.com/Sikarugir-App/Sikarugir/issues/288)) e escolher o jogo-base após T02. Ajustes documentais e cards aplicáveis foram sincronizados. T01/T02 foram retomados em worktrees paralelos. Em 2026-10-09 Elvis replanejou T01 (D2-c): gate = ABI verificada no binário contra o upstream `wine-11.0`, sem depender do mantenedor; T01 concluído com ABI PASS (`claude/t01-abi-check`) e T02 concluído com perfil Steam 1791415817 validado por `anchorcheck` real (`claude/t02-steam-profile`); ambos integrados e revisados por Claude Code Opus 5.5. T03 liberado. T03–T05 ainda exigem ABI/API reais; rollback continua obrigatório. T12 mantém Luna 6 e >=15 minutos com persistência/reabertura (save se suportado, dados pertinentes/configuração caso contrário). #18 não Done.

## Execução e estado (histórico anterior ao reescopo)

Estado inicial: 4 épicos e 12 cards em Todo, com Prontidão = Aguarda revisão do plano. Os cards têm relação nativa de sub-issue com o épico e bloqueadores nativos entre tarefas.

Readback em 2026-10-08 confirmou os 16 itens, 12 relações pai/filho, 14 bloqueadores nativos, todos os campos de responsabilidade e igualdade dos documentos locais/remotos. Distribuição: 4 épicos coordenados por Astra, 11 cards Sol 6.1 e 1 card Luna 6; cada card contém alternativa Claude Code.

O plano usa subagentes por card e revisão independente. Após a revisão Sonnet 5.5 e decisões de Elvis, liberar T01/T02 quando os ajustes documentais e os cards estiverem sincronizados; os demais só avançam após dependências e gates. Modelos indicados não são contas GitHub nem representam agentes já executando.

T01/T02 podem ocorrer em paralelo em worktrees/territórios distintos. T03–T12 são sequenciais pelo acoplamento das interfaces. Ao fechar cada card, incluir evidência, commit, checks, pedido de revisão a Claude Code Opus 5.5 e sincronizar Status; o épico só fecha depois de seus filhos e gate.

Nenhuma implementação começou. Runtime, save/reabertura e rollback continuam não executados.

## Retomada e manutenção 1.1.1 — 2026-10-08

Autor: codex. Branch `codex/sikarugir-ubisoft-1.1.1`. T01/T02 retomados por Sol 6.1 com evidências; T01 bloqueado por fonte/patchset e T02 parcial. Nenhum gate runtime encerrado.

[M01 / #18](https://github.com/ElvisBaggio/notproton/issues/18): `upstream_update` / `gpt-6.1-sol`, revisão independente Astra. Backport do patch agregado 1.1.1 e versão; teste de contrato host e checks bridge/route passaram. Build PE e descoberta no Ubisoft Connect continuam pendentes. Não confundir esta manutenção com conclusão de T03/T08 ou integração Sikarugir funcional.

## Execução dos cards — 2026-10-09

Autor: codex. Branch `codex/sikarugir-card-execution`; T01/T02 anteriores executados por `gpt-6.1-sol`, revisão por `gpt-6-astra`. T01 segue bloqueado pela origem da fonte/patchset. T02 possui backup independente de quatro saves locais e investigação direta no filesystem, sem localização atual do jogo nas áreas acessíveis; perfil de assinatura para o Steam atual ainda precisa ser validado; Cloud não comprovada. Esses registros são históricos e serão migrados/conferidos no escopo reespecificado antes do fechamento dos cards.
