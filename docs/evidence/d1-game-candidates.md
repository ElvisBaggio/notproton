# D1 — Candidatos a jogo-base para T05/T11

Agente: claude (Claude Code, modelo efetivo `sonnet` = Sonnet 5.5) · Data: 2026-10-09 · Branch `claude/d1-game-candidates`.
**A decisão final é de Elvis.** Este documento só propõe; nada foi instalado, comprado ou baixado, e o Steam não foi aberto nem alterado.

## 1. Inventário local (somente leitura)

- `steamapps/libraryfolders.vdf`: uma biblioteca, lista `apps` vazia. Não há `appmanifest_*.acf`: nenhum jogo está instalado. `steamapps/common/` tem só uma pasta vazia de nome "Baldurs Gate 3".
- `userdata/<conta>/config/localconfig.vdf` existe, mas não traz lista de posse utilizável. `config/librarycache/` tem JSONs de metadados para os AppIDs 1086940, 1705180, 19900, 220240, 2231380, 223750, 226455, 226456, 236390, 240, 320, 34830, 460930 e 949230. Isso mostra apps vistos pela biblioteca, **não** prova posse. Nenhum nome ou id de conta foi copiado.
- Conclusão: a conta tem posse não verificada de qualquer candidato. Por isso a preferência recai sobre jogos gratuitos, que dispensam compra e não dependem de posse.

## 2. Candidatos

Plataformas, preço, categorias e requisitos vêm da API pública da loja (`store.steampowered.com/api/appdetails`, consultada em 2026-10-09; preços em BRL). SteamDB retornou 403, então a ausência de depot macOS foi confirmada só pelo campo `platforms.mac=false` da loja; **confirmar os depots no SteamDB/`steamcmd` antes de T11**.

| # | Jogo | AppID | Preço | Plataformas na loja | Tamanho (loja, Windows) | API Steam (sinal) | Save/config no Windows | DRM / anti-cheat | Conta já possui |
|---|------|-------|-------|---------------------|-------------------------|-------------------|------------------------|------------------|-----------------|
| 1 | Banana | 2923300 | Grátis | Win + Linux; **sem mac** | 2 GB listados (jogo real tende a ser bem menor) | Conquistas + Steam Cloud | A confirmar em T11 (jogo Unity; provável `AppData\LocalLow` e/ou Cloud) | Nenhum conhecido | Desconhecido; gratuito, resgate sem custo |
| 2 | Halls of Torment: Prelude | 2316660 | Grátis | Win + Linux; **sem mac** | 1 GB | Steam Cloud (sem conquistas listadas) | A confirmar (provável `%APPDATA%\Godot\app_userdata\Halls of Torment` ou Cloud) | Nenhum conhecido | Desconhecido; gratuito |
| 3 | Halls of Torment (completo) | 2218750 | R$ 19,99 | Win + Linux; **sem mac** | 4 GB | Conquistas + Steam Cloud | Igual ao Prelude | Nenhum conhecido | Desconhecido; exigiria compra |

Os três têm depot Linux nativo, mas nenhum macOS, então o Steam usará ferramenta de compatibilidade no Mac. O depot Linux não atrapalha o critério, pois só o macOS importa para a seleção do Steam nativo no Mac.

Descartados por critério:
- Vampire Survivors (1794680), Unturned (304930), Crab Game (1782210): têm build macOS (ou sem API Steam útil no caso do Crab Game).
- Ghost Recon Breakpoint (2231380): 67 GB, pago, anti-cheat/DRM da Ubisoft.
- Gunner, HEAT, PC! (1705180): 11 GB, pago.
- Spacewar (480): a API da loja não retorna dados; é app de teste do SDK, sem save persistente. Útil só como controle técnico, não como D1.
- Cities: Skylines II (949230): excluído pelo plano.

## 3. Recomendação (sujeita a decisão de Elvis)

- **Principal: Banana (2923300).** Gratuito, sem macOS, com conquistas e Steam Cloud (dois sinais claros de `SteamAPI_Init` e de estado em Cloud), pequeno e sem anti-cheat conhecido. Ressalva: o jogo depende de rede e de drops de itens da conta; é pouco jogo, então T12 prova persistência por progresso/configuração, não por save elaborado.
- **Reserva: Halls of Torment: Prelude (2316660).** Gratuito, sem macOS, com Steam Cloud, e save de jogo real (progresso de run/meta), o que facilita a prova de save/reabertura do T12. Sem conquistas listadas, o sinal de API é só Cloud. Se Elvis aceitar pagar R$ 19,99, a versão completa (2218750) traz conquistas.

## 4. Verificações pendentes (para T11, antes de instalar)

1. Confirmar ausência de depot macOS em SteamDB ou `steamcmd +app_info_print`.
2. Confirmar caminho exato do save no prefixo e as regras de Cloud (`ufs savefiles`), com o jogo executado uma vez.
3. Confirmar que a conta tem ou pode resgatar o jogo sem custo.
4. Confirmar chamada real a `SteamAPI_Init` em T05, não só pela categoria da loja.

## Fontes

- [Banana, API da loja](https://store.steampowered.com/api/appdetails?appids=2923300&l=english) · [página](https://store.steampowered.com/app/2923300/)
- [Halls of Torment: Prelude, API](https://store.steampowered.com/api/appdetails?appids=2316660&l=english)
- [Halls of Torment, API](https://store.steampowered.com/api/appdetails?appids=2218750&l=english)
- [Vampire Survivors, API](https://store.steampowered.com/api/appdetails?appids=1794680&l=english) · [Unturned, API](https://store.steampowered.com/api/appdetails?appids=304930&l=english) · [Crab Game, API](https://store.steampowered.com/api/appdetails?appids=1782210&l=english)
- [Ghost Recon Breakpoint, API](https://store.steampowered.com/api/appdetails?appids=2231380&l=english) · [Gunner, HEAT, PC!, API](https://store.steampowered.com/api/appdetails?appids=1705180&l=english)
- [Banana: contexto (Yahoo)](https://malaysia.news.yahoo.com/banana-game-why-over-600k-163845707.html) · [GamingOnLinux](https://www.gamingonlinux.com/2024/06/hundreds-of-thousands-of-people-are-now-clicking-a-banana-on-steam/page=1/)
