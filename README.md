# prumo

Harness de contexto e método para agentes de código. **Claude Code** e **Cursor**.

Prumo é o fio com peso que diz se a parede está no esquadro. Ele não levanta a parede —
ele impede que ela suba torta. É isso que este harness faz: não escreve o seu código,
mas não deixa nada fechar sem prova.

Só Markdown e um instalador. Sem runtime, sem binário, sem dependência.

## Instalar

```bash
git clone https://github.com/<voce>/prumo.git
bash prumo/install.sh /caminho/do/seu/projeto
```

Antes, para ver o que ele faria sem escrever um byte:

```bash
bash prumo/install.sh --dry-run /caminho/do/seu/projeto
```

Depois, abra o agente no projeto e cole o pedido. A triagem escolhe a rota.

## Ele se adapta ao seu projeto, não o contrário

🔴 **Nada que já existe é sobrescrito.** Projeto com `AGENTS.md`, `docs/` e specs não é
obstáculo — é a melhor fonte que o harness vai ter. A instalação lê o que está lá, mede
os fatos (`perfil.tsv`), e escreve **só a lacuna**.

O índice canônico é o que o projeto já usa: se existe `CLAUDE.md` e não `AGENTS.md`, o
bloco vai para o `CLAUDE.md`. O bloco é delimitado por marcadores, então reinstalar
substitui só o miolo e preserva a prosa em volta.

**Sem documentação nenhuma?** Ele deriva o contexto do próprio código — stack, como se
roda, onde o código mora, o que a esteira exige, e as lacunas — em `.prumo/contexto.md`,
que é local e fora do git.

## A espinha

| Peça | Dispare quando |
|---|---|
| `triagem` | chega um pedido, chave ou bug |
| `plano` | a mudança não é trivial |
| `execucao` | existe plano aprovado |
| `prova` | antes de dizer "pronto" |
| `ui-plano` | a entrega muda o que se vê |
| `aprender` | a sessão ensinou algo |
| `leveza` | sempre, em qualquer código |

## O que ele faz de diferente

**O andaime não vai para o git.** `tasks/prd-<slug>/` — plano, tasks, spec de trabalho —
é efêmero e da pessoa que está trabalhando. Vai para `.git/info/exclude`, que é local,
**nunca** para o `.gitignore`, que é rastreado e sujaria a árvore de todo mundo. Só o
registro durável (decisão, ADR) entra no repositório, e no lugar que o projeto já usa.

**UI não começa sem referência, e bug não paga esse pedágio.** Quatro degraus: protótipo
medido → referência de base → mapear o padrão do próprio produto → nada. O plano de UI é
obrigatório nos quatro; o degrau só muda de onde vem a forma. Entrega sem mudança visual
não pede nada e não pergunta nada.

**A prova de interface é a tela.** Suíte verde com a tela quebrada é o caso normal, não a
exceção. Três resultados possíveis, e o terceiro é o que quase todo harness perde:
PASSOU, FALHOU e **NÃO MEDIU** — que nunca é PASSOU.

**Custo residente baixo.** Teto de 6.000 chars no projeto-alvo; hoje usa ~3.400. O
conhecimento profundo vive em `rules/`, lido por caminho, custo zero.

## Dois clientes, um conteúdo

O artefato é escrito uma vez em `skills/` e renderizado:

| Cliente | Onde | Forma |
|---|---|---|
| Claude Code | `.claude/skills/<n>` → symlink | `SKILL.md` |
| Cursor | `.cursor/rules/<n>.mdc` | rule, `alwaysApply` só em `leveza` |

Canônico em `.agents/skills/`. Duas cópias mantidas à mão divergem.

## Ferramentas

```bash
bash scripts/mapear-codebase.sh <dir>   # deriva contexto do código
bash scripts/detectar-slop.sh <dir>     # 11 regras de UI gerada por modelo
bash scripts/gerar-indice.sh <dir>      # índice de memória, gerado do disco
```

## Créditos

- A escada de leveza e a convenção de dívida derivam do
  [ponytail](https://github.com/pbakaus/ponytail) (MIT).
- Para ofício visual a sério — 61 regras sobre o DOM renderizado, crítica e iteração ao
  vivo — use o [Impeccable](https://github.com/pbakaus/impeccable). O `ui-plano` detecta
  se ele está instalado e cede a vez. O detector daqui é o piso para quando ele não está.

## Licença

MIT.
