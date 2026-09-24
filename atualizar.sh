#!/usr/bin/env bash
# atualizar.sh — puxa o kit e reinstala no projeto. Instalado como `prumo-atualizar`.
#
# 🔴 POR QUE ELE SE COPIA ANTES DE PUXAR. Este arquivo vive DENTRO do kit, e o
# `git pull` abaixo reescreve o kit — incluindo este arquivo. Bash lê script
# incrementalmente: sobrescrever o arquivo em execução corrompe o que ainda não foi
# lido, e o modo de falha é um erro de sintaxe numa linha que você nunca escreveu.
# Por isso ele se copia para um temporário e re-executa de lá ANTES de puxar.
set -uo pipefail

if [ "${PRUMO_REEXEC:-}" != "1" ]; then
  PRUMO_KIT="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
  _t="$(mktemp)"; cp "$0" "$_t" 2>/dev/null || { echo "erro: não consegui me copiar" >&2; exit 1; }
  export PRUMO_REEXEC=1 PRUMO_KIT
  exec bash "$_t" "$@"
fi
# --- daqui para baixo estamos rodando da CÓPIA; o kit pode ser reescrito à vontade ---
KIT="${PRUMO_KIT:?}"
ALVO="${1:-.}"
[ -d "$ALVO" ] || { echo "erro: '$ALVO' não é um diretório" >&2; exit 2; }

printf '\033[34m·\033[0m kit: %s\n' "$KIT"
antes="$(git -C "$KIT" rev-parse --short HEAD 2>/dev/null || echo '?')"

if git -C "$KIT" rev-parse --git-dir >/dev/null 2>&1; then
  if out=$(git -C "$KIT" pull --ff-only 2>&1); then
    depois="$(git -C "$KIT" rev-parse --short HEAD)"
    if [ "$antes" = "$depois" ]; then printf '\033[32m✓\033[0m kit já estava em dia (%s)\n' "$depois"
    else printf '\033[32m✓\033[0m kit atualizado: %s → %s\n' "$antes" "$depois"; fi
  else
    # Nunca force e nunca faça stash: o clone é de quem instalou.
    printf '\033[33m!\033[0m não consegui atualizar o kit — sigo com o que está no disco (%s)\n' "$antes" >&2
    printf '%s\n' "$out" | sed 's/^/      /' >&2
  fi
else
  printf '\033[33m!\033[0m %s não é repositório git — nada a puxar\n' "$KIT" >&2
fi

echo
exec bash "$KIT/install.sh" "$ALVO"
