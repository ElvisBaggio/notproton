# NotProton (fork Sikarugir)

Fork pessoal do [NotProton](https://github.com/NotProtonNot/NotProton) que roda **jogos Windows pelo Steam nativo do macOS**
usando o **Sikarugir 11.0** como motor Wine, **sem CrossOver**.

> **Status: experimental.** A cadeia técnica está provada (a API Steam responde dentro do Wine com
> sessão real: `STEAM_INIT=ok`, `AUTHENTICATED=yes`), mas a instalação pelo app e um jogo jogado de
> ponta a ponta ainda estão em validação (cards T10–T12 do
> [Project](https://github.com/users/ElvisBaggio/projects/8)).

## O que ele faz

O Steam do macOS já tem o "Steam Play" (ferramentas de compatibilidade, como o Proton no Linux),
só que desligado. O NotProton:

1. **Liga o Steam Play no Steam do Mac**: injeta uma biblioteca (`notproton.dylib`) no Steam, que
   faz o Steam mostrar e baixar jogos só-Windows e oferecer uma ferramenta de compatibilidade.
2. **Registra a ferramenta "Sikarugir 11.0 (experimental)"** em *Propriedades → Compatibilidade*
   de cada jogo.
3. **Faz uma cópia isolada do motor Sikarugir** e aplica nela o que falta para jogos Steam:
   - um patch na `ntdll` do Wine, que carrega a ponte Steam;
   - a **ponte `lsteamclient`**, porte do componente do Proton: o jogo Windows conversa com o
     Steam nativo do Mac (login, conquistas, Steam Cloud, DRM do Steam);
   - o `steam.exe` que o jogo espera encontrar.
4. **Lança o jogo** num prefixo Wine próprio por jogo, com o ambiente certo (Rosetta, D3DMetal
   para DirectX 12, bibliotecas do Sikarugir).

O seu app Sikarugir original **nunca é alterado**: tudo acontece na cópia em
`~/Library/Application Support/notproton/runners/sikarugir-11.0-r0/`.

## Requisitos

| Item | Detalhe |
|---|---|
| Mac | Apple Silicon, macOS 15 ou mais novo |
| Rosetta 2 | `softwareupdate --install-rosetta --agree-to-license` |
| Steam do macOS | Um build com perfil de assinaturas em `signatures/macos.arm64/` (hoje: 1790904859, 1791415817 e 1791592380). Se o Steam atualizar para um build sem perfil, o app **recusa instalar** até existir um perfil novo. |
| Sikarugir | Um app (wrapper) criado com o motor **Sikarugir 11.0 revision 0** (`WS12WineSikarugir11.0`) |

## Preciso configurar algo no Sikarugir?

**Não.** O NotProton é autoconfigurável. Você só precisa ter **um app Sikarugir criado com o motor
11.0 revision 0**. Nada de ajustar opções dentro dele:

- O app **encontra sozinho** wrappers em `/Applications`, `~/Applications` e
  `~/Applications/Sikarugir`. Se o seu estiver em outro lugar, use **Add Sikarugir…** e aponte para o
  `.app`.
- Ele **confere o motor por hash** (versão e 5 arquivos-chave). Outra versão é recusada com uma
  mensagem dizendo o que falta.
- As opções gráficas do Sikarugir (D3DMetal, DXVK, DXMT no `Info.plist` do wrapper) **são
  ignoradas**: o NotProton liga o D3DMetal (DirectX 12) na cópia, pelo próprio launcher.
- O prefixo (`C:`) de cada jogo é criado pelo NotProton. Os prefixos do Sikarugir não são usados.

Se você ainda não tem o wrapper: no **Sikarugir Creator**, crie um wrapper novo escolhendo o motor
`WS12WineSikarugir11.0`, com qualquer nome. Ele **não precisa ter Steam (Windows) nem nenhum jogo
instalado**: o NotProton copia só `Contents/SharedSupport/wine` (o motor) e `Contents/Frameworks`
(as bibliotecas dele) e ignora o resto do wrapper. O Steam usado pelos jogos é o **Steam do Mac**, e
a ponte `lsteamclient` liga o jogo Windows a ele. Um wrapper que já tenha Steam Windows instalado
também funciona, mas esse Steam não é usado nem alterado.

## Instalação

### 1. Gerar o app (a partir do código)

Precisa de Xcode (com a licença aceita: `sudo xcodebuild -license accept`) e `cmake`.

```sh
git clone https://github.com/ElvisBaggio/notproton.git && cd notproton

# Dobby (biblioteca de hooks), fixada num commit específico
git clone https://github.com/jmpews/Dobby.git vendor/dobby
git -C vendor/dobby checkout 5dfc8546954ce3b3198132ab13fddb89ee92cdd7
make dobby

make app-payload   # compila dylib, ferramentas e copia ponte, payloads e perfis
make app           # gera out/NotProton Sikarugir.app (assinado ad-hoc)
```

A ponte Sikarugir (`lsteamclient` e `steam.exe`) é compilada contra o Wine 11.0 com o
`llvm-mingw` por `bridge/build-sikarugir.sh`; a receita completa está em
`docs/evidence/` (cards T01 e T03). O `make app-payload` só aceita a ponte se os hashes baterem.

### 2. Instalar

1. Feche o Steam.
2. Mova `out/NotProton Sikarugir.app` para `/Applications` e abra.
3. Na janela do NotProton, clique em **Install**. Ele instala o `notproton.dylib` no Steam e guarda
   um backup do estado anterior. Se pedido, conceda a permissão **App Management** (Ajustes do
   Sistema → Privacidade e Segurança).
4. Na seção **Sikarugir 11.0 (experimental)**:
   - se aparecer o seu wrapper, clique em **Set Up**;
   - se aparecer "Not found", clique em **Add Sikarugir…** e escolha o app Sikarugir.

   O Set Up copia o motor (clone APFS, quase instantâneo), aplica o patch, instala a ponte e
   registra a ferramenta.
5. Abra o Steam.

## Uso

1. No Steam, abra **Propriedades** do jogo Windows → **Compatibilidade** → marque *Forçar o uso de
   uma ferramenta de compatibilidade* → escolha **Sikarugir 11.0 (experimental)**.
2. Instale o jogo normalmente pelo Steam.
3. **Jogos DirectX 12**: comece com a opção de inicialização do próprio jogo para DirectX 11, se
   existir. Exemplo: em PEAK, use `-force-d3d11` em *Propriedades → Geral → Opções de
   inicialização*. Se não funcionar, tire a opção para usar DX12 via D3DMetal.
4. Clique em **Jogar**.

**Onde ficam as coisas**

| O quê | Onde |
|---|---|
| Cópia do motor | `~/Library/Application Support/notproton/runners/sikarugir-11.0-r0/` |
| Prefixo (C:) do jogo | `~/Library/Application Support/Steam/steamapps/compatdata/<AppID>/` |
| Saves (ex.: PEAK) | `…/compatdata/<AppID>/pfx/drive_c/users/<usuário>/AppData/LocalLow/…` |
| Log do lançamento | `…/compatdata/<AppID>/notproton-run.log` |

## Manutenção

- **Steam atualizou e o NotProton parou de instalar**: falta o perfil de assinaturas do build novo.
  Gere-o com `dylib/tests/sigprofile.py` e `dylib/tests/sigstatic.c` e valide com
  `make anchorcheck` com o Steam fechado. O passo a passo está em `docs/evidence/system-baseline.md`.
  No canal beta do Steam isso acontece bem mais vezes; o canal estável reduz o trabalho.
- **Reparar a cópia do motor**: botão **Repair** na seção Sikarugir.
- **Remover**: **Remove Copy** apaga só a cópia (o app Sikarugir fica). **Remove NotProton** tira o
  NotProton do Steam; jogos e prefixos são mantidos.

## Limitações conhecidas

- Só jogos **x86_64** (64 bits) via Rosetta; i386 não foi validado.
- DirectX 12 só via **D3DMetal**; não há vkd3d-proton.
- Alguns jogos Unity recentes podem não responder a cliques no menu (`EnableMouseInPointer` não
  implementado no Wine).
- Motor fixo: só o **Sikarugir 11.0 revision 0**. Outra revisão exige revalidar a ABI e os patches
  (`docs/evidence/engine-abi-report.md`).
- Experimental, sem atualização automática (Sparkle desligado).

## Relação com o NotProton original

Este fork **removeu o CrossOver** do código (app, launcher, ponte, patches e testes). Ele não é
mesclável com o original: melhorias de lá são **portadas à mão**, usando o mapa de arquivos
fork ↔ original em `docs/evidence/remove-crossover.md`. O app tem bundle id próprio
(`com.notproton.NotProton.sikarugir`) e pode conviver com o NotProton original instalado.

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `app/` | App macOS (SwiftUI): instalação, cópia, patch e reparo |
| `dylib/` | `notproton.dylib`: hooks no Steam e launcher `feats/compat_run.sh` |
| `lsteamclient/`, `bridge/` | Ponte Steam (porte do lsteamclient do Proton) e build Sikarugir |
| `steam-shim/` | `steam.exe` (porte do steam-helper do Proton) |
| `ntdll-patch/` | Resolvedor, patcher e testes do patch da `ntdll` |
| `signatures/` | Perfis de assinaturas por build do Steam |
| `docs/` | Plano, evidências e revisões de cada etapa |

## Licença

Veja `NOTICE`.
