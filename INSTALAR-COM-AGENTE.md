# Instalar o prumo pedindo ao agente

Roteiro para um agente (Claude Code) montar a máquina de uma pessoa: kit, repositórios por
produto, prumo instalado, dependências, testes rodando e conexão com o Hub de memória.

A pessoa cola um prompt curto (modelo no fim deste arquivo) com a **org** no GitHub, os
**produtos** e o endereço do **Hub**. Todo o resto está aqui.

O prompt roda a partir de **qualquer pasta**: todo caminho aqui é absoluto. Fora da pasta em
que a sessão abriu, o Claude Code pede permissão para ler e escrever — é esperado; explique
isso à pessoa antes do primeiro pedido.

**Pasta base** (onde os produtos vão morar): se o prompt não trouxer, **pergunte**, sugerindo
`~/Dev/<org em minúsculas>`. Nunca escolha sozinho: cada pessoa organiza a máquina de um jeito.

---

## Contrato — leia antes do primeiro comando

- 🔴 **Nada é apagado.** Pasta antiga vai para a **Lixeira** (recuperável), e só depois de a
  pessoa confirmar. Nunca `rm -rf` em repositório.
- 🔴 **Segredo não passa pela conversa.** Não leia `.env`, chave nem senha para o chat; copie
  arquivo para arquivo. A chave do Hub a pessoa cola **no terminal**, nunca no chat.
- **Sem `sudo`.** Precisou instalar algo no sistema? Diga o comando e deixe a pessoa rodar.
- **O que travar vira pendência com nome** no relatório final — nunca um "pronto" com asterisco.
- **Nada fecha sem prova:** teste rodado, saída colada. NÃO MEDIU nunca é PASSOU.
- O shell da pessoa pode ser **fish**: `VAR=x cmd` e `read -s` não existem lá. Use
  `env VAR=x cmd` e, para ler segredo, `bash -c '…'`.

---

## 1. Pré-requisitos

```bash
git --version && gh --version && python3.12 --version && node --version
```

```bash
gh auth status
```

- `gh` sem login → a pessoa roda `gh auth login` (é interativo; não faça por ela).
- Falta Python 3.12 ou Node → diga o comando de instalação (ex.: `brew install python@3.12`)
  e espere. Não siga sem eles: o venv e o `npm ci` vão falhar mais adiante, longe da causa.

## 2. Kit

```bash
git clone https://github.com/SuetamId/prumo.git ~/.prumo-kit 2>/dev/null || git -C ~/.prumo-kit pull --ff-only
```

Clone recusado (404 / permission denied) = a pessoa não tem acesso ao repositório do kit.
**Pare** e diga quem precisa liberar. Não tente outro caminho.

## 3. Levantamento — antes de criar ou mover qualquer coisa

Procure clones que já existam dos repositórios da org **em qualquer lugar da home**, pelo
remote — não pelo nome da pasta, que cada pessoa escolhe:

```bash
find ~ -maxdepth 5 \( -path ~/Library -o -name node_modules -o -name .venv -o -path '*/.Trash' \) -prune -o -name .git -print 2>/dev/null \
  | while read g; do r="${g%/.git}"; u=$(git -C "$r" remote get-url origin 2>/dev/null); case "$u" in *[:/]<ORG>/*) echo "$r  $u" ;; esac; done
```

Achou clone de um produto fora da pasta base? Ele entra no levantamento e na migração do
passo 5 do mesmo jeito — o trabalho em andamento dele é o que mais importa preservar.

Para cada clone encontrado, meça e mostre numa tabela:

| O que medir | Comando |
|---|---|
| alterações não commitadas | `git -C <repo> status --porcelain` |
| commits que só existem na máquina | `git -C <repo> log --oneline HEAD --not --remotes` |
| stashes | `git -C <repo> stash list` |
| worktrees | `git -C <repo> worktree list` (repita os dois primeiros em cada um) |

Tem trabalho em andamento? **Pergunte** se ele já está nos ambientes (development, staging):
procure o PR (`gh pr list -R <org>/<repo> --state all --search <chave>`) e se o merge dele está
na branch (`git merge-base --is-ancestor <merge> origin/<branch>`). Comparar arquivo inteiro
engana: a branch local antiga diverge por milhares de linhas mesmo com o trabalho já entregue.

## 4. Estrutura por produto

Um diretório por produto, com os repositórios dele lado a lado — é o que deixa o prumo
medir os repositórios irmãos sozinho:

```bash
prumo-workspace <ORG> <produto> --dir <PASTA_BASE>/<produto> --sim
```

(sem o atalho ainda: `bash ~/.prumo-kit/workspace.sh …` — ele é criado no primeiro install)

🔴 **Colisão de nome:** se já existe um clone antigo chamado exatamente `<produto>` (ex.: a
pasta `loja` era o clone do frontend da loja), a pasta do produto não pode ser criada. Faça a migração do
passo 5 **antes**, para o antigo sair do caminho.

## 5. Migrar um clone antigo — só com confirmação

Antes de mandar o antigo para a Lixeira, salve o que **não está no git** e não é cache:

```bash
git -C <antigo> status --porcelain --ignored
```

| O quê | Para onde |
|---|---|
| **configuração local** — tudo que o `--ignored` listar e se encaixe: `.env*` (menos `.env.example`), `*.local.*`, `.npmrc`, `docker-compose.override.yml`, `.flaskenv`, `config/local*`, `.claude/settings.local.json`, `.vscode/settings.json` | mesma posição no clone novo — `cp -n` (**nunca sobrescreve** o que já estiver lá), sem ler o conteúdo |
| alteração local em arquivo **versionado** de configuração (ex.: URL da API em `environment.ts`) | mostre só as linhas trocadas e reaplique no clone novo |
| `tasks/` e `docs/ai-harness/memoria/` — **de todos os worktrees** (memória costuma nascer dentro de um) | clone novo; memórias unidas, a mais recente vence |
| stashes | `git stash show -p --include-untracked stash@{N}` → `tasks/stashes-antigos/N-<nome>.patch` |
| commits só locais e trabalho descartado | `git format-patch` / `git diff HEAD` → `tasks/descartado-*/` |
| memória do Claude Code daquele caminho | `~/.claude/projects/<caminho com / e . trocados por ->/memory/` → mesmo esquema no caminho novo |

Confira que nada saiu vazio (`find … -size 0`) e que **nenhuma variável ficou para trás** —
comparando só os **nomes**, nunca os valores:

```bash
diff <(grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' <antigo>/.env | sort) <(grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' <novo>/.env | sort)
```

(`<(…)` é bash/zsh; no fish, rode dentro de `bash -c '…'`.) Saída vazia = mesmas variáveis.
Só então:

```bash
osascript -e 'tell application "Finder" to delete POSIX file "<antigo>"'
```

Arquivo de workspace do editor (`*.code-workspace`) que apontava para o antigo: atualize os
caminhos.

### Sem clone antigo — `.env` do zero

Repositório que nunca esteve na máquina não tem `.env`. **Não invente valor.**

1. Procure outro clone do mesmo repositório (o levantamento do passo 3 acha por remote) e
   worktrees dele — o `.env` pode estar lá.
2. Não achou e existe `.env.example`: copie para `.env` e liste à pessoa **os nomes** das
   variáveis que ficaram com valor de exemplo — ela preenche (vem de quem já roda o projeto,
   ou do painel do ambiente de dev).
3. Nem exemplo existe: leia onde o código lê variáveis (`os.environ`, `process.env`,
   `pydantic` `Settings`) e liste os nomes. Pendência com nome no relatório.

Teste que falha por variável ausente **não é** teste quebrado — é pendência de configuração.
Diga isso, não "corrija" o teste.

## 6. Dependências

| Encontrou | Rode |
|---|---|
| `package-lock.json` | `npm ci --no-audit --no-fund` |
| `requirements.txt` | `python3.12 -m venv .venv && .venv/bin/pip install -r requirements.txt` (e `-r requirements-test.txt`, se existir) |

## 7. Testes — e o comando que de fato funciona

Rode o `teste` do `perfil.tsv` de cada repositório. Falhou? Descubra a causa antes de
declarar qualquer coisa. Os casos já vistos:

| Sintoma | Causa | Comando que funciona |
|---|---|---|
| `make test` → erro 127 | o Makefile chama `pytest` sem o `.venv` | `env PYTHONPATH=. .venv/bin/python -m pytest tests/` |
| `cannot load library 'libgobject'` | WeasyPrint precisa das libs do Homebrew (macOS) | prefixe `env DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib` (falta a lib? `brew install pango` — a pessoa roda) |
| teste Angular não termina | `ng test` fica em watch | `npx ng test --watch=false` |

Grave o comando que passou como linha declarada, que sobrevive ao reinstall:

```text
teste	<comando que passou>	declarado: <por que o medido não serve>
```

## 8. Branch base

Confira `branch_base` no `perfil.tsv` de cada repositório. Origem `medido: N dos últimos PRs
mergeados…` é confiável. Qualquer outra origem (`origin/HEAD`, git-flow): **pergunte** para
onde o time integra e declare.

## 9. Hub de memória

Sem Hub ("não tenho")? Pule este passo — a memória fica em cada repositório.

1. A pessoa entra no Hub com o e-mail dela. E-mail do domínio da empresa entra direto; outro
   domínio clica em **Pedir acesso**. Um admin a coloca nos times (página **Pessoas**).
2. Ela gera uma chave em **Chaves de API**.
3. Peça para ela rodar **num terminal dela** (a chave é pedida sem eco — nunca no chat):

   ```bash
   prumo-workspace --hub <URL-DO-HUB>
   ```

   Já existe chave válida na máquina (`~/.config/prumo/hub-key`)? O comando reaproveita e
   não pede de novo — só reconfigura os clientes.

4. Confira:

   ```bash
   claude mcp list
   ```

   `prumo-hub … ✔ Connected` = pronto.

## 10. Jira

Antes de adicionar qualquer coisa, veja se já existe:

```bash
claude mcp list | grep -i atlassian
```

Já tem (inclusive o conector **claude.ai Atlassian**)? Não adicione outro — ferramenta
duplicada confunde o agente. Não tem e a pessoa quer: `prumo-workspace … --jira`.

## 11. Relatório final

- Tabela: repositório · branch · testes (números colados)
- O que foi migrado e onde está (stashes, descartado, memórias)
- Quanto foi para a Lixeira — o espaço só volta quando a pessoa esvaziar
- Pendências com nome (o que travou e quem resolve)
- Lembrete: reiniciar o Claude Code e o Cursor e abrir sessões novas nas pastas novas

---

## Modelo de prompt

Troque os dados entre `< >` e cole no Claude Code, aberto em qualquer pasta:

```text
Instale e configure o prumo na minha máquina. Você é responsável pelo resultado.

1. Clone https://github.com/SuetamId/prumo.git em ~/.prumo-kit (se já existir, atualize).
2. Leia ~/.prumo-kit/INSTALAR-COM-AGENTE.md e siga o roteiro à risca.
3. Dados:
   - org no GitHub: <ORG>
   - produtos: <produto1>, <produto2>
   - Hub de memória: <URL-DO-HUB, ou "não tenho">
   - pasta base: pergunte-me onde eu quero os projetos
4. Não apague nada sem me perguntar e nunca me peça segredo no chat.
5. Termine com o relatório do passo 11.
```
