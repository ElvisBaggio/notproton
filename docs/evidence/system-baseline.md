# Inventário somente leitura — T02

Data: 2026-10-09 · Agente: codex · Executor: gpt-6.1-sol · Cliente: Codex.

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
