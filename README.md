# prumo

Harness de contexto e método para agentes de código. **Claude Code** e **Cursor**.

Prumo é o fio com peso que diz se a parede está no esquadro. Ele não levanta a parede —
ele impede que ela suba torta. É isso que este harness faz: não escreve o seu código,
mas não deixa nada fechar sem prova.

Só Markdown e um instalador. Sem runtime, sem binário, sem dependência.

## Instalar

**Passo 1** — clone o kit em `~/.prumo-kit`. Um clone serve todos os seus projetos, e
rodar de novo só atualiza:

```bash
git clone git@github.com:SuetamId/prumo.git ~/.prumo-kit 2>/dev/null || git -C ~/.prumo-kit pull
```

**Passo 2** — entre na pasta do projeto que você quer e rode:

```bash
bash ~/.prumo-kit/install.sh .
```

> O caminho `~/.prumo-kit` é usado em todos os comandos deste README. Se você preferir
> clonar em outro lugar, troque `~/.prumo-kit` pelo seu caminho em **todos** eles.

Pronto. Reinicie o agente (Claude Code ou Cursor) para ele carregar as skills, e cole o
seu pedido — a triagem escolhe a rota.

### Ver antes de escrever

Mede o projeto e mostra tudo que faria, sem tocar em um byte:

```bash
bash ~/.prumo-kit/install.sh --dry-run .
```

### Instalar em outro projeto sem sair daqui

```bash
bash ~/.prumo-kit/install.sh /caminho/do/outro/projeto
```

### Atualizar

Puxe e reinstale — é idempotente, substitui só o bloco gerenciado e não toca no que é seu:

De dentro do projeto:

```bash
prumo-atualizar
```

Ele puxa o kit e reinstala, nessa ordem. O atalho é criado pelo instalador em
`~/.local/bin/`; se esse diretório não estiver no seu `PATH`, a instalação avisa e diz o
que acrescentar ao shell.

Equivalente, sem o atalho:

```bash
git -C ~/.prumo-kit pull && bash ~/.prumo-kit/install.sh .
```

🔴 **O `pull` não é opcional.** Rodar só o `install.sh` reinstala a versão que você já
tinha — sem erro e sem aviso, e "atualizei" fica indistinguível de "nada mudou". Desde
`14ac46e` o instalador avisa quando o kit está atrás do remoto, mas um kit anterior a
esse commit não tem como avisar: a versão que avisa é justamente a que falta.

### Conferir se a atualização pegou

De dentro do projeto, sem escrever nada:

```bash
prumo-atualizar --conferir
```

```
✓ EM DIA — 16 artefato(s), iguais ao kit (5b6c50b)
```

Quando não está, ele nomeia o que falta. Sai `0` em dia, `1` desatualizado, `2` quando o
prumo não está instalado ali — então serve em CI também.

> Isto é um script, e não um comando de shell, de propósito: `<(...)` é sintaxe de
> bash/zsh e quebra no fish. Comando que só roda num shell não é comando, é pegadinha.

### O que ele cria no seu projeto

| Caminho | Vai pro git? | O que é |
|---|---|---|
| `~/.claude/skills/<peça>` | — | **global**: symlink para o kit; `git pull` no kit já atualiza |
| `.agents/skills/` | sim | cópia das skills, para o Cursor |
| `.cursor/rules/*.mdc` | sim | as mesmas skills, no formato do Cursor |
| bloco em `AGENTS.md` ou `CLAUDE.md` | sim | ponteiro, entre marcadores |
| `docs/ai-harness/memoria/` | sim | os episódios que o harness aprender |
| `perfil.tsv` · `produto.md` | **não** | fatos do projeto — medidos, ou declarados por você |
| `tasks/` | **não** | plano e tasks em andamento |
| `.prumo/` | **não** | contexto derivado do código |

O que não vai pro git entra em `.git/info/exclude` — local, sem diff, sem sujar a árvore
de ninguém.

> **Worktrees** (o Claude Code desktop cria um por sessão) só recebem o que está
> **commitado**. Por isso as skills do Claude Code são globais: chegam a qualquer
> worktree. O `perfil.tsv` fica no checkout principal, e a triagem sabe buscá-lo ali.

### Medição errada? Declare

O `perfil.tsv` é regenerado a cada install. Para corrigir um fato que a medição erra —
a branch base, por exemplo —, edite o valor e troque a origem por `declarado: <motivo>`:

```text
branch_base	development	declarado: time integra em development
```

Linha declarada sobrevive ao reinstall e cala a medição da mesma chave.

### Desinstalar

Remove as skills e tudo que é local:

```bash
rm -rf .prumo tasks perfil.tsv produto.md .agents/skills/{triagem,plano,execucao,prova,ui-plano,aprender,leveza} .cursor/rules/{triagem,plano,execucao,prova,ui-plano,aprender,leveza}.mdc
```

E tira o bloco do seu índice:

```bash
python3 -c "import re,sys,io; f=[x for x in ('AGENTS.md','CLAUDE.md') if __import__('os').path.isfile(x)][0]; t=open(f).read(); open(f,'w').write(re.sub(r'\n*<!-- prumo:start -->.*?<!-- prumo:end -->\n*','\n',t,flags=re.S)); print('bloco removido de',f)"
```

As skills globais servem a todos os seus projetos; para tirá-las da máquina:

```bash
rm -f ~/.claude/skills/{triagem,plano,execucao,prova,ui-plano,aprender,leveza}
```

**`docs/ai-harness/memoria/` fica de propósito:** são os episódios que o harness aprendeu
com o seu projeto. Apagar isso seria destruir conhecimento que você escreveu, não
desinstalar ferramenta. Apague à mão se realmente quiser zerar.

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
| Claude Code | `~/.claude/skills/<n>` → symlink para o kit | `SKILL.md` |
| Cursor | `.cursor/rules/<n>.mdc` | rule, `alwaysApply` só em `leveza` |

Canônico em `skills/` do kit. Duas cópias mantidas à mão divergem.

## Ferramentas

```bash
bash skills/triagem/scripts/mapear-codebase.sh <dir>   # deriva contexto do código
bash skills/ui-plano/scripts/detectar-slop.sh <dir>    # 11 regras de UI gerada por modelo
bash skills/aprender/scripts/gerar-indice.sh <dir>     # índice de memória, gerado do disco
```

## Créditos

- A escada de leveza e a convenção de dívida derivam do
  [ponytail](https://github.com/pbakaus/ponytail) (MIT).
- Para ofício visual a sério — 61 regras sobre o DOM renderizado, crítica e iteração ao
  vivo — use o [Impeccable](https://github.com/pbakaus/impeccable). O `ui-plano` detecta
  se ele está instalado e cede a vez. O detector daqui é o piso para quando ele não está.

## Licença

MIT.
