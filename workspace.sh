#!/usr/bin/env bash
# workspace.sh — monta a pasta de um produto: clona os repositórios dele e instala o
# prumo em cada um. Instalado como `prumo-workspace`.
#
#   prumo-workspace <org> <produto> [--dir <pasta>] [--jira] [--hub <url>] [--sim]
#   prumo-workspace --hub <url>          # só conecta os agentes ao Hub de memória
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

ORG=""; PROD=""; DIR=""; JIRA=0; SIM=0; HUB=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="${2:-}"; shift ;;
    --hub) HUB="${2:-}"; shift ;;
    --jira) JIRA=1 ;;
    --sim|-y) SIM=1 ;;
    -*) erro "opção desconhecida: $1" ;;
    *) [ -z "$ORG" ] && ORG="$1" || PROD="$1" ;;
  esac
  shift
done

# ── Hub de memória: valida a chave e registra o servidor MCP nos clientes ────
# A chave chega por terminal (sem eco) ou por PRUMO_HUB_KEY — nunca por argumento.
configure_hub() {
  local url="${HUB%/}" key me cfg="${XDG_CONFIG_HOME:-$HOME/.config}/prumo"
  echo; echo "── Hub de memória ($url) ──"
  key="${PRUMO_HUB_KEY:-}"
  if [ -z "$key" ]; then
    [ -t 0 ] || erro "sem terminal para pedir a chave — passe em PRUMO_HUB_KEY"
    printf '  Cole a chave (gerada em %s/keys) e tecle Enter: ' "$url"; read -rs key; echo
  fi
  key="$(printf '%s' "$key" | tr -d '[:space:]')"
  case "$key" in ph_*) ;; *) erro "isso não parece uma chave do Hub (começa com ph_)" ;; esac
  # header pelo stdin (-H @-): a chave não aparece na lista de processos
  me="$(printf 'Authorization: Bearer %s\n' "$key" | curl -sf -H @- "$url/api/me")" \
    || erro "o Hub recusou a chave ou não respondeu em $url/api/me — confira o endereço e a chave"
  ok "chave válida: $(printf '%s' "$me" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["email"], "·", ", ".join(t["slug"] for t in d["teams"]) or "nenhum time")')"

  mkdir -p "$cfg" && chmod 700 "$cfg"
  ( umask 077; printf '%s\n' "$key" > "$cfg/hub-key" )
  ok "chave guardada em $cfg/hub-key (só você lê)"

  if command -v claude >/dev/null; then
    claude mcp remove prumo-hub --scope user >/dev/null 2>&1 || true
    if claude mcp add-json prumo-hub --scope user \
        "{\"type\":\"http\",\"url\":\"$url/mcp\",\"headersHelper\":\"$KIT/hub-headers.sh\"}" >/dev/null 2>&1; then
      ok "Claude Code: prumo-hub configurado (a chave é lida do arquivo a cada conexão)"
    else
      avi "Claude Code: não consegui registrar — rode: claude mcp add-json prumo-hub --scope user '{\"type\":\"http\",\"url\":\"$url/mcp\",\"headersHelper\":\"$KIT/hub-headers.sh\"}'"
    fi
  else
    inf "Claude Code não encontrado — pulei"
  fi

  if [ -d "$HOME/.cursor" ]; then
    # O Cursor não tem headersHelper e não interpola variável em header remoto: a chave
    # vai no próprio mcp.json, que é arquivo do usuário. Escrita pelo python, fora do argv.
    PRUMO_HUB_KEY="$key" python3 - "$HOME/.cursor/mcp.json" "$url/mcp" <<'PYCUR' \
      && ok "Cursor: prumo-hub em ~/.cursor/mcp.json" || avi "Cursor: ~/.cursor/mcp.json ilegível — mantido como está"
import json, os, sys
p, url = sys.argv[1:3]
d = json.load(open(p)) if os.path.exists(p) and os.path.getsize(p) else {}
d.setdefault("mcpServers", {})["prumo-hub"] = {"url": url, "headers": {"Authorization": "Bearer " + os.environ["PRUMO_HUB_KEY"]}}
fd = os.open(p, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, "w") as f:
    json.dump(d, f, indent=2)
PYCUR
  else
    inf "Cursor não encontrado — pulei"
  fi
  inf "reinicie o agente para ele carregar as ferramentas do Hub"
}

if [ -z "$ORG" ] && [ -n "$HUB" ]; then configure_hub; exit 0; fi
[ -n "$ORG" ] && [ -n "$PROD" ] || erro "uso: prumo-workspace <org> <produto> [--dir <pasta>] [--jira] [--hub <url>] [--sim]   ·   prumo-workspace --hub <url>"
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

[ -n "$HUB" ] && configure_hub

echo
echo "Workspace pronto: $WS"
echo "  Abra o agente na pasta do repositório da tarefa. Os irmãos já estão no perfil.tsv"
echo "  de cada um (repos_irmaos), e trabalho que cruza repositórios usa esse caminho."
