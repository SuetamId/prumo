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

# ── 0 · O KIT ESTÁ ATUALIZADO? ───────────────────────────────────────────────
# MEDIDO: o kit ficou 2 commits atrás, o install rodou do snapshot velho e
# reinstalou a versão antiga por cima da antiga — sem erro e sem aviso. "Atualizei"
# e "nada mudou" ficaram indistinguíveis. Consulta remota é barata e só informa:
# ela nunca bloqueia nem puxa nada sozinha, porque o kit é de quem instalou.
if git -C "$KIT" rev-parse --git-dir >/dev/null 2>&1; then
  if timeout 10 git -C "$KIT" fetch -q origin 2>/dev/null; then
    atras=$(git -C "$KIT" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    if [ "${atras:-0}" -gt 0 ]; then
      printf '  \033[33m!\033[0m kit %s commit(s) atrás do remoto — você vai instalar a versão ANTIGA\n' "$atras" >&2
      printf '      atualize antes:  git -C %s pull\n\n' "$KIT" >&2
    fi
  else
    printf '  \033[34m·\033[0m sem rede para conferir se o kit está atualizado\n' >&2
  fi
fi

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
  echo "# Medição errada? Corrija o valor e troque a origem por 'declarado: <motivo>'."
  echo "# Linha declarada sobrevive ao reinstall e cala a medição da mesma chave."
  echo "#"
  echo "# chave	valor	origem"
} > "$PERFIL.novo"

reg(){ printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$PERFIL.novo"; }
# DECLARADO vence MEDIDO. MEDIDO num projeto real: origin/HEAD é main e o time
# integra em development — nenhuma medição acerta isso, quem sabe é gente.
DECL=""
[ -f "$ALVO/perfil.tsv" ] && DECL="$(awk -F'\t' '$3 ~ /^declarado/' "$ALVO/perfil.tsv")"
n_fatos=0
medir(){ # chave · valor · origem  — só registra se o valor existir e não houver declaração
  [ -n "$DECL" ] && printf '%s\n' "$DECL" | cut -f1 | grep -qxF "$1" && return 0
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
  # Base é para onde o trabalho integra, NUNCA a branch em que o install rodou.
  # git-flow: develop(ment) só vence a default do remoto se estiver VIVA (commit mais
  # novo) — um develop abandonado num repo trunk-based não pode virar base.
  def="$(git -C "$ALVO" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)"; def="${def#origin/}"
  base="$def"; ori="origin/HEAD"
  t_def=$(git -C "$ALVO" log -1 --format=%ct "origin/$def" 2>/dev/null || echo 0)
  for b in development develop; do
    t=$(git -C "$ALVO" log -1 --format=%ct "origin/$b" 2>/dev/null) || continue
    [ "$t" -gt "${t_def:-0}" ] && { base=$b; ori="origin/$b mais recente que origin/${def:-?} (git-flow)"; break; }
  done
  medir branch_base "$base" "$ori"
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

n_decl=0
[ -n "$DECL" ] && { printf '%s\n' "$DECL" >> "$PERFIL.novo"; n_decl=$(printf '%s\n' "$DECL" | wc -l | tr -d ' '); }
mv "$PERFIL.novo" "$PERFIL"
ok "perfil.tsv: $n_fatos fato(s) medido(s) · $n_decl declarado(s), preservado(s)"
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
  for f in "$IDX_SECO" "~/.claude/skills/ (global)" .agents/skills/ .cursor/rules/ .prumo/contexto.md docs/ai-harness/memoria/ perfil.tsv; do
    [ -n "$f" ] && printf '  %s\n' "$f"
  done
  echo; echo "Dry-run: nada foi escrito."
  rm -f "$PERFIL"; exit 0
fi

# ── 2 · ARTEFATOS — uma fonte, dois clientes ─────────────────────────────────
# Claude Code: skill GLOBAL, symlink para o kit. MEDIDO: skill instalada no projeto
# e não commitada sumia em todo worktree — e o Claude Code desktop abre um worktree
# por sessão. Global chega a qualquer worktree, e `git pull` no kit já atualiza.
# Cursor: lê do projeto, então recebe a cópia em .agents/skills + .mdc renderizado.
echo; echo "── 2 · Artefatos ──"
GLOBAL="$HOME/.claude/skills"
mkdir -p "$GLOBAL" "$ALVO/.agents/skills" "$ALVO/.cursor/rules"

n_sk=0
while IFS=$'\t' read -r kind nome alvo sempre _; do
  case "$kind" in ''|'#'*) continue ;; skill) ;; *) continue ;; esac

  # global: só substitui o que já é nosso — skill homônima de outra fonte fica
  g="$GLOBAL/$nome"
  if [ -e "$g" ] && ! { [ -L "$g" ] && [ "$(readlink "$g")" = "$KIT/skills/$nome" ]; }; then
    avi "$g já existe e não é do prumo — mantido; a skill $nome NÃO foi instalada globalmente"
  else
    ln -sfn "$KIT/skills/$nome" "$g"
  fi
  # o symlink de projeto que versões anteriores criavam duplicaria a skill global
  [ -L "$ALVO/.claude/skills/$nome" ] && [ "$(readlink "$ALVO/.claude/skills/$nome")" = "../../.agents/skills/$nome" ] \
    && rm -f "$ALVO/.claude/skills/$nome"

  rm -rf "$ALVO/.agents/skills/$nome"
  cp -R "$KIT/skills/$nome" "$ALVO/.agents/skills/$nome"

  # Cursor: .mdc renderizado do mesmo SKILL.md
  src="$KIT/skills/$nome/SKILL.md"
  desc=$(awk '/^description:/{sub(/^description: */,""); print; exit}' "$src")
  [ "$sempre" = "sim" ] && aa=true || aa=false
  { echo "---"
    echo "description: ${desc:-$nome}"
    echo "alwaysApply: $aa"
    echo "---"
    echo
    echo "> Fonte canônica: \`.agents/skills/$nome/SKILL.md\`. Os caminhos \`rules/\`,"
    echo "> \`scripts/\` e \`templates/\` citados abaixo vivem em \`.agents/skills/$nome/\`."
    echo
    awk 'BEGIN{k=0} /^---$/{k++; next} k>=2' "$src"
  } > "$ALVO/.cursor/rules/$nome.mdc"
  n_sk=$((n_sk+1))
done < "$KIT/manifest.tsv"
ok "$n_sk skills → ~/.claude/skills/ (global, symlink ao kit) · .agents/skills/ + .cursor/rules/ (Cursor)"

mkdir -p "$ALVO/tasks" "$ALVO/docs/ai-harness/memoria"
ok "memória → docs/ai-harness/memoria/"

# Versões anteriores copiavam scripts/ e templates para o projeto; agora moram na
# skill. Só some o que é byte a byte nosso — script do projeto com o mesmo nome fica.
rm -rf "$ALVO/.prumo/templates"
for s in triagem/scripts/mapear-codebase.sh ui-plano/scripts/detectar-slop.sh \
         aprender/scripts/gerar-indice.sh aprender/scripts/selecionar-instintos.sh; do
  f="$ALVO/scripts/${s##*/}"
  [ -f "$f" ] && cmp -s "$f" "$KIT/skills/$s" && rm -f "$f"
done
rmdir "$ALVO/scripts" 2>/dev/null || true

# Contexto derivado do CÓDIGO — é o que salva o harness em projeto sem documentação.
# Vai para .prumo/ (local, fora do git) porque derivado é regenerável: não há o
# que preservar, e assim não impomos estrutura no repositório de ninguém.
if bash "$KIT/skills/triagem/scripts/mapear-codebase.sh" "$ALVO" >/dev/null 2>&1; then
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
  echo "Fatos deste projeto: \`perfil.tsv\`. Memória: \`docs/ai-harness/memoria/\`."
  echo "\`rules/\`, \`scripts/\` e \`templates/\` citados numa skill são relativos à pasta dela."
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

# ── 3b · ATALHO `prumo-atualizar` ────────────────────────────────────────────
# Fica em ~/.local/bin, que é o diretório de binário do usuário no padrão XDG e
# já está no PATH na maioria dos sistemas. Se NÃO estiver, dizemos — atalho que
# não responde é pior que atalho que não existe.
if [ -f "$KIT/atualizar.sh" ]; then
  BIN="$HOME/.local/bin"; mkdir -p "$BIN" 2>/dev/null
  if ln -sfn "$KIT/atualizar.sh" "$BIN/prumo-atualizar" 2>/dev/null; then
    case ":$PATH:" in
      *":$BIN:"*) ok "atalho: prumo-atualizar (puxa o kit e reinstala)" ;;
      *) avi "atalho criado em $BIN, que NÃO está no seu PATH"
         printf '      acrescente ao seu shell:  export PATH="$HOME/.local/bin:$PATH"\n' ;;
    esac
  else
    avi "não consegui criar o atalho em $BIN — use: bash $KIT/atualizar.sh"
  fi
fi

# ── 4 · PROVA — relendo o disco ──────────────────────────────────────────────
echo; echo "── 4 · Prova (relida do disco) ──"
falhou=0
prova(){ [ -e "$2" ] && ok "$1" || { printf '  \033[31m✗\033[0m %s\n' "$1"; falhou=1; }; }
prova "perfil.tsv"                       "$ALVO/perfil.tsv"
prova "índice canônico ($(basename "$IDX"))" "$IDX"
prova "skill canônica (leveza)"          "$ALVO/.agents/skills/leveza/SKILL.md"
prova "skill global do Claude Code"      "$HOME/.claude/skills/leveza/SKILL.md"
prova "rule do Cursor"                   "$ALVO/.cursor/rules/leveza.mdc"
prova "reference de custo zero"          "$ALVO/.agents/skills/ui-plano/rules/qualidade-ui.md"
prova "template de UI"                   "$ALVO/.agents/skills/ui-plano/templates/ui-plano.md"
prova "diretório de memória"             "$ALVO/docs/ai-harness/memoria"
prova "workspace ativo (local)"          "$ALVO/tasks"
prova "contexto derivado do código"      "$ALVO/.prumo/contexto.md"
grep -qF "$INI" "$IDX" && ok "bloco gerenciado presente" || { echo "  ✗ bloco ausente"; falhou=1; }

# Worktree só recebe o que é RASTREADO. O Claude Code lê a skill global e não
# depende disso; o Cursor lê do projeto, e aí o que não foi commitado some.
if git -C "$ALVO" ls-files --others --exclude-standard -- .agents/skills .cursor/rules 2>/dev/null | grep -q .; then
  inf "Cursor: .agents/skills e .cursor/rules não commitados — worktrees do Cursor não os veem"
fi

echo
[ "$falhou" = 0 ] && { echo "prumo instalado em $ALVO"; echo; echo "  Abra o agente aqui e cole o pedido. A triagem escolhe a rota."; } \
                  || { echo "instalação INCOMPLETA — veja os ✗ acima" >&2; exit 1; }
