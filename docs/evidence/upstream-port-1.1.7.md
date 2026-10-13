# Porte manual do upstream v1.1.1 → v1.1.7 (#47)

2026-10-12 · Agente: claude · Modelo efetivo: opus (claude-opus-5-5) · Branch `claude/upstream-port-47`

Fonte: `git log v1.1.1..v1.1.7` do `upstream` (27 commits). Nada foi enviado ao upstream.

## Portado

| Upstream | O que faz | Como entrou |
|---|---|---|
| `efba9b3` | Fecha o Steam com `steam://exit` antes do `pkill`, e espera o `-9` terminar | cherry-pick |
| `a3228a7` | Remove Everything apaga também a pasta de templates vazia | cherry-pick |
| `3c3a679` | Corrige o lock do template ao apagar a pasta | cherry-pick |
| `c352b11` | Limpa FinderInfo e resource forks antes de assinar o Steam (erro de codesign) | cherry-pick |
| `d0a0e45` + `4f16e9e` | Link `Steam.dll` → `legacycompat/Steam.dll` ao lado da pasta do jogo (Prey e jogos antigos), marcado como oculto; Remove Everything desfaz | à mão: `compat_run.sh` com conflito; o teste do `bridgecheck` precisou criar a própria `legacycompat` |

## Descartado

| Upstream | Motivo |
|---|---|
| `5f25620` GPTK no CrossOver, `976df85` CrossOver China | CrossOver saiu do código (T09b) |
| `130cc2a` não repassar o dylib a ferramentas do Steam Helper | Só causa crash com SIP desligado. Aqui o SIP está ligado. Mexe no hook de spawn do núcleo |
| `740b2e9` fontes do Proton | 110 MB de fontes para jogos específicos (EA FC, AppIDs 1313860/1506830). Nenhum jogo nosso tem problema de fonte. Retomar se algum tiver |
| `71765b2` reusar launchers, `42fd778` descrições de microfone/câmera nos launchers | O nosso `run` não cria bundles de launcher por jogo |
| `5c18baa` Homebrew `--zap` | O app não é distribuído pelo Homebrew |
| `cc599ec` macOS Sequoia | Este Mac está no macOS 27 |
| `d8f2d38` Liquid Glass | O binário do app já sai com `minos 26.0 / sdk 26.0` |
| Commits de versão, README, CI e textos | Não se aplicam |

A versão (`dylib/version.h`, `steam-shim`) continua em 1.1.1. O porte é parcial, e mudar o `steam-shim` mudaria o hash fixado do `steam.exe`.

## Verificação

- `swift test` 456/456 depois de `make app-payload`. Rodei três vezes: numa das rodadas anteriores, o teste "Installation locking…" falhou uma vez e não se repetiu.
- `bridgecheck` (com a seção nova do `Steam.dll`), `settingscheck`, `envcheck`, `routecheck` e `compatcheck` passaram. O `runcheck` e o `scriptcheck` foram pulados porque o shellcheck não está instalado.
- Pendente (Elvis): depois de Install, abrir PEAK, GHPC e Wildlands pelo Steam e conferir que abrem e autenticam. Conferir também que aparece um `Steam.dll` oculto em `steamapps/common/`.
