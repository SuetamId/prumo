---
name: triagem
description: Use quando chegar um pedido, chave de issue, bug ou demanda sem skill escolhida — classifica, decide a rota mínima e declara a superfície de UI antes de qualquer arquivo ser tocado.
when_to_use: >-
  "chegou essa demanda", chave de issue colada, relato de bug, "o que eu faço com isso",
  "retomando a issue". NÃO dispare para commit, log ou pergunta de fato.
---

# Triagem — a rota mínima, antes de tocar arquivo

Sua saída é **uma linha** e a rota executada. Você não devolve ao DEV a escolha da skill.

## 1. Contexto: leia o que o projeto já diz

Antes de classificar, carregue o que existe — nunca presuma a stack nem a convenção:

```bash
cat perfil.tsv 2>/dev/null            # escrito pela adoção: build, teste, branch, specs
ls AGENTS.md CLAUDE.md docs/ tasks/ 2>/dev/null
```

Sem `perfil.tsv`, confira se é um **worktree** — ele só recebe o que é rastreado, e
`perfil.tsv`/`.prumo/` são locais. O original mora no checkout principal:

```bash
cat "$(git rev-parse --path-format=absolute --git-common-dir)/../perfil.tsv"
```

Use esse caminho também para `.prumo/templates/` — 🔴 **só leitura**. Toda escrita
(`tasks/`, memória, código) vai no worktree em que a sessão roda: o checkout principal
não é a branch desta sessão, e outra sessão pode estar mexendo nele. Só se nem lá existir o projeto nunca
foi adotado → `rules/adocao.md` **antes** de seguir.

**Projeto sem documentação?** Leia `.prumo/contexto.md` — contexto derivado do próprio
código: stack, como se roda, onde o código mora, o que a esteira exige, e as **lacunas**.
Ele é **gerado** e envelhece: confira o `HEAD` no cabeçalho contra o atual e regenere
quando divergir (`bash scripts/mapear-codebase.sh`, na raiz do projeto). 🔴 Ele dá **estrutura, nunca decisão** —
o código não diz o que foi rejeitado nem por quê. Isso só existe se alguém escreveu.

## 2. Classifique

| Classe | Como reconhecer | Rota mínima |
|---|---|---|
| **trivial** | typo, rename local, bump, formatação | executa direto, com prova. Sem plano, sem branch |
| **bug** | comportamento errado e reproduzível | reproduz → causa raiz (`leveza`) → corrige → `prova` |
| **mudança** | comportamento novo ou diferente | `plano` → `execucao` → `prova` |
| **investigação** | ninguém sabe ainda o que está errado | mede antes de propor; só depois vira bug ou mudança |
| **consulta** | pergunta de fato | responde. Sem branch, sem plano, sem cerimônia |

🔴 **O tipo declarado no rastreador não decide.** É alegação. Sintoma, alcance e estado
do código decidem. Ticket marcado "Bug" que pede comportamento novo é **mudança**.

🔴 **Não invente etapa para tarefa simples.** A cerimônia que não serve ao caso ensina o
time a pular a cerimônia que serve.

## 3. Declare a superfície de UI

Sempre, em qualquer classe. Carregue `../ui-plano/SKILL.md` e rode os dois gates dele.
Ele decide se há referência visual a exigir — e em bug sem mudança visual manda **não
perguntar nada**.

## 4. Saída obrigatória

Duas linhas, antes de executar:

```
<chave/pedido> → <classe> → <rota> · assumi <X> porque <evidência verificável>
UI: classe <A|B|C> · <degrau da escada ou "sem mudança visual">
```

A assunção é obrigatória e precisa ser **verificável**. "Assumi backend" não serve;
"assumi backend porque o sintoma reproduz sem abrir a tela" serve.

## Regras duras

- Sem mudança em código de produção, sem branch.
- Não presuma stack, comando ou convenção: está em `perfil.tsv` ou você mede.
- Se os desempates forem inconclusivos, **meça** — não escolha a rota provável.
- Falha na prova volta para a causa raiz, não para um plano novo.
