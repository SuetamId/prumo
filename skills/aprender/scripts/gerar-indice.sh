#!/usr/bin/env bash
# gerar-indice.sh — gera MEMORY.md a partir do DISCO. Nunca edite o índice à mão.
set -uo pipefail
DIR="${1:-docs/ai-harness/memoria}"
[ -d "$DIR" ] || { echo "erro: '$DIR' não existe" >&2; exit 2; }
python3 - "$DIR" <<'PY'
import sys, os, re, glob
d = sys.argv[1]; out = os.path.join(d, "MEMORY.md")
itens = []
for f in sorted(glob.glob(os.path.join(d, "*.md"))):
    b = os.path.basename(f)
    if b == "MEMORY.md": continue
    try: t = open(f, encoding="utf-8").read()
    except Exception: continue
    m = re.match(r'^---\n(.*?)\n---', t, re.S)
    fm = dict(re.findall(r'^([a-z_]+):\s*"?([^"\n]*)"?\s*$', m.group(1), re.M)) if m else {}
    try: c = float(fm.get("confianca", 0))
    except ValueError: c = 0.0
    itens.append((c, fm.get("id", b[:-3]), b, fm.get("dominio","-"),
                  fm.get("escopo","projeto"), fm.get("gatilho",""),
                  fm.get("acao",""), int(fm.get("projetos","1") or 1)))
itens.sort(key=lambda x: (-x[0], x[1]))
L = ["# Memória — instintos", "",
     "> **GERADO** por `aprender/scripts/gerar-indice.sh` a partir do disco. Não edite à mão.",
     "> Ordenado por confiança. A seleção do que entra na sessão é outra coisa:",
     "> `aprender/scripts/selecionar-instintos.sh`.", ""]
if not itens:
    L += ["_Nenhum instinto ainda._"]
else:
    L += ["| Conf. | Domínio | Escopo | Instinto | Quando |", "|---|---|---|---|---|"]
    for c, i, b, dom, esc, gat, ac, projs in itens:
        marca = "🌐" if esc == "global" else ""
        L.append("| %.2f | %s | %s%s | [%s](%s) | %s |" % (c, dom, esc, marca, i, b, gat or "—"))
    prom = [x for x in itens if x[4] != "global" and x[7] >= 2]
    if prom:
        L += ["", "## Candidatos a promoção global", "",
              "Vistos em 2+ projetos e ainda com `escopo: projeto`. Promover é ato humano.", ""]
        L += ["- `%s` — %d projetos" % (x[1], x[7]) for x in prom]
    arq = os.path.join(d, "arquivados")
    if os.path.isdir(arq):
        n = len([x for x in os.listdir(arq) if x.endswith(".md")])
        if n: L += ["", "_%d arquivado(s) em `arquivados/` (confiança caiu abaixo de 0.3)._" % n]
    L += ["", "_%d instinto(s) ativo(s)._" % len(itens)]
open(out, "w", encoding="utf-8").write("\n".join(L) + "\n")
print("índice gerado: %s (%d instinto(s))" % (out, len(itens)))
PY
