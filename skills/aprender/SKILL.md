---
name: aprender
description: Use ao fim de uma tarefa quando o usuário te corrigir, um comando documentado falhar, você gastar tempo demais descobrindo algo sem doc, ou a sessão revelar algo que a próxima deveria já saber.
when_to_use: >-
  "registra isso", "não erra mais isso", usuário corrigiu uma suposição sua,
  comando da doc não funcionou, achado que custou caro e vai se repetir.
---

# Aprender

O harness fica mais inteligente porque alguém escreve o que a sessão ensinou. Sem isto,
cada sessão recomeça do zero e o mesmo erro custa de novo.

## Admissão — um dos dois tem de valer

1. **Carrega o "porquê" que a regra determinística descarta de propósito.** A regra diz
   *nunca faça X*; o episódio diz *em tal data alguém fez X por um bom motivo e o
   resultado foi este*. A regra guia a ação; o episódio impede que a ação errada volte
   pela mão de quem acha que agora é diferente.
2. **É correção de rota do agente** — o que ele fez errado, não o que o sistema é.

Nenhum dos dois? Tem outro dono: contrato vai para a doc do projeto, decisão vai para
ADR, número com validade vai para `perfil.tsv`. **Episódio não é wiki paralela.**

## O que NÃO entra

- Narrativa de sessão rotineira. "Implementei X e funcionou" não ensina nada.
- Fato que o repositório já diz. Se `git log` conta, não duplique.
- 🔴 **Identidade.** Sem nome de pessoa, caminho de home, e-mail, usuário nominal ou IP
  privado. Identidade vira **papel**; valor de máquina vira **nome de variável**. Isto
  não é higiene: é o que permite o episódio circular entre projetos e entre times.

## A forma

Um arquivo por episódio em `docs/ai-harness/memoria/`, nome em kebab-case que é a
**lição**, não o assunto — `cache-invalida-antes-do-commit.md`, nunca `notas-cache.md`.

```markdown
---
name: <slug>
description: "uma frase: o que aconteceu e o que custou"
dono_canonico: <caminho da regra que é fonte de verdade do fato, ou "-">
verificado_em: AAAA-MM-DD
ttl: nunca            # ou nº de dias, quando o texto afirma estado ATUAL
---

O que eu acreditava · o que medi · o que custou · o que fazer da próxima vez.
```

`ttl: nunca` para episódio histórico. Número de dias quando o texto afirma estado atual —
e aí fato vencido é **pendência de reverificação**, nunca licença para usar o valor velho.

## O índice é gerado

```bash
bash scripts/gerar-indice.sh docs/ai-harness/memoria/
```

Escreveu episódio? Rode. Índice escrito à mão mente no dia em que alguém renomeia um
arquivo — e índice que mente sobre o próprio diretório é pior que não ter índice.

## Como o aprendizado circula

| Sentido | Como |
|---|---|
| kit → projeto | o instalador materializa a semente e **atualiza só o que você não editou** |
| projeto → kit | o instalador **lista** o que é local; promover é decisão humana |

O ledger `.sdd-origem.tsv` (`arquivo → sha → data`) é o que distingue os quatro casos:
**pristino** atualiza · **editado** nunca é tocado · **local** é preservado e listado ·
**novo** entra. Sem ele a única política segura seria nunca sobrescrever — e aí correção
feita no kit jamais chegaria a quem já instalou.

**Não edite o ledger.** É registro de entrega, não configuração: mexer nele faz a
atualização confundir editado com pristino, e o modo de falha é perder o que você escreveu.
