# Recuperação de alterações isoladas

Data: 2026-10-09 · Agente: codex · Executor: gpt-6.1-sol · Cliente: Codex.

## Pré-condições de implantação

Este procedimento não autoriza deploy nem encerra T02. Antes de T10, fechar Steam e confirmar processos encerrados; revalidar build efetivo, perfil exato suportado, hashes, assinatura e espaço. **T02 está BLOCKED pela ausência de perfil validado para 1791415817.** O perfil mais alto existente, 1790904859, não substitui essa prova. Não alterar o canal `publicbeta` nem bloquear updates para contornar o gate.

O app/suporte NotProton **1.1.0** e a injeção preexistente no plist externo do Steam são o estado anterior observado; a fonte **1.1.1** não foi implantada. A recuperação deve preservar esse estado, inclusive ferramentas/configurações alheias. Não tratar backups antigos como cópias do estado atual.

O jogo-base será escolhido após T02. Antes de T11, conferir seu AppID/build, prefixo/biblioteca isolados, espaço e estado local/remoto do Steam Cloud. A localização/build/Cloud do Cities II é opcional para a integração base; antes de eventual teste desse jogo, resolver essas informações e preservar seus dados específicos.

## Manifesto e ordem de recuperação

1. Usar manifesto privado schemaVersion=1 com `steamClientBuild`, `steamSupportEvidence`, `wrapperState`, `diskFreeBytes` e `touchedFiles[{path,existed,sha256,mode,symlinkTarget,backupPath}]`. Antes de T10, preencher **todos os destinos realmente tocados**, incluindo payloads/executáveis, plists interno/externo, registros de ferramentas, configs, hashes/metadados de assinatura e ferramentas afetadas. `touchedFiles=[]` em T02 significa zero alteração viva; `wrapperState.preservationCandidates` é inventário, não backup de deploy.
2. Capturar imediatamente antes da alteração o estado do destino e seu backup privado independente ou clone APFS. Não usar hard links. Copiar symlinks sem seguir o alvo. Marcar destinos antes inexistentes. Conferir hash/modo/link e independência de cada backup. `backupPath=null` não atende ao gate de backup de um arquivo existente que será alterado.
3. Preservar wrapper, engine, prefixo, biblioteca, saves e ferramentas alheias. Implantar somente nos destinos aprovados, com identidade/diretório exclusivo da integração experimental. Não usar a remoção global de Uninstall para desfazer esta integração.
4. Em rollback, encerrar os processos da integração. Restaurar somente os itens existentes do manifesto a partir de backups conferidos; remover somente itens criados pela operação, marcados como antes inexistentes. Não apagar diretórios compartilhados nem remover a pasta de suporte inteira.
5. Comparar hashes, modos, links, configurações e estado anterior dos registros/ferramentas. Verificar a assinatura operacional dos apps: copiar metadados de assinatura isoladamente não comprova validade. Uma alteração que não permita recompor o estado assinado precisa de retorno Valve revisado antes do deploy; a função SteamRepair substitui bundle e limpa configurações, então não é rollback automático do fork.
6. Conferir abertura do Steam original e do wrapper pela UI no gate funcional autorizado. Preservar versões local/remota de saves antes de qualquer conflito Cloud, sem resolver sincronização automaticamente. Só declarar recuperação funcional após esses checks; hashes ou processo não bastam.

## Ensaio atual — 2026-10-09

**PASS**, exclusivamente em diretório privado descartável `/private/tmp/notproton-t02-*/recovery`, indicado no manifesto local. Foram simulados arquivo alterado, symlink alterado e arquivo criado pela operação. Asserts compararam estado antes/depois: conteúdo/SHA-256 e modo **0640** restaurados, symlink com alvo original, arquivo antes inexistente removido e arquivo alheio preservado. Backup via `copy2`, sem hard link, com inode independente conferido. Nenhuma restauração sobre app, biblioteca, prefixo ou save real.

O ensaio histórico de 2026-10-08 em `scratch/sikarugir/recovery-*` também passou; ele é evidência histórica distinta. O ensaio atual confirma somente pós-condições de arquivos sintéticos. **NOT RUN:** backup de toda instalação atual, rollback vivo, assinatura operacional restaurada, UI/reabertura dos apps, Steam Cloud e persistência de jogo.

## Preservação local de saves — histórico e readback atual

As quatro cópias históricas em `scratch/sikarugir/save-backup-20261009` foram revalidadas em 2026-10-09: dois `.cok` e dois `.cid`, **77.406.562 bytes**, SHA-256/modos iguais aos originais e inodes distintos. Paths de conta permanecem no manifesto local 0600; nenhum save foi modificado, restaurado ou novamente copiado. O resultado não comprova todo o estado do jogo nem inclui dados remotos Cloud.

O manifesto atualizado preserva integralmente o inventário anterior em `historicalEvidence`; `referenceGame` mantém os campos Cities II opcionais. Não restaurar saves sobre o prefixo atual nem sincronizar Cloud a partir deste ensaio. Instalação viva, UI e jogo seguem pendentes dos gates respectivos.

## Pedido de revisão

Claude Code **Opus 5.5**: revisar o manifesto schemaVersion=1, limites do sigcheck/parser, bloqueio do perfil Steam exato, proteção do estado preexistente e ordem de recuperação. Registrar o modelo efetivo usado; manter T02 In Progress/BLOCKED até cumprir o aceite. O pedido será publicado na issue #6 com o commit da tarefa.

## Rollback vivo — procedimento validado no T10 (2026-10-11)

Agente: claude · Modelo efetivo: opus (claude-opus-5-5). Evidência: `docs/evidence/deployment-rollback.md`. Substitui o "NOT RUN" acima para rollback vivo, assinatura e UI do Steam; Steam Cloud e persistência de jogo continuam com T11/T12. A pendência de perfil do T02 descrita nas pré-condições foi resolvida (perfis `1791415817` e `1791592380`).

1. **Fechar o Steam** (Cmd+Q) e conferir que não há `steam_osx` nem jogo/Wine rodando.
2. **Backup:** `python3 -I tools/rollback_snapshot.py <dir>/manifest.json --backup <dir>/files --games` (`<dir>` em `scratch/`, ignorado). Clona por APFS e confere o hash de cada alvo (e o inode, nos arquivos do nível superior; não confere modo, alvo de symlink no topo, permissões internas nem diretórios vazios): `/Applications/Steam.app`, os plists externo e interno, os dois `steam.cfg`, `compatibilitytools.d/notproton-*`, `config.vdf` e o registro em `notproton/`. Para se algum alvo divergir.
3. **Rollback:** no NotProton Sikarugir.app, **Repair Steam**. Restaura o bundle Valve por download com hash fixado, limpa a injeção interna e remove o bloqueio de atualização. Depois **mover** (não apagar) `compatibilitytools.d/notproton-*` para o backup. Não usar **Remove**, que apaga a pasta de suporte, os runners e os templates.
3a. **Antes de abrir o Steam sem a ferramenta** (lição do T10, 2026-10-11): sem nenhuma ferramenta de compatibilidade, o Steam do Mac remove os depots Windows dos jogos instalados e, quando a ferramenta volta, exige re-download do conteúdo (8,3 GB no Cities II). Uma desinstalação nesse estado apaga o `compatdata/<appid>` (prefixo e saves locais). Antes do readback: (i) incluir no backup `steamapps/compatdata/*` e `steamapps/appmanifest_*.acf` de todo jogo que use a ferramenta (o `--games` do passo 2 faz isso na biblioteca padrão), ou (ii) fazer o readback do Steam original **sem jogos Windows instalados** (desinstalar antes, com saves copiados), ou (iii) aceitar por escrito a perda e o re-download. Não basta Steam Cloud: o AutoCloud do PEAK não achou arquivos.
4. **Readback:** `codesign --verify --strict /Applications/Steam.app` com `TeamIdentifier=MXGJJ98X76`; `LSEnvironment` só com `LC_ALL`; sem `notproton.dylib` e sem `steam.cfg`. Depois, pela UI: o Steam abre e a ferramenta some da lista de compatibilidade. Conferir o build em `package/steam_client_publicbeta_signed-2_osx.manifest`. Se mudou, gerar perfil antes do redeploy.
5. **Redeploy:** **Install** no app e novo snapshot sem `--backup`. Todos os alvos devem bater com o manifesto, salvo `config.vdf` (cache de servidores do Steam), a ordem de chaves do `install-build.json` e o `Info.plist.before-notproton` recriado. A ferramenta tem de reaparecer na UI.
6. **Restauração manual** (se o Repair falhar): copiar de volta `files/Applications/Steam.app` e os demais itens a partir do backup, com `cp -Rc -P -p`, e mover a pasta da ferramenta de volta de `moved/`.
