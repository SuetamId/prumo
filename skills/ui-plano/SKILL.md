---
name: ui-plano
description: Use quando a entrega mudar o que a pessoa usuária vê — tela nova, alteração visível, componente. Decide que referência visual exigir, e constrói o plano de UI antes do código. Bug sem mudança visual não dispara.
when_to_use: >-
  "tela nova", "muda o layout", "novo componente", "ajusta a interface",
  "implementa essa tela", link de protótipo, print de referência,
  ou qualquer plano cujo diff toque template, estilo ou componente.
---

# Plano de UI

Interface construída por prosa sai imprecisa — sempre. Esta skill existe para que nada
de UI comece sem **referência** e sem **plano**, e para que nada que NÃO é UI pague esse
custo.

## Gate 1 — exige referência visual?

Uma pergunta, e ela é sobre o usuário, não sobre o repositório:

> A entrega muda alguma coisa que a pessoa usuária **vê**?

**Não** → pare. Nenhuma referência, nenhuma pergunta, e a linha de saída registra isso.
Alterar um `service` que muda o texto de um erro na tela **é** UI; trocar o mock de um
teste de componente não é.

## Gate 2 — a classe decide o rigor

| Classe | É | Exige |
|---|---|---|
| **A · superfície nova** | tela, modal, painel, passo ou estado que não existe | referência + plano de UI completo |
| **B · alteração visível** | muda layout, campo, coluna, ordem, estado ou texto do que já existe | referência da região + plano das partes tocadas |
| **C · sem mudança visual** | bug de lógica, performance, permissão, integração, refactor | **nada** |

🔴 **Classe C não pede referência e não pergunta.** Cobrar protótipo de quem corrige
lógica é o caminho mais curto para o time aprender a ignorar o pedido quando ele importa.

Dúvida entre B e C: se o critério de aceite pode ser escrito inteiro sem citar nada que
o usuário vê, é **C**.

## A escada de referência — desça só se o degrau acima não existir

1. **Protótipo medido.** Figma (ou equivalente) lido por **MCP**, pelo **nó** da
   superfície — nunca pelo arquivo inteiro, que guarda exploração descartada ao lado do
   aprovado. Nunca reconstrua de screenshot: perde medida, token, estado e variante.
2. **Referência de base.** Print, link, ou a tela de um produto que serve de inspiração.
   Declare que é inspiração: ela governa **intenção e hierarquia**, não medida. Medida
   sai do degrau 3.
3. 🔴 **O próprio produto.** Sem protótipo e sem referência, **mapeie a interface atual**
   e construa em cima dela — `rules/mapear-padroes.md`. Isto **não** é o degrau da
   desistência: é o degrau que produz consistência, e numa base madura costuma dar
   resultado melhor que um protótipo solto que ninguém conciliou com o que já existe.
4. **Nada.** Só quando o produto não tem interface alguma ainda. Aí valem os padrões de
   `rules/qualidade-ui.md` e a decisão vira registro, porque ela cria precedente.

**O plano de UI é obrigatório nos quatro degraus.** O degrau muda de onde vem a forma,
não se existe plano. Foi essa confusão que produziu o sintoma original: sem Figma, o
agente pulava direto para o código.

## Peça uma vez, e não bloqueie

Classe A ou B sem referência identificada: pergunte **uma vez**, com a saída pronta.

> Isto mexe em `<superfície>`. Não achei referência visual.
> Com o nó do protótipo eu construo pela medida real — espaçamento, estado, variante.
> Sem ele, eu mapeio a interface atual e construo pelo padrão que já existe aí.
> Tem protótipo ou alguma referência, ou sigo pelo padrão do produto?

- **Uma vez por execução.** Respondida, não repita a cada tela.
- **Não escolha sozinho.** Degradar em silêncio esconde que existia opção melhor.
- **Não bloqueia.** "Segue" segue, na hora.
- **Declare o degrau na saída.**

## O plano de UI

Antes da primeira linha de template. Grava em **`tasks/prd-<slug>/ui.md`**, ao lado do
plano técnico e fora do git. Template em `templates/ui-plano.md` (desta skill), cinco blocos:

1. **Superfícies** — o que é tocado, como se chega, nova ou existente, referência de cada.
2. **Estados** — vazio · carregando · erro · sem permissão · desabilitado. Uma linha por
   superfície, `n/a` onde não existe, nunca em branco. O estado que ninguém descreve é o
   que volta como bug.
3. **Componentes** — elemento → o que já existe no produto → veredito → o que será usado.
   Nunca construa antes de procurar: `rules/mapear-padroes.md`.
4. **Texto** — rótulo, mensagem, erro, estado vazio. Vem da especificação escrita, nunca
   do protótipo. Com chave de i18n quando o produto usa.
5. **Divergências** — o que a referência mostra × o que a spec diz × o que foi feito.
   `nenhuma` é linha válida; em branco não é.

## Antes de escrever estilo

`rules/anti-slop.md` — as marcas que todo modelo deixa, e o que fazer no lugar. Rode o
detector determinístico no fim:

```bash
bash scripts/detectar-slop.sh <dir>     # scripts/ desta skill · 0 limpo · 2 achados · 1 não mediu
```

**Se o Impeccable estiver instalado, ele manda** — ele é dedicado a isto, roda sobre o DOM
renderizado e tem muito mais alcance que o nosso piso. Cheque antes de usar o nosso:

```bash
ls .claude/skills/impeccable .cursor/skills/impeccable 2>/dev/null
```

Nosso detector é o piso para quando ele não está lá. O plano de UI continua sendo nosso:
ele decide **quando** o ofício visual entra e o que conta como pronto.

## Prova

A prova de UI **é a tela**, não o teste. Detalhe em `../prova/SKILL.md`: teste unitário
verde com a tela quebrada é o caso normal, não a exceção.

## Saída obrigatória

Uma linha, sempre, inclusive quando não há nada a exigir:

```
UI: classe C · sem mudança visual · nada perguntado
UI: classe B · degrau 1 (2 nós) · 3 componentes reusados · plano em tasks/prd-<slug>/ui.md
UI: classe A · degrau 3 (padrão do produto) · 12 telas mapeadas · plano em tasks/prd-<slug>/ui.md
```
