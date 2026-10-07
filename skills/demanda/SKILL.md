---
name: demanda
description: Use quando alguém de produto quiser transformar uma ideia, pedido de cliente ou problema em demanda pronta para engenharia — investiga o que já existe, pergunta só o que muda o resultado e registra a história no rastreador depois de aprovada.
when_to_use: >-
  "cria uma demanda", "escreve a história", "abre no Jira", "refina essa ideia",
  "o cliente pediu…", PM com texto solto, print ou link querendo virar issue.
  NÃO dispare para implementar nem para planejar a parte técnica — isso é `plano`.
---

# Demanda — da ideia à história pronta para engenharia

Quem pede não precisa saber escrever issue. Quem implementa não pode precisar adivinhar.
Esta skill fica no meio: transforma a ideia em uma **história de negócio** clara, verificável
e honesta sobre o que ainda não foi decidido.

🔴 **Garantias, não tarefas.** A história diz **o que** o produto passa a garantir e **para
quem**. Como construir — tabelas, endpoints, arquivos, divisão em tasks por camada — é do
`plano`, feito por quem lê o código de cada repositório. Escrever isso aqui produz o defeito
mais comum de issue gerada por IA: detalhe técnico chutado sobre um código que não foi lido.

## 1. Entender o pedido

Receba o que vier — texto, print, link de issue, conversa colada. Aproveite tudo que já foi
dito; não pergunte o que já está lá.

## 2. Investigar antes de perguntar

Pergunta que a investigação responderia é custo jogado na pessoa. Detalhe em
`rules/investigar.md`. Em resumo:

- **Rastreador:** issues parecidas, épico a que isso pertence, decisões já tomadas.
- **Código** (só se houver acesso — Claude Code com os repositórios): o que **já existe** e o
  que **não existe**, em **todos** os repositórios do produto. Só leitura.
- **Sem acesso ao código** (chat): não afirme nada sobre ele. "Situação atual" vira pendência
  para a engenharia confirmar.

## 3. Perguntar só o que muda o resultado

Depois de investigar, sobra o que só uma pessoa decide: público, regra, limite, prioridade.
Pergunte **uma coisa por vez**, com opções concretas e a sua recomendação. Detalhe que não
muda escopo, regra nem aceite não é pergunta — é premissa declarada na história.

## 4. Escrever a história

Siga o formato do **próprio projeto**: antes de escrever, leia 2 ou 3 issues recentes do mesmo
tipo no projeto de destino e copie a estrutura de seções, o estilo do título e os labels.
Sem padrão claro, use `templates/historia.md`. Em qualquer formato, estas partes não faltam:

| Parte | Por quê |
|---|---|
| **Objetivo** — o que muda para quem usa, em uma frase | é o que a engenharia vai perguntar primeiro |
| **Exemplo prático** — uma situação concreta, com nomes de papéis | transforma regra abstrata em algo que todo mundo entende igual |
| **Situação atual** — o que já existe e o que não existe | evita refazer o que existe; só com fonte (código lido ou issue) |
| **Regras de negócio** | o que vale sempre, inclusive nos casos de erro |
| **Cenários** — Dado / Quando / Então | o caminho feliz, o de erro e o de permissão |
| **Critérios de aceite** — numerados, observáveis | é por eles que a entrega é provada |
| **Fora de escopo** | o que alguém poderia supor que entra, e não entra |
| **Pendências** — decisão aberta, impacto, quem decide | 🔴 nunca escondidas no meio das regras como "a definir" |

Uma demanda pequena cabe em poucas linhas por parte. Não invente métrica, prazo ou número
para encorpar o texto.

## 5. Revisar antes de mostrar

- Todo critério de aceite é verificável por alguém de fora? ("funcionar bem" não é.)
- Alguma regra depende de uma decisão que ninguém tomou? → vira **pendência**, não regra.
- Há nome de tabela, endpoint, arquivo ou método? → tire. É do `plano`.
- Tem segredo (token, senha, chave) em algum lugar? → tire antes de qualquer registro.

Com pendência aberta que muda escopo, regra ou aceite, a história **não está pronta**. Diga
isso no preview — ela pode ser registrada assim, mas marcada como pendente.

## 6. Mostrar, confirmar e registrar

Mostre o texto final e diga **onde** vai entrar: projeto, tipo (Story; Epic se for um conjunto
grande), épico pai, labels. Só registre depois de um "sim" explícito para **esse conteúdo e esse
destino**. Como registrar e provar o registro: `rules/rastreador.md`.

Termine com o link da issue criada e, se houver, a lista de pendências com quem decide cada uma.
