# Revisão independente — Gate E4

Data: **2026-10-11**  
Revisor: **Astra — Codex, gpt-6-astra**  
Base revisada: `81f053155068b2aa11b95266438ea45efac29bc1`  
Escopo: critério 15; T10 (#14), T11 (#15) e T12 (#16).

**Parecer: E4 ACEITO COM RESSALVAS. Pode fechar, preservando as exceções explicitamente aceitas por Elvis.**

Revisão independente da execução Claude, realizada somente por leitura de código, documentos, backups e logs locais. Não houve nova sessão de gameplay, rollback ou alteração do ambiente. A revisão Opus foi considerada como referência, sem substituir a conferência independente.

## Parecer por card

| Card | Parecer | Fundamentação |
|---|---|---|
| **T10 — #14** | **ACEITO COM RESSALVAS** | Backup conferido, rollback documentado com assinatura Valve e readback humano, redeploy registrado. Perda de depots permanece **FAIL parcial aceito**, não PASS. |
| **T11 — #15** | **ACEITO COM RESSALVAS** | GHPC instalado com depot Windows, prefixo Sikarugir reutilizado, D3D11 e API Steam registrados, duas saídas limpas. Biblioteca padrão e gameplay por relato são exceções aceitas. |
| **T12 — #16** | **ACEITO COM RESSALVAS** | Sessão e persistência aceitas por relato; guia e recuperação publicados. Esta revisão satisfaz o critério 15, com os limites abaixo. |

## Achados

### 1. Média — rollback funcional não significa preservação integral da biblioteca

**Evidência:** `docs/evidence/deployment-rollback.md:70–88`; `content_log.txt:315–317,461,471`.

Confirmei nos logs a remoção dos depots às **00:37:02**, o download de **8.313.245.008 bytes** do Cities II e a necessidade de baixar novamente **1.565.047.488 bytes** do PEAK. O prefixo PEAK está ausente; `compat_log.txt:206` registra sua exclusão na desinstalação posterior.

A separação causal dos documentos está correta: remoção de depots durante o rollback; exclusão do prefixo durante a desinstalação decidida por Elvis.

**Disposição:** não bloqueia diante do aceite explícito do critério 3. Manter **FAIL parcial aceito**. O `--games` protege prefixos e manifestos da biblioteca padrão; não inclui os arquivos dos jogos em `steamapps/common` nem evita o re-download.

### 2. Baixa — o NOT RUN de jogo após redeploy está desatualizado

**Evidência:** `docs/evidence/deployment-rollback.md:63`; `docs/evidence/game-launch.md`, fechamento com GHPC; `content_log.txt:507–508`; `notproton-run.log:227`.

O GHPC executou das **02:06:42 às 02:07:09**, depois do redeploy das **00:37:43**. O shim terminou com `status=0`; o `Player.log` registra D3D11 e inicialização da API para o AppID correto.

**Disposição:** há prova de **abertura e encerramento após redeploy**. Corrigir documentalmente o NOT RUN, sem transformar essa sessão de 27 segundos em prova de gameplay ou de duração mínima.

### 3. Média — gameplay, duração e persistência continuam dependentes do relato

**Evidência:** `docs/evidence/acceptance.md:43–45`; `docs/evidence/game-launch.md`, seções T12 e fechamento GHPC.

Os dois logs Unity do GHPC registram `MainMenu2_Scene`; não demonstram missão jogada. Os rastros do PEAK usados anteriormente não estão mais disponíveis. O Cloud do PEAK encontrou **zero arquivos**, confirmado em `cloud_log.txt:318,321`.

**Disposição:** critérios 10–12 aceitos exclusivamente na modalidade **PASS por relato**, conforme autorização explícita. Esta revisão não converte relato em evidência técnica nem usa Cloud como prova de persistência do PEAK.

### 4. Média — script reproduz o backup, mas sua validação tem limites

**Evidência:** `tools/rollback_snapshot.py:34–55,63–77`; `docs/runbooks/recovery.md:43–48`.

R1 da revisão Opus foi atendido quanto à disponibilidade: o script está versionado e inclui `--games`. Conferi os **dez backups históricos** contra o manifesto: hashes, modos e campos de links disponíveis coincidem; os inodes das raízes são distintos dos destinos atuais.

Entretanto, o script compara automaticamente apenas hashes e, para arquivos regulares no nível superior, inode. Não compara modo ou alvo de symlink no nível superior; o digest de diretório não representa permissões dos descendentes nem diretórios vazios. A expressão “confere hash e inode de cada alvo” é mais ampla que a implementação.

**Disposição:** ressalva não bloqueante para o ciclo histórico conferido. Antes de reutilizar o procedimento como garantia geral de restauração, ajustar essa descrição ou completar a validação. Bibliotecas adicionais exigem inventário próprio.

### 5. Baixa — critério 13 cobre o wrapper atual, não o wrapper histórico

**Evidência:** `docs/evidence/acceptance.md:46`; `docs/evidence/deployment-rollback.md:64`.

O wrapper histórico foi apagado antes do T10. A prova registrada é a abertura do wrapper atual até `Configure.app`, sem programa definido.

**Disposição:** aceitar nesse escopo restrito. Não declarar regressão funcional completa do wrapper anterior, de seu prefixo ou de jogos nele instalados.

## Decisão final

**O gate E4 pode fechar com ressalvas. O critério 15 está satisfeito por esta revisão independente.** Não identifiquei bloqueador adicional para o aceite pessoal delimitado pelas decisões de Elvis.

R2 e R3 da revisão Opus estão corrigidos: D3D12 permanece não testado; Cloud ativo está distinguido de arquivos efetivamente sincronizados. Os hashes atuais de `notproton.dylib` e `run` coincidem com `acceptance.md`.

Falta a formalização documental: salvar este parecer, atualizar o critério 15 e o estado do gate em `acceptance.md`, corrigir a referência de execução após redeploy e sincronizar HANDOFF/cards/Project. Essas ações não foram realizadas nesta revisão somente leitura.

Não repeti gameplay, UI, rollback vivo ou restauração de saves; não executei a suíte Swift.  
Risco residual: rollback pode exigir re-download, e Cloud não substitui backup local dos saves.

