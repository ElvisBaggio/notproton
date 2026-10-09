# Execução dos agentes

Data: 2026-10-08 · Autor: codex

Astra (`gpt-6-astra`) planeja, coordena e revisa. Implementação padrão: Sol 6.1 (`gpt-6.1-sol`); tarefas pequenas explicitamente atribuídas: Luna 6 (`gpt-6-luna`).

Elvis autorizou em 2026-10-08 uma alternativa de execução pelo Claude Code. Cada card declara `sonnet` ou `opus` como alias alternativo; não é fallback automático. Ao iniciar, registrar no card cliente, nome do subagente, modelo efetivamente resolvido e branch. Os aliases seguem a versão disponível na conta; não presumir disponibilidade nem inventar uma versão. O CLI local consultado aceita `--model` com esses aliases. Se o modelo atribuído não estiver disponível, reportar antes de trocar.

A escolha do cliente ocorre uma vez por card. Não executar Codex e Claude simultaneamente nos mesmos arquivos. Um revisor separado (Astra, Sol 6.1 ou Claude Code Opus) verifica evidências e regressões; o autor não encerra sozinho um gate de runtime.

## Papéis e território

Os nomes de subagente nos cards são papéis de execução, não contas GitHub nem agentes já iniciados. O campo Assignee do GitHub não é usado para fingir atribuição a um modelo. O campo Subagente e os campos Modelo principal/Alternativa Claude registram a responsabilidade.

- Leia AGENTS.md, HANDOFF.md, especificação e plano, além do card e suas dependências.
- Trabalhe em branch própria; execute um card por vez no mesmo checkout. Use worktree isolado se houver execução paralela autorizada.
- Não reverta alterações alheias. Avise o coordenador sobre sobreposição de arquivos.
- Antes de implementar, registrar o início e mover o card a In Progress. Prontidão só vira Pronto após revisão do plano e dependências concluídas.
- Ao terminar, incluir commit, testes, evidências, riscos, atualizar HANDOFF.md, fazer push sem force e sincronizar issue e Project.
- Uma issue fechada exige Status Done no Project. Épico só fecha quando os filhos e seu gate funcional estiverem aceitos.

## Handoff para Claude Code

Exemplo de início manual, após liberação do card: `claude --model sonnet` (ou `opus`, conforme o card). Instrução inicial: “Atue como o subagente indicado na issue; leia AGENTS.md, HANDOFF.md, a especificação e o plano. Execute somente esse card, preservando os territórios dos outros agentes. Registre o modelo efetivo e os checks.”

O arquivo CLAUDE.md importa AGENTS.md. Não é necessário lançar Claude nem enviar conteúdo a ele para preparar esta opção; nenhuma sessão Claude foi iniciada nesta publicação.

## Reescopo de 2026-10-09 — revisão concluída com ajustes

Claude Code Sonnet 5.5 recomendou aprovação com ajustes F1–F8; findings em `docs/reviews/claude-scope-review-findings.md`. Elvis decidiu gerar perfil para o build Steam atual, solicitar ao mantenedor a proveniência da engine (pedido em https://github.com/Sikarugir-App/Sikarugir/issues/288) e selecionar o jogo depois do inventário T02. Ajustes de plano/spec e descrições dos cards aplicáveis foram publicados. T01/T02 foram retomados em paralelo em worktrees distintos; ambos permanecem bloqueados por evidências faltantes. T01 não libera T03 sem base fixada e `abiCheck.status=PASS` (replanejamento D2-c de 2026-10-09; fonte do mantenedor, se chegar, substitui a verificação). `cities_integration` mantém o nome histórico do papel de T11, agora teste de jogo Windows simples com instalação nova; não indica dependência de Cities II.

Ao final de cada card, registrar evidências e deixar pedido de revisão para Claude Code Opus 5.5, conforme solicitação de Elvis. A versão/modelo efetivo deve ser registrado pelo revisor; não assumir disponibilidade de alias/versionamento.
