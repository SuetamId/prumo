# Falhas silenciosas — o que passa verde e está quebrado

Lido por `prova` antes de fechar, e ao revisar código. Custo zero.

## Por que isto é uma reference própria

Teste verifica o que alguém pensou em verificar. Falha silenciosa é, por definição, o que
ninguém pensou: o erro que foi engolido, o fallback que devolveu vazio como se fosse
resposta, a promessa que ninguém esperou. **Suíte verde é compatível com sistema quebrado**,
e essa é a razão de a 2ª lei existir.

É o mesmo princípio do `NÃO MEDIU nunca é PASSOU`, virado para dentro do código: lá o
harness mente sobre ter medido; aqui o código mente sobre ter funcionado.

## Os sete padrões

Procure no diff, não na árvore — reprovar legado preexistente torna o gate inútil.

| # | Padrão | Por que mente |
|---|---|---|
| 1 | `catch` vazio, ou que só loga | a exceção sumiu e quem chamou acha que deu certo |
| 2 | Fallback que devolve vazio no erro | `[]` de "não achei" é indistinguível de `[]` de "quebrou" |
| 3 | `catch` que devolve o valor padrão | o padrão vira resposta legítima e contamina o que vem depois |
| 4 | Assíncrono sem espera | a falha acontece fora do rastro de quem chamou |
| 5 | Retorno de erro ignorado | linguagem que devolve erro em vez de lançar só falha se alguém olhar |
| 6 | Escrita sem confirmar efeito | escrever não é ter escrito. Releia, ou não afirme |
| 7 | Condição larga demais no `catch` | capturar tudo captura o bug que você acabou de escrever |

## As três perguntas

Para cada tratamento de erro que o diff introduz ou toca:

1. **Se isto falhar, quem fica sabendo?** "O log" não é resposta — ninguém lê log de
   caminho feliz. A resposta é um humano, um alerta, ou o chamador.
2. **O valor devolvido no erro é distinguível do valor de sucesso?** Se `[]` pode ser as
   duas coisas, o chamador não tem como decidir.
3. **Existe teste que prova o caminho de erro?** Caminho de erro sem teste é caminho que
   nunca rodou.

## Varredura rápida

Ponto de partida, nunca veredito — cada achado pede julgamento:

```bash
git diff --unified=0 origin/<base> | grep -nE '^\+' | \
  grep -iE 'catch\s*\([^)]*\)\s*\{\s*\}|except.*:\s*pass|catch.*\{\s*(console\.|log)|\
rescue\s*$|_\s*[,=]\s*err|catch\s*\(\s*Exception|return\s*(\[\]|\{\}|null|None)\s*;?\s*\}'
```

## Quando o silêncio é a decisão certa

Existe, e não é raro: telemetria que não pode derrubar o fluxo, limpeza no melhor esforço,
cache que pode falhar. Aí o silêncio é **deliberado** e leva marca, com o teto nomeado —
mesma convenção da dívida em `leveza/rules/ledger.md`:

```
// leveza: falha silenciosa deliberada — telemetria não derruba o fluxo
```

🔴 **Silêncio sem marca não é decisão, é defeito.** A marca é o que separa os dois, e é a
única coisa que sobrevive à pessoa que escreveu.

## Procedência

Derivado do `silent-failure-hunter` do [ECC](https://github.com/affaan-m/ECC) (MIT). Os
sete padrões, as três perguntas e a convenção de marca são daqui.
