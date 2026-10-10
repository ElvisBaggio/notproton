**ACEITO COM RESSALVAS — viabilidade técnica do E2 comprovada para x86_64/Rosetta.**  
Cliente: `codex` · Revisor: Astra · Modelo efetivo: `gpt-6-astra`. Branch/HEAD conferidos: `codex/game-agnostic-scope` / `06df336`.

O executável Windows mínimo alcançou a Steam nativa e observou sessão autenticada. Isso atende ao resultado do E2; não comprova ainda o lançamento de jogos pelo NotProton.

**Critérios do plano, item a item**

| Critério | Parecer e evidência |
|---|---|
| Base fixada e ABI compatível | **PASS.** Comparação registra zero divergências bloqueantes; diferenças de `build_module` exigem hooks próprios, devidamente tratados em T04. [engine-abi-report.md:94](../../docs/evidence/engine-abi-report.md:94) |
| T03: ponte reproduzível, isolada, arquiteturas/dependências verificadas e negativos de base | **PASS com ressalva documental.** Inspeções, sete negativos e reconstrução constam do relatório. A correção LC_UUID em `152df29` registra relink reproduzível; T05 confere o novo artefato `d71f954c…`. A tabela principal de T03 ainda descreve o anterior. [bridge-build.md:110](../../docs/evidence/bridge-build.md:110), [steam-api-probe.md:199](../../docs/evidence/steam-api-probe.md:199) |
| T04: pins reais, aplicação em cópias, negativos e preservação dos originais | **PASS.** Correção `0x40000000` restrita aos hashes Sikarugir; rebuild, diff, recusa de reaplicação e 12 testes documentados. A equivalência CrossOver cobre fonte preprocessada e payload x64 LLVM; **não** reprodução do pin GCC legado. [ntdll-port.md:129](../../docs/evidence/ntdll-port.md:129) |
| T05, passo 1: falha explícita sem Steam | **PASS.** Negativo real alcança a biblioteca nativa, falha em `CreateSteamPipe` e retorna exit 1. [steam-api-probe.md:264](../../docs/evidence/steam-api-probe.md:264) |
| T05, passo 2: prefixo isolado e comunicação Unix sem falhas | **PASS no caminho exercitado**, após correções de ambiente, LC_UUID e flags. Sem assert, `c0000135` ou falha Unix observada na rodada final. [steam-api-probe.md:268](../../docs/evidence/steam-api-probe.md:268) |
| T05, passo 3: API nativa, AppID selecionado e autenticação | **PASS.** Steam build `1791415817`; saída `ok / 3527290 / yes`, exit 0, acompanhada da cadeia real até `BLoggedOn`. Posse de PEAK declarada por Elvis. [steam-api-probe.md:323](../../docs/evidence/steam-api-probe.md:323) |
| Assert “AppID diferente ⇒ falha” | **PASS de comparação; não de licença.** Saída 480 comparada com esperado 3527290 é recusada. Executar com `--appid 480` altera também o esperado e passa: não constitui teste negativo de propriedade. Essa limitação precisa ficar explícita no contrato. [plano:197](../../docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md:197), [steam-api-probe.md:361](../../docs/evidence/steam-api-probe.md:361) |
| T05, passo 4: integridade e relatório | **PASS nas superfícies medidas:** cinco arquivos do wrapper, 965 entradas Frameworks e `steamclient.dylib` iguais antes/depois; logs públicos filtrados. Não equivale a auditoria integral da biblioteca/saves. [steam-api-probe.md:369](../../docs/evidence/steam-api-probe.md:369) |

O gate exige prova real, não obrigatoriamente jogo real nesta etapa: a especificação define expressamente um **executável Windows mínimo** para o Marco 1. Gameplay, persistência e rollback pertencem aos marcos posteriores. [plano:123](../../docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md:123), [spec:109](../../docs/superpowers/specs/2026-10-08-sikarugir-cities2-design.md:109)

**Condições explícitas para T06–T12**

- **T06:** manter suporte declarado x86_64/Rosetta; definir layout único incluindo Frameworks, descoberta por hashes e TSV preservado. Payload i386 construído não significa ponte i386 funcional.
- **T07:** consumir exclusivamente hashes pós-correção; preservar isolamento da ponte CrossOver; validar cópia completa e build Steam igual ao perfil. Reprodução GCC legado ausente não pode virar “regressão CrossOver integralmente validada”. [e3-codemap.md:170](../../docs/reviews/e3-codemap.md:170)
- **T08:** transportar o ambiente comprovado para launcher, ferramentas e rebuild: `SikarugirAppWine11`, DYLD após `arch`, caminho da Steam nativa e localização do trigger. Validar **`steam.exe` e o lançamento integrado**, incluindo conversão de caminhos; repetir o probe não cobre esse fluxo. Observar interferências de `apply_binary_patches` em memória, sem inferir ausência por hashes em disco. [e3-codemap.md:119](../../docs/reviews/e3-codemap.md:119)
- **T09:** regressões Swift em Xcode/CI funcional, sem contar SKIP como PASS; pacote experimental aberto e conferido, updater isolado e aplicativo original preservado. [e3-codemap.md:158](../../docs/reviews/e3-codemap.md:158)
- **T10:** deploy → rollback → readback funcional → redeploy, conforme o plano; backup sozinho não encerra o card. [plano:344](../../docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md:344)
- **T11:** instalação Windows nova, Jogar pelo Steam nativo, renderer efetivamente carregado, entrada funcional e gameplay. Menu sem clique é FAIL. Registrar Cloud antes de jogar; usar DX11 como primeira tentativa é coerente com a preparação atual, sem exigir um novo programa D3D12 para provar esse caminho. [game-launch.md:63](../../docs/evidence/game-launch.md:63)
- **T12:** ≥15 minutos, alteração persistente e reabertura após encerrar jogo e Steam; wrapper funcional e rollback comprovado. Nenhum NOT RUN encerra E4. [plano:396](../../docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md:396)

**Inconsistências a corrigir**

1. **Receita T03 obsoleta:** ainda recomenda `-no_uuid` e publica `.so 3dd9b54f…`; vigente: `d71f954c…`. [bridge-build.md:72](../../docs/evidence/bridge-build.md:72)
2. **Hashes históricos parecem finais:** `64930d7e…`/`932f5d47…` continuam na seção “Artefatos finais” e no HANDOFF. Vigentes: x64 `ef8e9971…`, i386 `60c6a031…`. Preservar histórico, mas marcar explicitamente como superado. [ntdll-port.md:96](../../docs/evidence/ntdll-port.md:96), [ntdll-port.md:142](../../docs/evidence/ntdll-port.md:142)
3. **Contrato de ambiente conflitante:** T08 proíbe variáveis CrossOver, mas a proposta D3DMetal usa `CX_APPLEGPTK_LIBD3DSHARED_PATH`. Resolver como exceção nominal, apontando exclusivamente para a cópia, ou escolher outro perfil; não remover indiscriminadamente nem herdar `CX_*`. [plano:290](../../docs/superpowers/plans/2026-10-08-sikarugir-cities2-implementation.md:290), [dx12-renderer-risk.md:93](../../docs/evidence/dx12-renderer-risk.md:93)
4. **Estado documental atrasado:** AGENTS ainda aguarda positivo; HANDOFF pede confirmação de posse já registrada; plano diz Cloud não listado, enquanto cache documenta Auto-Cloud. Há também ordens diferentes de tentativa DX12/DX11. [AGENTS.md:5](../../AGENTS.md:5), [HANDOFF.md:7](../../HANDOFF.md:7), [game-launch.md:31](../../docs/evidence/game-launch.md:31)
5. **Revisão Opus permanece pendente.** Este parecer registra o aceite Astra; não representa revisão Opus executada nem fechamento/sincronização de cards. [steam-api-probe.md:387](../../docs/evidence/steam-api-probe.md:387)

**E3 está tecnicamente liberado para começar por T06**, registrando este aceite e as condições no fechamento de T05. T07 → T08 → T09 continuam sequenciais, cada qual dependendo do aceite anterior. Não há bloqueio técnico remanescente do probe que justifique recusar E2.

Não alterei arquivos, executei runtime, reli logs privados ou verifiquei o board remoto; o parecer avalia as evidências versionadas. Risco restante: a ponte funciona no probe, mas `steam.exe`, renderer, gameplay e persistência ainda precisam de prova própria.
