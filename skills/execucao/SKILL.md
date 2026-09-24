---
name: execucao
description: Use quando existir plano aprovado e for hora de escrever o código — executa wave a wave, com prova a cada bloco e sem improvisar escopo.
when_to_use: >-
  "executa o plano", "implementa", plano aprovado em tasks/, retomada de execução parada.
---

# Execução

Você executa o plano. Você **não** redecide o plano.

## O laço, por wave

1. Leia **só** a wave atual. Ler o plano inteiro a cada bloco convida a antecipar.
2. 🔴 **Projeto que você não escreveu?** `rules/estilo-do-projeto.md` antes do primeiro
   bloco — o modelo escreve nos idiomas que treinou, e num projeto que decidiu diferente
   isso transforma uma base em duas.
3. Aplique `../leveza/SKILL.md` a cada bloco — inclusive ao código que o plano sugeriu.
   O plano autoriza o **quê**; a escada ainda manda no **como**.
4. Escreva o mínimo que entrega a wave.
5. **Rode a verificação da wave.** Cole a saída. Verificação que você não rodou não conta.
6. Vermelho → conserte antes de seguir. Nunca acumule wave quebrada: a segunda falha
   esconde a primeira.
7. Marque a wave e siga.

## Quando o plano está errado

Acontece, e descobrir isso é resultado bom. **Pare e diga** — não conserte em silêncio.
Um executor que ajusta o plano sozinho produz um resultado que ninguém revisou e que não
bate com o registro.

Exceção única: erro **mecânico** e óbvio no plano (caminho de arquivo trocado, nome de
símbolo errado). Corrija e nomeie a correção na saída.

## Escopo

🔴 Não faça nada que a wave não pede. Não é rigor de processo: melhoria oportunista no
meio de uma wave é o que torna o diff irrevisável, e o que faz uma correção de uma linha
virar um MR de trezentas. Viu algo para consertar? **Anote**, não conserte.

## Saída por wave

```
Wave N · <o que entregou>
verificação: <comando>
<saída colada>
anotado fora de escopo: <lista ou "nada">
```
