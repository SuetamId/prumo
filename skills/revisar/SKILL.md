---
name: revisar
description: Use para revisar código antes do PR, um PR aberto ou todos os PRs de uma chave do rastreador — quem escreveu não aprova; a revisão roda num agente novo, de contexto limpo.
when_to_use: >-
  "revisa", "faz code review", "revisa o PR <url|número>", "revisa a <CHAVE>",
  chamado por `prova` antes de abrir PR em toda classe que não seja trivial.
---

# Revisar

**Você orquestra; não revisa.** O contexto que escreveu o código carrega as premissas que
produziram o defeito: relê o diff e enxerga a intenção, não o que está escrito. Por isso a
revisão roda num **agente novo**, sem a conversa, e você só lê o veredito.

🔴 Não abra o diff "para adiantar". O que você ler entra no contexto que depois vai corrigir —
é o viés que o agente novo existe para tirar.

| Modo | Alvo | Corrige? |
|---|---|---|
| `local` (padrão) | a branch atual contra a base + o que não foi commitado | sim, você |
| `pr <url\|número>` | um PR aberto, deste ou de outro repositório | não — só reporta |
| `chave <CHAVE>` | todo PR da chave, em todos os repositórios do produto | não — só reporta |

## 1. Preparar

```bash
RUN="$(git rev-parse --show-toplevel)/.prumo/revisao/$(date -u +%Y%m%dT%H%M%SZ)"; mkdir -p "$RUN"
EX="$(git rev-parse --path-format=absolute --git-common-dir)/info/exclude"
grep -qxF '.prumo/' "$EX" 2>/dev/null || echo '.prumo/' >> "$EX"
```

`.prumo/` fica fora do git (em `info/exclude`, local, nunca no `.gitignore`). Tudo da revisão mora em `$RUN` — nada fica só na conversa.

Grave `$RUN/prometido.md` com **o que a mudança promete**, nada mais: o pedido em uma frase,
os requisitos do plano (`tasks/prd-<slug>/plan.md`) ou o título e a descrição do PR, as
mensagens de commit e o resumo do ticket quando houver chave. 🔴 Nunca o seu raciocínio de
implementação nem o seu palpite sobre onde está o problema — é a tese que o revisor existe
para derrubar.

Modo `local` sem diff e sem árvore suja: "nada para revisar", e pare.

No modo `local`, **congele o estado antes de cada despacho** — a árvore suja não tem sha, e
sem ele a rodada seguinte não acha o delta. Um índice temporário fotografa tudo, inclusive
arquivo não rastreado, sem tocar no seu índice nem na branch:

```bash
foto(){ GIT_INDEX_FILE="$RUN/.idx" git read-tree HEAD && GIT_INDEX_FILE="$RUN/.idx" git add -A -- ':/' \
  && GIT_INDEX_FILE="$RUN/.idx" git write-tree; }
foto > "$RUN/estado-<N>"
```

## 2. Gates do projeto — antes do revisor

Fato medido vale mais que leitura. Rode os comandos que o `perfil.tsv` já tem — `lint`,
`teste`, `build`, nesta ordem, os que existirem — e grave a saída:

```bash
TOP=$(git rev-parse --show-toplevel); PERFIL="$TOP/perfil.tsv"   # worktree: o perfil é do checkout principal
[ -f "$PERFIL" ] || PERFIL="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")/perfil.tsv"
for k in lint teste build; do
  cmd=$(awk -F'\t' -v k="$k" '$1==k{print $2; exit}' "$PERFIL" 2>/dev/null)
  [ -z "$cmd" ] && { echo "== $k: NÃO MEDIU (sem linha no perfil.tsv)"; continue; }
  echo "== $k: $cmd"; (cd "$TOP" && sh -c "$cmd") > "$RUN/gate-$k.log" 2>&1; echo "exit=$?"
done > "$RUN/gates.txt"
```

No modo `pr`, os gates são o CI do PR: `gh pr checks <pr> > "$RUN/gates.txt"`. No `chave`,
um por PR. Gate que falhou não impede a revisão — vira achado.

## 3. Despachar o revisor

| Cliente | Como |
|---|---|
| Claude Code | ferramenta de agente com `subagent_type: prumo-revisor` |
| Claude Code sem o agente instalado | agente de uso geral, mandando ler `~/.claude/skills/revisar/rules/revisor.md` primeiro |
| Cursor ou outro | chat novo, colando `rules/revisor.md` + o despacho abaixo |
| nenhum dos três | **NÃO MEDIU** — não revise você mesmo e chame de revisado |

O despacho leva **só** o que o revisor não descobre sozinho:

```text
modo=<local|pr>  rodada=<N>  saida=$RUN/rodada-<N>.md
repo=<caminho absoluto>  base=<origin/branch_base do perfil.tsv>  [pr=<url>]
[estado=<conteúdo de $RUN/estado-<N>>]   # só local
prometido=$RUN/prometido.md  gates=$RUN/gates.txt
[anterior=$RUN/rodada-<N-1>.md  delta_base=<conteúdo de $RUN/estado-<N-1>>]
```

Nunca cole o diff, a conversa ou a sua opinião.

## 4. Ler o veredito e corrigir (só `local`)

O revisor devolve no máximo 15 linhas: veredito, contagem e os bloqueantes por id. O
relatório inteiro está em `saida` — leia **o item** que vai corrigir, não o arquivo todo.

- **Crítico** e **importante**: corrija todos da rodada antes de despachar a próxima, cada um
  como o item pede, rodando o comando de verificação dele.
- Discorda de um achado? Não apague: escreva a contestação com evidência em
  `$RUN/contestacoes.md`. O próximo revisor decide.
- **Menor**: decisão sua, fora do laço.

## 5. Revisor novo a cada rodada

Corrigiu → gates de novo, nova `foto` e **outro** agente, com `anterior` e `delta_base`. Ele confere cada achado aberto
contra o código atual e revisa só o delta da correção — é onde correção introduz defeito. O
revisor antigo já viu a versão errada e tende a confirmar a própria leitura.

🔴 **Teto de três rodadas.** Na terceira, só crítico bloqueia; importante vira pendência
nomeada no PR. Crítico aberto na terceira: pare e leve à pessoa — o problema é de desenho, não
de revisão.

## Modo `chave`

1. Ache os PRs: `gh pr list --search "<CHAVE>" --state open` em cada repositório de
   `repos_irmaos` do `perfil.tsv` (sem a linha, só no repositório atual — e diga).
2. **Um revisor por PR, em paralelo** (até 4 de uma vez), cada um no modo `pr` com a sua
   `saida` em `$RUN/<repo>/rodada-1.md`.
3. Com todos de volta, **mais um revisor** no modo `consolidar` confere o que atravessa
   repositórios:

   ```text
   modo=consolidar  saida=$RUN/consolidado.md  prometido=$RUN/prometido.md
   relatorios=<cada $RUN/<repo>/rodada-1.md>  prs=<cada url>
   ```

## Fechar

Na conversa, curto: modo, rodadas, veredito final, bloqueantes abertos, pendências e o caminho
de `$RUN`. Modo `pr`/`chave` não comenta no PR, não aprova e não faz merge sem pedido
explícito — publicar é ação da pessoa.
