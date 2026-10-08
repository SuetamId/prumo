# prumo

Harness de contexto e método para agentes de código. **Claude Code** e **Cursor**.
Só Markdown + um instalador — não contém código de aplicação.

Destilado de um harness maior de uso interno, mantendo o que se provou e cortando o
que era acoplamento de empresa. Aqui não existe nome de produto, endpoint, rastreador
nem convenção de time: o que varia vira **dado**, e o que é dado mora em `perfil.tsv`
do projeto-alvo — nunca no artefato.

## A espinha

Sete peças, e a ordem importa. Cada uma só existe porque a anterior não cobre o caso.

| # | Peça | Dispara quando | Entrega |
|---|---|---|---|
| 1 | `triagem` | chega um pedido, chave ou bug | classe, rota e a linha `UI:` |
| 2 | `plano` | a mudança não é trivial | plano executável, com superfície de UI quando houver |
| 3 | `execucao` | existe plano aprovado | código, um bloco por vez, com prova por bloco |
| 4 | `prova` | antes de dizer "pronto" | evidência — **incluindo a interface real**, não só teste |
| 5 | `ui-plano` | a entrega muda o que se vê | plano de UI: superfícies, estados, componentes, referência |
| 6 | `aprender` | a sessão ensinou algo | episódio durável, indexado |
| 7 | `leveza` | sempre, em qualquer código | a menor solução que funciona + ledger de dívida |

A `prova` chama `revisar`: a revisão roda num agente novo, de contexto limpo — quem escreveu
não aprova.

Antes da espinha, para quem é de produto: `demanda` transforma ideia em história de negócio no
rastreador. Ela para na história — a divisão técnica por repositório é do `plano`.

## Os cinco princípios

1. Mudança não trivial não escreve código sem plano. Ajuste trivial segue direto, com prova.
2. Nada fecha sem output de verificação. Teste que não rodou não é teste que passou.
3. Não presume — o que não está no repositório não existe.
4. A menor solução que funciona é a certa.
5. Entrega só fecha pela prova pós-implementação, e em UI a prova é a tela.

## Dois clientes, um conteúdo

O artefato é escrito **uma vez** e renderizado para cada cliente:

| Cliente | Onde lê | Forma |
|---|---|---|
| Claude Code | `~/.claude/skills/<nome>/SKILL.md` (global) | skill com frontmatter `name`/`description` |
| Cursor | `.cursor/rules/<nome>.mdc` | rule com frontmatter `description`/`alwaysApply` |

Ambos também leem `AGENTS.md` na raiz. Fonte única em `skills/`; o instalador converte.
Duas cópias mantidas à mão divergem — é o defeito que esta regra existe para impedir.

## Adoção: o projeto existente manda

🔴 **O instalador nunca sobrescreve contexto que já existe.** Projeto com `AGENTS.md`,
`docs/` e `tasks/` bons é ativo, não obstáculo: a adoção **lê** o que está lá, mapeia
contra a espinha e escreve **só a lacuna**. O que ele encontra vira o `perfil.tsv` do
projeto — comandos de build e teste, convenção de branch e commit, onde moram as specs.

Detalhe em `skills/triagem/rules/adocao.md`.

## Workspace ativo × registro durável

| | Onde | Git |
|---|---|---|
| **Workspace ativo** — `prd.md`, `plan.md`, `tasks.md`, `ui.md` | `tasks/prd-<slug>/` | 🔴 **nunca** (`info/exclude`) |
| **Registro durável** — ADR, decisão, spec consolidada | onde o projeto já guarda | sempre |

O workspace ativo é **nosso padrão em todo projeto**: andaime não se versiona, não se
revisa e gera conflito entre quem trabalha em paralelo. O registro durável é **do
projeto**: já existe e o time já sabe onde procurar.

## Memória

Um episódio por arquivo em `docs/ai-harness/memoria/`, índice **gerado** do disco.
O ledger `.sdd-origem.tsv` distingue quatro casos — pristino, editado, local, novo — e
é o que permite corrigir uma semente sem destruir o que a pessoa escreveu.

## Orçamento

Teto de **6.000 chars residentes** no projeto-alvo (`AGENTS.md` + descrições).
Estourar é falha — medido por `check.sh`, no CI. Conhecimento mora em `rules/`, lido por caminho, custo zero.
