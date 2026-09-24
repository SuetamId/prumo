---
name: aprender
description: Use ao fim de uma tarefa quando o usuário te corrigir, um comando documentado falhar, uma suposição sua for desmentida, ou a sessão revelar algo que a próxima deveria já saber.
when_to_use: >-
  "registra isso", "não erra mais isso", usuário corrigiu uma suposição sua,
  comando da doc não funcionou, achado que custou caro e vai se repetir.
---

# Aprender — instintos, não relatos

O harness fica mais inteligente porque alguém registra o que a sessão ensinou. O registro é
**estruturado e mecânico**: um instinto por arquivo, campos fixos, evidência datada.

🔴 **Nada de prosa.** Narrativa não é selecionável, não é ranqueável e não é verificável.
Se não couber nos campos abaixo, não é instinto — tem outro dono.

## Admissão — um dos dois tem de valer

1. **Contradiz o que um modelo assumiria por padrão.** Se o comportamento correto é o
   óbvio, o instinto não paga o próprio custo.
2. **É correção de rota do agente** — o que ele fez errado, não o que o sistema é.

Nenhum dos dois? Contrato vai para a doc do projeto, decisão vai para o registro durável,
valor com validade vai para `perfil.tsv`.

## A forma

Um arquivo por instinto em `docs/ai-harness/memoria/<id>.md`. Template em
`.prumo/templates/instinto.md`.

```yaml
---
id: cache-invalida-antes-do-commit
gatilho: "ao alterar entidade persistida em <módulo>"
acao: "invalidar o cache antes de commitar a transação, nunca depois"
confianca: 0.7
dominio: dados
escopo: projeto
origem: correcao-do-usuario
visto_em: 3
projetos: 1
verificado_em: 2026-09-24
---

## Evidência

- 2026-09-20 · leitura suja em produção após commit; cache invalidado depois
- 2026-09-22 · usuário corrigiu a ordem em review
- 2026-09-24 · reproduzido com teste; ordem invertida falha
```

## Os campos, e o que cada um decide

| Campo | Valores | Para que serve |
|---|---|---|
| `id` | kebab-case, é a **lição** | nome de assunto (`notas-cache`) não ensina nada |
| `gatilho` | `"quando/ao <condição observável>"` | é o que o seleciona. Condição que ninguém observa nunca dispara |
| `acao` | **uma linha**, imperativa | duas ações = dois instintos |
| `confianca` | `0.3`–`0.95` | ver a escada abaixo |
| `dominio` | `git · teste · ui · build · dados · fluxo · seguranca · ferramenta` | agrupa e ranqueia |
| `escopo` | `projeto` (padrão) · `global` | 🔴 global só por promoção medida |
| `origem` | `correcao-do-usuario · comando-falhou · medicao · curadoria` | correção do usuário vale mais que suposição |
| `visto_em` | inteiro | quantas observações sustentam |
| `projetos` | inteiro | quantos projetos distintos. É o que autoriza promover |
| `verificado_em` | `AAAA-MM-DD` | data da última confirmação |

## A escada de confiança — mecânica, não opinião

| Evento | Efeito |
|---|---|
| Nasce de observação única | `0.5` |
| Nasce de **correção explícita** do usuário | `0.7` |
| Nasce de medição reproduzida | `0.8` |
| Cada confirmação nova | `+0.1`, `visto_em +1` |
| Contrariado uma vez | `-0.2` |
| Chegou a `< 0.3` | arquiva: move para `memoria/arquivados/` |

🔴 **Teto de `0.95`. Nunca `1.0`** — instinto com certeza absoluta vira regra e sai daqui
para a reference que é dona do assunto. Memória que vira lei sem passar por revisão é como
se propaga erro confiante.

## Escopo: projeto por padrão, global por evidência

Nasce `escopo: projeto`. Vira `global` quando **`projetos >= 2`** — quando o mesmo instinto
foi observado em dois repositórios distintos. Não é preferência: instinto de um projeto
aplicado em outro é verdadeiro e inaplicável, que é o pior tipo de contexto.

Promover é ato humano. O agente **propõe** e nomeia os dois projetos.

## Seleção — o que entra na sessão

Memória cresce para sempre; contexto não. A seleção é ranqueada e com teto:

```bash
bash scripts/selecionar-instintos.sh          # os que valem para esta sessão
```

Ordena por `confianca` mais os bônus, corta no piso e no teto. Detalhe e números em
`rules/selecao.md`.

## O que NÃO entra

- Narrativa de sessão rotineira.
- Fato que o repositório já diz — se `git log` conta, não duplique.
- 🔴 **Identidade.** Sem nome de pessoa, caminho de home, e-mail, usuário ou IP privado.
  Identidade vira **papel**; valor de máquina vira **nome de variável**. É o que permite o
  instinto circular entre projetos e entre times.

## O índice é gerado

```bash
bash scripts/gerar-indice.sh docs/ai-harness/memoria/
```

Escreveu instinto? Rode. Índice escrito à mão mente no dia em que alguém renomeia um
arquivo.

## Procedência

O modelo de instinto — gatilho, confiança, domínio, evidência, escopo com promoção — é
derivado do [ECC](https://github.com/affaan-m/ECC) (MIT), adaptado e reduzido. Lá ele é
alimentado por observação automática via hooks; aqui o portão é humano de propósito.
