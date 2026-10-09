# Inventário somente leitura — T02

Data: 2026-10-09 · Agente: codex · Executor: gpt-6.1-sol · Cliente: Codex.
Branch: `codex/t02-steam-baseline` · Base documental: `b09836e`.

## Resultado atual: BLOCKED por perfil Steam ausente

O schema atual foi preenchido, o inventário foi revalidado e o ensaio de recuperação passou. T02 permanece **In Progress / BLOCKED** porque não há perfil exato validado para o build observado **1791415817**. A localização/build/Cloud do Cities II é referência opcional histórica e não bloqueia o inventário base. Nenhum jogo-base foi selecionado; isso ocorrerá após T02, pelos critérios D1 do plano.

| Critério | Readback atual | Estado |
|---|---|---|
| Steam nativo | Última linha `Client version`, em 2026-10-08 13:47:01: **1791415817** | Evidência de log; runtime NOT RUN |
| Perfil exato | Fonte e suporte instalado contêm somente **1788400362, 1789086785, 1790904859** | **BLOCKED**; nenhum perfil 1791415817 gerado/validado |
| NotProton | App instalado e suporte **1.1.0**; fonte `dylib/version.h` **1.1.1** | Readback PASS; não houve implantação |
| Injeção preexistente | Plist externo declara o `notproton.dylib` do Steam.app; plist interno não declara `DYLD_INSERT_LIBRARIES` | Estado anterior preservado; não comprova funcionamento |
| Updates | Marcador `package/beta` = **publicbeta**; os dois `steam.cfg` previstos por UpdateBlock estão ausentes | Nenhum bloqueio de updates nesses arquivos; política não alterada |
| Wrapper | `wine sikarugir 11.0 (revision 0)`; programa Steam Windows; D3DMETAL=0, DXVK=0, WINEESYNC=1, WINEMSYNC=1 | Configuração declarada; renderer/runtime NOT RUN |
| Biblioteca nativa | Configuração lista somente raiz padrão, zero AppIDs e zero `appmanifest_*.acf` nessa raiz | Inventário local; não prova catálogo/ownership da conta |
| Biblioteca do wrapper | Configuração lista AppIDs **228980, 460930, 949230, 1705180**; só manifesto 228980 presente na raiz C:; alvo antigo S: continua ausente | Entradas não comprovam instalações utilizáveis |
| Preservação | **26** candidatos registrados; hashes/modos/links monitorados; quatro saves e backups independentes correspondem | PASS de readback, sem afirmar cobertura de todo o estado do jogo |
| Saves encontrados | Duas cópias `.cok` e duas `.cid`, **77.406.562 bytes**; hashes, modos e inodes distintos conferidos | PASS; Cloud e save/reabertura NOT RUN |
| Espaço | **413.696.000.000 bytes**, aproximadamente 413,7 GB livres, via `shutil.disk_usage` | Snapshot; revalidar antes de T10/T11 |
| Recuperação | Diretório descartável em `/private/tmp`; conteúdo/hash, modo 0640, alvo de link, remoção de arquivo novo e arquivo alheio preservado | PASS; rollback de instalação viva NOT RUN |

## Perfil Steam e limites dos checks

`python3 dylib/tests/sigcheck.py` passou para os três perfis: **18 assinaturas por perfil, todas referenciadas**. Esse script compara nomes com os consumidores C; não resolve anchors, não verifica bytes e não vincula o perfil ao binário/build ativo.

| Build do perfil | SHA-256 na fonte e no suporte instalado |
|---|---|
| 1788400362 | `e845128f9c9df505c571c1675ba92d333c4d7245f44981bee31cfcc9ee4a0e35` |
| 1789086785 | `1b2cbc2e91e5f52311dbfdba5839ffe331240968dc796c7f1e78226515422499` |
| 1790904859 | `bba3d3bee778323592e71353f02f2edd44955458da1b5900b4b2d81de643102b` |

Um harness descartável reutilizou `np_load_profile`/`np_free_profile`, `sigdb.c`, `file.c`, `log.c` e cJSON, compilado com ASan/UBSan. **40 fixtures** foram verificadas somente no parser: 37 carregadas e três rejeitadas (`empty_file`, `not_json`, `truncated`), sem crash/diagnóstico de sanitizer. Os três rejeitados correspondem ao status 2 de `EXPECTED`; os demais são apenas carregamentos, não os veredictos completos do anchorcheck. Asserts verificaram módulo preenchido e liberação da estrutura.

`make sigdb-fixtures` e `anchorcheck` completos são **NOT RUN**: carregam bibliotecas Steam por `dlopen`, que pode executar construtores. Não há gerador de perfil no repositório; preencher build/endereço/bytes a partir de perfil antigo seria inferência. A geração/validação exata requer análise específica dos binários e fica pendente para uma etapa com escopo apropriado. Nenhum perfil foi renomeado/copiado como se fosse do build atual, nenhuma biblioteca Steam foi carregada e nenhum hook/injeção foi instalado nesta execução.

## Manifesto local e preservação

`scratch/sikarugir/system-baseline.json`, **schemaVersion=1**, modo **0600**, diretório **0700**, contém `steamClientBuild`, `steamSupportEvidence`, `wrapperState`, `diskFreeBytes` e `touchedFiles`. `referenceGame` preserva a referência opcional Cities II. A evidência anterior completa fica em `historicalEvidence`; os backups antigos mantêm suas referências originais, sem mudar nem recriar os saves.

`touchedFiles=[]` registra que T02 não alterou arquivos de instalações vivas. O inventário de candidatos de preservação está em `wrapperState.preservationCandidates`, com existência/hash/modo/link e `backupPath=null`; não confundir candidatos com backup completo de deploy. T10 terá de gerar o manifesto dos destinos realmente tocados e conferir seus backups imediatamente antes da alteração.

Logs do parser/sigcheck, harness e ensaio ficam no diretório temporário privado indicado pelo manifesto. Não são artefatos versionados nem garantia de retenção permanente. SHA-256 do log de parser: `ab189f8b434c314291cc1a0070e8cede9008f81e1bfff232eb4ae844c6610795`; SHA-256 do log sigcheck: `b97167dfe296f575b9e357b95682281aadc081335260ef2274bf217959a145bd`.

Não foram repetidas as buscas globais de jogos, nem acessadas áreas antes negadas. Nenhum Steam, Wine, wrapper ou jogo foi iniciado; nenhum update, biblioteca, save ou instalação foi modificado. A cobertura de preservação é dos candidatos monitorados, não de toda a árvore de arquivos.

## Próximo passo e revisão

1. Gerar e validar um perfil exato para **1791415817**, incluindo todos os anchors/bytes necessários, em escopo apropriado; repetir o readback se Steam atualizar. Não fixar ou desabilitar updates para contornar o gate.
2. Solicitar revisão independente a **Claude Code Opus 5.5**, conforme pedido de Elvis; o revisor registra modelo efetivo e separa parser/nome de suporte real do cliente. T02 não fica Done por esses checks estáticos.
3. Após conclusão de T02, selecionar jogo-base segundo D1 e validar AppID/build/Cloud nas tarefas respectivas. T03 continua dependente da fonte/patchset em T01.

## Evidência histórica anterior aos ajustes F1–F8

As seções abaixo preservam os inventários e buscas anteriores. Seus critérios antigos de localização/build/Cloud do Cities II não são os critérios atuais de conclusão de T02; o resultado atual está acima.

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

Manifesto local: `scratch/sikarugir/system-baseline.json`, schemaVersion=1, modo 0600, diretório 0700. Registra hashes/modos/links dos candidatos de preservação. `backupPath=null` nos candidatos de instalação significa que **nenhum backup da instalação foi criado**; não é manifesto final de deploy. O manifesto agora também contém `saveBackups`, com quatro cópias independentes conferidas de saves locais, sem publicar paths de conta.

Nenhum wrapper, Wine, Ubisoft Connect ou jogo foi executado. Nenhum arquivo da instalação foi alterado. Steam Cloud continua desconhecido. Build, localização atual do jogo, renderer carregado e teste de save/reabertura continuam pendentes.

## Prova proporcional da correção 1.1.1

Testar em prefixo descartável com cópia isolada da engine: registrar o shim no HKLM esperado e consultar sua presença pelo mecanismo de descoberta Windows usado pelo Ubisoft. O executável deve existir no caminho anunciado. A regressão automatizada precisa falhar na 1.1.0 e passar no backport da 1.1.1.

Esse teste confirma o contrato de descoberta. Aceitação ponta a ponta ainda exige Ubisoft Connect presente no prefixo isolado e observação de que reconhece Steam; não usar o Steam Windows real do wrapper como evidência do novo fluxo. Os gates de ponte/ABI e Cities II continuam separados.

## Ensaio de recuperação

PASS em scratch privado: conteúdo, modo e link restaurados; arquivo criado removido; arquivo alheio preservado. Ver runbook recovery.md. Não houve restauração sobre instalações reais. T02 permanece parcial pelos critérios de jogo/build/Cloud e compatibilidade Steam pendentes.

## Readback adicional — 2026-10-09

| Critério T02 | Resultado observado | Estado |
|---|---|---|
| Cliente nativo | Última linha `Client version`, `content_log.txt`: 2026-10-08 13:47:01, build **1791415817** | Identificado por log; runtime NOT RUN |
| Perfis Steam | Repositório e suporte instalado têm somente **1788400362, 1789086785, 1790904859**; não há perfil exato 1791415817 | Compatibilidade não comprovada; bloqueia avanço |
| Localização/build | Biblioteca nativa só declara raiz padrão e não lista o jogo. Biblioteca Windows declara `S:\SteamLibrary`; alvo de S: ausente | Não localizado; build desconhecida |
| Cloud | Logs Windows de 2026-09-28 registram sync completo **não tentado**. Ausência de `userdata/*/949230/remotecache.vdf` nos dois clientes | Estado atual desconhecido |
| Preservação saves | Duas cópias `.cok` e duas `.cid`, **77.406.562 bytes**, em scratch privado; SHA-256, modos e inodes independentes conferidos | PASS de cópia local; abertura/reabertura NOT RUN |
| Espaço | Aproximadamente **413 GB** livres após cópia | Revalidar no deploy |

O loader atual (`dylib/core/loader.c`, `pick_latest_sigdb`) escolhe o maior perfil disponível, salvo override, e exige resolver todas as assinaturas de `steamclient.dylib` antes de instalar esses hooks. Isso não demonstra suporte ao cliente 1791415817. Não foi executado fallback nem resolução/injeção em cliente ativo; ausência do perfil exato exige revisão da compatibilidade antes de T02/T10 serem liberados.

Busca somente leitura cobriu os manifestos das duas bibliotecas, prefixo, `My Games`, `Downloads`, `Documents`, `Applications` e consulta Spotlight por `Cities2.exe`/`appmanifest_949230.acf`. Não houve resultado nesses alvos. `/Volumes` contém somente Macintosh HD e Recovery neste readback. Logs históricos de instalação e launcher apontam para `S:\SteamLibrary\steamapps\common\Cities Skylines II` em 2026-09-28; eles não localizam a instalação atual. A ausência nesses alvos **não prova ausência do jogo no Mac** nem invalida o relato de Elvis de que abre pelo Sikarugir.

### Próximo passo e parada

1. Localização permanece pendente após a busca filesystem descrita abaixo: consultar áreas negadas somente com acesso explicitamente concedido ou um caminho comprovado. Não inferir ausência global nem iniciar jogo para localizar.
2. Resolver em revisão técnica a compatibilidade do Steam 1791415817 com um perfil correspondente e validação das assinaturas. Não aplicar perfil antigo por suposição nem modificar Steam para contornar o gate.
3. Conferir estado atual do Steam Cloud por readback no cliente correto e preservar versões local/remota antes de eventual resolução de conflito.
4. Criar backup de **todos os arquivos realmente tocados** imediatamente antes do futuro deploy T10; as cópias de saves feitas aqui não substituem esse backup.

T02 permanece **parcial/bloqueado**: compatibilidade Steam, localização/build e Cloud ainda pendentes. Nenhum Steam, Wine, wrapper, jogo ou NotProton foi iniciado/alterado por este readback; a única gravação externa aos documentos foi a cópia independente para scratch privado. O ensaio de recuperação existente não foi repetido.

## Busca real no filesystem — autorização adicional de Elvis

Em 2026-10-09, Elvis solicitou explicitamente procurar no filesystem. Foram concluídos percursos reais somente leitura, além do Spotlight anterior:

| Raízes | Método | Resultado | Limite registrado |
|---|---|---|---|
| `/Users`, `/Volumes`, `/Applications` | `os.walk`, sem seguir symlinks | Zero `Cities2.exe`, `appmanifest_949230.acf` e `Colossal.IO.dll`; quatro `libraryfolders.vdf` já conhecidos; prefixo do wrapper original | 101 erros: permission denied ou timeout; 61,92 s |
| `/Library`, `/opt`, `/usr/local`, `/private` | `os.walk`, sem seguir symlinks | Zero nomes de jogo/manifesto/DLL e zero diretórios candidatos encontrados | 107 erros: permission denied ou operation not permitted; 2,88 s |
| `/Users`, `/Applications` | `rg --files --hidden --no-ignore`, seleção por nomes de jogo e engine/registro | Engine Sikarugir somente no wrapper já inventariado; engine e bottle Steam CrossOver também presentes. Nenhum candidato adicional do Cities | Exit 2 por 101 erros de acesso; paths privados no scratch |

Exclusões explícitas: `.git`, `node_modules`, `.Trash`, `notproton/scratch` (cópias e backups gerados), `/private/tmp`, `/private/var/folders` e `/private/var/vm`. Não foram seguidos links recursivamente; `Macintosh HD` em `/Volumes` é alias de `/`, evitando concluir que exista um volume de biblioteca separado. Não foi varrido novamente o alias Data de `/System/Volumes/Data`. Nenhum volume foi montado, nenhuma rede/download/sudo ou concessão de privacidade foi acionada.

Listas completas de hits, links relevantes, erros e raízes estão exclusivamente em `scratch/sikarugir/filesystem-search-20261009.json`, `filesystem-search-extra-20261009.json` e `filesystem-rg-20261009.json`, modo 0600. Links Steam/Wine/Sikarugir encontrados não indicaram biblioteca alternativa. Configurações `libraryfolders.vdf` continuam apontando à raiz nativa padrão e ao `S:` antigo no cliente Windows.

**Resultado:** instalação atual/build ainda não localizados nas áreas legíveis pesquisadas. Erros de acesso/timeout e exclusões impedem qualquer afirmação de ausência global. Nenhum novo executável encontrado para hash/build. Saves locais preservados permanecem os quatro arquivos do prefixo inventariado. O bloqueio de compatibilidade Steam e o estado desconhecido do Cloud continuam independentes da localização do jogo.

A bottle Steam do CrossOver foi identificada por `system.reg`; seus três registros não contêm referências Cities/AppID 949230, e seus drives C:/Y:/Z: apontam para a bottle, home e raiz. Ela não revelou manifesto/executável nem biblioteca alternativa na busca. A presença dessa bottle não altera o requisito de integração sem CrossOver.

## Confirmação humana do fluxo de referência

Em 2026-10-09, Elvis esclareceu: “o cities esta usando o steam instalado no wine”. O fluxo de referência relatado é, portanto, **Cities II pelo Steam Windows dentro do Wine**. Isso concorda com o programa principal Steam Windows e registros Valve/Steam já observados no wrapper Sikarugir. Confirma o launcher de referência relatado, mas não determina a pasta/build atual do jogo nem o estado do Cloud.

O resultado pretendido continua iniciar pelo **Steam nativo do macOS** com integração NotProton/Sikarugir. A execução existente pelo Steam Windows não encerra esse gate. Não houve nova varredura global ou execução de runtime após o esclarecimento; as configurações já inspecionadas permanecem apontando à biblioteca `S:` cujo alvo está ausente.
