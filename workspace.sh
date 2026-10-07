#!/usr/bin/env bash
# workspace.sh — monta a pasta de um produto: clona os repositórios dele e instala o
# prumo em cada um. Instalado como `prumo-workspace`.
#
#   prumo-workspace <org> <produto> [--dir <pasta>] [--jira] [--sim]
#
# Org e produto são ARGUMENTO: nada de empresa mora no kit. Repositório do produto é
# o que tem o topic <produto> no GitHub ou o nome começando por "<produto>-". O topic
# existe para a exceção — repositório cujo nome não segue o padrão.
#
# De propósito, NÃO faz: instalar ferramenta, configurar identidade git, desfazer.
# Para desfazer, apague a pasta.
set -uo pipefail
KIT="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
inf(){ printf '  \033[34m·\033[0m %s\n' "$1"; }
avi(){ printf '  \033[33m!\033[0m %s\n' "$1"; }
erro(){ printf '\033[31merro:\033[0m %s\n' "$1" >&2; exit 2; }

ORG=""; PROD=""; DIR=""; JIRA=0; SIM=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="${2:-}"; shift ;;
    --jira) JIRA=1 ;;
    --sim|-y) SIM=1 ;;
    -*) erro "opção desconhecida: $1" ;;
    *) [ -z "$ORG" ] && ORG="$1" || PROD="$1" ;;
  esac
  shift
done
[ -n "$ORG" ] && [ -n "$PROD" ] || erro "uso: prumo-workspace <org> <produto> [--dir <pasta>] [--jira] [--sim]"
command -v gh >/dev/null || erro "precisa do gh (https://cli.github.com)"
gh auth status >/dev/null 2>&1 || erro "gh sem login — rode: gh auth login"

p="$(printf '%s' "$PROD" | tr '[:upper:]' '[:lower:]')"
WS="${DIR:-$HOME/$(printf '%s' "$ORG" | tr '[:upper:]' '[:lower:]')/$p}"

# ── 1 · quais repositórios são do produto ───────────────────────────────────
repos="$(gh repo list "$ORG" --limit 1000 --no-archived --json name,repositoryTopics --jq \
  ".[] | select((.name|ascii_downcase|startswith(\"$p-\")) or (.name|ascii_downcase) == \"$p\"
               or ([.repositoryTopics[]?.name] | index(\"$p\"))) | .name" 2>/dev/null | sort)"
[ -n "$repos" ] || erro "nenhum repositório de '$PROD' em $ORG (nome '$p-*' ou topic '$p')"

echo; echo "── $ORG · $PROD → $WS ──"
printf '%s\n' "$repos" | while read -r r; do
  [ -d "$WS/$r/.git" ] && inf "$r (já clonado — vai receber pull)" || inf "$r"
done
if [ "$SIM" = 0 ]; then
  [ -t 0 ] || erro "sem terminal para confirmar — rode de novo com --sim"
  printf '\nSeguir? [s/N] '; read -r resp
  case "$resp" in s|S|sim|y|Y) ;; *) echo "nada foi feito."; exit 0 ;; esac
fi

# ── 2 · clona o que falta, atualiza o que existe ────────────────────────────
mkdir -p "$WS" || erro "não consegui criar $WS"
# Marca a pasta como workspace: é o que deixa o install.sh tratar as pastas vizinhas
# como repositórios irmãos. Sem a marca, ~/Dev com 50 repos viraria "50 irmãos".
printf 'org\t%s\nproduto\t%s\n' "$ORG" "$PROD" > "$WS/.prumo-workspace"
echo; echo "── Repositórios ──"
for r in $repos; do
  if [ -d "$WS/$r/.git" ]; then
    # nunca força: árvore suja ou branch divergente fica como está, e a pessoa decide
    git -C "$WS/$r" pull -q --ff-only 2>/dev/null && ok "$r: atualizado" || avi "$r: pull não foi possível (alterações locais?) — mantido como está"
  else
    gh repo clone "$ORG/$r" "$WS/$r" -- -q 2>/dev/null && ok "$r: clonado" || avi "$r: clone falhou"
  fi
done

# ── 3 · prumo em cada um — depois de todos clonados, para os irmãos saírem completos
echo; echo "── Harness ──"
LOG="$(mktemp -d)"
for r in $repos; do
  [ -d "$WS/$r/.git" ] || continue
  if bash "$KIT/install.sh" "$WS/$r" >"$LOG/$r.log" 2>&1; then ok "$r: prumo instalado"
  else avi "$r: instalação incompleta"; grep -E '✗|erro' "$LOG/$r.log" | sed 's/^/      /'; fi
done
rm -rf "$LOG"

# ── 4 · Jira, quando pedido: servidor MCP oficial da Atlassian, no nível do usuário
if [ "$JIRA" = 1 ]; then
  echo; echo "── Jira (MCP) ──"
  URL="https://mcp.atlassian.com/v2/mcp"
  if command -v claude >/dev/null; then
    if claude mcp get atlassian >/dev/null 2>&1; then ok "Claude Code: atlassian já configurado"
    elif claude mcp add --scope user --transport http atlassian "$URL" >/dev/null 2>&1; then ok "Claude Code: atlassian adicionado — autentique com /mcp na primeira sessão"
    else avi "Claude Code: não consegui adicionar — rode: claude mcp add --scope user --transport http atlassian $URL"; fi
  else
    inf "Claude Code não encontrado — pulei"
  fi
  if [ -d "$HOME/.cursor" ]; then
    python3 - "$HOME/.cursor/mcp.json" "$URL" <<'PY' && ok "Cursor: atlassian em ~/.cursor/mcp.json — autentique pelo próprio Cursor" || avi "Cursor: ~/.cursor/mcp.json ilegível — mantido como está"
import json, os, sys
p, url = sys.argv[1:3]
d = json.load(open(p)) if os.path.exists(p) and os.path.getsize(p) else {}
s = d.setdefault("mcpServers", {})
if "atlassian" not in s:
    s["atlassian"] = {"url": url}
    json.dump(d, open(p, "w"), indent=2)
PY
  else
    inf "Cursor não encontrado — pulei"
  fi
fi

echo
echo "Workspace pronto: $WS"
echo "  Abra o agente na pasta do repositório da tarefa. Os irmãos já estão no perfil.tsv"
echo "  de cada um (repos_irmaos), e trabalho que cruza repositórios usa esse caminho."
