# Jogos Windows pelo Steam do Mac com NotProton Sikarugir

Guia de uso para o Elvis, para seguir sem precisar do histórico das conversas. Data: 2026-10-11 · Agente: claude · Modelo efetivo: opus (claude-opus-5-5). Recuperação detalhada: `docs/runbooks/recovery.md`.

## Combinação fixada

| Peça | Versão | Como conferir |
|---|---|---|
| Steam (cliente Mac) | `1791592380`, branch `publicbeta` | `Steam.AppBundle/Steam/Contents/MacOS/package/steam_client_publicbeta_signed-2_osx.manifest` → `"version"` |
| Perfil de assinaturas | `signatures/macos.arm64/1791592380.json` | o Install recusa build sem perfil |
| App | NotProton Sikarugir **1.1.1** (`/Applications/NotProton Sikarugir.app`) | `notproton/install-build.json` |
| Motor | Sikarugir 11.0 revision 0, cópia em `notproton/runners/sikarugir-11.0-r0` | `wine/version` |
| Ferramenta no Steam | `compatibilitytools.d/notproton-sikarugir-11.0-r0` | aparece em Propriedades → Compatibilidade |
| Renderer | D3DMetal, D3D11 (D3D12 não testado) | `Player.log`: `Direct3D 11.0 [level 11.1]`, `AMD Compatibility Mode` |

Os hashes SHA-256 dos artefatos implantados em 2026-10-11 estão em `docs/evidence/acceptance.md`.

## Instalar ou atualizar a ferramenta

1. Feche o Steam (Cmd+Q).
2. Abra o NotProton Sikarugir.app e clique em **Set Up**, que copia o motor, se ainda não houver cópia. Depois clique em **Install**. O Install para e reinicia o Steam sozinho, se preciso.
3. No Steam, em Propriedades do jogo → **Compatibilidade**, marque *Forçar ferramenta* → **NotProton Sikarugir**.

## Instalar e iniciar um jogo Windows

1. Instale pelo Steam normalmente. Jogos só para Windows exigem a ferramenta selecionada.
2. Clique em **Jogar**. Na primeira vez a ferramenta cria o prefixo em `steamapps/compatdata/<appid>/pfx` a partir de um template.
3. Para um jogo Unity com opção DX11, como o PEAK, use `-force-d3d11` em *Opções de inicialização* se o DX12 falhar.
4. Logs: `compatdata/<appid>/notproton-run.log` (ferramenta) e `…/pfx/drive_c/users/steamuser/AppData/LocalLow/<empresa>/<jogo>/Player.log` (Unity).

Testados: PEAK (3527290, T11/T12), GHPC (1705180, T11). Não funciona: Cities: Skylines II (`docs/evidence/cities-launcher.md`).

## Saves

Ficam dentro do prefixo do jogo (`compatdata/<appid>/pfx/drive_c/users/steamuser/…`). O Steam Cloud fica ativo pela ferramenta (`steam_autocloud.vdf` no prefixo), mas só sobe arquivos que casam com a regra Windows do jogo: o GHPC sincronizou saves; no PEAK o AutoCloud achou 0 arquivos `*.peak`. **Desinstalar um jogo apaga o `compatdata` dele.** Antes de desinstalar, copie a pasta de saves.

## Atualizações do Steam

O Install bloqueia a atualização do cliente (`BootStrapperInhibitUpdateOnLaunch` nos dois `steam.cfg`), porque cada build novo precisa de um perfil de assinaturas. Se o Steam atualizar mesmo assim (Repair, reinstalação), o Install vai recusar até existir um perfil para o build novo. O método está em `docs/evidence/system-baseline.md` ("Perfil 1791592380"). Não troque o canal `publicbeta` para contornar isso.

## Desfazer (voltar ao Steam original)

Siga `docs/runbooks/recovery.md`, seção "Rollback vivo". Resumo:

1. Faça o backup com `tools/rollback_snapshot.py … --games` (passos 2 e 3a), que inclui `steamapps/compatdata/*` e `appmanifest_*.acf`. Sem a ferramenta, o Steam remove os depots Windows e exige baixar o conteúdo de novo.
2. Rode **Repair Steam** no app. Ele restaura o bundle assinado pela Valve.
3. Mova `compatibilitytools.d/notproton-*` para o backup.
4. **Não use "Remove"**: ele apaga a pasta de suporte, os runners e os templates.

Para reimplantar, rode **Install** de novo.

## Problemas conhecidos

- O `installscript.vdf` roda pelo `legacycompat/iscriptevaluator.exe` da Valve, que o `run` copia do payload para a pasta do cliente a cada launch (#41). O log mostra `helper exited status=0`.
- Mouse em jogos com mira (#44): com o cursor do Windows escondido, o `run` carrega `notproton-rawmouse.dylib`, que entrega as contagens do sensor (sem aceleração do macOS) e prende o cursor do Mac; Cmd+Tab solta. `NOTPROTON_RAW_MOUSE=0` desliga, `NOTPROTON_RAW_MOUSE_SCALE=<n>` ajusta a sensibilidade. Detalhes: `docs/evidence/raw-mouse.md`.
- Capturar todas as telas em tela cheia (`CaptureDisplaysForFullscreen`) apaga os outros monitores; é opt-in com `NOTPROTON_CAPTURE_DISPLAYS=1`.
- A ponte cobre processos 32-bit (#42): o prefixo recebe o gatilho Valve `steamclient.dll` i386 e o runner o `lib/wine/i386-windows/lsteamclient.dll`, que usa os thunks wow64 do `lsteamclient.so` x86_64. Depois de atualizar o app, rode **Set Up/Repair** do runner para instalar o arquivo novo.
- Janelas Electron/Chromium, como o Paradox Launcher, ficam brancas no Sikarugir 11.0 r0.
- O CI `app` falha fora do Mac do Elvis, porque a ponte é local (`scratch/sikarugir/bridge`).
