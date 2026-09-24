# Prova de tela — o instrumento

Lido quando a entrega é classe A ou B. Custo residente zero.

## Por que isto é uma reference e não um parágrafo

Porque "testei na tela" sem método é a afirmação mais frágil de um harness: ela parece
prova, custa nada e não sobrevive a ninguém perguntar "testou o estado vazio?".

## O roteiro

Um bloco por superfície do plano de UI.

```
Superfície: <nome>        Como cheguei: <caminho do usuário>
Referência: <degrau + nó/print/tela-modelo>

estado vazio        [ ] o que vi:
estado carregando   [ ] o que vi:
estado erro         [ ] o que vi:
sem permissão       [ ] o que vi:
parcial             [ ] o que vi:

trajeto completo    [ ] da abertura até a última opção/campo
teclado             [ ] Tab percorre na ordem visual, foco sempre visível
console             [ ] sem erro novo
antes/depois        [ ] mesmo enquadramento, mesmo instrumento
```

`n/a` é resposta válida quando o estado não existe naquela superfície. **Em branco não
é** — em branco significa "não olhei" disfarçado de "está tudo bem".

## Como capturar

Com navegador controlável disponível, capture a tela em cada estado. Sem ele, descreva o
que viu com precisão suficiente para alguém contestar: "lista com 3 linhas, cabeçalho
fixo, sem paginação" é contestável; "tela ok" não é.

## O que reprova

- Estado do plano que não foi exercitado.
- Trajeto provado só até o gatilho.
- Foco invisível em qualquer elemento operável.
- Erro novo no console.
- "Antes" reconstruído de memória em vez de capturado.

## O que NÃO reprova

- Defeito preexistente que o diff não tocou. Registre e siga — reprovar quem não causou
  o problema é como se aprende a ignorar o gate.
- Divergência de pixel contra referência de **inspiração** (degrau 2 da escada). Ela
  governa intenção e hierarquia, não medida.
