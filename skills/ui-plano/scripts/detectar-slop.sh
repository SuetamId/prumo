#!/usr/bin/env bash
# detectar-slop.sh — detector DETERMINÍSTICO de marcas de UI gerada por modelo.
#
# HONESTIDADE DE ESCOPO: são 11 regras, não 61. Cada uma é grep sobre o código-fonte,
# sem modelo e sem rede. Elas cobrem as marcas que dá para achar estaticamente; NÃO
# cobrem o que só aparece renderizado (contraste real, card dentro de card, alvo de
# toque depois do CSS cascatear). Para isso existe `npx impeccable detect`, que roda
# no DOM renderizado — se ele estiver disponível, use os dois.
#
# Saída: achados em stderr. exit 0 = limpo · 2 = achados · 1 = não conseguiu medir.
set -uo pipefail
RAIZ="${1:-.}"
[ -d "$RAIZ" ] || { echo "erro: '$RAIZ' não é diretório" >&2; exit 1; }

EXT=(--include=*.css --include=*.scss --include=*.less --include=*.tsx --include=*.jsx
     --include=*.vue --include=*.svelte --include=*.html --include=*.ts --include=*.js)
PODA=(--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build
      --exclude-dir=.next --exclude-dir=coverage --exclude-dir=vendor)
n=0
achado(){ # regra · porquê · saída do grep
  [ -z "${3:-}" ] && return 0
  n=$((n+1))
  printf '\n\033[33m▸ %s\033[0m\n  %s\n' "$1" "$2" >&2
  printf '%s\n' "$3" | head -6 | sed 's/^/    /' >&2
  c=$(printf '%s\n' "$3" | wc -l | tr -d ' ')
  [ "$c" -gt 6 ] && printf '    … mais %s\n' "$((c-6))" >&2
}
g(){ grep -rn "${EXT[@]}" "${PODA[@]}" -E "$1" "$RAIZ" 2>/dev/null; }

# 1-2 · fonte que todo modelo escolhe
achado "fonte superexposta" \
  "Inter/Roboto/Arial é o default de todo modelo. Fonte é a decisão de marca mais barata que existe — escolha uma." \
  "$(g "font-family:[^;]*(Inter|Roboto|Arial|Helvetica Neue)" | grep -viE 'fallback|,\s*(sans-serif|system-ui)\s*$' | head -20)"
achado "só o stack do sistema" \
  "system-ui sozinho não é decisão tipográfica, é ausência de decisão." \
  "$(g "font-family:\s*(system-ui|-apple-system)[^;]*;" | head -20)"

# 3 · o gradiente
achado "gradiente roxo→azul" \
  "A marca registrada de UI gerada. Se o gradiente não sai da paleta da marca, ele não é decisão." \
  "$(g "linear-gradient[^;]*(#(6366f1|818cf8|8b5cf6|a855f7|7c3aed|c084fc)|purple|violet|indigo)" | head -20)"

# 4 · cor sem tinta
achado "preto/branco/cinza puro" \
  "Cinza puro é o cinza de ninguém. Tinte com a matiz da marca — a diferença é sutil e é o que separa produto de template." \
  "$(g "(color|background(-color)?):\s*(#000000|#000|#fff|#ffffff|rgb\(0, ?0, ?0\)|black|white)\s*;" | head -20)"

# 5 · easing datado
achado "easing com salto" \
  "Bounce/elastic virou marca de 2015. Movimento explica origem e destino; salto só chama atenção para si." \
  "$(g "(cubic-bezier\([^)]*-0?\.[0-9]|ease-in-out-back|bounce|elastic)" | head -20)"

# 6 · sombra colorida
achado "glow colorido" \
  "box-shadow com cor saturada imita foco e compete com o foco de verdade." \
  "$(g "box-shadow:[^;]*(rgba?\((1[0-9]{2}|[2-9][0-9]),\s*[0-9]+,\s*(2[0-4][0-9]|25[0-5])|#(6366f1|8b5cf6|a855f7))" | head -20)"

# 7 · foco apagado
# MEDIDO num projeto real: a versão ingênua desta regra (todo `outline:none`)
# deu 11 achados, dos quais 8 eram falsos — o arquivo já tinha `:focus-visible`
# logo abaixo. Regra que grita no código certo ensina a ignorar a regra.
# Agora só reprova o arquivo que remove o outline e NÃO oferece substituto.
sem_fv=""
while IFS= read -r ln; do
  [ -z "$ln" ] && continue
  arq="${ln%%:*}"
  grep -q "focus-visible" "$arq" 2>/dev/null || sem_fv="${sem_fv}${ln}\n"
done <<< "$(g "outline:\s*(none|0)\s*;")"
achado "outline removido sem :focus-visible no mesmo arquivo" \
  "Remover o outline sem oferecer substituto elimina a navegação por teclado. Arquivo que já tem :focus-visible não entra aqui." \
  "$(printf "$sem_fv" | sed '/^$/d')"

# 8 · alvo pequeno
achado "alvo de toque abaixo de 44px" \
  "Botão/ícone com altura fixa menor que 44px falha em dedo." \
  "$(g "(height|min-height):\s*([1-9]|[1-3][0-9]|4[0-3])px" | grep -iE 'btn|button|icon|chip|tag|badge|toggle' | head -20)"

# 9 · texto sem medida
achado "bloco de texto sem max-width" \
  "Parágrafo que ocupa a largura da tela passa de 75 caracteres e fica ilegível. Verifique se há medida em algum ancestral." \
  "$(g "^\s*(p|\.prose|article)\s*\{" | head -20)"

# 10 · hierarquia pulada
achado "nível de heading pulado" \
  "h1 seguido de h3 quebra leitor de tela e denuncia hierarquia decidida por tamanho, não por estrutura." \
  "$(grep -rn --include=*.html --include=*.tsx --include=*.jsx --include=*.vue "${PODA[@]}" -E "<h1[^>]*>" "$RAIZ" -A20 2>/dev/null | grep -E "<h[3-6]" | head -20)"

# 11 · marcador de trabalho inacabado
achado "texto provisório em código" \
  "Lorem ipsum e placeholder vão para produção. Não existe 'texto provisório'." \
  "$(grep -rni "${EXT[@]}" "${PODA[@]}" -E "(lorem ipsum|TODO: ?(texto|copy)|placeholder text)" "$RAIZ" 2>/dev/null | head -20)"

echo >&2
if [ "$n" = 0 ]; then
  printf '\033[32m✓ detector: nenhum achado nas 11 regras\033[0m\n' >&2
  printf '  Isto é evidência, não prova: o detector não vê a tela renderizada.\n' >&2
  exit 0
fi
printf '\033[33m%s regra(s) com achado.\033[0m Nenhuma é automática — cada uma pede julgamento.\n' "$n" >&2
exit 2
