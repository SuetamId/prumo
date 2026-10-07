# Revisão — quem escreveu não aprova

Lido por `prova` antes de abrir PR, em toda classe que não seja **trivial**. Custo zero.

## Por que outro contexto

O contexto que escreveu o código carrega as mesmas premissas que produziram o defeito.
Ele relê o diff e enxerga a intenção, não o que está escrito. Revisar no mesmo contexto
é corrigir prova com o gabarito na mão.

🔴 **Nunca auto-aprovar no mesmo contexto.** Sem revisor disponível, o resultado é
**NÃO MEDIU**, não "revisado".

## Como despachar

| Cliente | Revisor |
|---|---|
| Claude Code | subagente (ferramenta de agente), sem histórico desta sessão |
| Cursor | chat novo, colando o prompt abaixo |

O revisor recebe **só** isto — nada da conversa, nada da sua opinião sobre o diff:

```
Revise o diff de `git diff origin/<base>...HEAD` neste repositório.
Pedido original: <uma frase, do plano ou do ticket>.
Prometido: <requisitos do plano, um por linha>.
Leia o código ao redor quando precisar. Não edite nada. Só escreva o relatório.

Quatro lentes:
1. Correção — o código faz o que diz? caminho de erro, borda, concorrência
2. Contrato — quem chama isto continua funcionando? API, schema, tipo exportado
3. Dado — migração reversível? dado existente sobrevive? isolamento entre clientes
4. Prova — o que foi prometido tem teste ou evidência? falhas silenciosas no diff

Para cada achado: severidade (crítico | importante | menor), arquivo:linha,
o que está errado, evidência, correção esperada, comando que prova a correção.
Crítico ou importante sem arquivo:linha e evidência vira menor.
Termine com: prometido × entregue — cada requisito: ENTREGUE | PARCIAL | AUSENTE.
```

## Depois do relatório

- **Crítico** bloqueia o PR. **Importante** se corrige ou se justifica por escrito no PR.
  **Menor** é decisão sua.
- Discordou de um achado? Argumente com evidência. Achado não se descarta em silêncio.
- Corrigiu? **Revisor novo**, olhando só o delta da correção. O revisor antigo já viu a
  versão errada e tende a confirmar a própria leitura.
- 🔴 **Teto de três rodadas.** Na terceira com crítico aberto, pare e leve à pessoa: o
  problema é de desenho, não de revisão.

## Tamanho

Proporcional ao risco, como o plano. Diff de uma linha em texto de tela não precisa de
quatro lentes; migração de dado precisa das quatro, sempre.
