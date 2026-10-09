# Recuperação de alterações isoladas

Data: 2026-10-08 · Agente: codex · Executor: gpt-6.1-sol.

## Pré-condições de implantação

Este procedimento não autoriza deploy nem encerra T02. Fechar Steam, conferir processos e revalidar build suportado, hashes, espaço e Steam Cloud antes de qualquer implantação. Resolver localização do jogo e preservar todos os saves antes de teste de jogo. Não tratar backups antigos do NotProton como cópias do estado atual.

## Ordem

1. Criar manifesto local privado dos **arquivos exatos realmente tocados**, incluindo existência anterior, hash, modo e alvo de link. Incluir executáveis/payloads, plists, configurações e metadados de assinatura afetados pela operação revisada.
2. Copiar os itens existentes para backup privado independente ou clone APFS. Não usar hard links. Para links, preservar o link sem seguir o alvo. Marcar arquivos antes inexistentes explicitamente. Conferir conteúdo, modo e links de cada backup antes de prosseguir.
3. Preservar wrapper, prefixo, biblioteca, saves e ferramentas alheias. Implantar apenas o artefato experimental no destino aprovado; não substituir o app original ou remover a pasta de suporte inteira.
4. Em rollback, encerrar os processos da integração. Restaurar somente cada item do manifesto a partir da cópia conferida; remover somente arquivos criados pela operação que antes não existiam. Não apagar diretórios compartilhados.
5. Comparar hashes, modos, links, configurações e assinatura operacional com a referência. Conferir abertura do Steam original e do wrapper pela UI antes de declarar recuperação funcional. Saves e Steam Cloud requerem readback separado; não sincronizar conflitos automaticamente.

## Ensaio executado

**PASS**, exclusivamente em `scratch/sikarugir/recovery-*`: arquivo alterado recuperou conteúdo SHA-256 e modo 0640; link recuperou alvo original; arquivo antes inexistente desapareceu; arquivo alheio permaneceu. Backup foi independente via `copy2`, sem hard links. Asserts verificaram cada pós-condição; resultado permanece no scratch local.

**Não executado:** backup da instalação real, rollback de Steam/NotProton, validação de assinatura operacional e abertura dos apps. O ensaio comprova as pós-condições básicas de arquivo; não comprova recuperação do aplicativo instalado.

## Preservação local de saves — T02, 2026-10-09

Cópia independente de dois `.cok` e dois `.cid` em `scratch/sikarugir/save-backup-20261009` (diretório 0700; conta/path completo somente no manifesto 0600). Conferidos SHA-256, modo e inode distinto para cada original/cópia; total de 77.406.562 bytes. Originais não alterados. Isso protege os arquivos locais encontrados, mas não comprova que constituem todo o estado do jogo nem inclui dados remotos do Steam Cloud.

O backup da instalação real continua NOT RUN: candidatos `touchedFiles` conservam `backupPath=null`. Não restaurar saves sobre o prefixo atual nem sincronizar Cloud usando este procedimento sem resolver o estado local/remoto. Antes de T10, parar enquanto Steam 1791415817 não tiver compatibilidade comprovada e localização/build/Cloud permanecerem desconhecidos.
