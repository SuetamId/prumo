# prumo

[![check](https://github.com/SuetamId/prumo/actions/workflows/check.yml/badge.svg)](https://github.com/SuetamId/prumo/actions/workflows/check.yml)
[![licença: MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-blue.svg)](LICENSE)

**Método de trabalho para agentes de código — Claude Code e Cursor.**

O prumo é o fio com peso que diz se a parede está no esquadro: ele não levanta a parede,
impede que ela suba torta. Este harness não escreve o seu código. Ele faz o agente
**entender antes, planejar quando precisa, provar antes de dizer "pronto"** — e lembrar do
que o time já aprendeu.

Só Markdown, um instalador e alguns scripts de shell. Sem runtime, sem binário, sem
dependência no seu projeto.

---

## Por que existe

Agentes de código são rápidos e confiantes. Os defeitos vêm daí:

| O agente costuma… | O prumo faz… |
|---|---|
| sair escrevendo código antes de entender o pedido | **triagem** classifica o pedido e escolhe a menor rota que resolve |
| mexer em vários arquivos sem plano | mudança não trivial **planeja antes**, em ondas que terminam verificáveis |
| dizer "pronto" sem rodar nada | **nada fecha sem a saída do teste colada** — e, se mexeu em tela, sem abrir a tela |
| aprovar o próprio código | um **revisor em outro contexto** revisa antes do PR |
| presumir comandos, branch e convenções | o projeto é **medido** na instalação; o que a medição erra é **declarado** |
| repetir o erro que o time já corrigiu | lições viram **memória**: do repositório e, opcionalmente, do time inteiro |
| complicar | **leveza**: a menor solução que funciona |

## Como funciona

Sete peças. Cada uma existe porque a anterior não cobre o caso — e o agente escolhe a
peça sozinho, pelo tipo do pedido.

```
pedido, bug ou chave de issue
        │
     triagem ──► trivial ─────────────────────────► executa ──► prova
        │
        ├──► bug ──────► causa raiz ──────────────► corrige ──► prova
        │
        └──► mudança ──► plano (+ ui-plano) ──► execucao ──► prova ──► PR revisado
                                                                  │
                                         aprender ◄── a sessão ensinou algo
                         leveza: em todo código, sempre
```

| Peça | Entra quando | Entrega |
|---|---|---|
| `triagem` | chega um pedido, chave ou bug | classe, rota e a superfície de UI |
| `plano` | a mudança não é trivial | plano executável, com contrato entre repositórios |
| `execucao` | existe plano aprovado | código, uma onda por vez, com prova por onda |
| `prova` | antes de dizer "pronto" | evidência — teste, tela real e revisão em outro contexto |
| `ui-plano` | a entrega muda o que se vê | superfícies, estados, componentes, referência visual |
| `aprender` | a sessão ensinou algo | episódio de memória durável |
| `leveza` | sempre | a menor solução que funciona, e a dívida marcada |

**Para quem é de produto**, a peça `demanda` vem antes de tudo isso: transforma uma ideia ou
pedido de cliente numa história pronta para engenharia — investiga o que já existe, pergunta só
o que muda o resultado e registra no rastreador depois de aprovada. Funciona no Claude Code e,
para quem não usa terminal, como skill do claude.ai ([abaixo](#para-o-time-de-produto)).

**Os cinco princípios**

1. Mudança não trivial não escreve código sem plano.
2. Nada fecha sem saída de verificação. Teste que não rodou não é teste que passou.
3. Não presume: o que não está no repositório não existe.
4. A menor solução que funciona é a certa.
5. Em interface, a prova é a tela.

---

## Instalação

### Pedindo ao agente (recomendado)

Cole no Claude Code, aberto em qualquer pasta, trocando os dados entre `< >`:

```text
Instale e configure o prumo na minha máquina. Você é responsável pelo resultado.

1. Clone https://github.com/SuetamId/prumo.git em ~/.prumo-kit (se já existir, atualize).
2. Leia ~/.prumo-kit/INSTALAR-COM-AGENTE.md e siga o roteiro à risca.
3. Dados:
   - org no GitHub: <sua-org>
   - produtos: <produto1>, <produto2>
   - Hub de memória: <endereço do Hub, ou "não tenho">
   - pasta base: pergunte-me onde eu quero os projetos
4. Não apague nada sem me perguntar e nunca me peça segredo no chat.
5. Termine com o relatório do passo 11.
```

O agente segue o roteiro de [`INSTALAR-COM-AGENTE.md`](INSTALAR-COM-AGENTE.md): organiza os
repositórios por produto, **migra clones que você já tem sem perder trabalho** (configuração
local, stashes, memórias — o antigo vai para a Lixeira, nunca é apagado), instala as
dependências, roda os testes e declara o comando que funciona quando o documentado não
funciona. Termina com um relatório do que fez e do que ficou pendente.

> **Produto** é o conjunto de repositórios que andam juntos — `loja-frontend`, `loja-api`,
> `loja-worker` são o produto `loja`. O workspace pega os repositórios pelo prefixo do nome
> ou pelo topic `<produto>` no GitHub.

### À mão

Requer `git` e `python3`; para montar um produto inteiro, também o [`gh`](https://cli.github.com)
com login (`gh auth login`).

```bash
git clone https://github.com/SuetamId/prumo.git ~/.prumo-kit
```

Depois, uma das duas:

```bash
bash ~/.prumo-kit/workspace.sh <org> <produto> --dir ~/Dev/<org>/<produto>
```

```bash
cd meu-projeto && bash ~/.prumo-kit/install.sh .
```

A primeira clona os repositórios do produto lado a lado e instala o prumo em cada um. A
segunda instala num projeto que você já tem. `install.sh --dry-run .` mostra o que seria
feito sem escrever nada.

Reinicie o Claude Code ou o Cursor para carregar as skills.

---

## Uso

Abra o agente na pasta do repositório e cole o pedido — a chave da issue, o bug ou a
descrição. Não precisa escolher skill.

| Você pede | O que acontece |
|---|---|
| ajuste pequeno | executa direto e mostra a prova |
| bug | reproduz, acha a causa raiz, corrige, prova |
| funcionalidade | plano primeiro; código só com o plano aprovado |
| "não sei o que está errado" | levanta hipóteses e derruba com dado antes de propor |
| problema em produção | investiga só lendo; nada muda em produção sem você aprovar |
| mudança em front e API | um plano para os dois, com ordem de merge |

---

## Para o time de produto

A skill `demanda` leva uma ideia até a história no rastreador (Jira, pelo conector da Atlassian):

1. Você descreve a ideia, cola o pedido do cliente ou um link.
2. Ela investiga o que já existe — issues parecidas e, no Claude Code, o código de todos os
   repositórios do produto.
3. Pergunta só o que muda o resultado, uma coisa por vez.
4. Escreve no formato que o projeto já usa: objetivo, exemplo prático, situação atual, regras,
   cenários, critérios de aceite, fora de escopo e pendências.
5. Mostra, e só cria depois do seu "sim" — como **Story**, filha do épico certo. As tasks
   técnicas por repositório ficam com o `plano` do time de engenharia.

**No claude.ai (sem terminal):** alguém do time gera o pacote uma vez —

```bash
bash ~/.prumo-kit/empacotar.sh demanda ~/Downloads
```

— e quem é de produto envia o `demanda.zip` em *Configurações → Capacidades → Skills* do
claude.ai e conecta o **Atlassian** em *Configurações → Conectores*. O pacote segue a
[especificação de Agent Skills](https://agentskills.io/specification).

**No Claude Code:** já vem com o prumo; peça "cria uma demanda para…".

## Ajustar ao projeto

A instalação **mede** o projeto e grava os fatos em `perfil.tsv` (local, fora do git):
comandos de build, teste e lint; a branch onde o time integra — medida pelos PRs
mergeados de verdade —; o estilo de commit; os repositórios irmãos.

Quando a medição erra, **declare**. A linha declarada sobrevive às reinstalações:

```text
teste	env PYTHONPATH=. .venv/bin/python -m pytest tests/	declarado: make test não ativa o venv
```

O prumo **nunca sobrescreve** o que o projeto já tem: num `AGENTS.md` ou `CLAUDE.md`
existente, ele acrescenta um bloco entre marcadores e não toca no resto. Sem documentação
nenhuma, deriva o contexto do próprio código em `.prumo/contexto.md`.

---

## Memória do time (opcional)

Cada repositório guarda as próprias lições em `docs/ai-harness/memoria/`. Para o que vale
para o **time inteiro** — e para não ficar preso na máquina de quem aprendeu —, o prumo
conversa com um **Hub de memória**: um servidor MCP onde o agente busca no início da
tarefa e propõe ao fim dela. Uma pessoa admite cada proposta antes de ela virar regra.

```bash
prumo-workspace --hub https://endereco-do-hub
```

O comando pede a chave sem exibi-la, confere com o servidor e configura o Claude Code e o
Cursor. A chave fica em `~/.config/prumo/hub-key`, legível só por você; no Claude Code ela
nem entra na configuração. Rodar de novo reaproveita a chave se ela ainda é válida.

O Hub precisa expor `memory_search`, `memory_propose` e `memory_read` por MCP (HTTP com
`Authorization: Bearer`) e `GET /api/me` para conferir a chave.

---

## Atualizar

```bash
prumo-atualizar
```

Puxa o kit e reinstala no projeto atual. `prumo-atualizar --conferir` só compara, sem
escrever. Num produto inteiro, rode o workspace de novo: ele dá pull nos repositórios e
reinstala em cada um.

---

## Problemas comuns

| Sintoma | O que fazer |
|---|---|
| o agente não vê as skills | reinicie o agente; no Claude Code elas ficam em `~/.claude/skills/` |
| repositório do produto ficou de fora | o nome não segue `<produto>-*`: adicione o topic `<produto>` no GitHub e rode de novo |
| `prumo-atualizar: command not found` | `~/.local/bin` fora do `PATH` — use `bash ~/.prumo-kit/atualizar.sh` ou acrescente-o ao shell |
| instalei e nada mudou | o kit estava velho; `prumo-atualizar` puxa antes de instalar |
| worktree sem `perfil.tsv` | esperado: o perfil é local; a triagem lê o do checkout principal |

---

<details>
<summary><b>O que a instalação cria</b></summary>

| Caminho | Vai para o git? | O que é |
|---|---|---|
| `~/.claude/skills/<peça>` | — | skills do Claude Code, globais (link para o kit) |
| `.agents/skills/` · `.cursor/rules/` | sim | as mesmas skills, para o Cursor |
| bloco em `AGENTS.md` ou `CLAUDE.md` | sim | índice curto, entre marcadores |
| `docs/ai-harness/memoria/` | sim | o que o harness aprendeu neste projeto |
| `perfil.tsv` | não | fatos do projeto, medidos ou declarados |
| `tasks/` | não | planos e tarefas em andamento |
| `.prumo/` | não | contexto derivado do código |

O que não vai para o git entra em `.git/info/exclude` — local, sem sujar a árvore de
ninguém.

</details>

<details>
<summary><b>Desinstalar</b></summary>

No projeto:

```bash
rm -rf .prumo tasks perfil.tsv .agents/skills/{triagem,plano,execucao,prova,ui-plano,aprender,leveza} .cursor/rules/{triagem,plano,execucao,prova,ui-plano,aprender,leveza}.mdc
```

```bash
python3 -c "import re,os; f=[x for x in ('AGENTS.md','CLAUDE.md') if os.path.isfile(x)][0]; t=open(f).read(); open(f,'w').write(re.sub(r'\n*<!-- prumo:start -->.*?<!-- prumo:end -->\n*','\n',t,flags=re.S)); print('bloco removido de',f)"
```

Na máquina:

```bash
rm -f ~/.claude/skills/{triagem,plano,execucao,prova,ui-plano,aprender,leveza}
```

`docs/ai-harness/memoria/` fica de propósito — é conhecimento do seu projeto.

</details>

---

## Contribuir

- Princípios, orçamento de contexto e regras de escrita: [`AGENTS.md`](AGENTS.md).
- Tudo o que é instalado está em [`manifest.tsv`](manifest.tsv) — adicionar artefato é
  adicionar linha.
- Uma fonte, dois clientes: escreva em `skills/<peça>/`; o instalador gera o formato do
  Cursor.
- Antes do PR:

  ```bash
  bash check.sh
  ```

  Confere sintaxe, manifesto, referências, credenciais, uma instalação real e o orçamento
  de contexto residente (teto de 6.000 caracteres). A neutralidade — nenhum nome de
  produto ou cliente nas skills — lê a lista de `PRUMO_NOMES_PROIBIDOS`.

## Créditos

- A escada de leveza e a convenção de dívida derivam do
  [ponytail](https://github.com/pbakaus/ponytail) (MIT).
- Para ofício visual a sério, o [Impeccable](https://github.com/pbakaus/impeccable): o
  `ui-plano` detecta se ele está instalado e cede a vez.

## Licença

[MIT](LICENSE).
