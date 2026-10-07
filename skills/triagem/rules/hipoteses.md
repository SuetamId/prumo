# Hipóteses — derrube antes de decidir

Lido pela `triagem` na classe **investigação**, e em **bug** cuja causa não é óbvia na
primeira leitura. Nunca em trivial. Custo zero.

## Por que três

Com uma hipótese só, toda evidência parece confirmá-la. Você lê o código procurando o
defeito que já decidiu que existe, e acha. Três hipóteses obrigam a evidência a
escolher entre elas.

## O método

1. **Escreva pelo menos três**, cada uma falsificável: "se for X, então Y é observável".
   Duas são obrigatórias, porque são as que ninguém quer escrever:
   - **o defeito é do código que eu (ou esta sessão) escrevi**;
   - **o pedido está errado** — o comportamento atual é o certo e a expectativa não.
2. Para cada uma, o **teste que a derruba** — o comando, a consulta, o log, a reprodução.
   Prefira o mais barato que separa as hipóteses, não o que confirma a favorita.
3. Rode. **Evidência é dado observado** — saída de comando, linha de log, registro do
   banco, reprodução. 🔴 Leitura de código não derruba nem confirma hipótese: ela gera
   hipótese.
4. Registre o que caiu e por quê. Hipótese derrubada é conhecimento — ela poupa a
   próxima pessoa de testar de novo.

## Saída

```
H1 <enunciado> — DERRUBADA · <evidência>
H2 <enunciado> — DERRUBADA · <evidência>
H3 <enunciado> — SOBREVIVE · <evidência que tentou derrubar e não conseguiu>
→ causa provável: H3. Próximo passo: <reprodução mínima | correção | o que falta medir>
```

Nenhuma sobreviveu? Diga isso e diga **o que falta medir** — não promova a menos pior.
Duas sobreviveram? Ache o teste que separa as duas antes de corrigir qualquer coisa.

## Depois

A causa que sobreviveu vira **bug** e segue a rota normal. A armadilha que custou caro
de achar vira episódio pela `aprender`.
