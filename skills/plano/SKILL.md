---
name: plano
description: Use quando a mudança não for trivial e antes de escrever código — transforma pedido em plano executável, com superfície de UI quando a entrega muda o que se vê.
when_to_use: >-
  triagem classificou como mudança; "planeja isso", "como a gente faz",
  feature nova, refactor que atravessa arquivos, qualquer diff previsto > 1 arquivo.
---

# Plano

Um plano existe para que quem executa **não precise decidir**. Se o executor tem de
inferir, o plano não terminou.

## Antes de escrever: resolva a incógnita

Liste o que você **não sabe** e que muda o desenho. Para cada uma: meça agora, ou
declare a assunção com o custo de estar errada. Incógnita não declarada vira retrabalho
no meio da execução, que é o lugar mais caro.

🔴 Rode `../leveza/SKILL.md` **aqui**, não na execução. A escada decide o escopo; aplicá-la
só na hora de codar significa planejar o que não precisava existir.

## Mudou o que se vê?

`../ui-plano/SKILL.md` **antes** de montar as waves. O plano de UI é entrada do plano
técnico, não um anexo: superfície e estado mudam quantos arquivos a mudança toca.

## O plano

Grava em **`tasks/prd-<slug>/plan.md`** — local, fora do git (`perfil.tsv:workspace_ativo`).
O que merecer sobreviver à entrega vai depois para o registro durável do projeto
(`perfil.tsv:registro_duravel`); o andaime morre com a feature.

Template em `.prumo/templates/plano.md`. Obrigatórios:

1. **Objetivo** — uma frase, no que muda para o usuário, não no que muda no código.
2. **Contexto embutido** — comandos de build/teste/lint do `perfil.tsv`, convenções, e o
   que o executor precisa saber. 🔴 Copiado para dentro do plano, não referenciado: quem
   executa não deve precisar abrir outro arquivo.
3. **Mapa de arquivos** — criar · alterar · deletar, com o propósito de cada um.
4. **Superfície de UI** — quando houver; sai do `ui-plano`.
5. **Waves** — cada wave é um bloco coerente que termina **verificável**. Uma wave que
   não tem como ser provada não é uma wave, é um desejo.
6. **Verificação por wave** — o comando exato, e o que significa passar.
7. **Rastreabilidade** — cada requisito → a wave que o entrega. Requisito órfão é escopo
   que ninguém pediu ou requisito que ninguém vai entregar.

## Tamanho

Plano é proporcional ao risco, não ao gosto. Duas linhas para mudança de uma linha.
Um plano que custa mais que a mudança é exatamente o que a 4ª lei proíbe.

## Saída

O caminho do plano escrito, e a primeira wave. Não comece a executar na mesma resposta:
plano não revisado é plano de uma cabeça só.
