# NotProton pessoal — regras dos agentes

@/Users/elvisoliveira/.codex/RTK.md

Comunicação em português brasileiro. Projeto: instalar jogos Windows e iniciar pelo Steam nativo do Mac, com Sikarugir 11.0 revision 0 fixado inicialmente e sem dependência de CrossOver. Cities II é teste opcional posterior. Claude Code Sonnet 5.5 revisou o plano em `docs/reviews/claude-scope-review-findings.md` e recomendou aprovação com ajustes F1–F8; os ajustes documentais e cards aplicáveis estão sincronizados. T01 e T02 foram retomados em worktrees paralelos e permanecem BLOCKED: fonte/patchset e perfil Steam exato pendentes. T03 não inicia sem T01 concluído.

## Fonte de verdade

- Leia `HANDOFF.md`, a especificação e o plano em `docs/superpowers/` antes de trabalhar.
- Repositório pessoal: `ElvisBaggio/notproton`; `upstream` é o projeto original. Nunca enviar trabalho pessoal ao upstream sem pedido explícito.
- GitHub Project: https://github.com/users/ElvisBaggio/projects/8. Cards e dependências são o contrato de execução.
- No início, `git pull --ff-only` na branch com tracking. Trabalho em branch própria; main só com trabalho concluído. Nunca `push --force`.

## Modelos e propriedade

- Astra (`gpt-6-astra`) planeja, coordena e revisa; não implementa.
- Implementação padrão: Sol 6.1 (`gpt-6.1-sol`); Luna 6 (`gpt-6-luna`) somente nos cards atribuídos a ele.
- Claude Code é alternativa autorizada pelo usuário: usar `sonnet` ou `opus` conforme o card, registrar o modelo efetivo. Detalhes em `docs/AGENT_EXECUTION.md`.
- Uma execução por card/território. Você não está sozinho no repositório: preserve mudanças alheias e não edite arquivos de outro responsável em paralelo.
- Não iniciar cards além de T01/T02 antes de suas dependências e gates. A revisão aprovada com ajustes não encerra gates de runtime. Ao final de cada card, deixar pedido de revisão para Claude Code Opus 5.5 e registrar modelo efetivo do revisor.

## Evidência e encerramento

- Preservar wrapper, biblioteca e saves; alterações somente em cópias e prefixos isolados. Manter validação de origem, hashes, arquitetura e bytes de patches.
- Binários de terceiros, backups, dados de conta e logs privados ficam em `scratch/` ignorado; nunca commitar segredos.
- Não declarar runtime funcionando por build/processo/hash. Cumprir a prova exigida no card, incluindo save/reabertura e rollback quando aplicável.
- Encerrar com revisão, checks, `HANDOFF.md` (Agente: codex ou claude), commit `[codex] ...`/`[claude] ...`, push e sincronização issue/Project.
- Se `.codegraph/` existir, usar CodeGraph antes de buscar código; sem índice, usar `rg`.
