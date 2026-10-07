#!/usr/bin/env bash
# empacotar.sh — gera o .zip de uma skill no formato Agent Skills, para enviar ao claude.ai.
#
#   bash empacotar.sh <skill> [pasta-de-saida]
#
# O SKILL.md do kit tem `when_to_use`, que é do Claude Code e não existe na especificação
# (agentskills.io/specification: name, description, license, compatibility, metadata,
# allowed-tools). Aqui ele é dobrado para dentro do `description`, que tem teto de 1024.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
nome="${1:?uso: bash empacotar.sh <skill> [pasta-de-saida]}"
saida="$(cd "${2:-.}" && pwd)"
src="$KIT/skills/$nome"
[ -f "$src/SKILL.md" ] || { echo "erro: skills/$nome/SKILL.md não existe" >&2; exit 2; }
tmp="$(mktemp -d)"; trap 'rm -rf -- "$tmp"' EXIT
cp -R "$src" "$tmp/$nome"
python3 - "$tmp/$nome/SKILL.md" <<'PY'
import re, sys
p = sys.argv[1]; t = open(p).read()
_, fm, body = t.split("---", 2)
name = re.search(r"^name:\s*(.+)$", fm, re.M).group(1).strip()
desc = re.search(r"^description:\s*(.+)$", fm, re.M).group(1).strip()
w = re.search(r"^when_to_use:\s*>-?\n((?:  .*\n?)+)", fm, re.M)
quando = " ".join(l.strip() for l in w.group(1).splitlines()) if w else ""
full = f"{desc} Quando: {quando}" if quando else desc
if len(full) > 1024:
    sys.exit(f"erro: description com {len(full)} caracteres (teto 1024) — encurte o when_to_use")
if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name) or len(name) > 64:
    sys.exit(f"erro: name '{name}' fora da especificação")
esc = full.replace('"', '\\"')
open(p, "w").write(f'---\nname: {name}\ndescription: "{esc}"\n---{body}')
print(f"  description: {len(full)}/1024 caracteres")
PY
rm -f "$saida/$nome.zip"; (cd "$tmp" && zip -qr "$saida/$nome.zip" "$nome")
echo "  $saida/$nome.zip"
