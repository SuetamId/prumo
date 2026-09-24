#!/usr/bin/env bash
# selecionar-instintos.sh — ranqueia instintos e corta no piso e no teto.
# Regra e números em skills/aprender/rules/selecao.md. Read-only.
set -uo pipefail
ALVO="${1:-.}"; cd "$ALVO" 2>/dev/null || { echo "erro: '$ALVO'" >&2; exit 1; }
DIR="docs/ai-harness/memoria"
[ -d "$DIR" ] || { echo "sem memória em $DIR" >&2; exit 0; }

# stack → domínios que ganham bônus. Detecção pelo manifesto, sem adivinhação.
STACK=""
if [ -f package.json ]; then
  if grep -qE '"(react|next|vue|@angular/core|svelte)"' package.json 2>/dev/null; then STACK="ui teste build"
  else STACK="build teste"; fi
fi
[ -f pyproject.toml ] || [ -f requirements.txt ] && STACK="$STACK dados teste"
[ -f go.mod ] || [ -f pom.xml ] || [ -f Cargo.toml ] && STACK="$STACK build teste"
[ -f Dockerfile ] || [ -f docker-compose.yml ] && STACK="$STACK ferramenta seguranca"

PROJ=$(git config --get remote.origin.url 2>/dev/null || pwd)

python3 - "$DIR" "$STACK" "$PROJ" <<'PY'
import sys, os, re, glob
d, stack, proj = sys.argv[1], set(sys.argv[2].split()), sys.argv[3]
PISO, TETO, PISO_CONF = 0.5, 12, 0.4
# PISO_CONF existe porque MEDIDO: um instinto de confiança 0.3 alcançou o piso de
# pontuação 0.5 só com o bônus de stack, e entrou dando ordem imperativa ao modelo.
# O número não restringe ninguém — quem lê "faça X" faz X. Palpite continua no disco
# e continua achável por busca; ele só não é INJETADO como se fosse sabido.
linhas = []
for f in sorted(glob.glob(os.path.join(d, "*.md"))):
    if os.path.basename(f) == "MEMORY.md": continue
    try: t = open(f, encoding="utf-8").read()
    except Exception: continue
    m = re.match(r'^---\n(.*?)\n---', t, re.S)
    if not m: continue
    fm = dict(re.findall(r'^([a-z_]+):\s*"?([^"\n]*)"?\s*$', m.group(1), re.M))
    try: c = float(fm.get("confianca", 0))
    except ValueError: continue
    p, motivos = c, []
    if fm.get("escopo", "projeto") == "projeto": p += 0.25; motivos.append("projeto")
    if fm.get("dominio") in stack:               p += 0.20; motivos.append("stack")
    if fm.get("origem") == "correcao-do-usuario": p += 0.10; motivos.append("correção")
    if p >= PISO and c >= PISO_CONF:
        linhas.append((p, c, fm.get("id", os.path.basename(f)[:-3]),
                       fm.get("dominio", "-"), fm.get("gatilho", ""),
                       fm.get("acao", ""), "+".join(motivos) or "-"))
linhas.sort(key=lambda x: -x[0])
sel, resto = linhas[:TETO], linhas[TETO:]
if not linhas:
    print("nenhum instinto acima dos pisos (pontuação %.2f · confiança %.2f)" % (PISO, PISO_CONF)); raise SystemExit(0)
print("── %d instinto(s) para esta sessão (de %d acima do piso) ──\n" % (len(sel), len(linhas)))
for p, c, i, dom, gat, ac, mot in sel:
    print("%.2f  [%s] %s" % (p, dom, i))
    if gat: print("      quando: %s" % gat)
    if ac:  print("      faça:   %s" % ac)
    print("      (confiança %.2f · bônus %s)\n" % (c, mot))
if resto:
    print("── %d abaixo do teto, não injetados ──" % len(resto))
    print("   " + ", ".join(x[2] for x in resto[:8]) + (" …" if len(resto) > 8 else ""))
PY
