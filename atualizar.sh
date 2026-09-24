#!/usr/bin/env bash
# atualizar.sh — puxa o kit e reinstala no projeto. Instalado como `prumo-atualizar`.
#
# POR QUE ELE SE COPIA ANTES DE PUXAR — e o que disso foi MEDIDO.
#
# Este arquivo vive DENTRO do kit, e o `git pull` abaixo reescreve o kit, inclusive
# este arquivo. Medido em 2026-09-25: o `pull` escreve NO MESMO INODE, ou seja, por
# cima do arquivo aberto — o mecanismo de corrupção existe.
#
# O que NÃO foi reproduzido: a corrupção em si. Rodando um script que se reescreve no
# meio da própria execução, com deslocamento de offsets, ele chegou ao fim intacto a
# 2 KB, 64 KB e 256 KB. Para este arquivo (~2 KB) o bash já leu tudo antes do `pull`.
#
# A guarda fica porque custa 5 linhas e o inode compartilhado é fato. Mas ela é
# seguro, não conserto de bug observado — e quem vier depois não deve gastar tempo
# defendendo uma falha que ninguém viu acontecer aqui.
set -uo pipefail

if [ "${PRUMO_REEXEC:-}" != "1" ]; then
  PRUMO_KIT="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
  _t="$(mktemp)"; cp "$0" "$_t" 2>/dev/null || { echo "erro: não consegui me copiar" >&2; exit 1; }
  export PRUMO_REEXEC=1 PRUMO_KIT
  exec bash "$_t" "$@"
fi
# --- daqui para baixo estamos rodando da CÓPIA; o kit pode ser reescrito à vontade ---
KIT="${PRUMO_KIT:?}"
CONFERIR=0
args=(); for a in "$@"; do case "$a" in --conferir|--check) CONFERIR=1 ;; *) args+=("$a") ;; esac; done
set -- "${args[@]:-}"
ALVO="${1:-.}"
[ -d "$ALVO" ] || { echo "erro: '$ALVO' não é um diretório" >&2; exit 2; }

# `--conferir` compara o instalado com o kit e NÃO escreve nada.
# Mora aqui, e não num comando de shell no README, porque `<(...)` é bash/zsh e
# quebra no fish — MEDIDO. Comando que só roda num shell não é comando, é pegadinha.
if [ "$CONFERIR" = 1 ]; then
  # 🔴 Compara SÓ o que é do prumo. O manifesto é a fonte única de quem é nosso.
  # MEDIDO: a versão anterior comparava tudo que havia em .agents/skills/, e num
  # projeto com skills PRÓPRIAS (angular-developer, motion-design) reportava as 56
  # skills do time como "sobra" → DESATUALIZADO, logo depois de uma instalação que
  # provou 11/11. Convivência não é divergência: é a tese do produto.
  nossas="$(awk -F'\t' '$1=="skill"{print $2}' "$KIT/manifest.tsv" 2>/dev/null)"
  [ -n "$nossas" ] || { echo "erro: não consegui ler $KIT/manifest.tsv" >&2; exit 2; }
  filtro="$(printf '%s\n' "$nossas" | sed 's|^|^skills/|;s|$|/|' | paste -sd'|' -)"
  a="$(cd "$KIT" && find skills -name '*.md' 2>/dev/null | grep -E "$filtro" | sort)"
  b="$(cd "$ALVO" && find .agents/skills -name '*.md' 2>/dev/null | sed 's|^\.agents/||' | grep -E "$filtro" | sort)"
  if [ -z "$b" ]; then
    printf '\033[33m!\033[0m prumo NÃO está instalado em %s\n' "$(cd "$ALVO" && pwd)"; exit 2
  fi
  falta="$(comm -23 <(printf '%s\n' "$a") <(printf '%s\n' "$b") 2>/dev/null)"
  sobra="$(comm -13 <(printf '%s\n' "$a") <(printf '%s\n' "$b") 2>/dev/null)"
  if [ -z "$falta" ] && [ -z "$sobra" ]; then
    outras="$(cd "$ALVO" && find .agents/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's|.*/||' | grep -vxF "$(printf '%s\n' "$nossas")" | wc -l | tr -d ' ')"
    printf '\033[32m✓\033[0m EM DIA — %s artefato(s) do prumo, iguais ao kit (%s)\n' \
      "$(printf '%s\n' "$b" | wc -l | tr -d ' ')" "$(git -C "$KIT" rev-parse --short HEAD 2>/dev/null || echo '?')"
    [ "${outras:-0}" -gt 0 ] && printf '      (+%s skill(s) própria(s) do projeto, que o prumo não gerencia)\n' "$outras"
    exit 0
  fi
  printf '\033[33m!\033[0m DESATUALIZADO\n'
  [ -n "$falta" ] && printf '%s\n' "$falta" | sed 's/^/      falta: /'
  [ -n "$sobra" ] && printf '%s\n' "$sobra" | sed 's/^/      sobra: /'
  printf '\n      corrija com:  prumo-atualizar\n'
  exit 1
fi

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
