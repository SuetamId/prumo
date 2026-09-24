#!/usr/bin/env bash
# mapear-codebase.sh — deriva contexto DO CÓDIGO quando não há documentação.
#
# Escreve .prumo/contexto.md, que é LOCAL e fora do git: derivado é regenerável,
# então não há o que preservar, e assim o harness não impõe estrutura no repo de ninguém.
#
# 🔴 O QUE ELE NÃO FAZ: decisão. O código diz o que EXISTE; nunca diz o que foi
# rejeitado nem por quê. Isto é mapa, não enciclopédia e não ADR.
set -uo pipefail
ALVO="${1:-.}"; [ -d "$ALVO" ] || { echo "erro: '$ALVO' não existe" >&2; exit 1; }
ALVO="$(cd "$ALVO" && pwd)"; OUT="$ALVO/.prumo/contexto.md"; mkdir -p "$(dirname "$OUT")"
cd "$ALVO" || exit 1
SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "sem-git")
PODA=(-not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*'
      -not -path '*/build/*' -not -path '*/.next/*' -not -path '*/vendor/*' -not -path '*/venv/*')

{
echo "# Contexto derivado — ${ALVO##*/}"
echo
echo "> **GERADO** de \`scripts/mapear-codebase.sh\` em $(date +%Y-%m-%d) · HEAD \`$SHA\`."
echo "> Não edite à mão — regenere. Derivado envelhece: confira o HEAD antes de confiar."
echo "> Isto é **estrutura**, nunca decisão. O código não diz o que foi rejeitado."
echo
echo "## Stack"
echo
for m in package.json pyproject.toml requirements.txt go.mod pom.xml build.gradle Cargo.toml Gemfile composer.json; do
  find . -maxdepth 3 -name "$m" "${PODA[@]}" 2>/dev/null | head -4 | while read -r f; do echo "- \`${f#./}\`"; done
done
echo
echo "## Como se roda"
echo
echo '```'
[ -f package.json ] && python3 -c "
import json
try: s=json.load(open('package.json')).get('scripts') or {}
except Exception: s={}
[print(f'npm run {k:<18} {v[:62]}') for k,v in list(s.items())[:12]]" 2>/dev/null
[ -f Makefile ] && grep -oE '^[a-z][a-z0-9_-]*:' Makefile 2>/dev/null | tr -d ':' | head -10 | sed 's/^/make /'
echo '```'
echo
echo "## Onde o código mora"
echo
echo "Diretórios com mais arquivos de código — é onde a mudança provavelmente cai:"
echo
echo '```'
find . -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' \
  -o -name '*.java' -o -name '*.go' -o -name '*.rb' -o -name '*.vue' -o -name '*.svelte' \) "${PODA[@]}" 2>/dev/null \
  | sed 's|^\./||' | awk -F/ 'NF>1{print $1"/"$2}' | sort | uniq -c | sort -rn | head -14
echo '```'
echo
echo "## Pontos de entrada"
echo
# MEDIDO num Next.js real: os padrões clássicos (index.ts, main.*) devolveram ZERO,
# porque o App Router usa page.tsx/layout.tsx/route.ts. Framework moderno não tem
# "o" entry point — tem convenção de roteamento, e é ela que localiza a mudança.
ep=$(find . -maxdepth 4 \( -name 'main.*' -o -name 'index.ts' -o -name 'index.js' \
  -o -name 'app.module.ts' -o -name 'App.tsx' -o -name 'server.*' -o -name 'run.py' \) "${PODA[@]}" 2>/dev/null | head -8)
[ -n "$ep" ] && printf '%s\n' "$ep" | sed 's|^\./|- `|;s|$|`|'
for par in "page.tsx:rota (Next App Router)" "layout.tsx:layout (Next)" "route.ts:handler de API (Next)" \
           "+page.svelte:rota (SvelteKit)" "*.page.ts:rota (Angular)" "*.controller.ts:controller (Nest)"; do
  pat="${par%%:*}"; lbl="${par##*:}"
  c=$(find . -name "$pat" "${PODA[@]}" 2>/dev/null | wc -l | tr -d ' ')
  [ "${c:-0}" -gt 0 ] && echo "- **$c** × \`$pat\` — $lbl"
done
[ -z "$ep" ] && [ "$(find . -name 'page.tsx' -o -name '*.page.ts' "${PODA[@]}" 2>/dev/null | wc -l | tr -d ' ')" = 0 ] \
  && echo "- nenhum padrão conhecido casou — localize pelo diretório mais denso acima"
echo
echo "## Testes"
echo
nt=$(find . \( -name '*.spec.*' -o -name '*.test.*' -o -name 'test_*.py' -o -name '*_test.go' \) "${PODA[@]}" 2>/dev/null | wc -l | tr -d ' ')
if [ "$nt" = 0 ]; then
  echo "🔴 **Nenhum arquivo de teste encontrado.** Não há como provar mudança automaticamente aqui."
  echo "A prova tem de ser manual e declarada — ver \`prova/SKILL.md\`."
else
  echo "$nt arquivo(s) de teste. Onde ficam:"; echo
  echo '```'
  find . \( -name '*.spec.*' -o -name '*.test.*' -o -name 'test_*.py' -o -name '*_test.go' \) "${PODA[@]}" 2>/dev/null \
    | sed 's|^\./||' | awk -F/ '{print $1"/"$2}' | sort | uniq -c | sort -rn | head -6
  echo '```'
fi
echo
tem_ci(){ [ -n "$(find .github/workflows -maxdepth 1 \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null)" ] \
          || [ -f .gitlab-ci.yml ] || [ -f Jenkinsfile ] || [ -f .circleci/config.yml ]; }
echo "## O que a esteira exige"
echo
if tem_ci; then
  echo "É a definição operacional de \"pronto\" — o que reprova aqui reprova a entrega."; echo
  for f in .github/workflows/*.y*ml .gitlab-ci.yml; do
    [ -f "$f" ] || continue
    echo "**\`${f#./}\`** — $(grep -cE '^[[:space:]]*-[[:space:]]*(name|run|uses):' "$f" 2>/dev/null) passo(s)"
    # comando INTEIRO, não o prefixo: `npm run` sozinho não diz o que a esteira roda
    grep -hoE '(npm|yarn|pnpm|make|pytest|mvn|gradle|go|ng|python)[a-z0-9 :._-]*' "$f" 2>/dev/null \
      | sed 's/[[:space:]]*$//' | grep -vE '^(npm|yarn|pnpm|go|ng|make|python|npm run)$' | sort -u | head -8 | sed 's/^/  - `/;s/$/`/'
  done
else
  echo "Sem CI detectada. Nada é cobrado automaticamente na integração."
fi
echo
echo "## Convenções vivas (medidas, não declaradas)"
echo
if git rev-parse --git-dir >/dev/null 2>&1; then
  n=$(git log --format=%s -40 2>/dev/null | wc -l | tr -d ' ')
  c=$(git log --format=%s -40 2>/dev/null | grep -cE '^(feat|fix|chore|docs|refactor|test|style|perf|build|ci)(\(.+\))?!?: ' || true)
  echo "- Commit: **$c de $n** dos últimos casam conventional"
  echo "- Branches recentes: $(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/remotes 2>/dev/null | grep -v HEAD | head -5 | tr '\n' ' ')"
  # NUNCA nome de pessoa: `aprender/SKILL.md` proíbe identidade em contexto derivado,
  # e o número é o fato útil de qualquer forma — quantas mãos, não quais.
  echo "- Mãos ativas nos últimos 30 commits: $(git log --format='%an' -30 2>/dev/null | sort -u | wc -l | tr -d ' ')"
  echo "- Ritmo: $(git log --format='%ad' --date=short -30 2>/dev/null | sort -u | wc -l | tr -d ' ') dia(s) distintos nos últimos 30 commits"
fi
echo
echo "## Lacunas"
echo
[ -f README.md ]     || echo "- sem \`README.md\`"
# FONTE ÚNICA. Esta lacuna já foi respondida pela adoção, em perfil.tsv:registro_duravel.
# Perguntar de novo, com critério próprio, é como este script disse "sem CI" num repo
# com .github/workflows/ci.yml: duas perguntas para o mesmo fato sempre divergem, e um
# documento que se contradiz é pior que um documento calado.
# `docs/` criado pelo NOSSO instalador (docs/ai-harness/) nunca conta como registro do projeto.
reg=$(grep -m1 '^registro_duravel' perfil.tsv 2>/dev/null | cut -f2)
if [ -z "${reg:-}" ]; then
  if [ "$(find docs -mindepth 1 -maxdepth 1 -not -name 'ai-harness' 2>/dev/null | wc -l | tr -d ' ')" = "0" ]; then
    echo "- sem registro durável do projeto — decisão não tem onde morar (só existe \`docs/ai-harness/\`, que é nosso)"
  fi
fi
[ "$nt" = 0 ]        && echo "- **sem testes** — a 2ª lei (nada fecha sem verificação) não tem instrumento aqui"
tem_ci || echo "- sem CI — nada é cobrado automaticamente na integração"
echo
echo "_Lacuna é informação, não tarefa. Preencher é decisão de quem mantém o projeto._"
} > "$OUT"

echo "contexto derivado: $OUT ($(wc -l < "$OUT") linhas, HEAD $SHA)"
