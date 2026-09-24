# Deriva de estilo — o modelo impondo os idiomas que ele treinou

Lido antes do primeiro bloco de código em projeto que você não escreveu. Custo zero.

## O problema, em uma frase

Todo modelo treinou nos mesmos repositórios populares, e escreve como eles. Num projeto
que decidiu diferente — de propósito, anos atrás, por um motivo que ninguém mais lembra —
cada bloco novo vem no idioma do treino, não no idioma do projeto. O código passa no
review, passa no lint, funciona. E a base vira duas bases.

É o mesmo mecanismo do slop visual (`ui-plano/rules/anti-slop.md`), aplicado à
arquitetura em vez da tela. Lá é Inter e gradiente roxo; aqui é o repository pattern que
ninguém pediu e a camada de serviço que o projeto não tem.

## O que se alinha, e o que não

🔴 **Alinhe meta-arquitetura. Não alinhe sintaxe.**

| Alinhe | Não alinhe |
|---|---|
| como o projeto separa camadas | formatação — isso é do formatter |
| onde estado mora, e quem pode alterá-lo | preferência pessoal de `const` vs `let` |
| como erro atravessa a fronteira | nome de variável em código antigo |
| como dependência entra (injeção, import direto, singleton) | idade do estilo — antigo não é errado |
| granularidade de arquivo e módulo | |
| como o projeto testa: unidade sobre o quê, dublê de quê | |

Sintaxe é barulho no diff e o formatter resolve. Meta-arquitetura é o que faz a base ser
uma só.

## Como medir, antes de escrever

Sempre **três** amostras, nunca uma: uma amostra é acidente, três é padrão.

**1. Ache o vizinho mais próximo do que você vai escrever.**
Mesmo papel, não mesmo nome: se você vai escrever um handler de rota, ache três handlers.

**2. Leia o fluxo inteiro de um deles**, da borda ao dado e de volta. Não leia só o
arquivo que você vai tocar — o padrão mora na travessia, não no ponto.

**3. Responda estas cinco, por evidência com caminho:**

| Pergunta | O que procurar |
|---|---|
| Quantas camadas o dado atravessa? | conte no fluxo que você leu |
| Erro sobe, ou é tratado onde acontece? | `try`/`catch`/`Result`/`error` nos três vizinhos |
| O que é injetado e o que é importado direto? | topo dos arquivos vizinhos |
| Um arquivo = uma coisa, ou módulo agrupado? | tamanho e contagem dos vizinhos |
| O que é testado, e o que é dublê? | os testes DOS vizinhos, não a config de teste |

## A regra de decisão

Se o projeto faz **diferente** do que você faria: **faça como o projeto**, e siga.

Duas exceções, e só duas:

1. **O padrão do projeto está medido como defeituoso** — não "é antigo", não "eu faria
   melhor": defeituoso, com evidência. Aí você nomeia a divergência no plano, com o
   caminho do arquivo que prova.
2. **O usuário pediu explicitamente para modernizar**, e isso é escopo próprio — nunca
   carona dentro de outra mudança.

🔴 **Modernização de carona é o dano mais caro deste documento.** Ela mistura, no mesmo
diff, a mudança que alguém pediu e a que ninguém revisou — e torna as duas irrevisáveis.

## Saída

Uma linha, antes do primeiro bloco:

```
Estilo: 3 vizinhos lidos (<caminhos>) · camadas: N · erro: sobe até <onde> · dep: <como> · sigo o padrão
Estilo: divergindo em <o quê> porque <evidência com caminho> — registrado no plano
```

## Procedência

Derivado do conceito de *style drift* do [ECC](https://github.com/affaan-m/ECC) (MIT).
A fronteira meta-arquitetura × sintaxe e a regra das três amostras são daqui.
