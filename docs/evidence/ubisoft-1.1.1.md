# Correção Ubisoft Connect da release 1.1.1

Data: 2026-10-08 · Agente: codex · Executor: upstream_update / gpt-6.1-sol

## Comparação e escopo

A [comparação upstream v1.1.0…v1.1.1](https://github.com/NotProtonNot/NotProton/compare/v1.1.0...v1.1.1) contém quatro commits e altera apenas `README.md`, `dylib/version.h` e `steam-shim/steam.cpp`. A release termina em `682177c5ff1d8f2e47062b13e12868409584eeaf`.

Os commits `1f49b77045daef85a7933d12932e5d4e4917796f` e `dfb5251e0002da575ff4d8d5be10fa26ae1987bd` apresentam o mesmo patch para descoberta de Steam. Aplicado uma única vez o resultado agregado da release em `steam.cpp`, junto ao versionamento 1.1.1; omitida a revisão editorial do README sobre versões/recomendações CrossOver.

O shim agora registra `InstallPath` em ambas as chaves HKLM Valve/Steam (inclusive Wow6432Node), `SteamExe` em HKCU Valve/Steam e `SteamPath` em HKCU Valve/Steam/ActiveProcess. Os valores apontam ao diretório Windows onde o launcher já coloca o shim. A gravação ocorre no ramo `SteamGameId`, antes da inicialização da API Steam e do lançamento do jogo. O tratamento de erros segue exatamente o upstream.

Não houve mudança no launcher, descoberta de engine, wrapper, biblioteca, saves ou instalações vivas. Esta manutenção não implementa T03/T08 nem encerra seus gates Sikarugir.

## Validação

| Verificação | Resultado | Evidência |
|---|---|---|
| Regressão antes da correção | PASS | `sh steam-shim/tests/install-paths-check.sh` falhou com `FAIL: Steam install registry setup missing` |
| Regressão após a correção | PASS | A função real extraída de `steam.cpp` foi compilada com clang++; capturadas e verificadas quatro chamadas, hives, chaves, valores REG_SZ e bytes incluindo terminador NUL; call site único no caminho de jogo antes de `steam_client_init` |
| Staging de bridge | PASS | `make bridgecheck`: prefixos novos/atuais/incompletos, atualização de steam.exe, mudança com mesmo tamanho/mtime, links e falhas de cópia |
| Roteamento de launch | PASS | `make routecheck`: jogo, helpers/URLs, argumentos com espaços, exit status e atribuição de AppID |
| Guard negativo de ordem | PASS | Cópia descartável de `steam.cpp` sem a linha `if (steam_client_init())` foi recusada pelo check; bloco precisa terminar exatamente nessa linha |
| Build PE do shim | NOT RUN | Não existe árvore Wine em scratch; compilador `x86_64-w64-mingw32-gcc` ausente |
| Registro real no prefixo Sikarugir | NOT RUN | Depende de artefato compilado para a fonte/ABI validada e prefixo descartável |
| Ubisoft Connect iniciado pelo Steam nativo | NOT RUN | Nenhuma execução viva autorizada neste território; prova da ponte Sikarugir ainda pendente |

Comandos usam `rtk proxy sh steam-shim/tests/install-paths-check.sh` e `rtk make bridgecheck routecheck`. O teste host verifica o contrato das chamadas ao Registro, não sua persistência sob Wine nem o comportamento do Ubisoft Connect.

## Próxima prova funcional

Após T01/T03/T05, compilar o shim corrigido contra a fonte fixada; implantar apenas em bridge/prefixo isolados; iniciar pelo Steam nativo um jogo Ubisoft legitimamente disponível; consultar as quatro entradas do Registro, confirmar o arquivo `steam.exe` no caminho apontado e verificar que Ubisoft Connect reconhece Steam sem oferecer instalá-lo. Comparar com o mesmo prefixo/cenário usando shim 1.1.0. Não substituir o Steam Windows funcional do wrapper por esse shim. Registrar falha e manter gate aberto se não houver jogo Ubisoft ou autenticação disponível.
