# NotProton com Sikarugir para jogos Windows pelo Steam nativo

Data: 2026-10-08 · Autor: codex · Planejamento e revisão: Astra

Estado: Claude Code Sonnet 5.5 revisou em 2026-10-09 e recomendou aprovação com ajustes F1–F8. Ajustes documentais e cards aplicáveis foram sincronizados; T01 e T02 foram retomados, ambos permanecem BLOCKED por suas evidências pendentes. Elvis decidiu gerar perfil Steam para o build atual, solicitar ao mantenedor o manifesto da engine e selecionar o jogo-base após T02. A aprovação anterior refere-se ao escopo antigo.

## 1. Resultado esperado

Permitir instalar versões Windows de jogos e iniciá-las pelo botão Jogar do Steam nativo do macOS, usando uma cópia isolada do motor Sikarugir 11.0 (revision 0), sem instalação ou licença CrossOver.

A integração é agnóstica ao jogo, com engine inicial fixada e um único Mac pessoal. Não é agnóstica a engines nem garante que todos os jogos funcionem. A base será demonstrada com jogo Windows simples legitimamente disponível, instalado do zero em biblioteca de teste isolada. Registrar AppID e build selecionados em vez de fixar AppID 949230.

Sucesso: selecionar a ferramenta, instalar a versão Windows pelo Steam nativo, iniciar gameplay real, jogar >=15 minutos, encerrar jogo e Steam e reabrir para verificar estado persistente. Se o jogo suporta saves, usar slot de teste; caso contrário verificar dados pertinentes/configuração persistente identificável. Menu, build ou processo não encerram a validação. Steam original e wrapper permanecem utilizáveis e rollback é demonstrado.

Cities: Skylines II é teste opcional posterior. Sua pasta, build, Steam Cloud e patches não bloqueiam E1/T02/T05/T10 ou a entrega base; preservar saves existentes e evidências, sem reutilizá-los no teste inicial. O relato de Elvis de que o jogo abre no Steam Windows/Sikarugir permanece uma referência histórica, sem provar a nova integração.

## 2. Restrições e responsabilidades

- Astra: especificação, plano, decisões de arquitetura e revisão dos resultados.
- Implementação padrão, incluindo scripts de prova, patches, testes e ferramentas auxiliares: **Sol 6.1 (`gpt-6.1-sol`) ou Luna 6 (`gpt-6-luna`)**. Não substituir por Sol 6, Luna 5.6 ou implementação pelo Astra.
- Exceção autorizada por Elvis em 2026-10-08: modelos do **Claude Code** podem executar cards como alternativa explicitamente selecionada. Cada card indica `sonnet` ou `opus`; registrar a versão efetiva ao iniciar. A política e os papéis estão em `docs/AGENT_EXECUTION.md`. Não é fallback automático nem execução simultânea no mesmo território.
- Sol 6.1 assume a integração Wine/Steam, patches binários e validação principal. Luna 6 pode receber tarefas pequenas, com arquivos e critérios de aceitação definidos.
- Separar propriedade dos arquivos quando houver agentes em paralelo; nenhum agente deve reverter trabalho alheio.
- Preservar o wrapper Sikarugir atual, sua engine, prefixo, biblioteca e saves. As alterações experimentais ocorrem em cópias.
- Manter validações de versão, hashes, arquitetura e bytes esperados antes de aplicar patches. Motor desconhecido deve ser recusado.
- Nenhuma gravação de credenciais, identificadores de conta ou tokens nos documentos, fixtures e logs publicados.

## 3. Base e evidências

Inspeção somente leitura realizada em 2026-10-08; revalidar antes de implementar ou implantar.

| Item | Evidência |
|---|---|
| Base do fork | NotProton `v1.1.0`, commit `05a27874798ffbffb8e64a37595bde6f16d5320a` |
| Sistema observado | macOS 27.2, arquitetura arm64 |
| Wrapper | `~/Applications/Sikarugir/wrapper-steam.app` |
| Motor no wrapper | `Contents/SharedSupport/wine/version`: `wine sikarugir 11.0 (revision 0)` |
| Configuração observada | `D3DMETAL=0`, `DXVK=0`, `WINEESYNC=1`, `WINEMSYNC=1`; Steam.exe como programa principal |
| Layout do motor | `bin/wine`, `bin/wineserver`, `lib/wine/x86_64-unix`, `i386-windows`, `x86_64-windows` |
| NotProton existente | `/Applications/NotProton.app` 1.1.0; pasta de suporte com bridge, backups e `install-build.json` |
| Jogo | Biblioteca do Steam Windows lista AppID 949230, mas o antigo drive S: aponta para `~/My Games/Wrapper Steam`, ausente na inspeção |

O estado instalado do NotProton não demonstra que o Steam está corretamente modificado ou que existe um runner funcional. Não executar instalação sobre esse estado sem inventário.

Os flags gráficos encontrados não bastam para afirmar qual renderizador é carregado pelo jogo. A configuração efetiva, os DLL overrides e eventuais correções do Cities devem ser identificados antes de qualquer teste opcional posterior do Cities II; não são pré-condição da base.

Hashes observados no motor, úteis como referência inicial de integridade:

| Arquivo sob `Contents/SharedSupport/wine` | SHA-256 |
|---|---|
| `bin/wine` | `874d068ebd42114388e77edffc526d85460350f9d599d074acd951a2f0a32e2c` |
| `lib/wine/x86_64-windows/ntdll.dll` | `da7e1ea5d7e6bca3192ff5aa4a603302a9572233a1dbe02c9c8d85505101f676` |
| `lib/wine/i386-windows/ntdll.dll` | `e1ce5ae37f57cee3c4fea80b681fbf64e3f0611b36d5c9125851c03dea985589` |

Esses hashes identificam os arquivos presentes; não atestam origem limpa nem compatibilidade. A origem e a fonte correspondente da engine devem ser verificadas antes de gerar patches.

## 4. Abordagem escolhida e alternativas

Abordagem mantida para revisão: fork mínimo do NotProton com suporte explícito a uma única engine Sikarugir. Preservar as partes existentes da integração com Steam e modificar apenas as dependências concretas do CrossOver necessárias a esse motor.

Um adaptador externo foi considerado, mas continuaria exigindo resolver a ponte e dependeria de detalhes internos do NotProton. Um sistema genérico de múltiplos motores foi descartado do primeiro escopo por não ajudar a provar a integração com a engine fixada.

Não construir um framework de plugins, gerenciador de engines, novo launcher ou instalador público. Não adicionar suporte FEX, ARM Windows ou uma matriz de versões. Não criar lógica específica de AppID para a integração base. Componentes de 32 bits só entram quando exigidos pelo caminho escolhido ou pelos auxiliares do jogo.

## 5. Arquitetura e fluxo

```text
Steam nativo do macOS
  → integração Steam Play do NotProton
  → opção de compatibilidade Sikarugir 11.0
  → launcher do fork com caminhos e ambiente do motor selecionado
  → cópia isolada do Wine + ponte lsteamclient adaptada
  → prefixo Windows exclusivo do jogo selecionado
  → jogo e estado persistente da nova integração
```

### 5.1 Integração com Steam

Reutilizar a detecção de jogos, a seleção de ferramenta de compatibilidade e a integração de inicialização existentes no NotProton. Verificar a versão efetiva do cliente Steam e validar um perfil de assinaturas correspondente a esse build antes de qualquer modificação. O perfil é gerado/validado para o build atual inventariado; não fixar ou desabilitar updates como atalho. A validação deve confirmar correspondência de build e resolver todas as assinaturas necessárias; o perfil mais recente não é suficiente se for de outro build.

Registrar a ferramenta com identidade própria, distinta das ferramentas CrossOver. O fluxo aceito precisa partir do botão Jogar do Steam nativo; um atalho que simplesmente abre o Steam Windows no wrapper não atende ao objetivo.

### 5.2 Suporte específico ao motor Sikarugir

Reconhecer o layout real, a arquitetura e os arquivos da versão fixada. Copiar o motor para uma área exclusiva do projeto e aplicar patches somente ali. Definir os caminhos do loader, wineserver, DLLs e prefixo a partir desse motor.

O suporte ao Sikarugir terá sua própria validação de origem e integridade. As exigências de licença do CrossOver permanecem associadas ao caminho CrossOver; não remover globalmente suas verificações nem fazer o Sikarugir se passar por CrossOver.

A integração deve reutilizar os modelos existentes onde couber, sem generalização antecipada. A escolha dos pontos exatos de edição fica no plano de implementação após aprovação desta especificação.

### 5.3 Ponte Steam/Wine

O upstream liga a parte Unix do `lsteamclient` ao `ntdll.so` da árvore de compilação e usa interfaces internas do Wine. Seu preparo de build fixa Wine 11.15; o motor observado é 11.0. Compatibilidade binária entre ambos não está demonstrada.

Identificar a fonte correspondente ao Sikarugir 11.0, construir os componentes necessários contra ela e resolver os hooks sobre seus binários exatos. Não reutilizar offsets ou blobs do CrossOver por semelhança de nomes. Não substituir a ntdll do Sikarugir pela do Wine 11.15.

Trabalhar inicialmente no caminho x86_64/Rosetta. Validar também arquitetura, dependências dinâmicas, assinatura e entitlements exigidos pelo carregamento; não copiar cegamente as suposições de assinatura do runner CrossOver.

### 5.4 Ambiente do jogo

Criar prefixo e biblioteca de teste exclusivos. Depois do inventário T02, selecionar jogo pequeno, somente Windows (sem build/depot macOS), que inicialize a API Steam, tenha save ou configuração persistente identificável e conta/Cloud conhecidos. Registrar AppID/build e evidência de elegibilidade antes de T05. Instalar a versão Windows do zero via Steam nativo; confirmar por manifesto/depot que o conteúdo Windows foi selecionado; não reutilizar biblioteca, prefixo ou saves do Cities II.

T02 inventaria Steam, NotProton e wrapper, prepara rollback geral e protege dados existentes. Seu schema não exige campos de jogo; `referenceGame` é opcional. Localização/build/Cloud do Cities II não bloqueiam o inventário. T11 verifica espaço e Cloud do jogo selecionado antes de tocá-lo; não sobrescrever versões locais/remotas nem resolver conflitos automaticamente.

Em teste opcional posterior do Cities II, localizar e identificar build/configuração/saves antes de copiar, validar patches contra a build exata e usar cópia independente/clone APFS, nunca hard link. Evidências históricas permanecem em seus arquivos originais.

## 6. Marcos e provas de aceitação

### Marco 1 — Viabilidade da ponte

Pré-condições: origem/fonte da engine identificada; binários conferidos; ferramentas de build disponíveis; teste realizado fora do prefixo original.

Evidências exigidas:

1. Resolução dos hooks nos binários exatos, com invariantes verificadas.
2. Build da ponte e auxiliares necessários para a arquitetura correta.
3. Inicialização de prefixo descartável sem incompatibilidade loader/server ou erro de chamadas Unix.
4. Um executável Windows mínimo inicializa a API Steam e recebe o contexto esperado de usuário autenticado e AppID pelo cliente nativo, sem exigir o cliente Windows. Usar conta e jogo legitimamente disponíveis, sem armazenar credenciais nem falsificar autenticação.

Interromper e voltar à decisão de arquitetura se a fonte correspondente não for identificável, os hooks não puderem ser resolvidos com validação, ou a comunicação real com o Steam falhar. Não compensar removendo verificações. Trocar a versão do motor exige nova decisão, não atualização automática.

### Marco 2 — Inicialização pelo Steam nativo

A ferramenta aparece na seleção de compatibilidade, o Steam instala do zero os arquivos Windows do jogo simples selecionado em biblioteca isolada e o botão Jogar inicia esse jogo pelo motor escolhido. A interface volta ao estado correto após encerrar o jogo. Logs permitem distinguir falha na ponte, no Wine e no jogo.

### Marco 3 — Sessão de jogo e persistência

Entrar em gameplay real do jogo selecionado, realizar ação identificável e jogar pelo menos 15 minutos. Salvar em slot separado quando suportado; caso contrário registrar alteração pertinente de dados/configuração persistente. Encerrar jogo e Steam, reabrir pelo Steam nativo e comprovar o estado identificado. Registrar renderer e falhas, sem prometer desempenho ou compatibilidade de outros jogos.

Verificar que o wrapper original continua utilizável e executar o procedimento de retorno ao estado anterior da integração. Uma restauração descrita, mas não testada, deve continuar marcada como pendente.

## 7. Erros, proteção de dados e rollback

- Fazer inventário e backup antes de modificar Steam, registros de ferramentas de compatibilidade ou arquivos compartilhados do NotProton existente.
- O backup deve corresponder ao estado real imediatamente anterior à mudança, não apenas aos backups antigos encontrados no disco.
- Não modificar Steam enquanto estiver aberto. Preparar e validar artefatos antes de instalar; registrar quais arquivos e configurações a implantação alterou.
- Identidade e diretórios do runner experimental devem ser exclusivos. Evitar colisão com bridge, ferramentas e prefixos existentes.
- Em erro de hash, arquitetura, assinatura ou versão do Steam, interromper com diagnóstico explícito, preservando o original.
- Falha parcial de implantação deve permitir restaurar todos os arquivos e configurações tocados. Não remover a pasta de suporte inteira para desfazer apenas esta integração.
- Atualização de Steam, NotProton ou engine invalida a combinação validada. Não permitir que atualização automática do aplicativo experimental substitua o fork por uma versão upstream sem esse suporte.
- Não automatizar resolução de conflito de saves; conservar cópias antes de decidir qual versão usar.

## 8. Validação técnica proporcional

Reutilizar os testes upstream aplicáveis e acrescentar casos pequenos para a lógica nova: identificação da engine, recusa de binário desconhecido, caminhos do launcher, isolamento do prefixo e falha de implantação recuperável. Fixtures devem representar entradas válidas e inválidas, sem copiar dados pessoais.

Para patches binários, verificar arquivo original, posições, bytes esperados e integridade do resultado antes de executá-lo. Para a ponte, testar comunicação real; mocks não substituem o Marco 1. Para o jogo, o Marco 3 depende de observação funcional e participação de Elvis quando a interação não puder ser automatizada de forma confiável.

Manter um registro curto de versão do Steam, build do jogo, engine, hashes e resultado de cada prova. Distinguir validado, falhou e não executado.

## 9. Referências técnicas verificadas na base

- `app/Sources/NotProtonApp/Model/CrossOverSource.swift`: descoberta e identificação das builds existentes.
- `app/Sources/NotProtonApp/Model/SupportedRunner.swift`: lista de builds, hashes e ferramentas.
- `app/Sources/NotProtonApp/Model/RunnerSetup.swift`: fluxo e verificações de licença CrossOver.
- `app/Sources/NotProtonApp/Model/RunnerInstaller.swift`: cópia e validação do runner.
- `app/Sources/NotProtonApp/Model/RunnerPatcher.swift`: instalação da ponte, patches e assinatura.
- `app/Sources/NotProtonApp/Model/NtdllPatcher.swift` e `ntdll-patch/`: patches por build e resolução de hooks.
- `dylib/feats/compat_run.sh`: launcher, ambiente e criação de prefixos.
- `bridge/setup-wine-tree.sh`: versão da árvore Wine e arquitetura de compilação.
- `lsteamclient/build.sh`, `steamclient_main.c` e `unixlib.cpp`: ligação com Wine e Steam nativo.

## 10. Próxima etapa e limites desta entrega

O plano efetivo está no arquivo relacionado; os nomes históricos dos documentos são preservados. Revisão pendente por Claude Code Opus, com recado em `docs/reviews/claude-opus-scope-review.md`. Não iniciar Claude automaticamente, implementação ou probes. Após revisão aprovada, manter os gates de fonte/patchset, ABI real, API Steam, suporte/assinatura do cliente, instalação Windows, persistência e rollback.

Este registro não inclui produto implementado, prova de viabilidade executada, dependências instaladas nem alterações nas instalações de Steam, NotProton e Sikarugir. Elvis autorizou posteriormente a publicação dos documentos, épicos e cards no repositório pessoal privado `ElvisBaggio/notproton` e no Project associado.
