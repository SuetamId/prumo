---
name: prova
description: Use antes de dizer que algo está pronto, corrigido ou passando — exige evidência colada, e quando a entrega toca interface a prova é a tela real, não só o teste.
when_to_use: >-
  "está pronto?", "funciona?", antes de abrir MR/PR, antes de fechar task,
  "verifica", "testa isso", qualquer afirmação de que algo passou.
---

# Prova

**Evidência antes de afirmação.** Você não diz "pronto", "corrigido" ou "passando" sem
ter rodado o comando e colado a saída na mesma resposta.

## As três camadas, e nenhuma substitui a outra

| Camada | Responde | Não responde |
|---|---|---|
| **Unitário** | a lógica está certa | se está ligada em alguma coisa |
| **Integração / E2E** | as peças conversam | se a pessoa consegue usar |
| **Interface real** | a pessoa consegue usar | nada além do que você olhou |

🔴 **Suíte verde com a tela quebrada é o caso normal, não a exceção.** Teste de
componente monta o componente isolado, com mock no lugar do que quebra: o dado real, o
CSS do host, o z-index do overlay, a rota, a permissão. Parar no verde é parar antes da
pergunta que importa.

## Quando a entrega toca interface, a prova é a tela

Obrigatório para classe **A** e **B** do `../ui-plano/SKILL.md`. Detalhe operacional em
`rules/prova-de-tela.md`. O mínimo:

1. **Suba de verdade** — o comando está em `perfil.tsv` (`ui_dev`).
2. **Chegue na tela pelo caminho do usuário**, não por URL direta que pula guarda de rota.
3. **Exercite os cinco estados** do plano de UI: vazio, carregando, erro, sem permissão,
   parcial. Estado planejado e não exercitado não está entregue.
4. **Percorra o trajeto inteiro** da interação, não só o gatilho. A prova de um menu é
   chegar na **última** opção — não é ele abrir.
5. **Teclado e foco** — `Tab` até o fim, foco sempre visível.
6. **Antes e depois**, com o mesmo instrumento e o mesmo enquadramento. Comparação com
   enquadramento diferente não é comparação.
7. **Console limpo.** Erro novo no console é achado, mesmo com a tela parecendo certa.

## Falha silenciosa — o que passa verde e está quebrado

`rules/falhas-silenciosas.md`. Suíte verde é compatível com sistema quebrado: o erro
engolido, o fallback que devolve vazio como se fosse resposta, o assíncrono que ninguém
esperou. Sete padrões e três perguntas, sobre o diff.

## Revisão e PR

Antes de abrir PR, em toda classe que não seja trivial: **revisão em outro contexto** —
`rules/revisao.md`. Quem escreveu não aprova. Depois, a entrega por PR segue
`rules/entrega-pr.md`: o que pode sem pedir, corpo que não executa, CI classificado.

## Regra de honestidade

Três resultados, e o terceiro é o que quase todo harness perde:

- **PASSOU** — rodou e deu verde. Cole a saída.
- **FALHOU** — rodou e deu vermelho. Cole a saída.
- 🔴 **NÃO MEDIU** — não rodou, não subiu, faltou ferramenta, faltou acesso.

**NÃO MEDIU nunca é PASSOU.** É o resultado mais importante dos três, porque é o único
que costuma ser reportado como um dos outros dois. Ferramenta que falta tem que
aparecer, não desaparecer.

## Antes de fechar

- [ ] Todo requisito do plano tem prova nomeada
- [ ] Todo estado do plano de UI foi exercitado na tela
- [ ] Nenhum `TODO`, `FIXME` ou `console.log` no código novo
- [ ] Atalho deliberado marcado com `leveza:` e teto nomeado
- [ ] O que ficou fora está dito, não omitido
- [ ] Revisado em outro contexto, sem crítico aberto — ou NÃO MEDIU, dito
