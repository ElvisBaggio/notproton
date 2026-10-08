# Inventário somente leitura — T02

Data: 2026-10-08 · Agente: codex · Executor: gpt-6.1-sol · Cliente: Codex.

## Estado observado

- NotProton instalado e suporte local: **1.1.0**; o shim `bridge/steam.exe` existe.
- Wrapper Sikarugir original: motor Wine 11.0 r0, prefixo próprio, programa principal Steam Windows. D3DMETAL=0, DXVK=0, WINEESYNC=1, WINEMSYNC=1 são configuração declarada; renderer efetivamente carregado permanece não validado.
- Steam nativo: última linha `Client version` do `content_log.txt`, em 2026-10-08, informa **1791415817**. O CFBundleVersion 6.1 é do bootstrapper e não deve substituir o build do cliente. Compatibilidade ainda precisa casar com as assinaturas suportadas.
- Biblioteca Windows registra AppID 949230 e 460930. O drive S: continua apontando para diretório inexistente. Não há manifesto/build do Cities II confirmado no alvo; a entrada da biblioteca não prova instalação utilizável.
- Saves do Cities II encontrados no prefixo: **dois arquivos .cok e dois .cid**. Caminhos completos e conta ficam somente no manifesto ignorado.
- `UbisoftConnect.exe` não foi encontrado sob `drive_c`. Ghost Recon Wildlands consta no registro, mas isso não prova cliente Ubisoft instalado nem fluxo operacional.
- Registros HKCU/HKLM Valve/Steam do wrapper apontam para o **Steam Windows real**. A descoberta nesse prefixo não demonstra o comportamento do shim NotProton pelo Steam nativo.
- Espaço livre observado: aproximadamente **418 GB**. Revalidar antes de qualquer cópia.

## Evidência e limites

Manifesto local: `scratch/sikarugir/system-baseline.json`, schemaVersion=1, modo 0600, diretório 0700. Registra hashes/modos/links dos candidatos de preservação. `backupPath=null` significa que **nenhum backup foi criado**; não é um backup utilizável nem manifesto final de deploy.

Nenhum wrapper, Wine, Ubisoft Connect ou jogo foi executado. Nenhum arquivo da instalação foi alterado. Steam Cloud continua desconhecido. Build, localização atual do jogo, renderer carregado e teste de save/reabertura continuam pendentes.

## Prova proporcional da correção 1.1.1

Testar em prefixo descartável com cópia isolada da engine: registrar o shim no HKLM esperado e consultar sua presença pelo mecanismo de descoberta Windows usado pelo Ubisoft. O executável deve existir no caminho anunciado. A regressão automatizada precisa falhar na 1.1.0 e passar no backport da 1.1.1.

Esse teste confirma o contrato de descoberta. Aceitação ponta a ponta ainda exige Ubisoft Connect presente no prefixo isolado e observação de que reconhece Steam; não usar o Steam Windows real do wrapper como evidência do novo fluxo. Os gates de ponte/ABI e Cities II continuam separados.

## Ensaio de recuperação

PASS em scratch privado: conteúdo, modo e link restaurados; arquivo criado removido; arquivo alheio preservado. Ver runbook recovery.md. Não houve restauração sobre instalações reais. T02 permanece parcial pelos critérios de jogo/build/Cloud e compatibilidade Steam pendentes.
