# Handoff

Atualizado: 2026-10-08 · Agente: codex · Máquina: mac

## Estado

- Projeto pessoal: Cities: Skylines II pelo Steam nativo com NotProton e motor Sikarugir, sem depender de CrossOver.
- Abordagem e arquitetura aprovadas em conversa: fork mínimo, engine fixada, cópia isolada e prefixo exclusivo.
- Base: NotProton v1.1.0, commit `05a27874798ffbffb8e64a37595bde6f16d5320a`.
- Branch de documentação: `codex/sikarugir-cities2-design`; remoto `upstream` aponta ao projeto original.
- Especificação: `docs/superpowers/specs/2026-10-08-sikarugir-cities2-design.md`, aguardando revisão do arquivo por Elvis.
- Apenas investigação somente leitura e documentação. Nenhuma implementação ou teste de runtime foi executado.

## Próximo passo

1. Receber revisão/aprovação da especificação escrita.
2. Usar `superpowers:writing-plans` para preparar o plano detalhado.
3. Receber revisão do plano e escolha do método de execução antes de implementar.

Regra explícita de modelos: Astra planeja e revisa; **qualquer implementação somente por `gpt-6.1-sol` ou `gpt-6-luna`**, incluindo scripts de prova e testes. Não substituir por outros modelos. Delegar arquivos de forma exclusiva e preservar mudanças de outros agentes.

## Bloqueios / decisões pendentes

- Ponte upstream preparada com Wine 11.15; engine observada no wrapper é Sikarugir 11.0. Viabilidade ainda não comprovada.
- Fonte exata da engine, versão efetiva do Steam e configuração gráfica carregada precisam de validação na execução do plano.
- Localização atual do Cities II precisa ser confirmada; o antigo drive S: aponta para diretório ausente. Elvis afirma que consegue abrir o jogo pelo Sikarugir.
- NotProton 1.1.0 e pasta de suporte já existem; inventariar e preparar rollback antes de futura implantação.
- Sem remoto pessoal configurado: documentação mantida em commit local. Não criar/publicar projeto remoto nesta etapa do brainstorming, nem fazer push para o upstream.
