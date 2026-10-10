# Recado para Claude Code Opus — revisão do reescopo

Data: 2026-10-09 · Autor: codex · Estado: concluída por Claude Code Sonnet 5.5, com recomendação de aprovação após ajustes. Findings: [claude-scope-review-findings.md](claude-scope-review-findings.md). A autorização de Elvis para usar Sonnet nesta sessão ficou registrada no relatório.

Branch efetiva do reescopo: `codex/game-agnostic-scope`. Revise os documentos dessa branch; as referências dos cards apontam para ela, preservando os nomes históricos dos arquivos.

Elvis autorizou reescopar os cards para instalar a versão Windows de jogos e iniciar pelo Steam nativo do Mac, usando Sikarugir 11.0 revision 0 fixado inicialmente, sem CrossOver. Cities II vira teste opcional posterior; sua localização, build e Cloud não bloqueiam a integração base. Não se promete compatibilidade com todos os jogos nem suporte agnóstico a engines.

Atue somente como revisor Claude Code `opus`, registrando modelo efetivo quando iniciado manualmente. Leia AGENTS.md, HANDOFF.md, PROJECT.md, docs/AGENT_EXECUTION.md, a especificação e o plano em docs/superpowers/, cards #1–#16 e as evidências já existentes. Os nomes históricos dos arquivos e do papel `cities_integration` foram preservados.

Revise a coerência com os objetivos acima, a rastreabilidade da origem/fonte/patchset de T01, a ABI/arquitetura/bytes/hashes e API real de T03–T05, o suporte/assinatura efetivos do Steam, isolamento, rollback e os marcos de instalação Windows e sessão persistente. Verifique T02 como inventário/recuperação geral com referenceGame opcional; T05 com AppID legítimo selecionado; T11 como instalação nova de jogo Windows simples legitimamente disponível; T12 mantendo Luna 6, >=15 minutos e save/reabertura se suportado, senão dados pertinentes/configuração persistente. Preserve modelos, alternativas, relações pai/filho e dependências.

Publique findings priorizados com referências e recomendação de aprovação/ajustes em arquivo versionado sob docs/reviews/ ou na PR de revisão. Diferencie documentação de evidência runtime. #18 continua não Done e não encerra gates da integração.

Esta mensagem registrou o escopo pedido ao revisor. A revisão foi concluída em `8462af8`; F1–F8 foram incorporados ao plano/spec e aos cards aplicáveis. T01/T02 foram retomados em worktrees separados e continuam bloqueados pelas evidências registradas nos próprios cards. Não iniciar T03–T12 sem dependências e gates técnicos cumpridos.
