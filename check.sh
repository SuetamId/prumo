#!/usr/bin/env bash
# check.sh — prova que o kit cumpre o que o AGENTS.md promete. Roda no CI e à mão.
#
# Cada regra do AGENTS.md que pode ser medida vira um check aqui. Regra que só
# existe em prosa é promessa; a que quebra o CI é regra.
set -uo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"; cd "$KIT"
falhou=0
ok(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
ko(){ printf '  \033[31m✗\033[0m %s\n' "$1"; falhou=1; }
TETO=6000

# 1 · sintaxe de todo shell do kit
ruins=""; for f in *.sh skills/*/scripts/*.sh; do bash -n "$f" 2>/dev/null || ruins="$ruins $f"; done
[ -z "$ruins" ] && ok "sintaxe dos scripts" || ko "sintaxe quebrada:$ruins"

# 2-5 · manifesto, frontmatter, referências, neutralidade — tudo que é leitura de texto
python3 - <<'PY' || falhou=1
import glob, os, re, sys
ok=lambda m: print(f"  \033[32m✓\033[0m {m}")
erros=0
def ko(m):
    global erros; erros+=1; print(f"  \033[31m✗\033[0m {m}")

# 2 · manifesto ↔ disco, nos dois sentidos
man=[l.split('\t') for l in open('manifest.tsv') if l.strip() and not l.startswith('#')]
skills={c[1] for c in man if c[0]=='skill'}
refs={c[1] for c in man if c[0]=='reference'}
disco_sk={os.path.basename(os.path.dirname(p)) for p in glob.glob('skills/*/SKILL.md')}
disco_rf={p[len('skills/'):-3] for p in glob.glob('skills/*/rules/*.md')}
falta=sorted((skills-disco_sk)|{r for r in refs if r not in disco_rf})
sobra=sorted((disco_sk-skills)|(disco_rf-refs))
if falta: ko(f"no manifesto e não no disco: {', '.join(falta)}")
if sobra: ko(f"no disco e não no manifesto: {', '.join(sobra)}")
if not falta and not sobra: ok(f"manifesto ↔ disco ({len(skills)} skills, {len(refs)} references)")

# 3 · frontmatter: name = pasta, descrição começa pelo gatilho
n=erros
for p in sorted(glob.glob('skills/*/SKILL.md')):
    fm=open(p).read().split('---')[1]
    nome=re.search(r'^name:\s*(.+)$',fm,re.M); desc=re.search(r'^description:\s*(.+)$',fm,re.M)
    d=os.path.basename(os.path.dirname(p))
    if not nome or nome.group(1).strip()!=d: ko(f"{p}: name diferente da pasta")
    if not desc or len(desc.group(1))<40 or not desc.group(1).startswith('Use '):
        ko(f"{p}: description precisa começar por 'Use ' e ter ≥40 chars")
if erros==n: ok("frontmatter das skills")

# 4 · todo caminho citado existe — relativo à skill, à pasta do arquivo ou a skills/
pat=re.compile(r'(?:\.\./)*(?:[a-z-]+/)?(?:rules|scripts|templates)/[a-z0-9-]+\.(?:md|sh)|(?:\.\./)+[a-z-]+/SKILL\.md')
n=erros
for p in sorted(glob.glob('skills/*/SKILL.md')+glob.glob('skills/*/rules/*.md')):
    sk=os.path.join('skills',p.split('/')[1])
    for m in set(pat.findall(open(p).read())):
        bases=[os.path.dirname(p), sk, 'skills']
        if not any(os.path.exists(os.path.normpath(os.path.join(b,m))) for b in bases):
            ko(f"{p}: cita {m}, que não existe")
if erros==n: ok("referências citadas existem")

# 5 · neutralidade: nome de produto, cliente ou empresa nunca entra no artefato.
# A lista é DADO, fora do repositório: publicada aqui, ela mesma vazaria os nomes.
# Local: export PRUMO_NOMES_PROIBIDOS="nome1,nome2" · CI: secret do repositório (mascarado no log).
nomes=[n.strip() for n in os.environ.get("PRUMO_NOMES_PROIBIDOS","").split(",") if n.strip()]
if not nomes:
    print("  \033[33m!\033[0m neutralidade NÃO MEDIDA — defina PRUMO_NOMES_PROIBIDOS")
else:
    proibidos=re.compile(r'\b(' + '|'.join(map(re.escape, nomes)) + r')\b', re.I)
    n=erros
    for p in sorted(glob.glob('skills/**/*',recursive=True)+glob.glob('agents/*')):
        if os.path.isfile(p):
            for i,l in enumerate(open(p,errors='ignore'),1):
                if proibidos.search(l): ko(f"{p}:{i}: nome próprio no artefato")
    if erros==n: ok(f"neutralidade ({len(nomes)} nomes proibidos, nenhum nos artefatos)")

# credencial versionada
seg=re.compile(r'(ghp_[A-Za-z0-9]{20,}|github_pat_|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|xox[bp]-)')
achou=[p for p in glob.glob('**/*',recursive=True) if os.path.isfile(p) and seg.search(open(p,errors='ignore').read())]
achou=[p for p in achou if p!='check.sh']
ko(f"credencial em: {', '.join(achou)}") if achou else ok("nenhuma credencial versionada")
sys.exit(1 if erros else 0)
PY

# 6 · o instalador instala, reinstala e prova — num repo descartável, com HOME falso
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/home" "$T/p"; git -C "$T/p" init -q -b main
git -C "$T/p" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "feat: inicial"
if HOME="$T/home" bash "$KIT/install.sh" "$T/p" >"$T/1.log" 2>&1 \
   && HOME="$T/home" bash "$KIT/install.sh" "$T/p" >"$T/2.log" 2>&1; then
  ok "install.sh: instala e reinstala num repo limpo"
else
  ko "install.sh falhou num repo limpo:"; grep -E '✗|erro' "$T"/*.log | sed 's/^/      /'
fi

# 7 · orçamento residente: o bloco do índice + descrições que o cliente carrega sempre
if [ -f "$T/p/AGENTS.md" ]; then
  res=$(python3 - "$T/p/AGENTS.md" <<'PY'
import glob,re,sys
t=open(sys.argv[1]).read()
blk=re.search(r'<!-- prumo:start -->.*?<!-- prumo:end -->',t,re.S)
n=len(blk.group(0)) if blk else 0
for p in glob.glob('skills/*/SKILL.md'):
    fm=open(p).read().split('---')[1]
    d=re.search(r'^description:\s*(.+)$',fm,re.M); n+=len(d.group(1)) if d else 0
    w=re.search(r'^when_to_use:\s*>-?\n((?:  .*\n?)+)',fm,re.M); n+=len(w.group(1)) if w else 0
print(n)
PY
)
  [ "$res" -le "$TETO" ] && ok "orçamento residente: $res / $TETO chars" || ko "orçamento estourado: $res / $TETO chars"
else
  ko "orçamento: NÃO MEDIU (a instalação não gerou AGENTS.md)"
fi

echo
[ "$falhou" = 0 ] && echo "kit OK" || { echo "kit com falha — veja os ✗" >&2; exit 1; }
