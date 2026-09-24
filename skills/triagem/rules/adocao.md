# Adoção — o projeto existente manda

Roda uma vez por projeto, e de novo quando o projeto muda de forma. Custo residente zero.

## O princípio

🔴 **Nada que já existe é sobrescrito.** Um projeto com `AGENTS.md`, `docs/` e `tasks/`
bons não é obstáculo a instalar em cima — é **a melhor fonte** que o harness vai ter.
A adoção lê o que está lá, mapeia contra a espinha, e escreve **só a lacuna**.

O harness de onde este veio errava exatamente aqui: instalava `AGENTS.md` só se ausente
e nunca mais olhava. Resultado medido numa estação real — o índice ficou **8 dias**
apontando para artefatos que não existiam mais, e um artefato novo ficou invisível para
o modelo porque nada o nomeava. Criar-se-ausente resolve a primeira instalação e cria a
segunda falha.

## 1. Leia

| Procure | Se achar, extraia |
|---|---|
| `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.cursor/rules/` | as leis que já valem, e o tom |
| `README.md`, `CONTRIBUTING.md` | build, teste, lint, como rodar |
| `package.json`, `Makefile`, `pyproject.toml`, `pom.xml`, `go.mod` | comandos reais |
| `docs/adr/`, `docs/`, `*.md` na raiz | decisões já tomadas |
| `tasks/`, `specs/`, `.github/ISSUE_TEMPLATE` | como o time escreve trabalho |
| `.github/workflows/`, `.gitlab-ci.yml` | o que a esteira já cobra |
| histórico: `git log --format=%s -60` | convenção de commit **medida**, não declarada |
| `git branch -r \| head -20` | convenção de branch medida |

## 2. Escreva `perfil.tsv` — e só ele

Uma linha por fato, na raiz do projeto. É o que torna os artefatos neutros: o
comportamento é do harness, o vocabulário é do projeto.

```
# chave	valor	origem
build	npm run build	package.json:scripts.build
teste	npm test	package.json:scripts.test
lint	npm run lint	package.json:scripts.lint
ui_dev	npm run dev	package.json:scripts.dev
branch_base	main	git symbolic-ref
commit_estilo	conventional	medido em 60 commits (54 casam)
specs_em	docs/specs/	existe no disco
design_system	@acme/ui	package.json:dependencies
```

**`origem` é obrigatória.** Fato sem origem é chute, e chute em `perfil.tsv` contamina
toda decisão que vier depois. Não achou? A linha não existe — e o consumidor responde
**SEM MEDIR**, que é a resposta honesta.

## 2b. `produto.md` — a verdade durável, separada dos fatos técnicos

🔴 `perfil.tsv` guarda fato **técnico** que muda com o repositório (comando de build,
branch). `produto.md` guarda verdade **durável** que quase nunca muda:

| Campo | Pergunta |
|---|---|
| Para quem | quem usa isto, em que contexto, com quanta pressa |
| Para quê | o trabalho que a pessoa contrata o produto para fazer |
| Onde roda | desktop? celular? sob sol? com luva? em rede ruim? |
| Restrições | regulatório, acessibilidade exigida, navegador mínimo, idioma |
| Voz | como o produto fala — e o que ele nunca diria |

Por que separado: sem isso, "audiência" e "direção visual" viram a mesma conversa, e aí
toda decisão de UI é opinião. Com isso, `ui-plano` consegue justificar forma por função —
alvo de 44px porque se usa em pé no celular, não porque uma regra mandou.

**Escreva só o que der para inferir do repositório, e marque o resto como lacuna.** Não
invente audiência. `produto.md` com chute é pior que `produto.md` ausente: ele parece
levantado. Pergunte à pessoa apenas as lacunas **materiais** — as que mudariam uma decisão
de UI — e no máximo cinco de uma vez.

Arquivo criado **só se ausente**. Depois disso ele é da pessoa; o instalador nunca reescreve.

## 3. Mapeie contra a espinha, e relate a lacuna

| Peça | Já tem? | Ação |
|---|---|---|
| índice (`AGENTS.md`) | sim | **acrescenta** a seção do harness; não reescreve |
| índice | não | cria a partir do scaffold, com o `perfil.tsv` embutido |
| registro durável (`docs/`) | sim | usa o que existe; não cria diretório paralelo |
| registro durável | não | cria `docs/` mínimo |
| workspace ativo (`tasks/`) | — | **sempre nosso**, sempre local. Ver abaixo |
| memória | nunca tem | cria `docs/ai-harness/memoria/` |

## Workspace ativo × registro durável — a distinção que faz tudo funcionar

São duas coisas, e confundi-las foi o erro que esta seção conserta.

| | Workspace ativo | Registro durável |
|---|---|---|
| Onde | `tasks/prd-<slug>/` | `docs/`, ou onde o projeto já guarda |
| O que | `prd.md` · `techspec.md` · `tasks.md` · `plan.md` · `ui.md` | ADR, decisão, spec consolidada |
| Vida | enquanto a mudança está em curso | para sempre |
| Git | 🔴 **nunca** — `.git/info/exclude` | sempre |
| Quem manda na convenção | **o harness** | **o projeto** |

**Por que o workspace ativo é nosso e não do projeto:** ele é efêmero e da pessoa que
está trabalhando. Plano e lista de tasks são andaime — sujam o histórico, geram conflito
entre quem trabalha em paralelo, e ninguém revisa. É o mesmo mecanismo que os harness do
Claude e do Cursor usam para não mandar plano para o repositório. Padronizá-lo é o que
permite a mesma skill funcionar em qualquer projeto sem herdar arquitetura imposta.

🔴 **E ele vai para `.git/info/exclude`, nunca para o `.gitignore`.** O `.gitignore` é
arquivo **rastreado**: escrever nele suja a árvore de todo mundo e vira diff que ninguém
pediu. `info/exclude` dá o mesmo ignore, é local, e não aparece em lugar nenhum.

**Por que o registro durável é do projeto:** ele já existe, já tem histórico, e o time já
sabe onde procurar. Um harness que renomeia `docs/specs/` para `docs/adr/` é um harness
que o time desinstala.

## 4. Prove

Releia do disco o que você escreveu e mostre. Diga o que **não** foi escrito e por quê.
Instalação que não prova o efeito é instalação que ninguém sabe se aconteceu.

## Reincidência

Rodar de novo é seguro e esperado: `perfil.tsv` é regenerado (os fatos mudam), e a seção
do harness no índice é substituída **só entre seus marcadores** — a prosa que a pessoa
escreveu em volta é preservada. Sem marcador, a reinstalação duplica e a desinstalação
vira arqueologia de diff.
