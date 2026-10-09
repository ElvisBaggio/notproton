# Inventário somente leitura — T02

Data: 2026-10-09 · Agente: codex · Executor: gpt-6.1-sol · Cliente: Codex.
Branch: `codex/t02-steam-baseline` · Base documental: `b09836e`.

## Resultado atual: perfil Steam 1791415817 gerado e validado estaticamente; T02 aguarda revisão

Atualização 2026-10-09 · Agente: claude · Modelo efetivo: `sonnet` (Claude Sonnet 5.5) · Branch `claude/t02-steam-profile`. O bloqueio único (perfil exato do build **1791415817**) foi resolvido: `signatures/macos.arm64/1791415817.json` tem as 18 assinaturas resolvidas por âncora nos binários do build, com padrão de bytes único e endereços conferidos por decodificação independente (seção "Perfil 1791415817"). Limites: o `anchorcheck`/`make sigdb-fixtures` com `dlopen` **NOT RUN** (executaria construtores do Steam real) e nenhum runtime foi exercitado. T02 **não** fica Done sem a revisão independente (Claude Code Opus 5.5).

Registro anterior (Codex): O schema atual foi preenchido, o inventário foi revalidado e o ensaio de recuperação passou. T02 permanecia **In Progress / BLOCKED** porque não havia perfil exato validado para o build observado **1791415817**. A localização/build/Cloud do Cities II é referência opcional histórica e não bloqueia o inventário base. Nenhum jogo-base foi selecionado; isso ocorrerá após T02, pelos critérios D1 do plano.

| Critério | Readback atual | Estado |
|---|---|---|
| Steam nativo | Última linha `Client version`, em 2026-10-08 13:47:01: **1791415817** | Evidência de log; runtime NOT RUN |
| Perfil exato | Fonte agora contém **1791415817** (além de 1788400362, 1789086785, 1790904859); suporte instalado ainda só tem os três antigos (nada implantado) | Perfil gerado e validado estaticamente (18/18); runtime NOT RUN |
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

## Perfil 1791415817: método e resultado (claude, `sonnet`)

**Build ativo.** `logs/content_log.txt`: `Client version: 1791415817` em 2026-10-08 13:47:01 (antes, 1790904859 às 13:43:17); `logs/bootstrap_log.txt`: manifesto baixado `steam_client_publicbeta_osx version 1791415817`. O `package/steam_client_publicbeta_signed-2_osx.manifest` instalado declara `version 1791415817` e `package/beta` = `publicbeta`. Leitura somente; nada gravado no Steam.

**Cópias e hashes** (em `scratch/steam-1791415817/`, ignorado; binários não commitados):

| Arquivo | SHA-256 |
|---|---|
| `steamclient.dylib` (universal, cópia do original) | `3db7cac83567792f98bc36e4f545bba6cb9aaa545846c02e489e07f0ba4ff6ec` |
| `steamui.dylib` (universal, cópia do original) | `51958623e20047a07e76fa92e31443287ecb3a406164aff08ea8e2e6270a21ce` |
| `steamclient.arm64` (fatia arm64, `lipo -thin`) | `d6557fb939914d92887e41568a83481efeb700eae7fe21eb264e880b562b11a6` |
| `steamui.arm64` (fatia arm64) | `d6a74cb50dbc35193a8e8bbc24c27d6c65d9443faa7d43eb8fa54932037e1462` |
| `signatures/macos.arm64/1791415817.json` (gerado) | `955abf5cda35c423fe1d9af99efd1764124ce2318a0bfa06e1b7c1c4ddd6dd47` |

**Método.**
1. `dylib/tests/sigstatic.c` (novo) monta a fatia arm64 em memória anônima (segmentos nos vmaddr; opcodes de rebase clássicos aplicados, pois os binários usam `LC_DYLD_INFO_ONLY`, sem chained fixups) e chama o mesmo `np_locate_anchor`, `np_aob_site` e `np_rtti_vptr` do dylib. Nenhum código da imagem executa e não há `dlopen`. Rodado só sobre as cópias.
2. As âncoras do perfil 1790904859 (strings, `caller_hops`, pares de instruções, `calls`) foram reaplicadas ao binário novo; endereços e bytes saem do binário novo. Controle negativo: o perfil antigo contra o binário novo dá 13 problemas (6 padrões não casam, 7 endereços gravados divergem). As 5 assinaturas cujo endereço não mudou (3 de WebUI, 2 de steamui) coincidem com os gravados, o que valida o harness.
3. `sigstatic --emit` e `dylib/tests/sigprofile.py` (novo) geram o JSON: o modelo fornece só nomes, módulo e definição de âncora. O padrão antigo é mantido apenas se casar de forma única no endereço da âncora do binário novo; senão é refeito a partir dos bytes novos (instruções dependentes de posição viram `??`) e ampliado até ser único em `__TEXT`. Resultado: 12 padrões mantidos (confirmados no binário novo) e 6 refeitos.
4. Verificação independente (scripts descartáveis em Python com `objdump`/`otool`): para cada âncora de steamclient, string única, xref e função contendo conferem via ADRP/ADD/LDR decodificados à parte e `LC_FUNCTION_STARTS`; `caller_hops`/`caller_tail` têm um único chamador; os pares de instruções têm exatamente um acerto; as duas âncoras `calls` de steamui conferem com as stubs `_V_GetFileExtension` e `_V_strnicmp` (`otool -Iv`).

**Resultado por assinatura** (endereços não deslocados; `=` mantém o endereço do perfil anterior):

| Assinatura | Módulo | Âncora | Endereço 1791415817 | Padrão |
|---|---|---|---|---|
| CCompatManager::Init | steamclient | string | 0x6ac7b4 (era 0x6a0e50; corpo mudou) | refeito |
| CCompatManager::BIsCompatibilityToolEnabled | steamclient | string | 0x6a492c | mantido |
| CCompatManager::YldRegisterTool | steamclient | string | 0x6a8a10 | mantido |
| CCompatManager::GetOSListOverrideForApp.oslist_gate | steamclient | insn_pair | 0x6a4548 | refeito |
| CCompatManager::ResolveCompatToolForApp.local_redirect | steamclient | insn_pair | 0x6a4638 | refeito |
| CAppManager::TerminateProcessByPid | steamclient | string indireta + 1 hop | 0xdd4d4 | refeito |
| CCompatManager::FindToolForTargetApp | steamclient | string | 0x6a4034 | refeito |
| CCompatManager::GetValidPlatforms | steamclient | string | 0x6a2aa0 | mantido |
| CWebUIJobDispatcher::RegisterHandler | steamclient | string | = 0x93e60 | mantido |
| CWebUITransport::DispatchJob | steamclient | string | = 0x94064 | mantido |
| CWebUIMsgJob::SendResponse | steamclient | string | = 0x9453c | mantido |
| CCompatManager::SetCompatToolMapping | steamclient | string + 1 hop (tail) | 0x6a3d84 | mantido |
| CCompatManager::InternalSpecifyCompatTool | steamclient | string | 0x6a2f04 | mantido |
| CCompatManager::FindMapping | steamclient | string | 0x6a4210 | mantido |
| CCompatManager::GetWildcardMapping | steamclient | string | 0x6a4288 | refeito |
| LaunchBuilder::SteamVRSupportCheck | steamclient | string | 0xb250cc | mantido |
| steamui::ShortcutExtensionMatches | steamui | calls | = 0xa5478 | mantido |
| steamui::ShortcutIconRender | steamui | calls | = 0xa55fc | mantido |

Também foram lidos os 8 vptrs RTTI (`14CCompatManager` 0x1743c80 etc.), conferidos por decodificação independente (typeinfo para vtable primária), e acrescentados à tabela de `anchorcheck.c` para o build 1791415817.

**Checks.** `sigstatic` sobre o perfil novo e os dois módulos: 18/18 âncoras resolvidas, padrão e endereço gravado coincidentes, 8/8 vptrs, **0 problemas**. `python3 dylib/tests/sigcheck.py`: 4 perfis, 18 assinaturas cada, todas referenciadas. As 40 fixtures de `sigdb-fixtures` passaram pelo `sigstatic` sem crash (só robustez; os status de `EXPECTED` são do `anchorcheck` e não foram reproduzidos). `anchorcheck.c` compila (`-fsyntax-only`).

**Limites e riscos.**
- `anchorcheck` e `make sigdb-fixtures` **NOT RUN**: fazem `dlopen` do `steamclient.dylib` instalado (caminho fixo sob `~/Library/Application Support/Steam`, não das cópias), com construtores e dependências `@loader_path`; não é seguro nem viável apontar para `scratch/`. O equivalente estático é o `sigstatic`. Diferença conhecida: o `dlopen` real aplica o runtime ObjC aos slots de seletor; a leitura estática usa os slots do arquivo (ponteiros para a própria string). Só a execução real do `anchorcheck` confirmaria o ramo `uniqued_selector` da âncora indireta de `TerminateProcessByPid`.
- `steamui::ShortcutIconRender` usa seletores ObjC; os endereços vêm do resolvedor (mesmo código que casou o perfil anterior), sem decodificação independente dos nomes de seletor.
- O perfil não foi instalado no suporte do NotProton nem testado com o loader; nenhum hook, injeção, update ou arquivo do Steam/NotProton foi alterado. Se o Steam atualizar, o perfil precisa ser regerado (`sigstatic --emit` e `sigprofile.py` a partir do perfil mais recente, depois `sigstatic` de novo).
- Os padrões refeitos usam a regra de máscara de `sigstatic.c` (ADRP/ADR, B/BL/B.cond, CBZ/TBZ, LDR literal e deslocamento de página após ADRP). Nos 12 padrões mantidos a regra reproduz o antigo, exceto em `YldRegisterTool`, onde o padrão antigo (mantido) não mascara um LDR após ADRP.

Reprodução: compilar `dylib/tests/sigstatic.c` com `dylib/core/macho.c`, `dylib/resolver/{aob,anchor,resolver,sigdb}.c`, `dylib/util/{log,file}.c` e `vendor/cJSON.c` (`clang -arch arm64 -Idylib -Ivendor`), depois `sigstatic [--emit out.tsv] signatures/macos.arm64/<build>.json steamclient.dylib=<cópia> steamui.dylib=<cópia> [rtti:<tipo>...]`. O manifesto `scratch/sikarugir/system-baseline.json` não existe neste worktree (fica no checkout do Codex); o `steamSupportEvidence` correspondente deve registrar: perfil 1791415817 na fonte, validado estaticamente, não implantado no suporte instalado.

## Manifesto local e preservação

`scratch/sikarugir/system-baseline.json`, **schemaVersion=1**, modo **0600**, diretório **0700**, contém `steamClientBuild`, `steamSupportEvidence`, `wrapperState`, `diskFreeBytes` e `touchedFiles`. `referenceGame` preserva a referência opcional Cities II. A evidência anterior completa fica em `historicalEvidence`; os backups antigos mantêm suas referências originais, sem mudar nem recriar os saves.

`touchedFiles=[]` registra que T02 não alterou arquivos de instalações vivas. O inventário de candidatos de preservação está em `wrapperState.preservationCandidates`, com existência/hash/modo/link e `backupPath=null`; não confundir candidatos com backup completo de deploy. T10 terá de gerar o manifesto dos destinos realmente tocados e conferir seus backups imediatamente antes da alteração.

Logs do parser/sigcheck, harness e ensaio ficam no diretório temporário privado indicado pelo manifesto. Não são artefatos versionados nem garantia de retenção permanente. SHA-256 do log de parser: `ab189f8b434c314291cc1a0070e8cede9008f81e1bfff232eb4ae844c6610795`; SHA-256 do log sigcheck: `b97167dfe296f575b9e357b95682281aadc081335260ef2274bf217959a145bd`.

Não foram repetidas as buscas globais de jogos, nem acessadas áreas antes negadas. Nenhum Steam, Wine, wrapper ou jogo foi iniciado; nenhum update, biblioteca, save ou instalação foi modificado. A cobertura de preservação é dos candidatos monitorados, não de toda a árvore de arquivos.

## Próximo passo e revisão

1. Perfil exato para **1791415817**: gerado e validado estaticamente (ver seção acima). Repetir o readback se o Steam atualizar; não fixar ou desabilitar updates para contornar o gate. Opcional: Elvis roda `make anchorcheck` por conta própria no Steam real para fechar o ramo `dlopen`.
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
