# prumo

Método para agentes de código — **Claude Code** e **Cursor**.

Prumo é o fio com peso que diz se a parede está no esquadro. Ele não levanta a parede;
impede que ela suba torta. Este harness não escreve o seu código — ele faz o agente
**planejar antes, provar depois e não fechar nada sem evidência**.

Só Markdown e um instalador. Sem runtime, sem binário, sem dependência.

---

## Começar

**Mais fácil: peça ao agente.** Cole no Claude Code o prompt de
[`INSTALAR-COM-AGENTE.md`](INSTALAR-COM-AGENTE.md) (no fim do arquivo), com a sua org, os
produtos, a pasta base e o endereço do Hub. Ele clona, organiza por produto, migra clones
antigos sem perder nada, instala dependências, roda os testes e conecta ao Hub.

Prefere fazer à mão:

Você precisa de `git`, `python3` e — para o produto inteiro — o [`gh`](https://cli.github.com)
com login (`gh auth login`).

**1. Baixe o kit** (uma vez por máquina):

```bash
git clone https://github.com/SuetamId/prumo.git ~/.prumo-kit
```

**2. Instale.** Escolha um dos dois:

| Situação | Comando |
|---|---|
| Produto com vários repositórios (front, API, worker…) | `bash ~/.prumo-kit/workspace.sh <org> <produto> --jira` |
| Um projeto que você já tem clonado | `cd meu-projeto && bash ~/.prumo-kit/install.sh .` |

O primeiro monta `~/<org>/<produto>/`, clona os repositórios do produto, instala o prumo
em cada um e — com `--jira` — conecta o Jira no Claude Code e no Cursor.

**3. Reinicie o agente** e cole o seu pedido. Pronto.

> Quer ver antes? `bash ~/.prumo-kit/install.sh --dry-run .` mostra tudo que seria feito
> sem escrever nada.

### Memória do time (Hub)

Se a sua empresa roda um Hub de memória, conecte os agentes a ele — uma vez por máquina:

```bash
prumo-workspace --hub https://endereco-do-hub
```

Ele pede a chave (gerada em **Chaves de API** no Hub, sem eco no terminal), confere com o
servidor e configura o Claude Code e o Cursor. A chave fica em `~/.config/prumo/hub-key`,
legível só por você; no Claude Code ela nem entra na configuração. Também funciona junto
com o workspace: `prumo-workspace <org> <produto> --hub https://…`.

Com o Hub conectado, a triagem busca o que o time já sabe antes de começar, e o `aprender`
propõe ao time o que vale para além do repositório — um admin revisa antes de virar regra.

---

## Usar no dia a dia

Abra o agente na pasta do repositório e cole **a chave do Jira, o bug ou o pedido**. Não
precisa escolher skill — a triagem escolhe:

```
PROJ-123 → mudança → plano → execucao → prova · assumi front porque o ticket só cita a tela
UI: classe B · degrau 3 (padrão do próprio produto)
```

| Você pede | O que acontece |
|---|---|
| ajuste pequeno, typo | executa direto e mostra a prova |
| bug | reproduz, acha a causa raiz, corrige, prova |
| funcionalidade nova | plano primeiro; código só depois do plano aprovado |
| "não sei o que está errado" | levanta hipóteses e derruba com dado antes de propor |
| problema em produção | investiga só lendo; nada muda em produção sem você aprovar |

Antes de dizer "pronto", o agente **cola a saída** dos testes — e, se mexeu em tela, abre
a tela de verdade. Antes do PR, um **revisor em outro contexto** revisa o diff: quem
escreveu não aprova.

### As sete peças

| Peça | Entra quando |
|---|---|
| `triagem` | chega um pedido, chave ou bug |
| `plano` | a mudança não é trivial |
| `execucao` | existe plano aprovado |
| `prova` | antes de dizer "pronto" — e antes do PR |
| `ui-plano` | a entrega muda o que se vê |
| `aprender` | a sessão ensinou algo que vale guardar |
| `leveza` | sempre: a menor solução que funciona |

---

## Atualizar

De dentro de qualquer projeto:

```bash
prumo-atualizar
```

Puxa o kit e reinstala. Para conferir sem mudar nada: `prumo-atualizar --conferir`.

Para atualizar um produto inteiro (pull dos repositórios + prumo em cada um), rode o
workspace de novo: `prumo-workspace <org> <produto>`.

> Os atalhos ficam em `~/.local/bin/`. Se ele não estiver no seu `PATH`, a instalação
> avisa e diz o que acrescentar.

---

## Ajustar ao seu projeto

A instalação **mede** o projeto e grava os fatos em `perfil.tsv`: comandos de build,
teste e lint, branch base, estilo de commit, repositórios irmãos.

**A medição errou?** Edite o valor e troque a origem por `declarado:` — a linha passa a
sobreviver às reinstalações:

```text
branch_base	development	declarado: time integra em development
```

Fatos que nenhuma medição descobre também vão como `declarado:` — de onde ler os logs,
o painel de métricas, como abrir o banco **só leitura**. Nunca a senha: só o caminho.

**Nada que já existe é sobrescrito.** Se o projeto já tem `AGENTS.md` ou `CLAUDE.md`, o
prumo acrescenta um bloco entre marcadores e não toca no resto. Sem documentação
nenhuma, ele deriva o contexto do próprio código em `.prumo/contexto.md`.

---

## Problemas comuns

**O agente não encontra as skills.** Reinicie o agente depois de instalar. No Claude Code,
as skills ficam em `~/.claude/skills/` e valem para todos os projetos.

**Um repositório do produto ficou de fora do workspace.** O workspace pega os
repositórios com nome `<produto>-*`. Para um nome fora do padrão, adicione o topic
`<produto>` ao repositório no GitHub e rode de novo.

**`prumo-atualizar: command not found`.** `~/.local/bin` não está no `PATH`. Use
`bash ~/.prumo-kit/atualizar.sh` ou acrescente ao seu shell:
`export PATH="$HOME/.local/bin:$PATH"`.

**Rodei o `install.sh` e nada mudou.** O kit estava velho — o install reinstala a versão
que está no disco. Use `prumo-atualizar`, que puxa antes.

**Worktree sem `perfil.tsv`.** Normal: worktree só recebe o que é commitado, e o perfil é
local. A triagem lê o do checkout principal sozinha.

---

<details>
<summary><b>O que a instalação cria</b></summary>

| Caminho | Vai pro git? | O que é |
|---|---|---|
| `~/.claude/skills/<peça>` | — | skills do Claude Code, globais (symlink para o kit) |
| `.agents/skills/` · `.cursor/rules/` | sim | as mesmas skills, para o Cursor |
| bloco em `AGENTS.md` ou `CLAUDE.md` | sim | índice curto, entre marcadores |
| `docs/ai-harness/memoria/` | sim | o que o harness aprendeu neste projeto |
| `perfil.tsv` · `produto.md` | não | fatos do projeto |
| `tasks/` | não | plano e tarefas em andamento |
| `.prumo/` | não | contexto derivado do código |

O que não vai pro git entra em `.git/info/exclude`: local, sem diff, sem sujar a árvore
de ninguém.

</details>

<details>
<summary><b>Desinstalar</b></summary>

No projeto:

```bash
rm -rf .prumo tasks perfil.tsv produto.md .agents/skills/{triagem,plano,execucao,prova,ui-plano,aprender,leveza} .cursor/rules/{triagem,plano,execucao,prova,ui-plano,aprender,leveza}.mdc
```

```bash
python3 -c "import re,os; f=[x for x in ('AGENTS.md','CLAUDE.md') if os.path.isfile(x)][0]; t=open(f).read(); open(f,'w').write(re.sub(r'\n*<!-- prumo:start -->.*?<!-- prumo:end -->\n*','\n',t,flags=re.S)); print('bloco removido de',f)"
```

Na máquina (skills globais do Claude Code):

```bash
rm -f ~/.claude/skills/{triagem,plano,execucao,prova,ui-plano,aprender,leveza}
```

`docs/ai-harness/memoria/` fica de propósito — é conhecimento do seu projeto. Apague à
mão se quiser zerar.

</details>

<details>
<summary><b>Para quem mantém o kit</b></summary>

- Princípios, orçamento e regras de escrita: [`AGENTS.md`](AGENTS.md).
- Inventário de tudo que é instalado: [`manifest.tsv`](manifest.tsv) — adicionar artefato
  é adicionar linha.
- Uma fonte, dois clientes: escreva em `skills/<peça>/`; o instalador gera o formato do
  Cursor. `rules/`, `scripts/` e `templates/` de uma skill moram dentro dela.
- Antes de abrir PR:

  ```bash
  bash check.sh
  ```

  Confere sintaxe, manifesto, referências, neutralidade (nenhum nome de cliente nos
  artefatos), credencial, uma instalação real e o orçamento residente. Roda no CI.

</details>

---

## Créditos

- A escada de leveza e a convenção de dívida derivam do
  [ponytail](https://github.com/pbakaus/ponytail) (MIT).
- Para ofício visual a sério, use o [Impeccable](https://github.com/pbakaus/impeccable).
  O `ui-plano` detecta se ele está instalado e cede a vez.

## Licença

MIT.
