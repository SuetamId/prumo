#!/usr/bin/env bash
# gerar-indice.sh — gera MEMORY.md a partir do DISCO. Nunca edite o índice à mão.
set -uo pipefail
DIR="${1:-docs/ai-harness/memoria}"
[ -d "$DIR" ] || { echo "erro: '$DIR' não existe" >&2; exit 2; }
OUT="$DIR/MEMORY.md"
{ echo "# Memória"; echo
  echo "> GERADO por \`scripts/gerar-indice.sh\` a partir do disco. Não edite à mão."; echo
  n=0
  for f in "$DIR"/*.md; do
    [ -e "$f" ] || continue
    b="$(basename "$f")"; [ "$b" = "MEMORY.md" ] && continue
    d=$(awk -F': *' '/^description:/{gsub(/^"|"$/,"",$2); print $2; exit}' "$f")
    printf -- '- [%s](%s) — %s\n' "${b%.md}" "$b" "${d:-sem description}"
    n=$((n+1))
  done
  echo; echo "_${n} episódio(s)._"
} > "$OUT"
echo "índice gerado: $OUT"
