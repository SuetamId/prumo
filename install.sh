#!/usr/bin/env bash
# install.sh — instala o prumo num projeto, ADOTANDO o que já existe.
#
# Princípio: nada que já existe é sobrescrito. O projeto é lido primeiro; o que
# ele já resolve vira dado em perfil.tsv, e só a lacuna é escrita.
set -uo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
SECO=0
args=(); for a in "$@"; do case "$a" in --dry-run|--seco) SECO=1 ;; *) args+=("$a") ;; esac; done
set -- "${args[@]:-}"
ALVO="${1:-.}"
[ -d "$ALVO" ] || { echo "erro: '$ALVO' não é um diretório" >&2; exit 2; }
ALVO="$(cd "$ALVO" && pwd)"
[ "$ALVO" = "$KIT" ] && { echo "erro: origem == destino" >&2; exit 2; }

INI='<!-- prumo:start -->'
FIM='<!-- prumo:end -->'
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
inf(){ printf '  \033[34m·\033[0m %s\n' "$1"; }
avi(){ printf '  \033[33m!\033[0m %s\n' "$1"; }

# ── 1 · ADOÇÃO — ler antes de escrever ───────────────────────────────────────
echo; echo "── 1 · Adoção: lendo o projeto ──"

json_script(){ # $1 = chave em package.json scripts
  [ -f "$ALVO/package.json" ] || return 1
  python3 - "$ALVO/package.json" "$1" <<'PY' 2>/dev/null
import json,sys
try: s=json.load(open(sys.argv[1])).get("scripts") or {}
except Exception: sys.exit(1)
v=s.get(sys.argv[2])
print(v) if v else sys.exit(1)
PY
}

[ "$SECO" = 1 ] && PERFIL="$(mktemp)" || PERFIL="$ALVO/perfil.tsv"
{ echo "# Fatos MEDIDOS deste projeto. Escrito pela adoção — regenerado a cada install."
  echo "# Linha sem origem não existe: fato sem procedência é chute."
  echo "#"
  echo "# chave	valor	origem"
} > "$PERFIL.novo"

reg(){ printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$PERFIL.novo"; }
n_fatos=0
medir(){ # chave · valor · origem  — só registra se o valor existir
  [ -n "${2:-}" ] && { reg "$1" "$2" "$3"; n_fatos=$((n_fatos+1)); }
}

# comandos, pela ordem de evidência mais forte
if [ -f "$ALVO/package.json" ]; then
  medir build "$(json_script build)"  "package.json:scripts.build"
  medir teste "$(json_script test)"   "package.json:scripts.test"
  medir lint  "$(json_script lint)"   "package.json:scripts.lint"
  for d in dev start serve; do
    v="$(json_script "$d")" && { medir ui_dev "$v" "package.json:scripts.$d"; break; }
  done
fi
[ -f "$ALVO/Makefile" ] && {
  grep -qE '^build:' "$ALVO/Makefile" && medir build "make build" "Makefile"
  grep -qE '^test:'  "$ALVO/Makefile" && medir teste "make test"  "Makefile"
}
# ── MONOREPO ────────────────────────────────────────────────────────────────
# MEDIDO num monorepo real (backend NestJS + web Next + mobile Expo + qa): a raiz
# não tem package.json, então medir só a raiz devolveu ZERO comando. Harness que
# não sabe rodar o teste do projeto é harness inútil ali. Cada workspace declara
# os seus, com a chave prefixada — não existe "o" comando de build num monorepo.
ws=""
for d in "$ALVO"/*/; do
  b="$(basename "$d")"
  case "$b" in node_modules|dist|build|.*|docs|scripts|deploy|public|assets) continue ;; esac
  [ -f "$d/package.json" ] || [ -f "$d/Makefile" ] || [ -f "$d/pyproject.toml" ] || continue
  ws="$ws $b"
  if [ -f "$d/package.json" ]; then
    for par in build:build teste:test lint:lint; do
      k="${par%%:*}"; s="${par##*:}"
      v=$(python3 - "$d/package.json" "$s" <<'PY2' 2>/dev/null
import json,sys
try: sc=json.load(open(sys.argv[1])).get("scripts") or {}
except Exception: sys.exit(1)
v=sc.get(sys.argv[2]); print(v) if v else sys.exit(1)
PY2
) && medir "$k.$b" "$v" "$b/package.json:scripts.$s"
    done
    for s in dev start serve; do
      v=$(python3 - "$d/package.json" "$s" <<'PY3' 2>/dev/null
import json,sys
try: sc=json.load(open(sys.argv[1])).get("scripts") or {}
except Exception: sys.exit(1)
v=sc.get(sys.argv[2]); print(v) if v else sys.exit(1)
PY3
) && { medir "ui_dev.$b" "$v" "$b/package.json:scripts.$s"; break; }
    done
  fi
  [ -f "$d/Makefile" ] && grep -qE '^test:' "$d/Makefile" && medir "teste.$b" "make -C $b test" "$b/Makefile"
done
[ -n "$ws" ] && medir workspaces "${ws# }" "subdiretórios com manifesto próprio"

[ -f "$ALVO/pyproject.toml" ] && medir teste "pytest" "pyproject.toml existe"
[ -f "$ALVO/go.mod" ]         && medir teste "go test ./..." "go.mod existe"
[ -f "$ALVO/pom.xml" ]        && medir teste "mvn test" "pom.xml existe"

# git: convenção MEDIDA, nunca declarada
if git -C "$ALVO" rev-parse --git-dir >/dev/null 2>&1; then
  base="$(git -C "$ALVO" symbolic-ref --short HEAD 2>/dev/null)"
  medir branch_base "$base" "git symbolic-ref"
  n=$(git -C "$ALVO" log --format=%s -60 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -ge 10 ]; then
    c=$(git -C "$ALVO" log --format=%s -60 2>/dev/null \
        | grep -cE '^(feat|fix|chore|docs|refactor|test|style|perf|build|ci)(\(.+\))?!?: ' || true)
    [ "$((c*2))" -gt "$n" ] \
      && medir commit_estilo conventional "medido: $c de $n commits casam" \
      || medir commit_estilo livre        "medido: só $c de $n casam conventional"
  fi
fi

# WORKSPACE ATIVO: nosso padrão, sempre, em todo projeto. Não é negociável com a
# convenção do projeto porque não compete com ela — ele é EFÊMERO e LOCAL, e o
# registro durável (abaixo) continua sendo do projeto.
medir workspace_ativo "tasks/prd-<slug>/" "padrão do harness; local, fora do git"

# REGISTRO DURÁVEL: aqui sim a convenção do projeto vence.
for d in docs/specs specs doc/specs .specs; do
  [ -d "$ALVO/$d" ] && { medir registro_duravel "$d/" "existe no disco"; break; }
done
for d in docs doc documentation; do
  [ -d "$ALVO/$d" ] && { medir docs_em "$d/" "existe no disco"; break; }
done
# convenção de raiz que não é diretório — medida num monorepo real
for f in rules.md RULES.md CONVENTIONS.md; do
  [ -f "$ALVO/$f" ] && { medir regras_em "$f" "existe na raiz"; break; }
done
# A ESTRUTURA que o time usa por feature vence o nosso template. Lida do disco:
# a pasta de spec mais recente diz quais arquivos o time de fato escreve.
sdir=$(grep -m1 '^registro_duravel' "$PERFIL.novo" 2>/dev/null | cut -f2)
if [ -n "${sdir:-}" ] && [ -d "$ALVO/$sdir" ]; then
  amostra=$(find "$ALVO/$sdir" -mindepth 1 -maxdepth 1 -type d ! -name '_*' 2>/dev/null | head -1)
  [ -n "$amostra" ] && {
    arqs=$(find "$amostra" -maxdepth 1 -name '*.md' -exec basename {} \; 2>/dev/null | sort | tr '\n' ' ' | sed 's/ $//')
    medir registro_estrutura "$arqs" "medido em $(basename "$amostra")"
  }
  # conta PASTA e ARQUIVO: medido num monorepo real: specs/ tinha 3 .md soltos e 0 pastas,
  # e reportar "0 specs" num projeto com 3 documentos é mentir com número certo.
  n_d=$(find "$ALVO/$sdir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  n_f=$(find "$ALVO/$sdir" -mindepth 1 -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  medir registro_existente "${n_d} pasta(s) · ${n_f} arquivo(s)" "contado no disco"
fi
# harness que JÁ existe — para não duplicar nem sobrescrever
nr=$(ls "$ALVO"/.cursor/rules/*.mdc 2>/dev/null | wc -l | tr -d ' ')
[ "${nr:-0}" -gt 0 ] && medir cursor_rules_existentes "$nr" "ls .cursor/rules/*.mdc"
ns=$(ls -d "$ALVO"/.agents/skills/*/ 2>/dev/null | wc -l | tr -d ' ')
[ "${ns:-0}" -gt 0 ] && medir agent_skills_existentes "$ns" "ls .agents/skills/*/"
# design system, se houver
if [ -f "$ALVO/package.json" ]; then
  ds=$(grep -oE '"@[a-z0-9.-]+/(ui|design-system|tokens|components)"' "$ALVO/package.json" | head -1 | tr -d '"')
  medir design_system "$ds" "package.json:dependencies"
fi

mv "$PERFIL.novo" "$PERFIL"
ok "perfil.tsv: $n_fatos fato(s) medido(s)"
[ "$n_fatos" = 0 ] && avi "nenhum fato medido — os artefatos vão responder SEM MEDIR, que é honesto"

if   [ -f "$ALVO/AGENTS.md" ]; then IDX_SECO="AGENTS.md (existe)"
elif [ -f "$ALVO/CLAUDE.md" ]; then IDX_SECO="CLAUDE.md (existe — índice canônico deste projeto)"
else IDX_SECO="AGENTS.md (seria CRIADO)"; fi

# o que o projeto JÁ tem, e que por isso não será criado
for f in AGENTS.md CLAUDE.md README.md .cursorrules; do
  [ -f "$ALVO/$f" ] && inf "já existe, será preservado: $f"
done

if [ "$SECO" = 1 ]; then
  echo; echo "── Fatos que seriam gravados ──"
  grep -v '^#' "$PERFIL" | while IFS=$'\t' read -r k v o; do printf '  %-26s %-44s %s\n' "$k" "$v" "$o"; done
  echo; echo "── O que seria escrito ──"
  for f in "$IDX_SECO" .agents/skills/ .claude/skills/ .cursor/rules/ .prumo/templates/ docs/ai-harness/memoria/ scripts/ perfil.tsv; do
    [ -n "$f" ] && printf '  %s\n' "$f"
  done
  echo; echo "Dry-run: nada foi escrito."
  rm -f "$PERFIL"; exit 0
fi

# ── 2 · ARTEFATOS — uma fonte, dois clientes ─────────────────────────────────
echo; echo "── 2 · Artefatos ──"
mkdir -p "$ALVO/.agents/skills" "$ALVO/.claude/skills" "$ALVO/.cursor/rules"

n_sk=0
while IFS=$'\t' read -r kind nome alvo sempre _; do
  case "$kind" in ''|'#'*) continue ;; skill) ;; *) continue ;; esac
  rm -rf "$ALVO/.agents/skills/$nome"
  cp -R "$KIT/skills/$nome" "$ALVO/.agents/skills/$nome"

  # Claude Code: symlink, para o conteúdo existir uma vez só no disco
  ln -sfn "../../.agents/skills/$nome" "$ALVO/.claude/skills/$nome"

  # Cursor: .mdc renderizado do mesmo SKILL.md
  src="$KIT/skills/$nome/SKILL.md"
  desc=$(awk '/^description:/{sub(/^description: */,""); print; exit}' "$src")
  [ "$sempre" = "sim" ] && aa=true || aa=false
  { echo "---"
    echo "description: ${desc:-$nome}"
    echo "alwaysApply: $aa"
    echo "---"
    echo
    echo "> Fonte canônica: \`.agents/skills/$nome/SKILL.md\`. As references citadas"
    echo "> como \`rules/*.md\` vivem em \`.agents/skills/$nome/rules/\`."
    echo
    awk 'BEGIN{k=0} /^---$/{k++; next} k>=2' "$src"
  } > "$ALVO/.cursor/rules/$nome.mdc"
  n_sk=$((n_sk+1))
done < "$KIT/manifest.tsv"
ok "$n_sk skills → .agents/skills/ · .claude/skills/ (symlink) · .cursor/rules/ (.mdc)"

mkdir -p "$ALVO/.prumo/templates"
cp "$KIT"/templates/*.md "$ALVO/.prumo/templates/" 2>/dev/null
ok "templates → .prumo/templates/"

mkdir -p "$ALVO/tasks" "$ALVO/docs/ai-harness/memoria"
mkdir -p "$ALVO/scripts"
for s in gerar-indice.sh detectar-slop.sh mapear-codebase.sh selecionar-instintos.sh; do
  [ -f "$KIT/scripts/$s" ] && { cp "$KIT/scripts/$s" "$ALVO/scripts/$s"; chmod +x "$ALVO/scripts/$s"; }
done
ok "memória → docs/ai-harness/memoria/ · scripts → scripts/"

# Contexto derivado do CÓDIGO — é o que salva o harness em projeto sem documentação.
# Vai para .prumo/ (local, fora do git) porque derivado é regenerável: não há o
# que preservar, e assim não impomos estrutura no repositório de ninguém.
if bash "$KIT/scripts/mapear-codebase.sh" "$ALVO" >/dev/null 2>&1; then
  lac=$(sed -n '/## Lacunas/,$p' "$ALVO/.prumo/contexto.md" 2>/dev/null | grep -c '^- ' || true)
  ok "contexto derivado → .prumo/contexto.md ($lac lacuna(s) nomeada(s))"
  [ "${lac:-0}" -gt 0 ] && sed -n '/## Lacunas/,$p' "$ALVO/.prumo/contexto.md" | grep '^- ' | sed 's/^- /      · /'
else
  avi "não consegui derivar contexto do código"
fi

# O Impeccable cobre o ofício visual melhor que nós. Se estiver lá, ele manda.
if ls "$ALVO"/.claude/skills/impeccable "$ALVO"/.cursor/skills/impeccable >/dev/null 2>&1; then
  ok "Impeccable detectado — ui-plano vai preferir /impeccable audit ao nosso detector"
else
  inf "Impeccable não instalado — vale o nosso piso de 11 regras (npx impeccable install dá 61 sobre o DOM)"
fi

# ── 3 · ÍNDICE — bloco gerenciado, nunca o arquivo inteiro ───────────────────
echo; echo "── 3 · Índice ──"
BLOCO=$(mktemp)
{ echo "$INI"
  echo "## Harness"
  echo
  echo "| Peça | Dispare quando |"
  echo "|---|---|"
  while IFS=$'\t' read -r kind nome _ _ nota; do
    case "$kind" in skill) printf '| `%s` | %s |\n' "$nome" "$nota" ;; esac
  done < "$KIT/manifest.tsv"
  echo
  echo "Fatos medidos deste projeto: \`perfil.tsv\`. Conhecimento sob demanda:"
  echo "\`.agents/skills/<peça>/rules/\`. Memória: \`docs/ai-harness/memoria/\`."
  echo "$FIM"
} > "$BLOCO"

# O índice canônico é o que o projeto JÁ usa — não o que a gente preferiria.
# MEDIDO num projeto real: ele tinha CLAUDE.md (173 linhas, arquivo real) e nenhum
# AGENTS.md. Escrever em AGENTS.md criaria um segundo índice que o agente nunca lê —
# o bloco ficaria instalado e invisível, que é pior que não instalado.
if   [ -f "$ALVO/AGENTS.md" ]; then IDX="$ALVO/AGENTS.md"
elif [ -f "$ALVO/CLAUDE.md" ]; then IDX="$ALVO/CLAUDE.md"; inf "índice canônico deste projeto: CLAUDE.md (AGENTS.md não existe)"
else IDX="$ALVO/AGENTS.md"
fi
if [ -f "$IDX" ] && grep -qF "$INI" "$IDX"; then
  python3 - "$IDX" "$BLOCO" "$INI" "$FIM" <<'PY'
import sys,re
idx,blk,ini,fim=sys.argv[1:5]
t=open(idx).read(); novo=open(blk).read().rstrip('\n')
t=re.sub(re.escape(ini)+r'.*?'+re.escape(fim), lambda _: novo, t, flags=re.S)
open(idx,'w').write(t)
PY
  ok "$(basename "$IDX"): bloco gerenciado SUBSTITUÍDO (a prosa em volta ficou intacta)"
elif [ -f "$IDX" ]; then
  printf '\n' >> "$IDX"; cat "$BLOCO" >> "$IDX"
  ok "$(basename "$IDX") já existia: bloco ACRESCENTADO ao fim, nada foi reescrito"
else
  { echo "# ${ALVO##*/}"; echo; cat "$BLOCO"; } > "$IDX"
  ok "$(basename "$IDX") criado"
fi
rm -f "$BLOCO"
ok "bloco escrito em $(basename "$IDX")"
[ -e "$ALVO/CLAUDE.md" ] || { ln -s AGENTS.md "$ALVO/CLAUDE.md"; ok "CLAUDE.md → AGENTS.md (symlink)"; }

# runtime fora do git, em info/exclude — NUNCA no .gitignore, que é rastreado
if gc=$(git -C "$ALVO" rev-parse --git-common-dir 2>/dev/null) && [ -n "$gc" ]; then
  case "$gc" in /*) ;; *) gc="$ALVO/$gc" ;; esac
  mkdir -p "$gc/info"
  # `tasks/` e `.prumo/` vão para info/exclude — LOCAL e não rastreado — e nunca
  # para o .gitignore, que é arquivo versionado: escrever nele sujaria a árvore de
  # todo mundo e viraria diff que ninguém pediu. É o mesmo mecanismo que os harness
  # do Claude e do Cursor usam para não mandar plano para o repositório.
  for pat in '.prumo/' 'tasks/' 'perfil.tsv' 'produto.md'; do
    grep -qxF "$pat" "$gc/info/exclude" 2>/dev/null || printf '%s\n' "$pat" >> "$gc/info/exclude"
  done
  ok "tasks/ · perfil.tsv · runtime → .git/info/exclude (local, zero diff, nada vai pro git)"
else
  avi "sem repositório git — tasks/ não pôde ser excluído automaticamente"
fi

# ── 4 · PROVA — relendo o disco ──────────────────────────────────────────────
echo; echo "── 4 · Prova (relida do disco) ──"
falhou=0
prova(){ [ -e "$2" ] && ok "$1" || { printf '  \033[31m✗\033[0m %s\n' "$1"; falhou=1; }; }
prova "perfil.tsv"                       "$ALVO/perfil.tsv"
prova "índice canônico ($(basename "$IDX"))" "$IDX"
prova "skill canônica (leveza)"          "$ALVO/.agents/skills/leveza/SKILL.md"
prova "symlink do Claude Code"           "$ALVO/.claude/skills/leveza"
prova "rule do Cursor"                   "$ALVO/.cursor/rules/leveza.mdc"
prova "reference de custo zero"          "$ALVO/.agents/skills/ui-plano/rules/qualidade-ui.md"
prova "template de UI"                   "$ALVO/.prumo/templates/ui-plano.md"
prova "diretório de memória"             "$ALVO/docs/ai-harness/memoria"
prova "workspace ativo (local)"          "$ALVO/tasks"
prova "contexto derivado do código"      "$ALVO/.prumo/contexto.md"
grep -qF "$INI" "$IDX" && ok "bloco gerenciado presente" || { echo "  ✗ bloco ausente"; falhou=1; }

echo
[ "$falhou" = 0 ] && { echo "prumo instalado em $ALVO"; echo; echo "  Abra o agente aqui e cole o pedido. A triagem escolhe a rota."; } \
                  || { echo "instalação INCOMPLETA — veja os ✗ acima" >&2; exit 1; }
